#!/usr/bin/env bash
# Set every AeroSpace workspace pill's label to its app glyphs (one Nerd Font
# glyph per distinct app in that workspace). The workspace number is the pill's
# icon (set in sketchybarrc), so it is not touched here.
#
# Called on:
#   - front_app_switched            (apps opening/closing/focusing)
#   - workspace switch / window move (chained from AeroSpace, see aerospace.toml)
#   - bar (re)load                  (from sketchybarrc)
# Idempotent: recomputes all pills from live state every run, so no lock/state
# file is needed. One aerospace read + one batched sketchybar write.
#
# Only label TEXT is set here; the focused-pill highlight (background +
# label.color) is owned by ws_driver.sh — the two touch different properties.
#
# Staleness: an app that opens/closes in a *background* workspace without any
# focus change won't redraw until the next event. Add update_freq to the
# space_icons item in sketchybarrc if that ever bites.

AEROSPACE=/opt/homebrew/bin/aerospace
[ -x "$AEROSPACE" ] || AEROSPACE=aerospace

# App name -> Nerd Font glyph. Extend the case as needed; unknown apps fall
# through to a generic window glyph. Match on the exact %{app-name} AeroSpace
# reports (e.g. "Google Chrome", "zoom.us").
# Codepoints are Nerd Font (Font Awesome range); comments name them so you can
# swap glyphs without a font viewer. \xEF\x.. is the UTF-8 encoding of U+Fxxx.
glyph_for() {
  case "$1" in
    Ghostty|Terminal|iTerm2|Alacritty|kitty|WezTerm)     printf '\xEF\x84\xA0' ;;  # terminal  U+F120
    Cursor|Code|"Visual Studio Code"|Zed|"Sublime Text") printf '\xEF\x84\xA1' ;;  # code      U+F121
    "Google Chrome"|Chrome|Chromium)                     printf '\xEF\x89\xA8' ;;  # chrome    U+F268
    Safari|Arc)                                          printf '\xEF\x89\xA7' ;;  # safari    U+F267
    Firefox)                                             printf '\xEF\x89\xA9' ;;  # firefox   U+F269
    Slack)                                               printf '\xEF\x86\x98' ;;  # slack     U+F198
    Notion|Notes)                                        printf '\xEF\x89\x89' ;;  # note      U+F249
    Mail|Spark|Superhuman)                               printf '\xEF\x83\xA0' ;;  # envelope  U+F0E0
    Messages)                                            printf '\xEF\x81\xB5' ;;  # comment   U+F075
    Spotify|Music)                                       printf '\xEF\x86\xBC' ;;  # spotify   U+F1BC
    Figma)                                               printf '\xEF\x87\xBC' ;;  # brush     U+F1FC
    zoom.us|Zoom)                                        printf '\xEF\x80\xBD' ;;  # video     U+F03D
    Finder)                                              printf '\xEF\x81\xBB' ;;  # folder    U+F07B
    Obsidian)                                            printf '\xEF\x80\xAD' ;;  # book      U+F02D
    Preview|Skim)                                        printf '\xEF\x87\x81' ;;  # file-pdf  U+F1C1
    Linear)                                              printf '\xEF\x82\xAE' ;;  # tasks     U+F0AE
    1Password)                                           printf '\xEF\x80\xA3' ;;  # lock      U+F023
    Calendar)                                            printf '\xEF\x81\xB3' ;;  # calendar  U+F073
    *)                                                   printf '\xEF\x8B\x90' ;;  # window    U+F2D0
  esac
}

# One read of all windows across all workspaces: "<workspace>|<app-name>".
ALL="$("$AEROSPACE" list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)"

args=()
for ws in 1 2 3 4 5 6 7 8 9 0; do
  # Distinct apps in this workspace, stable order. awk filters the single
  # dataset (no extra aerospace calls); sort -u dedups multi-window apps.
  glyphs=""
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    glyphs+="$(glyph_for "$app") "
  done < <(printf '%s\n' "$ALL" | awk -F'|' -v w="$ws" '$1==w && $2!=""{print $2}' | sort -u)
  glyphs="${glyphs% }"   # trim trailing space

  # Number lives in the pill's icon (set in sketchybarrc); label holds only the
  # app glyphs, empty when the workspace has no windows.
  args+=(--set "space.$ws" label="$glyphs")
done

[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
