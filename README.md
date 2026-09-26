# Apple Watch never reconnects after a successful manual pairing (watchOS 27 + Xcode 27 / Device Hub)

🇪🇸 [Leer en español](README.es.md)

> **Status: open · the fault is on the watch.** Last updated 2026-09-25.
> **Reported to Apple:** Feedback Assistant **FB24924229** (2026-09-24). If you hit the same problem, please file your own report and mention that number.
> **2026-09-25:** no reply from Apple yet. New: other developers report this family of problems on Xcode 27 betas, and two forum threads describe fixes
> (pair with the **iPhone powered off**; **start the pairing from the watch**). See [`docs/community-findings.md`](docs/community-findings.md).
> Retested after updating the watch (**watchOS 27.2, build 24S5091f**): same behavior. See [`docs/status-log.md`](docs/status-log.md).
>
> 🆕 **New (2026-09-24, night):** when the Mac is kept listening, the watch **does come back — but asks for a brand-new pairing**
> instead of verifying the one it just made. It loops: setup → close → setup. See [The pairing loop](#the-pairing-loop).
>
> ⚠️ **Correction (2026-09-24):** an earlier revision of this write-up treated the ~40 ms disconnect after pairing as the fault.
> A control run with the iPhone shows that disconnect is **normal**; the real fault is that the watch **never reconnects afterwards**.

An Apple Watch Ultra 2 that used to work as an Xcode run destination **disappeared from the Mac**
(`devicectl` first listed it as `unavailable`, then not at all). Re-pairing it from **Device Hub**
(*File ▸ Pair Nearby Device…*) **succeeds** (PairSetup M1–M6, `setupManualPairing succeeded`). The setup channel is then
closed within ~30–40 ms — which also happens to an iPhone, that **reconnects ~1.3 s later** (`verifyManualPairing`) and becomes
available. The watch **never reconnects**: no `verifyManualPairing`, no `_remotepairing._tcp` advertisement, and CoreDevice never
creates a device record for it.

This repository documents the symptoms, the log evidence, everything that was tried, and a ready-to-file
Feedback Assistant report. Personal identifiers (UDIDs, device names, network addresses) are redacted.

## Environment

| | |
|---|---|
| Mac | MacBook Pro (`MacBookPro17,1`, Apple M1), macOS 27.2 (`26B5086k`) |
| Xcode | 27.0 (`27A5237l`) — Devices are now managed by the separate **Device Hub** app |
| iPhone | iPhone 15 Pro Max (`iPhone16,2`), iOS 27.0 |
| Watch | Apple Watch Ultra 2 (`Watch7,5`), watchOS 27.0 → updated to **27.2 (24S5091f)** |
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

**3. Manual pairing succeeds, the setup channel closes, and the watch never comes back.**
Five watch attempts (10:02, 10:03, 10:14, 10:15 on watchOS 27.0; 10:55 after the update) all followed the same sequence.
Here is the 10:15 one in detail:

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

The SRP pairing (M1–M6) completes and the host stores the new pairing; the peer then closes the setup connection.
Device Hub ends the session and a follow-up `AcquireDeviceUsageAssertion` fails with *"The specified device was not found" (1000)*.

**4. Control case (iPhone, same Mac, same minute).** After *Reset Location & Privacy* the iPhone also had to be re-paired. It behaves
identically for the first 30 ms, and then recovers:

| | setup succeeded | setup channel closed | reconnect |
|---|---|---|---|
| iPhone | 10:54:22.173 | 10:54:22.209 (**+36 ms**) | **10:54:23.592** `verifyManualPairing succeeded` (+1.4 s) → *available* |
| Watch  | 10:55:08.951 | 10:55:08.980 (**+29 ms**) | **none** — and nothing advertises on Bonjour |

So the ~40 ms close is expected. What is missing is the watch's reconnection (and its own advertisement) that the iPhone performs.
(An earlier revision used an iPad `verifyManualPairing` as the control; that was a reconnect, not a setup, so it was not a valid comparison.)

## Timeline (local time, UTC−6)

| Time | Event |
|---|---|
| 00:08 | Watch works: an app is installed with `devicectl`. |
| 06:05 | First observation: watch is `unavailable`. |
| 09:33 | `remotepairingd` tries to remove the watch's pairing record. Watch disappears from `devicectl`. |
| 09:37 | iPhone on USB: watch seen as proxied device; automatic pairing skipped (see above). |
| 10:02 – 10:15 | Four manual pairings from Device Hub: each succeeds; the watch never reconnects. |
| later | *Reset Location & Privacy* on the iPhone; watch updated to 27.2 (24S5091f). |
| 10:54 | iPhone re-paired: setup → close (+36 ms) → **reconnects** → available. |
| 10:55 | Watch re-paired on the updated watchOS: setup → close (+29 ms) → **no reconnect**. |

## The pairing loop

Unlike an iPhone (which the Mac finds over `_remotepairing._tcp`), a watch pairs **into** the Mac: it connects to the Mac's
`_remotepairing-pairable-host._tcp` listener. `remotepairingd` only runs that listener while Device Hub's
*Pair Nearby Device…* sheet is open, and the sheet closes itself ~300–400 ms after setup. So the watch not advertising
`_remotepairing._tcp` is probably normal.

[`tools/watch-pair-keeper.sh`](tools/watch-pair-keeper.sh) reopens the sheet the moment it closes (listener gap: 0.6 s). Result:

```
22:53:00.613  setupManualPairing succeeded (watch)      → channel closed at +305 ms
22:53:01.533  Mac listening again
22:53:23.502  the watch connects again  ✅
22:53:23.558  …with startNewSession: true, kind: setupManualPairing   ← a NEW pairing, not verify
22:53:23.559  Device Hub shows a new pairing code
22:53:33.642  setupManualPairing succeeded (watch)      → closed again at +286 ms
```

The watch reconnects, but it behaves as if it had forgotten the pairing it finished 23 seconds earlier. The Mac side
(stores the pairing, listens) works; the watch does not keep or does not use its side. That logic lives in watchOS
(`remotepairingdeviced`), so it cannot be fixed from the Mac.

Also tried: *Unpair this device* on the watch's Developer settings, then re-pair (same); an independent host with
**pymobiledevice3** `remote pair-host`, over IPv4 and IPv6 ([`tools/pair_host_dualstack.py`](tools/pair_host_dualstack.py)):
the watch lists it and asks for its passcode, but never opens a connection. Details in
[`logs/remotepairingd-excerpts.md`](logs/remotepairingd-excerpts.md) § F–I.

## What is *not* the problem

* **The app being installed.** The watch app was validated: Apple Development signature, provisioning
  profile contains the watch UDID, bundle IDs and versions match the iPhone app, Release build.
* **Bluetooth / Wi-Fi / network.** Tried with Bluetooth on and off, Wi-Fi toggled, same network and band.
* **Cable.** With USB the Mac even sees the watch (proxied device); the failure is the same.
* **Developer Mode.** Enabled (also toggled off/on, and the pairing sheet is only offered from that screen).

See [`docs/what-i-tried.md`](docs/what-i-tried.md) for the full list.

## Hypotheses

1. **The watch does not persist (or does not use) the host pairing after setup.** Supported by the loop above: on reconnect it
   asks for a new pair-setup instead of pair-verify. Removing the Mac on the watch and pairing again does not change it.
2. **CoreDevice needs a verified connection to create the device record**, so a watch that never verifies stays invisible.
3. ~~The watch does not announce itself after setup.~~ Watches pair *into* the Mac's pairable-host listener; not advertising
   `_remotepairing._tcp` is probably by design.

Nothing on the Mac side fixed it. The only untried step is erasing the watch; otherwise this needs a watchOS fix.

## Tools

* [`tools/watch-pair-keeper.sh`](tools/watch-pair-keeper.sh) — reopens Device Hub's pairing sheet right after setup and reports
  whether the watch reconnected (needs Accessibility permission for the terminal).
* [`tools/pair_host_dualstack.py`](tools/pair_host_dualstack.py) — pymobiledevice3 pairable host on IPv4 + IPv6.

## Community findings (2026-09-25)

* An Apple DTS engineer acknowledged a possible Xcode / watchOS 26.2 regression in the
  [Apple Developer Forums](https://developer.apple.com/forums/thread/813066) and asked for Feedback reports with logging profiles;
  no Feedback IDs were shared there.
* Two Xcode 27 beta threads report fixes worth trying: pairing with the **iPhone powered off**
  ([thread](https://developer.apple.com/forums/thread/837517)), and **starting the pairing from the watch** under
  *Developer Mode ▸ paired devices* ([thread](https://developer.apple.com/forums/thread/829704)).
* No other public GitHub issue about this exact behavior was found; the closest is a tvOS 27 tool where pairing "succeeds" but the device is never
  registered ([bitxeno/atvloadly#121](https://github.com/bitxeno/atvloadly/issues/121)).
* Also tested here without success: 2.4 GHz for all devices, private Wi-Fi address off, Mac on the iPhone's hotspot (the watch never joined it).

Details and sources: [`docs/community-findings.md`](docs/community-findings.md).

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
