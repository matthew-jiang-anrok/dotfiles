# tmux config reference

Prefix = `Ctrl-a` (remapped from `C-b`). Nearly all bindings come from **plugins**, not `.tmux.conf` directly.

## Overrides
- **Prefix**: `C-b` → `C-a`.
- **tmux-pain-control**: rebinds pane nav/resize/split + `c`. Steals default `l` (`last-window`) for select-pane-right; remaps `%` `"` `c` to be current-path-aware.
- **tmux-sensible**: sets options (escape-time, history 50k, etc.) and adds `a`, `C-n`, `C-p`, `R`; restores `last-window` on `a` since pain-control took `l`.

## Plugins
`tmux-sensible`, `tmux-pain-control`, `tmux-battery`, `tmux-autoreload`, `tpm`. No theme plugin — the status bar is styled inline in `.tmux.conf`.

## Dead config
- `~/.config/tmux/plugins/catppuccin` exists but is never referenced — safe to delete.

## Shortcuts (prefix = `Ctrl-a`)

### Prefix / server
| Keys | Action |
|---|---|
| `C-a` `C-a` | send literal `C-a` to shell |
| `C-a` `a` | last (alternate) window |
| `C-a` `R` | reload `~/.tmux.conf` |

### Sessions
| Keys | Action |
|---|---|
| `C-a` `g` | **grove** — git worktree × session picker in a popup (`~/projects/grove`) |
| `C-a` `G` | **grove sidebar** — picker left, live session right (nested: inner prefix is `C-a` `C-a`) |
| `C-a` `o` | tmux-sessionx — fuzzy session picker in a popup |
| `C-a` `s` / `w` | built-in `choose-tree` (sessions / windows) |

### Windows
| Keys | Action |
|---|---|
| `C-a` `c` | new window (in current pane's path) |
| `C-a` `C-n` | next window |
| `C-a` `C-p` | previous window |
| `C-a` `<` | move window left *(hold to repeat)* |
| `C-a` `>` | move window right *(repeat)* |
| `C-a` `h` | previous window *(repeat)* |
| `C-a` `k` | next window *(repeat)* |

### Panes — split
| Keys | Action |
|---|---|
| `C-a` `\|` or `%` | split left/right (current path) |
| `C-a` `-` or `"` | split top/bottom (current path) |
| `C-a` `\` | full-width left/right split |
| `C-a` `_` | full-height top/bottom split |

### Panes — navigate
| Keys | Action |
|---|---|
Colemak layout: `m` `n` `e` `i` (pain-control's `hjkl` are unbound).

| Keys | Action |
|---|---|
| `C-a` `m` | select pane left |
| `C-a` `n` | select pane down |
| `C-a` `e` | select pane up |
| `C-a` `i` | select pane right |

### Panes — resize (5 cells, repeatable)
| Keys | Action |
|---|---|
| `C-a` `M` | left |
| `C-a` `N` | down |
| `C-a` `E` | up |
| `C-a` `I` | right |

### Mouse & options in effect
- `mouse on` — click to select pane/window, drag borders to resize, scroll to enter copy-mode.
- `base-index 1`, `pane-base-index 1` — windows/panes number from 1.
- `escape-time 0`, `history-limit 50000`, `display-time 4000`, `status-interval 5`, `status-keys emacs`, `focus-events on`, `aggressive-resize on` (sensible).
- automatic-rename / allow-rename **off** — window names stay fixed.

All other tmux defaults still work (`C-a d` detach, `C-a [` copy-mode, `C-a z` zoom, `C-a x` kill pane, `C-a &` kill window, `C-a 1-9` select window, `C-a ,` rename, `C-a :` command prompt). Only the keys above are overridden.
