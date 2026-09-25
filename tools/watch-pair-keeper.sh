#!/bin/bash
# watch-pair-keeper.sh — diagnostic for FB24924229.
#
# Watches remotepairingd while you pair a watch from Device Hub. As soon as Device
# Hub drops the Mac's pairable-host listener after setupManualPairing, it reopens
# "File ▸ Pair Nearby Device…" so the Mac keeps listening (gap ≈ 0.6 s), then
# reports whether the watch came back with pair-verify (RECONNECTED) or not.
#
# Usage:  tools/watch-pair-keeper.sh [--timeout SECONDS] [--udid-prefix 00008310]
# Needs:  Device Hub open, and Accessibility permission for the terminal app
#         (System Settings ▸ Privacy & Security ▸ Accessibility).

set -u

TIMEOUT=120
UDID_PREFIX="00008310"   # Apple Watch Ultra 2 (T8310) UDIDs start with this
while [ $# -gt 0 ]; do
  case "$1" in
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --udid-prefix) UDID_PREFIX="$2"; shift 2 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

RAW="watch-pair-keeper-$(date +%Y%m%d-%H%M%S).log"
PREDICATE='process == "remotepairingd" OR process == "DeviceHub"'

# Seconds since midnight from a syslog-style time field ("22:21:41.314778-0600").
secs() { awk -v t="${1%%[-+]*}" 'BEGIN { split(t, a, ":"); printf "%.3f", a[1]*3600 + a[2]*60 + a[3] }'; }
ms_between() { awk -v a="$(secs "$1")" -v b="$(secs "$2")" 'BEGIN { printf "%d", (b - a) * 1000 }'; }

reopen_pairing_sheet() {
  local i
  for i in $(seq 1 30); do
    if osascript >/dev/null 2>&1 <<'EOF'
tell application "System Events" to tell process "DeviceHub"
  set frontmost to true
  click menu item "Pair Nearby Device…" of menu 1 of menu bar item "File" of menu bar 1
end tell
EOF
    then return 0; fi
    sleep 0.1
  done
  return 1
}

if ! osascript -e 'tell application "System Events" to get name of process "DeviceHub"' >/dev/null 2>&1; then
  echo "Device Hub is not running, or the terminal lacks Accessibility permission." >&2
  exit 1
fi

cat <<EOF
Watching remotepairingd (raw log: $RAW).
1. In Device Hub: File ▸ Pair Nearby Device…
2. Pair the watch as usual. Don't touch anything after entering the code.
The pairing sheet is reopened automatically; waiting ${TIMEOUT}s for a reconnect.
EOF

state=waiting
t_setup="" t_ended="" t_listen="" deadline="" pending_verify=""
result="no pairing seen"

# One pipe carries the log stream plus a 1 s tick, so the timeout fires even when
# the log is quiet (bash 3.2's `read -t` can't tell a timeout from EOF).
exec 3< <(
  /usr/bin/log stream --style syslog --predicate "$PREDICATE" 2>/dev/null &
  while sleep 1; do echo __tick__; done
)
trap 'pkill -f "log stream --style syslog --predicate $PREDICATE" 2>/dev/null; pkill -P $$ 2>/dev/null' EXIT

while IFS= read -r line <&3; do
  if [ -n "$deadline" ] && [ "$(date +%s)" -ge "$deadline" ]; then
    result="NO RECONNECT within ${TIMEOUT}s of the listener reopening"
    break
  fi
  [ "$line" = __tick__ ] && continue
  printf '%s\n' "$line" >> "$RAW"
  ts=$(printf '%s' "$line" | awk '{print $2}')

  case "$line" in
    *"setupManualPairing) succeeded"*)
      state=armed; t_setup=$ts
      echo "[$ts] setup succeeded — waiting for Device Hub to drop the listener" ;;

    *"Beaconing pairing session explicitly ended"*)
      if [ "$state" = armed ]; then
        t_ended=$ts; state=reopening
        echo "[$ts] listener dropped (+$(ms_between "$t_setup" "$ts") ms) — reopening pairing sheet"
        reopen_pairing_sheet || echo "  could not click the menu item (Accessibility?)"
      fi ;;

    *"Started listening for network pairing"*)
      if [ "$state" = reopening ]; then
        t_listen=$ts; state=listening
        deadline=$(( $(date +%s) + TIMEOUT ))
        echo "[$ts] Mac listening again — gap without listener: $(ms_between "$t_ended" "$ts") ms"
      fi ;;

    *"Network pairing peers updated. Total count: "[1-9]*)
      [ "$state" = listening ] && echo "[$ts] INCOMING network pairing peer: ${line##*Total count: }" ;;

    *"verifyManualPairing) succeeded"*)
      if [ "$state" = listening ] || [ "$state" = reopening ]; then
        echo "[$ts] verifyManualPairing succeeded — checking which device…"
        pending_verify=$ts
      fi ;;

    *"($UDID_PREFIX"*"to authenticated"*)
      if [ -n "$pending_verify" ]; then
        result="RECONNECTED: watch verified at $pending_verify (+$(ms_between "$t_setup" "$pending_verify") ms after setup)"
        break
      fi ;;

    *"to authenticated"*)
      pending_verify="" ;;  # a verify for another device (iPhone/iPad)
  esac
done

if [ "$result" = "no pairing seen" ]; then
  case "$state" in
    armed)     result="setup seen, but Device Hub never dropped the listener" ;;
    reopening) result="could not reopen the listener (menu click failed?)" ;;
    listening) result="NO RECONNECT before the log ended" ;;
  esac
fi

echo
echo "Result: $result"
[ -n "$t_setup" ]  && echo "  setup succeeded:   $t_setup"
[ -n "$t_ended" ]  && echo "  listener dropped:  $t_ended"
[ -n "$t_listen" ] && echo "  listener reopened: $t_listen"
echo
xcrun devicectl list devices 2>/dev/null | grep -iE "watch|State" || true
