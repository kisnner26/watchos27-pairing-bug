# Status log

Newest first. Times are local (UTC−6).

## 2026-09-24

* **Cleanup of the Mac side.** The watch's pairing record is stored in SIP-protected locations (no files named by UDID
  under `/var/db`, `/Library/Apple`). `remotepairingd` was restarted; the Mac now has no record of the watch.
* **iPhone:** *Reset Location & Privacy* done (clears trusted computers).
* **Watch:** update to **watchOS 27.2 beta 2** started.
* **Next:** after the update, repeat *Pair Nearby Device…* and check whether the control channel stays `authenticated`
  past the first second. Outcome will be recorded here.

## 2026-09-24 (earlier)

* Found the four "succeeded → invalidated in ~40 ms" pairing attempts in `remotepairingd`.
* Found `Skipping companion proxy bootstrap pairing` (watch supports user-driven pairing).
* Found the 09:33 `Unable to remove pairing record` for the watch.
* Ruled out the app, network and cable (see [what-i-tried](what-i-tried.md)).
