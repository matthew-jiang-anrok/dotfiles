#!/usr/bin/env bash
# Unread GitHub notifications count via `gh`. Requires `gh auth login`.

if ! command -v gh >/dev/null; then
    sketchybar --set "$NAME" label="gh?" label.color=0xff928374
    exit 0
fi

COUNT=$(gh api notifications --jq 'length' 2>/dev/null)

if [ -z "$COUNT" ]; then
    sketchybar --set "$NAME" label="?" label.color=0xff928374
elif [ "$COUNT" = "0" ]; then
    sketchybar --set "$NAME" label="0" label.color=0xff928374
else
    sketchybar --set "$NAME" label="$COUNT" label.color=0xfffb4934
fi
