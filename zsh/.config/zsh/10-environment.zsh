# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================
# This file contains all PATH exports and environment variables

# Keep $path (and therefore $PATH) unique. Every export below prepends
# unconditionally, so without this a nested zsh accumulates duplicate entries.
typeset -U path PATH

# Homebrew (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Custom PATH entries
# NOTE: the repo root itself is deliberately NOT on PATH. Every top-level stow
# package is a directory there, so a package named after a real command (`mise`,
# `nvim`, `tmux`, ...) becomes a PATH candidate — mise resolved its own binary to
# ~/dotfiles/mise and generated 136 broken shims. stowup/stowDown are exposed
# through the `bin` package (~/.local/bin) instead.
export PATH="$HOME/dotfiles/bin:$PATH"
export PATH="$HOME/.local/script:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.config/composer/vendor/bin"

# Bun, Flutter/Dart, Go, Java, Node, Python, Rust and Ruby are all mise-managed.
# See .config/zsh/80-mise.zsh for activation and mise/PACKAGE.md for the rationale.

# Mason (Dart tooling)
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Binaries from `go install` (mise sets GOROOT/GOPATH itself; this is only the
# bin dir). NOTE: the previous line here was `GOPATH=$HOME/go PATH=...` without
# `export`, which is a prefix assignment — neither variable ever reached the
# environment.
export PATH="$PATH:$HOME/go/bin"

# Shorebird
export PATH="$PATH":"$HOME/.shorebird/bin/shorebird"
export PATH="$HOME/.shorebird/bin:$PATH"
export PATH="$HOME/.config/shorebird/bin:$PATH"

# Claude Code Templates - Global Agents
export PATH="$HOME/.claude-code-templates/bin:$PATH"

# Preferred editor
export EDITOR="nvim"
export ZAI_API_KEY="$(pass ApiKey/ZAi/opencode | head -n 1)"

# (SDKMAN removed: ~/.sdkman never existed on this machine and mise provides java.)
