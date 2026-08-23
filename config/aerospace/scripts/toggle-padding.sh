#!/bin/bash
# Toggle a wide focus padding: +400px on the left and right of both the tiling
# area (AeroSpace outer.left/right gaps) and the bar (sketchybar margin).
# Bound to ctrl-alt-p; press again to toggle off. State is derived from the
# current gap value, so no state file is needed.

set -euo pipefail

config="${HOME}/.config/aerospace/aerospace.toml"

BASE=8              # normal outer gap / bar margin
PAD=400            # extra padding per side when toggled on
ON=$((BASE + PAD))

current=$(grep -E '^[[:space:]]*outer\.left[[:space:]]*=' "$config" | head -n1 | sed -E 's/.*=[[:space:]]*([0-9]+).*/\1/')

if [ "${current:-$BASE}" -gt "$BASE" ]; then
	next=$BASE       # currently padded -> turn off
else
	next=$ON         # currently normal -> turn on
fi

# BSD sed (macOS) requires '' after -i.
sed -i '' -E "s/^([[:space:]]*outer\.left[[:space:]]*=[[:space:]]*)[0-9]+/\1${next}/" "$config"
sed -i '' -E "s/^([[:space:]]*outer\.right[[:space:]]*=[[:space:]]*)[0-9]+/\1${next}/" "$config"

aerospace reload-config

# Keep the bar indented to match the tiling area.
if command -v sketchybar >/dev/null 2>&1; then
	sketchybar --bar margin="${next}"
fi
