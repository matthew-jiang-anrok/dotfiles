#!/usr/bin/env bash
# Now-playing item backed by ungive/media-control. Reads whatever app is
# reporting to macOS Now Playing (YouTube Music in a Chrome tab reports via the
# Media Session API) and renders "Artist — Title". Handles click + scroll.
#
# Routed events ($SENDER):
#   media_update    custom event fired by media_stream.sh on every change
#   mouse.clicked   left = play/pause toggle, right = next track
#   mouse.scrolled  scroll up = previous, scroll down = next

# ── Gruvbox accents ───────────────────────────────────────────────────────────
FG=0xffd3869b     # label (gruvbox purple)
MAX_LABEL=32      # truncate "Artist — Title" to keep the bar tidy

# ── Handle interactions ───────────────────────────────────────────────────────
case "$SENDER" in
  mouse.clicked)
    case "$BUTTON" in
      right) media-control next-track >/dev/null 2>&1 ;;
      *)     media-control toggle-play-pause >/dev/null 2>&1 ;;
    esac
    ;;
  mouse.scrolled)
    if [ -n "$SCROLL_DELTA" ] && awk "BEGIN{exit !($SCROLL_DELTA > 0)}"; then
      media-control previous-track >/dev/null 2>&1
    else
      media-control next-track >/dev/null 2>&1
    fi
    ;;
esac

# ── Read current state and render ─────────────────────────────────────────────
JSON=$(media-control get 2>/dev/null)
TITLE=$(printf '%s' "$JSON" | jq -r '.title // empty' 2>/dev/null)
ARTIST=$(printf '%s' "$JSON" | jq -r '.artist // empty' 2>/dev/null)

# Nothing is playing (and nothing is loaded) → hide the item entirely.
if [ -z "$TITLE" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

LABEL="$TITLE"
[ -n "$ARTIST" ] && LABEL="$ARTIST — $TITLE"
if [ "${#LABEL}" -gt "$MAX_LABEL" ]; then
  LABEL="${LABEL:0:$((MAX_LABEL - 1))}…"
fi

sketchybar --set "$NAME" drawing=on label="$LABEL" label.color="$FG"
