# Resolution: update the iPhone to iOS 27.2

**Status: resolved on my setup (2026-10-03). Root cause not proven.** Apple replied on 2026-10-12 asking for more diagnostics (see [status-log.md](status-log.md)); the answer is in the report.

## What fixed it

1. Update the **iPhone** to **iOS 27.2** so it matches the watch (watchOS 27.2).
2. With the iPhone connected to the Mac, pair the watch from **Device Hub** (*File ▸ Pair Nearby Device…*).

After that the watch became available again and `devicectl` could install apps on it.

## What did *not* fix it

Everything in [`what-i-tried.md`](what-i-tried.md), plus two things worth stressing:

* **Updating only the watch** (watchOS 27.0 → 27.2). The iPhone stayed on iOS 27.0, so it was the only device left behind.
* **Resetting the watch and pairing it again** (same Apple ID) in the Watch app while the iPhone was still on iOS 27.0. The iPhone ↔ watch link was healthy,
  but Device Hub still could not reach the watch.

## Versions during the failure

| Phase | Mac | iPhone | Watch | Result |
|---|---|---|---|---|
| 1: filing (2026-09-24, before the watch update) | macOS 27.2 | iOS 27.0 | watchOS 27.0 | fails |
| 2: after updating only the watch | macOS 27.2 | iOS 27.0 | watchOS 27.2 | fails (also after the reset and re-pairing, 2 Oct) |
| 3: after updating the iPhone (3 Oct, 00:26) | macOS 27.2 | iOS 27.2 | watchOS 27.2 | works |

The first version of this document said the watch was "newer than the iPhone". That only describes phase 2. The accurate statement is that the devices were on **different** releases in both failing phases and on the **same** release when it worked.

Symptom shown by Device Hub while it was failing:

```
DeviceKitError, errorCode 4002
"Live device view took longer than expected to connect."
```

## Evidence from the iPhone's analytics logs

The iPhone keeps `.ips` diagnostic files for weeks (*Settings ▸ Privacy & Security ▸ Analytics & Improvements ▸ Analytics Data*).
They can be copied to a Mac without any extra tool:

```sh
xcrun devicectl device info files --device <iphone> --domain-type systemCrashLogs
xcrun devicectl device copy from  --device <iphone> --domain-type systemCrashLogs --source <file> --destination <path>
```

Each `JetsamEvent-*.ips` header carries the OS build at that moment, so the logs reconstruct the version history (local time, UTC−6):

| When | What the logs show | File |
|---|---|---|
| until 2026-10-02 17:19 | iPhone on **iOS 27.0 (24A5418b)** | `JetsamEvent-*` |
| 2026-10-02 22:06 → 22:41 | the watch's pairing identity on the iPhone changes (one `ProxiedDevice-*` folder stops, another starts): the watch was unpaired and paired again | `ProxiedDevice-*/` |
| 2026-10-02 23:45 – 23:54 | a clean iPhone ↔ watch pairing: activation ~11 s, passcode and unlock pairing done, initial sync, no errors | `DiagnosticLogs/Bridge-Pair-Performance-Report-*` |
| 2026-10-03 00:26 | **iPhone updated to iOS 27.2 (24B5089g)**, OTA result `success` | `ota_patch.txt` |
| from 2026-10-03 10:27 | iPhone on iOS 27.2; the same watch identity continues until the end of the logs, with no further re-pairing | `JetsamEvent-*` |

The watch was on **watchOS 27.2 (24S5091f)** under both pairing identities.

State of the watch afterwards (`devicectl device info details`): `pairingState: paired`, `transportType: localNetwork`,
`authenticationType: manualPairing`, `developerModeStatus: enabled`.

## What this does and does not show

* It shows that the devices were on mixed releases during the whole failure (the iPhone on 27.0 against a Mac on 27.2, and later also a watch on 27.2), that the iPhone ↔ watch pairing was healthy,
  and that the fix coincides with moving the iPhone to 27.2, with no further watch re-pairing afterwards.
* It does **not** separate the iPhone update from the new Device Hub pairing done right after it, and whether the iPhone was on USB at that moment is not recorded. The same Apple ID was used throughout; no other ID was tried. It is one case and was not repeated.
* It does **not** show the CoreDevice side. `remotepairingd` and `verifyManualPairing` messages are not kept in these files and the Mac's unified log
  expires within hours, so the reason the watch asked for a brand-new pair-setup in a loop ([see the loop](../README.md#the-pairing-loop)) is still unproven.
  A version mismatch between the companion iPhone and the watch is the working hypothesis, not a diagnosis.

## If you hit this

Check that the **Mac, iPhone and watch run matching OS versions** (macOS 27.2, iOS 27.2, watchOS 27.2) before anything else. If it still fails, capture the log
**before** pairing, so the evidence is not lost:

```sh
log stream --predicate 'process == "remotepairingd" OR process == "CoreDeviceService"' --style compact > pairing.log
```

and attach it to your Feedback report mentioning **FB24924229**.
