# Apple Watch drops the connection right after a successful pairing (watchOS 27 + Xcode 27 / Device Hub)

🇪🇸 [Leer en español](README.es.md)

> **Status: open · investigating.** Last updated 2026-09-24.
> Retest pending on **watchOS 27.2 beta 2**. Results will be added to [`docs/status-log.md`](docs/status-log.md).

An Apple Watch Ultra 2 that used to work as an Xcode run destination **disappeared from the Mac**
(`devicectl` first listed it as `unavailable`, then not at all). Re-pairing it from **Device Hub**
(*File ▸ Pair Nearby Device…*) **succeeds**, but **~40 ms later the watch closes the TCP connection**,
so CoreDevice never creates a device record and the watch never becomes available again.

This repository documents the symptoms, the log evidence, everything that was tried, and a ready-to-file
Feedback Assistant report. Personal identifiers (UDIDs, device names, network addresses) are redacted.

## Environment

| | |
|---|---|
| Mac | MacBook Pro (`MacBookPro17,1`, Apple M1), macOS 27.2 (`26B5086k`) |
| Xcode | 27.0 (`27A5237l`) — Devices are now managed by the separate **Device Hub** app |
| iPhone | iPhone 15 Pro Max (`iPhone16,2`), iOS 27.0 |
| Watch | Apple Watch Ultra 2 (`Watch7,5`), watchOS 27.0 (being updated to 27.2 beta 2) |
| Signing | Free Apple Developer account (Personal Team) |
| Pairing | The watch is a *manually paired* device in CoreDevice (`Authentication Type: manualPairing`) |

## Symptoms

1. `xcrun devicectl list devices` → the watch shows `unavailable`; later it **vanishes from the list**.
2. `xcrun devicectl manage pair --device <watch>` → `The specified device was not found (error 1000)`.
3. `xcrun xcdevice list` and `xcrun xctrace list devices` never list the watch.
4. Device Hub shows the watch page with **"Currently Unavailable — must be nearby to connect with this Mac"**.
5. The watch **does not advertise** `_remotepairing._tcp` / `_remotepairing-manual-pairing._tcp` over Bonjour
   while idle (only the iPhone and iPad do).
6. Installing an app from the **iPhone Watch app** ▸ *Install*: the progress ring fills about halfway,
   nothing happens, **the watch (reportedly) restarts**, and nothing is installed.
7. The iPhone ↔ watch link itself is healthy (Apple Watch Mirroring works).

## What the logs show

Full sanitized excerpts: [`logs/remotepairingd-excerpts.md`](logs/remotepairingd-excerpts.md).

**1. The Mac purged its record of the watch.**
`remotepairingd: Unable to remove pairing record for UDID 00008310-… in usbmux`
The watch had been `unavailable` for hours; from then on CoreDevice no longer knew it.

**2. watchOS 27 requires a user-driven pairing and the automatic path is skipped.**
With the iPhone on USB, the Mac sees the watch as a *proxied device* and then gives up:

```
Received MobileDevice device attach notification for proxied device 00008310-…
Attempting to bootstrap pairing using MobileDevice for device with UDID <private>
Device <private> supports user-driven network pairing flows. Skipping companion proxy bootstrap pairing
```

**3. Manual pairing succeeds, then the watch hangs up.** From Device Hub, four attempts
(10:02, 10:03, 10:14, 10:15 local time) all followed the same sequence — here the last one:

```
10:15:14.xxx DeviceHub   Presenting pairing challenge for "<watch name>"
10:15:20.954 remotepairingd  PairSetup server M3 -- verify request
10:15:20.979 remotepairingd  PairSetup server M4 -- verify response
10:15:22.397 remotepairingd  PairSetup server M5 -- exchange request
10:15:22.399 remotepairingd  Re-playing discovery … as new pairing for device with udid "00008310-…" has been added
10:15:22.400 remotepairingd  PairSetup server M6 -- exchange response / done -- client authenticated / Pairing completed
10:15:22.400 remotepairingd  tcp-13: Pairing session of kind setupManualPairing succeeded
10:15:22.401 remotepairingd  tcp-13 (00008310-…): ControlChannel … -> authenticated
10:15:22.441 remotepairingd  tcp-13: received error reading message: <private>          ← +40 ms
10:15:22.442 remotepairingd  tcp-13 (00008310-…): ControlChannel … authenticated -> invalidated
10:15:22.713 DeviceHub   Beaconing pairing session explicitly ended by client
```

The SRP pairing (M1–M6) completes and the host stores the new pairing, but the peer resets the TCP
connection immediately afterwards. Device Hub then ends the session, and a follow-up
`AcquireDeviceUsageAssertion` fails with *"The specified device was not found" (1000)*.

**4. Control case: the iPad works.** The same daemon completes `verifyManualPairing` for the iPad
and keeps its control channel `authenticated`. Only the watch is dropped.

## Timeline (local time, UTC−6)

| Time | Event |
|---|---|
| 00:08 | Watch works: an app is installed with `devicectl`. |
| 06:05 | First observation: watch is `unavailable`. |
| 09:33 | `remotepairingd` tries to remove the watch's pairing record. Watch disappears from `devicectl`. |
| 09:37 | iPhone on USB: watch seen as proxied device; automatic pairing skipped (see above). |
| 10:02 – 10:15 | Four manual pairings from Device Hub: each succeeds, each is cut ~40 ms later. |
| later | *Reset Location & Privacy* on the iPhone; watchOS update to 27.2 beta 2 started. |

## What is *not* the problem

* **The app being installed.** The watch app was validated: Apple Development signature, provisioning
  profile contains the watch UDID, bundle IDs and versions match the iPhone app, Release build.
* **Bluetooth / Wi-Fi / network.** Tried with Bluetooth on and off, Wi-Fi toggled, same network and band.
* **Cable.** With USB the Mac even sees the watch (proxied device); the failure is the same.
* **Developer Mode.** Enabled (also toggled off/on, and the pairing sheet is only offered from that screen).

See [`docs/what-i-tried.md`](docs/what-i-tried.md) for the full list.

## Hypotheses

1. **Out-of-sync pairing state.** The Mac dropped its record (09:33) without the watch forgetting the Mac.
   A new setup then conflicts with the watch's old record and the watch aborts after M6.
2. **watchOS 27.0 beta bug** in the step that follows PairSetup (persisting the pairing / opening the
   control channel). This would also fit the watch rebooting when an install is requested from the iPhone.

Neither is confirmed. Retest on watchOS 27.2 beta 2 will help separate them.

## Reproduce / gather evidence

```sh
xcrun devicectl list devices
xcrun devicectl manage pair --device <watch-udid>
/usr/bin/log show --last 30m --predicate 'process == "remotepairingd"' | grep -E "Presenting pairing challenge|PairSetup|Pairing session|received error reading|explicitly ended"
```

More in [`docs/how-to-collect-logs.md`](docs/how-to-collect-logs.md).

## Report to Apple

A ready-to-file text for Feedback Assistant is in
[`docs/feedback-assistant-report.md`](docs/feedback-assistant-report.md).

If you see the same thing, please add your environment (Xcode / macOS / watchOS builds) in an issue.

## License

[MIT](LICENSE). Not affiliated with Apple Inc.
