# Status log

Newest first. Times are local (UTC−6).

## 2026-09-25 (community research, more attempts)

* **Developer forums and GitHub searched** — see [`community-findings.md`](community-findings.md). An Apple DTS engineer acknowledged a
  possible regression in this area (Xcode/watchOS 26.2) and asked for logging-profile reports; two forum threads report fixes for
  *Xcode 27 beta 3*: pairing with the **iPhone powered off**, and **starting the pairing from the watch**. No one shared Feedback IDs.
* **FB24924229:** still *Submitted*, no reply from Apple two days after filing.
* **Mac on the iPhone's Personal Hotspot** (`172.20.10.x`): a network scan showed only the iPhone and the Mac — the **watch was not
  on that network**, so this does not test anything. Likely cause: a watch does not join the hotspot of the iPhone it is paired with
  (a guess, not verified).
* **All three devices on the same 2.4 GHz network, with the watch's private Wi-Fi address off:** the watch was still not detected. The only
  `_remotepairing._tcp` advertisers were the iPhone and the iPad (an "extra" instance that appeared turned out to be the iPad, and later the iPhone).
* **Developer Mode** re-enabled on the watch and the pairing sheet opened: no change.
* **Install from the iPhone Watch app** stalls at about half again. A syslog capture during the install could not be taken because
  the iPhone was not on USB (no data collected).
* **Reading this together with the pairing-loop finding below:** the watch not advertising `_remotepairing._tcp` is probably normal
  (watches connect *to* the Mac's pairable-host listener), so "not detected on Bonjour" was never a valid test by itself.
* **Not tried yet:** pairing with the iPhone powered off; starting the pairing from the watch (*Developer Mode ▸ paired devices*);
  re-pairing the watch to the iPhone as a new watch.

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
