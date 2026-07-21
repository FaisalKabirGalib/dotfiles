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
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.config/composer/vendor/bin"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Dynamic Flutter Setup
# Loops through potential Flutter SDK directories and adds the first valid path to PATH
for flutter_dir in "$HOME/development/flutter" "$HOME/Dev/flutter" "/opt/homebrew/share/flutter"; do
  if [[ -d "$flutter_dir/bin" ]]; then
    export PATH="$flutter_dir/bin:$PATH"
    break
  fi
done

# Mason (Dart tooling)
export PATH="$PATH":"$HOME/.pub-cache/bin"

#Go path 
GOPATH=$HOME/go PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Shorebird
export PATH="$PATH":"$HOME/.shorebird/bin/shorebird"
export PATH="$HOME/.shorebird/bin:$PATH"
export PATH="$HOME/.config/shorebird/bin:$PATH"

# Claude Code Templates - Global Agents
export PATH="$HOME/.claude-code-templates/bin:$PATH"

# SDKMAN (MUST BE AT THE END FOR SDKMAN TO WORK)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Preferred Editor
export EDITOR="nvim"

# Android Platform Tools (added for adb / mirroring)
export PATH="/opt/homebrew/share/android-commandlinetools/platform-tools:$PATH"

