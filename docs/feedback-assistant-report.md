# Feedback Assistant report (ready to file)

**Area:** Developer Tools ▸ Xcode ▸ Devices (Device Hub) — also relevant to watchOS ▸ Developer Mode
**Type:** Incorrect / Unexpected Behavior
**Title:** Apple Watch never reconnects after a successful manual pairing (Device Hub, watchOS 27); CoreDevice never creates the device

## Summary

After CoreDevice dropped its record of an Apple Watch Ultra 2, re-pairing it from Device Hub
(*File ▸ Pair Nearby Device…*) completes PairSetup (M1–M6) and reports `Pairing session of kind setupManualPairing succeeded`,
and the setup channel closes ~30 ms later (as it does for an iPhone). The iPhone then reconnects within ~1.4 s
(`verifyManualPairing succeeded`) and becomes available; the watch **never reconnects** and does not advertise
`_remotepairing._tcp`. It never appears in `devicectl list devices`, so it is unusable as a run destination.

## Steps to reproduce

1. Have an Apple Watch paired to an iPhone and previously added to the Mac as a manually paired device.
2. Let the watch become `unavailable`; observe CoreDevice remove its record
   (`remotepairingd: Unable to remove pairing record for UDID 00008310-… in usbmux`).
3. On the watch, open *Settings ▸ Privacy & Security ▸ Developer Mode* (Developer Mode on).
4. On the Mac, open Device Hub ▸ *File ▸ Pair Nearby Device…*, enter the challenge code shown.
5. Observe `remotepairingd` and `xcrun devicectl list devices`.

## Expected

After the setup channel closes, the watch reconnects (`verifyManualPairing`), CoreDevice creates a device record, and the watch
is `available` and can receive apps — as an iPhone does in the same situation.

## Actual

* `PairSetup server done -- client authenticated`, `Pairing session … succeeded`, state `authenticated`.
* ~30 ms later: `tcp-N: received error reading message`, state `invalidated` (also seen with an iPhone — expected).
* **Control (iPhone):** +1.4 s later `verifyManualPairing … succeeded`; device becomes available. **Watch: nothing follows.**
* Device Hub: `Beaconing pairing session explicitly ended by client`; a later `AcquireDeviceUsageAssertion` fails with
  `The specified device was not found (1000)`.
* `xcrun devicectl list devices` has no watch entry; `xcrun devicectl manage pair --device <udid>` → error 1000.
* No `_remotepairing._tcp` / `_remotepairing-manual-pairing._tcp` advertisement from the watch after pairing.
* Reproduced 5 times, including on the updated watchOS (27.2, build 24S5091f).

Also, with the iPhone on USB the Mac attaches the watch as a *proxied device* and logs
`Device … supports user-driven network pairing flows. Skipping companion proxy bootstrap pairing`.
Installing from the iPhone Watch app ▸ Install fills ~50 %, then stalls and the watch restarts (as reported by the user).

## Environment

* macOS 27.2 (26B5086k), MacBook Pro (MacBookPro17,1, M1)
* Xcode 27.0 (27A5237l), Device Hub
* iPhone 15 Pro Max (iPhone16,2), iOS 27.0
* Apple Watch Ultra 2 (Watch7,5), watchOS 27.0, then updated to 27.2 (24S5091f): same behavior
* Free Apple Developer account

## Attachments to include

* `log show` excerpt from `remotepairingd` and `DeviceHub` around the pairing (see the repository's `logs/`).
* sysdiagnose from the **Mac** taken right after a failed pairing.
* sysdiagnose from the **watch** (paired iPhone ▸ Watch app, or the watch side-button gesture) taken right after a failed pairing.
* Output of `xcrun devicectl list devices --json-output -` and `xcrun xcdevice list`.

Repository with the full write-up: https://github.com/kisnner26/watchos27-pairing-bug
