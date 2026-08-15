# =============================================================================
# COMPLETION CONFIGURATION
# =============================================================================
# This file contains completion styling and external completion scripts

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Dart CLI completion
## Completion scripts setup. Remove the following line to uninstall
[[ -f "$HOME/.dart-cli-completion/zsh-config.zsh" ]] && . "$HOME/.dart-cli-completion/zsh-config.zsh" || true
## [/Completion]

## Completion scripts setup. Remove the following line to uninstall
[[ -f "$HOME/.config/.dart-cli-completion/zsh-config.zsh" ]] && . "$HOME/.config/.dart-cli-completion/zsh-config.zsh" || true
## [/Completion]

# Bun completions live in 80-mise.zsh — bun is mise-managed and only resolves to
# the right binary after `mise activate`.