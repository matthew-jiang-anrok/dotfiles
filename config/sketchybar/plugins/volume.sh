#!/usr/bin/env bash
# Show system volume with a Nerd Font speaker icon.
VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

if [ "$MUTED" = "true" ] || [ "$VOLUME" = "0" ]; then
    ICON="󰝟"
    COLOR=0xff928374            # gray when muted
elif [ "$VOLUME" -lt 34 ]; then
    ICON="󰕿"
    COLOR=0xfffe8019            # orange
elif [ "$VOLUME" -lt 67 ]; then
    ICON="󰖀"
    COLOR=0xfffe8019
else
    ICON="󰕾"
    COLOR=0xfffe8019
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${VOLUME}%" label.color="$COLOR"
