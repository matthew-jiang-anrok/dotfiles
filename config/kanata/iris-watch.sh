#!/bin/bash
# Watches for the Keebio Iris CE over USB and drives kanata's active layer:
#   Iris present -> "off" (internal laptop keyboard dead)
#   Iris absent  -> "base" (normal kanata Colemak layout)
# kanata must be started with --port ${PORT}. Runs as a login LaunchAgent.

PORT=5829
MATCH="Iris CE"
prev=""

send() {
  # newline-terminated JSON command; -w1 gives kanata time to read before close.
  # Returns nc's exit status so the caller only commits state on a successful send.
  printf '%s\n' "$1" | /usr/bin/nc -w1 127.0.0.1 "$PORT" >/dev/null 2>&1
}

while true; do
  if ioreg -p IOUSB 2>/dev/null | grep -q "$MATCH"; then
    state="present"
  else
    state="absent"
  fi

  if [ "$state" != "$prev" ]; then
    if [ "$state" = "present" ]; then
      send '{"ChangeLayer":{"new":"off"}}' && prev="$state"
    else
      send '{"ChangeLayer":{"new":"base"}}' && prev="$state"
    fi
    # If the send failed (kanata port not up yet), prev is unchanged so we retry.
  fi
  sleep 1
done
