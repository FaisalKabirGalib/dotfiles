# =============================================================================
# ALIASES
# =============================================================================
# This file contains all aliases organized by category

# === General Aliases ===
alias ls='eza --color=always --long --git --no-permissions --no-user --no-time  --no-filesize  --icons=always'
alias v='nvim .'
alias vi='nvim'
alias t='tmux-se'
alias hp='herdr-se'
alias c='clear'
alias fv='nvim $(fd . -H ~ | fzf --algo=v1 -m --preview="bat --color=always {}")'
alias fp='tmux-se'

# === SSH/Remote Access ===
alias vps='ssh galib@ssh.faisal.click'
alias kube_vps='ssh -i ~/.ssh/kube_rsa faisal@13.126.197.249'
alias local_vps='ssh -i ~/.ssh/kube_rsa root@vm.softcellbd.net -p 65535'

# === Claude Code Aliases ===
alias cc='claude'
alias ccy='claude --dangerously-skip-permissions'  # Yellow mode - new session, skip permissions
alias ccc='claude --continue'  # Continue most recent conversation
alias ccr='claude --resume'    # Resume session interactively
alias ccp='claude -p'          # Print mode - query and exit
alias ccv='claude --verbose'   # Verbose logging
alias ccu='claude update'      # Update Claude Code
alias ccm='claude mcp'         # MCP server configuration

# === Opencode Aliases ===
alias ocy='opencode --auto'
alias dsync='dotfiles-sync'

# === Claude Code with Z.AI Endpoint ===
alias ccz='_ccz_env claude'                                              # Z.AI endpoint
alias cczy='_ccz_env claude --resume --dangerously-skip-permissions'     # Z.AI + yellow mode
alias cczc='_ccz_env claude --continue'                                  # Z.AI + continue
alias cczr='_ccz_env claude --resume'                                    # Z.AI + resume
alias cczp='_ccz_env claude -p'                                          # Z.AI + print mode
alias cczv='_ccz_env claude --verbose'                                   # Z.AI + verbose

# === Shorebird Aliases ===
alias shorebird-auth='load_shorebird_token'

# === File Association Suffix Aliases ===
alias -s md=glow
alias -s markdown=glow
alias -s json=jq
alias -s log=bat
alias -s py='$EDITOR'
alias -s go='$EDITOR'
alias -s ts='$EDITOR'
alias -s js='$EDITOR'

# === Global Aliases (Use Anywhere in Commands) ===
alias -g NE='2>/dev/null'
alias -g NO='>/dev/null'
alias -g NUL='>/dev/null 2>&1'
alias -g J='| jq'
alias -g C='| wl-copy'

# === Advanced Batch Rename (zmv) ===
autoload -Uz zmv
alias zcp='zmv -C'
alias zln='zmv -L'

# === Named Directories (Bookmarks) ===
hash -d dot=~/dotfiles
hash -d dl=~/Downloads

# === Wireless Mirroring Shortcut ===
# scrcpy-wireless is defined in 60-functions.zsh
alias mirror="scrcpy-wireless"
