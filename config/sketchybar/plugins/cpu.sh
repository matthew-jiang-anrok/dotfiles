#!/usr/bin/env bash
# Show CPU usage percentage with color-coded Nerd Font icon.

CPU=$(top -l 1 -n 0 | awk '/CPU usage/ {gsub(/%/,""); print int($3 + $5)}')

if [ "$CPU" -ge 80 ]; then
    COLOR=0xfffb4934   # red
elif [ "$CPU" -ge 50 ]; then
    COLOR=0xfffabd2f   # yellow
else
    COLOR=0xffb8bb26   # green
fi

sketchybar --set "$NAME" icon.color="$COLOR" label="${CPU}%"
