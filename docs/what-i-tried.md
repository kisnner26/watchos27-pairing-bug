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
| *Reset Location & Privacy* on the iPhone (clears trusted computers) | ✅ done; effect pending |
| Update the watch to watchOS 27.2 (24S5091f) | ✅ done (confirmed in Settings ▸ General ▸ About); re-pairing shows the same result: no reconnect |
| Re-pair the **iPhone** after the privacy reset (control) | ✅ works: setup → reconnect (`verifyManualPairing`) → available |
| Watch's **private Wi-Fi address** off | ✅ done; no change |
| **2.4 GHz** network for Mac, iPhone and watch | ✅ done; the watch is still not detected |
| Mac on the iPhone's **Personal Hotspot** (watch in the same hotspot) | ✅ the watch never appeared on that network (a watch likely cannot join its own iPhone's hotspot — unverified) |
| Developer Mode re-enabled, pairing sheet opened again (2026-09-25) | ✅ no change |

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

## Later (2026-09-24, night)

| Attempt | Result |
|---|---|
| Keep the Mac's pairable-host listener open after setup (reopen *Pair Nearby Device…* by hand, 15 s gap) | ✅ no reconnect within 40 s |
| Same, automated with `tools/watch-pair-keeper.sh` (0.6 s gap) | ⚠️ the watch **reconnects**, but asks for a **new** pair-setup, not pair-verify; then closes again |
| Watch sysdiagnose right after a failed pairing | ✅ collected; the watch log stops 7 s before the close |
| Watch ▸ Developer ▸ *Unpair this device* (the Mac), then re-pair | ✅ no change |
| iPhone Watch app ▸ General ▸ Reset (only offers Erase / Home Screen / Sync Data / Cellular) | not used: none clears the Mac pairing, except a full erase |
| pymobiledevice3 11.19.1 `remote pair-host` (independent host) | ❌ watch lists it, asks for its passcode, never connects |
| Same, listening/advertising IPv4 + IPv6 (`tools/pair_host_dualstack.py`) | ❌ same |

## The app being installed (ruled out)

* Signed with an Apple Development certificate, provisioning profile includes the watch UDID.
* Companion watch app (`WKApplication` + `WKCompanionAppBundleIdentifier`) embedded in the iPhone app.
* Bundle versions of iPhone app and watch app made identical (they were not at first).
* Debug build replaced by Release build (no `*.debug.dylib` / preview dylib in the watch bundle).

## Not yet tried (from the forums — see [`community-findings.md`](community-findings.md))

* **Power the iPhone completely off** and pair from Device Hub (fix reported on Xcode 27 beta 3).
* **Start the pairing from the watch**: *Developer Mode ▸ paired devices ▸ "Pair with MacBook"*, then match the codes.
* Unpair the watch from the iPhone and set it up again **as a new watch**.
* A phone hotspot from **another** phone.
* Attach the (already collected) watch sysdiagnose to FB24924229, and record the CoreDevice logging-profile logs the Apple DTS engineer asked for in the forum thread.

## Not yet tried (earlier list)

* Erase the watch (*Erase Apple Watch Content and Settings*) and set it up again — the only thing that clears all of the
  watch's pairing state; heavy, and may not help if this is a beta bug.
* Fresh macOS user account / another Mac, to separate host state from watch state.
