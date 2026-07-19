# =============================================================================
# MODULAR ZSH CONFIGURATION
# =============================================================================
# This file sources all modular configuration files in order
# Each module handles a specific aspect of the shell configuration

# Get the directory of this file
ZSH_CONFIG_DIR="$(dirname "$(readlink -f "${(%):-%x}")")/.config/zsh"

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

# NVM Configuration - Load after all other configurations
export NVM_DIR="$HOME/.config/nvm"
# Fix NPM_CONFIG_PREFIX issue before and after loading NVM
unset NPM_CONFIG_PREFIX
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# Ensure NVM default is loaded and NPM_CONFIG_PREFIX is unset
unset NPM_CONFIG_PREFIX
nvm use default > /dev/null 2>&1

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/galib/.config/.dart-cli-completion/zsh-config.zsh ]] && . /home/galib/.config/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]


# Shopify Hydrogen alias to local projects
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# bun completions
[ -s "/home/galib/.bun/_bun" ] && source "/home/galib/.bun/_bun"


# Added by Antigravity CLI installer
export PATH="/home/galib/.local/bin:$PATH"

# Turso
export PATH="$PATH:/home/galib/.turso"
