#!/usr/bin/env bash
# Show battery percentage with a Nerd Font icon.
PERCENTAGE=$(pmset -g batt | grep -Eo '[0-9]+%' | tr -d '%')
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
    sketchybar --set "$NAME" icon="󱉝" label="?"
    exit 0
fi

if [ -n "$CHARGING" ]; then
    ICON="󰂄"                    # charging
    COLOR=0xffb8bb26            # green
elif [ "$PERCENTAGE" -ge 80 ]; then
    ICON="󰁹" COLOR=0xff8ec07c   # full (aqua)
elif [ "$PERCENTAGE" -ge 60 ]; then
    ICON="󰂁" COLOR=0xff8ec07c   # aqua
elif [ "$PERCENTAGE" -ge 40 ]; then
    ICON="󰁾" COLOR=0xfffabd2f   # yellow
elif [ "$PERCENTAGE" -ge 20 ]; then
    ICON="󰁼" COLOR=0xfffb4934   # red-ish
else
    ICON="󰁺" COLOR=0xfffb4934   # critical
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%" label.color="$COLOR"
