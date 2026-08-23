#!/usr/bin/env bash
# Count of open Linear issues assigned to me.
# Requires LINEAR_API_KEY (personal API key from linear.app/settings/account/security).
#
# Note: sketchybar is started by launchd via brew services, so .zshrc env vars
# are NOT inherited. Either:
#   (a) `launchctl setenv LINEAR_API_KEY "$LINEAR_API_KEY"` in your .zshrc, or
#   (b) put LINEAR_API_KEY=... in ~/.config/sketchybar/.env (sourced below).

if [ -z "$LINEAR_API_KEY" ] && [ -f "$HOME/.config/sketchybar/.env" ]; then
    set -a
    . "$HOME/.config/sketchybar/.env"
    set +a
fi

if [ -z "$LINEAR_API_KEY" ]; then
    sketchybar --set "$NAME" label="auth?" label.color=0xff928374
    exit 0
fi

QUERY='{"query":"{ viewer { assignedIssues(filter: { completedAt: { null: true }, canceledAt: { null: true } }) { nodes { id } } } }"}'

RESPONSE=$(curl -sS --max-time 5 -X POST https://api.linear.app/graphql \
    -H "Content-Type: application/json" \
    -H "Authorization: $LINEAR_API_KEY" \
    -d "$QUERY" 2>/dev/null)

COUNT=$(echo "$RESPONSE" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(len(d['data']['viewer']['assignedIssues']['nodes']))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$COUNT" ]; then
    sketchybar --set "$NAME" label="?" label.color=0xff928374
elif [ "$COUNT" = "0" ]; then
    sketchybar --set "$NAME" label="0" label.color=0xff928374
else
    sketchybar --set "$NAME" label="$COUNT" label.color=0xff83a598
fi
