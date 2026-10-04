# Resolution: update the iPhone to iOS 27.2

**Status: resolved on my setup (2026-10-03). Root cause not proven.** The Apple-side report (FB24924229) is still open.

## What fixed it

1. Update the **iPhone** to **iOS 27.2** so it matches the watch (watchOS 27.2).
2. With the iPhone connected to the Mac, pair the watch from **Device Hub** (*File ▸ Pair Nearby Device…*).

After that the watch became available again and `devicectl` could install apps on it.

## What did *not* fix it

Everything in [`what-i-tried.md`](what-i-tried.md), plus two things worth stressing:

* **Updating only the watch** (watchOS 27.0 → 27.2). The iPhone stayed on iOS 27.0, so the watch ended up *newer* than its companion.
* **Unpairing and re-pairing the watch in the Watch app** while the iPhone was still on iOS 27.0. The iPhone ↔ watch link was healthy,
  but Device Hub still could not reach the watch.

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

* It shows that during the whole failure the watch (27.2) was **newer than the iPhone (27.0)**, that the iPhone ↔ watch pairing was healthy,
  and that the fix coincides with moving the iPhone to 27.2, with no further watch re-pairing afterwards.
* It does **not** show the CoreDevice side. `remotepairingd` and `verifyManualPairing` messages are not kept in these files and the Mac's unified log
  expires within hours, so the reason the watch asked for a brand-new pair-setup in a loop ([see the loop](../README.md#the-pairing-loop)) is still unproven.
  A version mismatch between the companion iPhone and the watch is the working hypothesis, not a diagnosis.

## If you hit this

Check that the **iPhone and the watch run matching OS versions** (iOS 27.2 with watchOS 27.2) before anything else. If it still fails, capture the log
**before** pairing, so the evidence is not lost:

```sh
log stream --predicate 'process == "remotepairingd" OR process == "CoreDeviceService"' --style compact > pairing.log
```

and attach it to your Feedback report mentioning **FB24924229**.
