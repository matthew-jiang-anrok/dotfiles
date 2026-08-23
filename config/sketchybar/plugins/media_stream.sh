#!/usr/bin/env bash
# Long-running listener started once from sketchybarrc. `media-control stream`
# emits one JSON line whenever the system now-playing state changes (track,
# play/pause, scrub). Each line re-triggers the media item's refresh via a
# custom sketchybar event, so updates are push-based rather than polled.
#
# The outer loop restarts the stream if it ever exits.

while true; do
  media-control stream 2>/dev/null | while IFS= read -r _line; do
    sketchybar --trigger media_update >/dev/null 2>&1
  done
  sleep 1
done
