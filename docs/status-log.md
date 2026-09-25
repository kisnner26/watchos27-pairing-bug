# Status log

Newest first. Times are local (UTC−6).

## 2026-09-24 (night): the pairing loop

* **How watches pair:** the watch connects *to* the Mac's `_remotepairing-pairable-host._tcp` listener, which exists only while
  Device Hub's *Pair Nearby Device…* sheet is open; the sheet closes itself ~300–400 ms after setup. See logs § F.
* **Keeping the Mac listening** ([`tools/watch-pair-keeper.sh`](../tools/watch-pair-keeper.sh), listener gap 0.6 s): the watch
  **came back 23 s later, but asked for a brand-new pair-setup** (`startNewSession: true, setupManualPairing`) instead of
  pair-verify. After that second setup it closed again (+286 ms). The fault is on the watch: it does not keep, or does not use,
  the pairing it just completed. See logs § G.
* **Watch sysdiagnose** (22:21:48) collected. The watch's pairing starts normally (Find My does not block it), but its log
  has no lines at all between 22:21:34.1 and 22:21:48, so the reason for the close is not recorded. See logs § H.
* *Unpair this device* for the Mac in the watch's Developer settings, then re-pairing: same result (had already been tried before).
* **pymobiledevice3 11.19.1 `remote pair-host`** as an independent host: the watch lists it and asks for its passcode, but never
  opens a TCP connection, over IPv4 or IPv6 ([`tools/pair_host_dualstack.py`](../tools/pair_host_dualstack.py)). See logs § I.
* **Conclusion so far:** nothing on the Mac side fixes it. Waiting for a new watchOS / Xcode build; the pairing-loop evidence
  was prepared as a follow-up to FB24924229.

## 2026-09-24 (report filed)

* Filed in Feedback Assistant as **FB24924229** (Xcode ▸ Incorrect/Unexpected Behaviour), with a macOS sysdiagnose attached automatically.
  No sysdiagnose from the watch was attached.

## 2026-09-24 (after the watch update)

* Watch updated and confirmed in Settings ▸ General ▸ About: **watchOS 27.2, build 24S5091f**. *Reset Location & Privacy* had already been done on the iPhone.
* **iPhone re-paired** with *Pair Nearby Device…*: setup → channel closes at +36 ms → **`verifyManualPairing` at +1.4 s → available**.
* **Watch re-paired** the same way: setup succeeded at 10:55:08 → channel closes at +29 ms → **no reconnect**, no Bonjour advertisement,
  no CoreDevice record. Behavior unchanged from watchOS 27.0.
* **Correction:** the ~40 ms close is normal (the iPhone shows it too). The fault is the missing reconnection. README, logs and the
  Feedback report were rewritten accordingly.
* Note: the pairing code is shown **on the Mac** and typed **on the device**.

## 2026-09-24

* **Cleanup of the Mac side.** The watch's pairing record is stored in SIP-protected locations (no files named by UDID
  under `/var/db`, `/Library/Apple`). `remotepairingd` was restarted; the Mac now has no record of the watch.
* **iPhone:** *Reset Location & Privacy* done (clears trusted computers).
* **Watch:** update to **watchOS 27.2** started.
* **Next:** after the update, repeat *Pair Nearby Device…* and check whether the control channel stays `authenticated`
  past the first second. Outcome will be recorded here.

## 2026-09-24 (earlier)

* Found the four "succeeded → invalidated in ~40 ms" pairing attempts in `remotepairingd`.
* Found `Skipping companion proxy bootstrap pairing` (watch supports user-driven pairing).
* Found the 09:33 `Unable to remove pairing record` for the watch.
* Ruled out the app, network and cable (see [what-i-tried](what-i-tried.md)).
