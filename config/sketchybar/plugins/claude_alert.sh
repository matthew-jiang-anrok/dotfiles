#!/usr/bin/env bash
# Claude Code Notification hook: flag the AeroSpace workspace whose tmux session
# is waiting for input by painting its sketchybar pill red. ws_driver.sh repaints
# the pill (yellow when focused, off when left), so focusing the workspace clears
# the alert automatically — no timer needed.
export PATH="/opt/homebrew/bin:$PATH"

s=$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null)
[ -n "$s" ] || exit 0

# set-titles-string is "#S · #T", so the pane's session name prefixes the window
# title; find the AeroSpace window carrying it and read its workspace.
w=$(aerospace list-windows --all --format '%{workspace}|%{window-title}' 2>/dev/null \
    | grep -m1 -- "|$s · " | cut -d'|' -f1)
[ -n "$w" ] || exit 0

# ponytail: skip if you're already looking at that workspace — nothing to alert
[ "$w" = "$(aerospace list-workspaces --focused 2>/dev/null)" ] && exit 0

sketchybar --set "space.$w" background.drawing=on background.color=0xfffb4934 label.color=0xff282828
