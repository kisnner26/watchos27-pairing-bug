# Sanitized log excerpts

Source: `log show --predicate 'process == "remotepairingd" OR process == "DeviceHub"'` on the Mac,
2026-09-24, local time (UTC−6). Redactions: UDIDs shortened to their chip prefix (`00008310-…` watch,
`00008130-…` iPhone, `00008103-…` iPad), device names replaced by `<watch name>`, `<iPhone name>`,
`<iPad name>`; network addresses and unrelated nearby devices removed. Everything else is verbatim.

## A. The Mac tries to remove the watch's pairing record

```
09:33:22.643 remotepairingd  Unable to remove pairing record for UDID 00008310-… in usbmux: <private>
```

## B. iPhone on USB: the watch is seen as a proxied device, then auto-pairing is skipped

```
09:37:08.982 remotepairingd  Handling MobileDevice notification of kind AMDeviceAction(rawValue: 1) for subscription type proxiedWatches
09:37:08.984 remotepairingd  Handling MobileDevice notification of kind AMDeviceAction(rawValue: 5) for subscription type proxiedWatches
09:37:08.990 remotepairingd  Received MobileDevice device attach notification for proxied device 00008310-…
09:37:08.990 remotepairingd  Attempting to bootstrap pairing using MobileDevice for device with UDID <private>
09:37:09.074 remotepairingd  Device <private> supports user-driven network pairing flows. Skipping companion proxy bootstrap pairing
…
09:41:49.214 remotepairingd  Received MobileDevice device detach notification for proxied device 00008310-…   (cable unplugged)
```

## C. Manual pairing: four attempts, same outcome

Summary of the four sessions (`setupManualPairing`, initiated by the watch over `awdl0` after the Device Hub sheet is open):

| Session | `PairSetup … client authenticated` | `Pairing session … succeeded` | Channel invalidated | Reconnect |
|---|---|---|---|---|
| tcp-9  | 10:02:20.802 | 10:02:20.802 | 10:02:21.133 | none |
| tcp-10 | 10:03:23.xxx | 10:03:23.xxx | 10:03:24.xxx | none |
| tcp-12 | 10:14:12.xxx | 10:14:12.xxx | 10:14:12.xxx | none |
| tcp-13 | 10:15:22.400 | 10:15:22.400 | 10:15:22.442 | none |
| tcp-9 (after watch update) | 10:55:08.951 | 10:55:08.951 | 10:55:08.980 | none |

(An earlier session, tcp-8 at 10:01:36, ended in `PairSetup server wrong setup code` ×2 — a mistyped code — and is not part of the failure.)

### C.1 Last attempt in detail (tcp-13)

```
10:15:13    remotepairingd  Network pairing peers updated. Total count: 1                       (watch connects to the Mac's listener)
10:15:14    DeviceHub       PairNearbyWirelessDeviceSheetModel: Presenting pairing challenge for "<watch name>".
10:15:20.953 remotepairingd tcp-13 (ccon_…): Received pairing data from peer: <private>
10:15:20.954 remotepairingd CUPairingSession  PairSetup server M3 -- verify request
10:15:20.978 remotepairingd CUPairingSession  Hide PIN
10:15:20.979 remotepairingd CUPairingSession  PairSetup server M4 -- verify response
10:15:22.397 remotepairingd CUPairingSession  PairSetup server M5 -- exchange request
10:15:22.399 remotepairingd Re-playing discovery of unauth bonjour devices as new pairing for device with udid Optional("00008310-…") has been added
10:15:22.400 remotepairingd CUPairingSession  PairSetup server M6 -- exchange response
10:15:22.400 remotepairingd CUPairingSession  PairSetup server done -- client authenticated
10:15:22.400 remotepairingd CUPairingSession  Pairing completed
10:15:22.400 remotepairingd tcp-13 (ccon_…): Pairing session of kind Optional(RemotePairing.PairingData.Kind.setupManualPairing) succeeded
10:15:22.400 remotepairingd CUPairingSession  Open stream 'main'
10:15:22.401 remotepairingd tcp-13 (00008310-…/ccon_…): ControlChannel connection state changing from setUpManualPairingInProgress to authenticated
10:15:22.441 remotepairingd tcp-13: received error reading message: <private>                   <-- +40 ms after authenticated
10:15:22.442 remotepairingd tcp-13 (00008310-…/ccon_…): Invalidating control channel connection due to reason: <private>
10:15:22.442 remotepairingd tcp-13 (00008310-…/ccon_…): ControlChannel connection state changing from authenticated to invalidated
10:15:22.442 remotepairingd CUPairingSession  Close stream 'main'
10:15:22.713 DeviceHub      beaconingpairing: Beaconing pairing session explicitly ended by client
10:15:22.713 DeviceHub      beaconingpairing: Recieved error from side channel peer: <private>
10:15:22.713 remotepairingd deviceinitiatedpairinghostservice: Received error from wireless pairing session peer: <private>
10:15:22.714 remotepairingd deviceinitiatedpairinghostservice: Manual pairing bonjour listener state changed: cancelled
```

