#!/usr/bin/env bash
# Rebuild the per-window list for the focused AeroSpace workspace.
#
# Triggered on aerospace_workspace_change. Removes the window.* pills left over
# from the previous workspace, then creates one pill per window in the now-
# focused workspace (labeled with the app name), highlighting the focused
# window. Clicking a pill focuses that window.
#
# Single-flight: switching workspaces quickly used to fire several instances
# concurrently, each of which removed only the pills it saw at query time and
# then added its own — so windows from multiple workspaces piled up together.
# We serialize with an atomic mkdir lock (macOS has no flock) and a dirty flag,
# so overlapping triggers collapse into one trailing rebuild that reconciles to
# whichever workspace actually ended up focused.
#
# Latency: each rebuild makes only two aerospace reads (focused window id +
# window list, both via the `focused` keyword) and one sketchybar write that
# carries the remove + add clauses together. The set of pills to remove comes
# from a state file we maintain ourselves, avoiding a `sketchybar --query | jq`
# roundtrip, and the single write means no flicker between clear and repaint.

STATE_DIR="${TMPDIR:-/tmp}"
LOCK="$STATE_DIR/sketchybar_ws_windows.lock"
DIRTY="$STATE_DIR/sketchybar_ws_windows.dirty"
PILLS="$STATE_DIR/sketchybar_ws_windows.pills"   # space-separated names we created

# Record that a rebuild is wanted, then try to become the sole worker. If
# someone else holds the lock, they'll observe the flag and rebuild again.
: > "$DIRTY"
if ! mkdir "$LOCK" 2>/dev/null; then
    exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM

rebuild() {
    # Read live state — a trailing rebuild has no idea which event queued it,
    # so the focused window/workspace must come from aerospace itself. The
    # `focused` keyword lets us skip a separate "which workspace?" lookup.
    local focused_win
    focused_win="$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)"

    local args=() created=()
    local item wid app color

    # Remove the pills we created last time (tracked in $PILLS, no bar query).
    if [ -f "$PILLS" ]; then
        for item in $(< "$PILLS"); do
            args+=(--remove "$item")
        done
    fi

    # Add one pill per window in the focused workspace.
    while IFS='|' read -r wid app; do
        [ -z "$wid" ] && continue
        if [ "$wid" = "$focused_win" ]; then
            color=0xffebdbb2   # fg1 (bright) for the focused window
        else
            color=0xffa89984   # fg4 (dim) for the rest
        fi
        args+=(--add item "window.$wid" left
               --set "window.$wid"
                   icon.drawing=off
                   label="$app"
                   label.font="Hack Nerd Font:Bold:13.0"
                   label.color="$color"
                   click_script="aerospace focus --window-id $wid")
        created+=("window.$wid")
    done < <(aerospace list-windows --workspace focused --format '%{window-id}|%{app-name}' 2>/dev/null)

    # One sketchybar write carries the removes + adds together (atomic, no
    # flicker). Then persist the new pill set for the next rebuild to remove.
    [ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
    printf '%s ' "${created[@]}" > "$PILLS"
}

# Drain the dirty flag: keep rebuilding as long as new triggers keep arriving.
while [ -e "$DIRTY" ]; do
    rm -f "$DIRTY"
    rebuild
done
