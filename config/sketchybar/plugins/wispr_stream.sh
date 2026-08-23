#!/usr/bin/env bash
# Long-running listener started once from sketchybarrc. Wispr Flow logs its
# dictation lifecycle to main.log: "Playing dictation start sound" when audio
# capture begins and "dictation stop sound" when it ends. We tail the log and
# trigger wispr_update with RECORDING=on/off around each dictation, so the
# indicator is push-based rather than polled. Mirrors media_stream.sh.
#
# The outer loop restarts the tail if it ever exits.

LOG="$HOME/Library/Logs/Wispr Flow/main.log"

while true; do
  # -F follows across Flow's log rotation; -n0 skips history so we only react
  # to dictations that happen after the bar loads.
  tail -n0 -F "$LOG" 2>/dev/null | while IFS= read -r line; do
    case "$line" in
      *"Playing dictation start sound"*)
        sketchybar --trigger wispr_update RECORDING=on  >/dev/null 2>&1 ;;
      *"dictation stop sound"*)
        sketchybar --trigger wispr_update RECORDING=off >/dev/null 2>&1 ;;
    esac
  done
  sleep 1
done
