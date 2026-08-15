# =============================================================================
# MODULAR ZSH CONFIGURATION
# =============================================================================
# This file sources all modular configuration files in order
# Each module handles a specific aspect of the shell configuration

# Get the directory of this file
# Resolve dir of this file portably (zsh :A resolves symlinks; readlink -f is GNU-only)
ZSH_CONFIG_DIR="$(dirname "${${(%):-%x}:A}")/.config/zsh"

# Source all configuration files in order
for config_file in "$ZSH_CONFIG_DIR"/*.zsh; do
  if [[ -f "$config_file" ]]; then
    source "$config_file"
  fi
done

# Alternatively, you can load files explicitly:
# source "$ZSH_CONFIG_DIR/00-core.zsh"
# source "$ZSH_CONFIG_DIR/10-environment.zsh"
# source "$ZSH_CONFIG_DIR/20-plugins.zsh"
# source "$ZSH_CONFIG_DIR/30-completions.zsh"
# source "$ZSH_CONFIG_DIR/40-aliases.zsh"
# source "$ZSH_CONFIG_DIR/50-tools.zsh"
# source "$ZSH_CONFIG_DIR/60-functions.zsh"
# source "$ZSH_CONFIG_DIR/70-theme.zsh"

# Node is managed by mise (see .config/zsh/80-mise.zsh); nvm has been removed.

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f "$HOME/.config/.dart-cli-completion/zsh-config.zsh" ]] && . "$HOME/.config/.dart-cli-completion/zsh-config.zsh" || true
## [/Completion]


# Shopify Hydrogen alias to local projects
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"

# Turso
export PATH="$PATH:$HOME/.turso"
