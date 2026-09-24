# How to collect the evidence

## 1. Device state on the Mac

```sh
xcrun devicectl list devices
xcrun devicectl list devices --json-output - | python3 -m json.tool | less   # look at pairingState / tunnelState
xcrun xcdevice list --timeout 20
xcrun xctrace list devices
```

## 2. What is advertising on the network

```sh
dns-sd -B _remotepairing._tcp local.
dns-sd -B _remotepairing-manual-pairing._tcp local.
dns-sd -B _apple-mobdev2._tcp local.
```

Resolve one entry to see which host it belongs to:

```sh
dns-sd -L <instance-name> _remotepairing._tcp local.
```

## 3. The pairing conversation (the important one)

Open **Device Hub ▸ File ▸ Pair Nearby Device…**, put the watch on
*Settings ▸ Privacy & Security ▸ Developer Mode*, complete the pairing, then:

```sh
/usr/bin/log show --last 30m --predicate 'process == "remotepairingd" OR process == "DeviceHub"' \
  | grep -E "Presenting pairing challenge|PairSetup server M[1-6]|Pairing session of kind|has been added|received error reading message|explicitly ended|to invalidated"
```

A healthy pairing stays `authenticated`. The failure is `authenticated -> invalidated` within milliseconds
of `Pairing session … succeeded`.

Useful earlier signals:

```sh
/usr/bin/log show --last 12h --predicate 'process == "remotepairingd"' \
  | grep -E "Unable to remove pairing record|proxied device|user-driven network pairing"
```

## 4. Logs from the iPhone (needs USB and an admin password)

```sh
sudo /usr/bin/log collect --device --last 3m --output ~/iphone.logarchive
/usr/bin/log show --archive ~/iphone.logarchive --info --debug | less
```

Notes: `--device-udid <udid>` failed with `Device not configured (6)` on iOS 27; `--device` (first device on USB) worked.
`idevicesyslog` (libimobiledevice) could not attach to an iOS 27 device.

## 5. Before you share anything

Logs contain UDIDs, device names and network addresses. Redact them (see
[`logs/remotepairingd-excerpts.md`](../logs/remotepairingd-excerpts.md) for the style used here).
