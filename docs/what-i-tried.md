# What was tried

Everything below was done with the symptoms described in the [README](../README.md).
✅ = ran without error but did **not** bring the watch back · ❌ = not possible / errored.

## Watch and iPhone

| Attempt | Result |
|---|---|
| Restart the watch (several times, before and after re-pairing) | ✅ no change |
| Restart the iPhone | ✅ no change |
| Developer Mode on the watch: off → reboot → on | ✅ no change |
| iPhone Bluetooth off (Settings ▸ Bluetooth, to push the watch onto Wi-Fi) | ✅ no change |
| iPhone Bluetooth back on | ✅ no change |
| Watch on the same Wi-Fi network / band as the Mac | ✅ no change |
| Personal Hotspot from the iPhone for all three devices | not tested |
| *Reset Location & Privacy* on the iPhone (clears trusted computers) | ✅ done; effect pending |
| Update the watch to watchOS 27.2 beta 2 | ✅ done (reported); re-pairing shows the same result: no reconnect |
| Re-pair the **iPhone** after the privacy reset (control) | ✅ works: setup → reconnect (`verifyManualPairing`) → available |

## Mac

| Attempt | Result |
|---|---|
| Kill / restart `CoreDeviceService` | ✅ no change |
| Open Xcode; open Device Hub | ✅ no change |
| Toggle Mac Wi-Fi | ✅ no change |
| iPhone on **USB** | ✅ Mac now sees the watch as a *proxied device*, but "Skipping companion proxy bootstrap pairing" |
| `xcrun devicectl manage pair --device <udid / name / CoreDevice id>` | ❌ `The specified device was not found (1000)` |
| Restart `remotepairingd` (root) and re-check | ✅ no change |
| Look for the watch's record on disk (`/var/db/lockdown`, `/Library/Apple`, …) | ❌ protected by SIP; nothing found by filename |
| **Device Hub ▸ File ▸ Pair Nearby Device…** with the watch on *Settings ▸ Privacy & Security ▸ Developer Mode* | ✅ pairing **succeeds** (×4) but the watch drops the connection ~40 ms later |
| `xcrun xcdevice list`, `xcrun xctrace list devices` | ✅ watch never listed |
| Bonjour: `dns-sd -B _remotepairing._tcp` / `_remotepairing-manual-pairing._tcp` | ✅ only iPhone and iPad advertise |

## The app being installed (ruled out)

* Signed with an Apple Development certificate, provisioning profile includes the watch UDID.
* Companion watch app (`WKApplication` + `WKCompanionAppBundleIdentifier`) embedded in the iPhone app.
* Bundle versions of iPhone app and watch app made identical (they were not at first).
* Debug build replaced by Release build (no `*.debug.dylib` / preview dylib in the watch bundle).

## Not yet tried

* Unpair the watch from the iPhone completely and set it up again (heavy; may make it vanish from Xcode).
* Fresh macOS user account / another Mac, to separate host state from watch state.
* `sysdiagnose` on the watch right after a failed pairing (to see why it closes the connection).
