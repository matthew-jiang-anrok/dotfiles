# dotfiles

macOS setup: a tiling window manager, a status bar, tmux, and a terminal that
stays out of the way. Everything here is a plain config file — no framework, no
generated output.

## What is in here

| Path | What it configures |
| --- | --- |
| `home/.tmux.conf` | tmux: `C-a` prefix, Colemak pane movement (`mnei`), Catppuccin status line, TPM plugins |
| `home/.zshrc`, `home/.zshenv` | shell startup: starship, atuin, fzf, zsh-syntax-highlighting |
| `home/.zsh_aliases` | git shorthands, an `fzf` project picker, and a `gwt` git-worktree helper |
| `home/.gitconfig` | push/pull defaults and LFS filters |
| `config/aerospace/` | AeroSpace tiling WM, with gaps and a sketchybar repaint hook |
| `config/ghostty/` | Ghostty: Catppuccin Mocha, JetBrains Mono, blurred translucent background |
| `config/sketchybar/` | the status bar and its plugin scripts (workspaces, media, battery, GitHub, Linear) |
| `config/borders/` | JankyBorders — the glow on the focused window |
| `config/karabiner/`, `config/kanata/` | keyboard remapping |
| `config/nvim/` | LazyVim-based Neovim config |
| `config/starship.toml` | the prompt |
| `config/atuin/`, `config/lazygit/`, `config/zed/`, `config/tmux/CHEATSHEET.md` | the rest |

## Install

```sh
git clone https://github.com/matthew-jiang-anrok/dotfiles ~/projects/dotfiles
~/projects/dotfiles/install.sh
```

`install.sh` symlinks `home/*` into `$HOME` and `config/*` into `~/.config`,
moving anything already there to `<name>.backup` first. It only ever writes
symlinks, so editing a file in this repo edits the live config.

## What is deliberately not here

- **Secrets.** API keys live in `~/.zsh_secrets`, which is sourced by `.zshrc`
  and never committed. Scripts that need a key (sketchybar's Linear pill, for
  one) read it from the environment.
- **Anything a package manager owns.** tmux plugins come from TPM
  (`prefix + I`), Neovim plugins from lazy.nvim, and the tools themselves from
  Homebrew.

## Dependencies

Homebrew, then: `tmux`, `neovim`, `starship`, `atuin`, `fzf`, `zsh-syntax-highlighting`,
`zsh-autosuggestions`, `jq`, and the casks `ghostty`, `nikitabobko/tap/aerospace`,
`FelixKratz/formulae/sketchybar`, `FelixKratz/formulae/borders`, `karabiner-elements`.
