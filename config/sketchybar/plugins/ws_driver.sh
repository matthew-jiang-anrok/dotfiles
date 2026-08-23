#!/usr/bin/env bash
# Repaint ONLY the two workspace pills affected by a switch, in one batched
# sketchybar call. Called directly by AeroSpace's exec-on-workspace-change so a
# switch is one script run -> one sketchybar invocation, instead of every
# space.N item re-running a script via an event subscription.
#
# Args (AeroSpace passes these positionally):
#   $1  focused workspace  -> now-active pill to highlight
#   $2  previous workspace -> pill to un-highlight
# Falls back to the FOCUSED_WORKSPACE/PREV_WORKSPACE env vars when invoked some
# other way (e.g. a manual sketchybar --trigger).

focused="${1:-$FOCUSED_WORKSPACE}"
prev="${2:-$PREV_WORKSPACE}"

# Gruvbox Dark. Keep in sync with the pill colors in sketchybarrc. Every pill's
# outline bubble stays drawn; focus only swaps the fill + text colors.
#   ACCENT = focused pill fill + unfocused app glyphs (label)
#   NUM    = unfocused workspace number (icon)
#   BG     = number + glyphs on the focused (filled) pill
#   CLEAR  = transparent fill on unfocused pills
ACCENT=0xff83a598
NUM=0xfffabd2f
BG=0xff282828
CLEAR=0x00000000

args=()
[ -n "$prev" ] && [ "$prev" != "$focused" ] && \
    args+=(--set "space.$prev" background.color=$CLEAR icon.color=$NUM label.color=$ACCENT)
[ -n "$focused" ] && \
    args+=(--set "space.$focused" background.color=$ACCENT icon.color=$BG label.color=$BG)

[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