### C.2 The watch never becomes a CoreDevice device

```
10:02:22.253 DeviceHub  Received reply from forwarded action (type=AcquireDeviceUsageAssertionActionDeclaration, device=<watch CoreDevice id>): failure(… "The specified d[evice was not found]" Code=1000)
10:02:22.255 DeviceHub  Failed to acquire usage assertion on device <watch CoreDevice id> due to error: <private>
```

```
$ xcrun devicectl manage pair --device <watch udid>
ERROR: The specified device was not found. (com.apple.dt.CoreDeviceError error 1000 (0x3E8))
```

## D. Control case: the iPhone, same Mac, one minute earlier

The iPhone had also lost trust (*Reset Location & Privacy*) and was re-paired first. It shows the **same** short setup channel,
followed by a normal reconnect:

```
10:54:15.768 DeviceHub       Presenting pairing challenge for "<iPhone name>"
10:54:22.171 remotepairingd  Re-playing discovery of unauth bonjour devices as new pairing for device with udid Optional("00008130-…") has been added
10:54:22.173 remotepairingd  tcp-7 (ccon_…): Pairing session of kind … setupManualPairing succeeded
10:54:22.209 remotepairingd  tcp-7: received error reading message: <private>                    <-- +36 ms
10:54:22.209 remotepairingd  tcp-7 (00008130-…/ccon_…): ControlChannel … authenticated -> invalidated
10:54:22.508 DeviceHub       Beaconing pairing session explicitly ended by client
10:54:23.567 remotepairingd  tcp-8 (default-…): ControlChannel … handshakeInProgress -> preparingPairingSession(… verifyManualPairing …)
10:54:23.592 remotepairingd  tcp-8 (00008130-…/default-…): Pairing session of kind … verifyManualPairing succeeded   <-- reconnect (+1.4 s)
```

`xcrun devicectl list devices` then shows the iPhone as `connected`, and Device Hub lists it as available.

The watch, one minute later (10:55:08), goes through the identical first half and then **nothing**:

```
10:55:04.327 DeviceHub       Presenting pairing challenge for "<watch name>"
10:55:08.951 remotepairingd  Re-playing discovery of unauth bonjour devices as new pairing for device with udid Optional("00008310-…") has been added
10:55:08.951 remotepairingd  tcp-9 (ccon_…): Pairing session of kind … setupManualPairing succeeded
10:55:08.980 remotepairingd  tcp-9 (00008310-…/ccon_…): Invalidating control channel connection due to reason: <private>   <-- +29 ms
10:55:09.266 DeviceHub       Beaconing pairing session explicitly ended by client
(no further lines about 00008310-… — no verifyManualPairing, no Bonjour advertisement)
```

> Correction: an earlier revision showed an iPad `verifyManualPairing` as the control. That was a *reconnect* of an already-paired
> device, not a fresh setup, so it was not a valid comparison. The iPhone above is.

## E. Not the watch-only advertising

While idle, only the iPhone and iPad advertise over Bonjour:

```
$ dns-sd -B _remotepairing._tcp local.
… Add … _remotepairing._tcp.   <iPad instance ×2>
… Add … _remotepairing._tcp.   <iPhone instance>
$ dns-sd -B _remotepairing-manual-pairing._tcp local.
(no results)
```
