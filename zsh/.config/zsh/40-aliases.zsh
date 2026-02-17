# =============================================================================
# ALIASES
# =============================================================================
# This file contains all aliases organized by category

# === General Aliases ===
alias ls='eza --color=always --long --git --no-permissions --no-user --no-time  --no-filesize  --icons=always'
alias v='nvim .'
alias vi='nvim'
alias t='tmux-se'
alias c='clear'
alias fv='nvim $(fd . -H ~ | fzf --algo=v1 -m --preview="bat --color=always {}")'
alias fp='tmux-se'

# === SSH/Remote Access ===
alias vps='ssh galib@ssh.faisal.click'
alias kube_vps='ssh -i ~/.ssh/kube_rsa faisal@13.126.197.249'
alias local_vps='ssh -i ~/.ssh/kube_rsa root@vm.softcellbd.net -p 65535'

# === Claude Code Aliases ===
alias cc='claude'
alias ccy='claude  --resume --dangerously-skip-permissions'  # Yellow mode - skip permissions
alias ccc='claude --continue'  # Continue most recent conversation
alias ccr='claude --resume'    # Resume session interactively
alias ccp='claude -p'          # Print mode - query and exit
alias ccv='claude --verbose'   # Verbose logging
alias ccu='claude update'      # Update Claude Code
alias ccm='claude mcp'         # MCP server configuration

# === Opencode Aliases ===
opencode() {
  local mcp_env="$HOME/dotfiles/opencode/mcp-env.sh"
  if [[ -f "$mcp_env" ]]; then
    source "$mcp_env"
  fi
  command opencode "$@"
}

# === Claude Code with Z.AI Endpoint ===
alias ccz='_ccz_env claude'                                              # Z.AI endpoint
alias cczy='_ccz_env claude --resume --dangerously-skip-permissions'     # Z.AI + yellow mode
alias cczc='_ccz_env claude --continue'                                  # Z.AI + continue
alias cczr='_ccz_env claude --resume'                                    # Z.AI + resume
alias cczp='_ccz_env claude -p'                                          # Z.AI + print mode
alias cczv='_ccz_env claude --verbose'                                   # Z.AI + verbose

# === Shorebird Aliases ===
alias shorebird-auth='load_shorebird_token'
