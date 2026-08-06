# =============================================================================
# PLUGIN MANAGEMENT WITH ZINIT
# =============================================================================
# This file contains Zinit initialization and all plugin loading

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Essential additions
zinit light hlissner/zsh-autopair
zinit light zdharma-continuum/history-search-multi-word
zinit light MichaelAquilina/zsh-you-should-use

# Add in snippets
# Basic
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Tools
zinit snippet OMZP::zoxide
zinit snippet OMZP::tmux
zinit snippet OMZP::ssh
zinit snippet OMZP::rsync
zinit snippet OMZP::ansible


# Development tools
zinit snippet OMZP::extract
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q
