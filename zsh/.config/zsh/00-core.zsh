# =============================================================================
# CORE ZSH CONFIGURATION
# =============================================================================
# This file contains essential zsh settings that should be loaded first

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# --- Command Line Editing & Widgets ---
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^N' edit-command-line

# Expand history expansion tags (!!, !$) on Space bar
bindkey ' ' magic-space

# Clear screen and scrollback buffer
function clear-screen-and-scrollback() {
  echoti civis >"$TTY"
  printf '%b' '\e[H\e[2J\e[3J' >"$TTY"
  echoti cnorm >"$TTY"
  zle redisplay
}
zle -N clear-screen-and-scrollback
bindkey '^Xl' clear-screen-and-scrollback

# Copy prompt buffer to clipboard (Wayland/X11/macOS agnostic)
function copy-buffer-to-clipboard() {
  if (( $+commands[wl-copy] )); then
    echo -n "$BUFFER" | wl-copy
  elif (( $+commands[xclip] )); then
    echo -n "$BUFFER" | xclip -selection clipboard
  elif (( $+commands[pbcopy] )); then
    echo -n "$BUFFER" | pbcopy
  else
    zle -M "No clipboard tool (install wl-clipboard)"
    return 1
  fi
  zle -M "Copied prompt to clipboard"
}
zle -N copy-buffer-to-clipboard
bindkey '^Xc' copy-buffer-to-clipboard

# History Configuration
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

alias egrep='grep -E'