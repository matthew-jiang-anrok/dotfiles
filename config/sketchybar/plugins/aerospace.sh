#!/usr/bin/env bash
# $1 = workspace ID this item represents
# $2 = this workspace's accent color
# $FOCUSED_WORKSPACE = set by the aerospace_workspace_change trigger

COLOR="${2:-0xffebdbb2}"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" \
        background.drawing=on    \
        background.color=$COLOR  \
        label.color=0xff282828
else
    sketchybar --set "$NAME" \
        background.drawing=off   \
        label.color=$COLOR
fi
