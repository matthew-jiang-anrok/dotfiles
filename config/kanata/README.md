# kanata config

Colemak-DHm (angle mod) layout for the MacBook's **built-in** keyboard, driven by
[kanata](https://github.com/jtroo/kanata). macOS itself stays on US-QWERTY —
kanata does all the remapping in software.

Only the `Apple Internal Keyboard / Trackpad` is grabbed. Any external board
(e.g. an Iris that already remaps in firmware) passes through untouched, so
plugging one in effectively disables kanata for that keyboard.

## Install & run

```sh
brew install kanata
kanata --cfg ~/.config/kanata/kanata.kbd     # run
kanata --cfg ~/.config/kanata/kanata.kbd --check   # validate only
kanata --list                                # list device names (to adjust the grab list)
```

macOS needs Karabiner's VirtualHID driver + Input Monitoring / Accessibility
permissions for kanata. See the kanata macOS setup docs.

## Layers

| Layer | How to reach it |
|-------|-----------------|
| `colemak` | base (default) |
| `nav` | **Tab** — tap toggles/locks, hold = momentary |
| `symbol` | **`[`** — tap toggles/locks, hold = momentary |

Layer triggers are on the pinky keys (not thumbs — the laptop has no thumb
cluster). Because they *toggle*, tapping the same key again returns to base.

## Home row mods (CAGS)

Both bases use home-row mods: **tap = letter, hold = modifier**, permissive-hold
(`tap-hold-release`, 200 ms). Order is pinky→index **C**trl **A**lt **G**ui(Cmd)
**S**hift, mirrored across hands.

| Hand | pinky | ring | middle | index |
|------|-------|------|--------|-------|
| Left  (`a s d f`) | Ctrl | Alt | Cmd | Shift |
| Right (`j k l ;`) | Ctrl | Alt | Cmd | Shift |

## Base layer (colemak)

- **Number row `1`–`0`** → emit **Ctrl+Alt+`<n>`** (not plain digits). Real digits
  live on the symbol layer.
- **Caps Lock** → **Esc**.
- **Both Shift keys** → **one-shot Shift** (tap = shift next key).
- **Tab** → nav layer trigger · **`[`** → symbol layer trigger.
- Alphas: Colemak-DHm with angle mod (bottom-left row `x c d v z`).

## Nav layer

- Arrows (vim-style) on physical **`h j k l`** → Left / Down / Up / Right.
- **`y u i o`** → Home / PgDn / PgUp / End.
- Everything else transparent — left home still gives home-row mods.

## Symbol layer

- **Home row = digits** with the same CAGS home-row mods:

  | a | s | d | f | g | h | j | k | l | ; |
  |---|---|---|---|---|---|---|---|---|---|
  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 |

  (`g`/`h` are plain 5/6; the eight outer keys also act as mods on hold.)
- **Top row = brackets**, order `< { [ ( ) ] } >`:

  | q | w | e | r | u | i | o | p |
  |---|---|---|---|---|---|---|---|
  | `<` | `{` | `[` | `(` | `)` | `]` | `}` | `>` |
- **Bottom row misc:** `x`=`` ` `` · `c`=`-` · `m`=`=` · `,`=`\`

## Combos (`defchordsv2`)

Positional — matched on **physical** keys, 40 ms window, active on **all** layers.

| Physical keys | Output |
|---------------|--------|
| `,` + `.` | Enter |
| `m` + `,` | Backspace |
| `z` + `x` | Tab |

> Because combos are physical and have no disabled-layer list, they also fire on
> nav/symbol. Add layer names after a combo (e.g. `(z x) tab 40 first-release (symbol)`)
> to restrict it.

## Tuning notes

- Adjust the `200` timeouts in the `defalias` block if home-row mods feel laggy
  (lower) or misfire while typing fast (raise, or switch to `tap-hold-release-keys`
  with opposite-hand key lists).
- One-shot Shift on the pinkies is redundant with the f/j home-row Shift — kept
  for sticky-shift convenience.
