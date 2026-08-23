eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(atuin init zsh)"
set -o vi
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Force emacs-style line editing (override Omachy's `set -o vi`)
set -o emacs

# Initialize zsh completion system (enables _git branch completion, etc.)
autoload -Uz compinit && compinit

export PATH="$HOME/.local/bin:$PATH"
export PATH="/Applications/QGIS-final-4_0_2.app/Contents/MacOS:$PATH"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export NODE_EXTRA_CA_CERTS="$HOME/Library/Application Support/mkcert/rootCA.pem"
export EDITOR="nvim"
export VISUAL="nvim"

# Secrets (API keys, etc.) — kept out of this file; see ~/.zsh_secrets
[ -f ~/.zsh_secrets ] && source ~/.zsh_secrets

source ~/.zsh_aliases

# Notion + neovim CLI workflow
# Default parent for new pages: page:<id>, database:<id> or data-source:<id>.
# export NOTION_PARENT="page:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
source ~/.config/notion/workflow.zsh
export PATH="/opt/homebrew/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
