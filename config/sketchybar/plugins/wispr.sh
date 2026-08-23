#!/usr/bin/env bash
# Renders the Wispr Flow dictation indicator. Driven by wispr_update events
# from wispr_stream.sh, which sets $RECORDING to "on" while Flow is capturing
# audio and "off" when it stops. Hidden (drawing=off) when idle.

case "$RECORDING" in
  on)
    sketchybar --set "$NAME" \
      drawing=on \
      icon="" \
      icon.color=0xfffb4934 \
      label="rec" \
      label.color=0xfffb4934 \
      label.drawing=on
    ;;
  *)
    sketchybar --set "$NAME" drawing=off
    ;;
esac
