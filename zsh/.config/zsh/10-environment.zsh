# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================
# This file contains all PATH exports and environment variables

# Homebrew (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Custom PATH entries
export PATH="$HOME/dotfiles/bin:$HOME/dotfiles:$PATH"
export PATH="$HOME/.local/script:$PATH"
export PATH="$PATH:/home/galib/.local/bin"
export PATH="$HOME/development/flutter/bin:$PATH"
export PATH="$PATH:$HOME/.config/composer/vendor/bin"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

#Flutter
# export PATH="$HOME/Dev/flutter/bin:$PATH"

# Mason (Dart tooling)
export PATH="$PATH":"$HOME/.pub-cache/bin"

#Go path 
GOPATH=$HOME/go PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Shorebird
export PATH="$PATH":"$HOME/.shorebird/bin/shorebird"
export PATH="/home/galib/.shorebird/bin:$PATH"
export PATH="/home/galib/.config/shorebird/bin:$PATH"

# Claude Code Templates - Global Agents
export PATH="/home/galib/.claude-code-templates/bin:$PATH"

# SDKMAN (MUST BE AT THE END FOR SDKMAN TO WORK)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
