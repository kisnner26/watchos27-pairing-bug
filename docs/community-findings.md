# Community findings and other reports

Collected 2026-09-25 from the Apple Developer Forums and GitHub. Summaries were read from the public pages;
nothing here has been confirmed on the affected machine unless it says so in [`what-i-tried.md`](what-i-tried.md).

## Apple Developer Forums

| Thread | Versions | What it says |
|---|---|---|
| [Apple watch Xcode pairing & connection issues](https://developer.apple.com/forums/thread/813066) | Xcode 26.2–26.4, watchOS 26.2–27.0 (Jan–Aug 2026), 22 replies | Same family of symptoms: watch not listed, *"A connection to this device could not be established"*, tunnel timeouts. An Apple DTS engineer called it a possible Xcode/watchOS 26.2 regression and asked for Feedback reports with a CoreDevice logging profile (Mac, iPhone, watch) and a watchOS sysdiagnose. A developer-tools engineer added: **do not unpair** the watch once it shows up (it prevents rediscovery), keep the watch **unlocked** while the developer disk image mounts, and `pkill -9 remotepairingd` should not be needed. **No Feedback IDs were shared in the thread.** |
| [Apple Watch won't show PIN when pairing in Device Hub (Solved)](https://developer.apple.com/forums/thread/837517) | Xcode 27 beta 3, watchOS 27 beta 3 | After removing the watch from Device Hub it stayed on "Waiting to Pair" with no PIN. Reported fix: **power the iPhone completely off**, keep the watch and Mac on, pair again from Device Hub — the PIN appeared immediately; power the iPhone back on afterwards. Suggested cause: the companion iPhone holds a stale developer-pairing state. |
| [Apple Watch does not appear in Xcode 27 Beta and Developer Mode option is missing](https://developer.apple.com/forums/thread/829704) | macOS 27 beta, Xcode 27 beta | Reported fix: re-pair the watch to the iPhone as a **new watch**, use Device Hub ▸ add ▸ nearby device (this is what made Developer Mode appear), then on the watch open *Developer Mode ▸ paired devices* and wait for a **"Pair with MacBook"** button — **start the pairing from the watch**, and match the codes on both screens. |
| [Why doesn't iPhone 13 Pro Max and Watch Series 11 connect to Xcode 27.0?](https://developer.apple.com/forums/thread/847308) | Xcode 27.0 | Same complaint, no replies yet. |

Workarounds mentioned in thread 813066 (mixed reports, none tied specifically to this bug): a 2.4 GHz network for all three
devices, a phone hotspot, turning Bluetooth off on the iPhone, restarting Mac → iPhone → watch in that order, turning the
Wi-Fi private address off on the watch, and toggling Developer Mode off → restart → on → restart.

## GitHub

Searches for the log strings (`Skipping companion proxy bootstrap pairing`, `remotepairingd`, `Pair Nearby Device`) and for
watchOS 27 / Xcode 27 + Apple Watch found **no other public issue about this exact behavior**. (GitHub's search treats the
"27" as an issue number, so a phrase-only search returns noise; a report could exist under different wording.)

The closest symptom is [bitxeno/atvloadly#121](https://github.com/bitxeno/atvloadly/issues/121): on **tvOS 27**, pairing "succeeds"
(`remotepairing_udid` is written) but the device is never registered afterwards. That is a third-party tool, not Xcode, and
it was closed on 2026-09-23 with *"It's been fixed"* and no explanation. It may point to the same tvOS/watchOS 27 change in the
remote-pairing flow, but that is a guess.

## Feedback Assistant

FB24924229 was still in *Submitted* with **no Apple reply** two days after filing, and the inbox contained only generic
beta announcements. Replies to Feedback Assistant reports are usually automatic status changes, "possible duplicate of…" links,
requests for a sysdiagnose, or "please retest on the latest beta"; there is no guaranteed response time.
