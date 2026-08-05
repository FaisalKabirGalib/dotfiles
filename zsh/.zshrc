# =============================================================================
# MODULAR ZSH CONFIGURATION
# =============================================================================
# This file sources all modular configuration files in order
# Each module handles a specific aspect of the shell configuration

# Get the directory of this file (zsh's :A modifier resolves symlinks portably,
# unlike `readlink -f` which BSD/macOS readlink doesn't support)
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
[[ -f "$HOME/.config/.dart-cli-completion/zsh-config.zsh" ]] && . "$HOME/.config/.dart-cli-completion/zsh-config.zsh" || true
## [/Completion]


# Shopify Hydrogen alias to local projects
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"


# --- Bonsai local LLM (llama.cpp, on-demand, :11436) ---
# bz  = 1-bit (bonsai, fast/default) ; bz2 = 2-bit (ternary, sharper). Both take {8b|27b}; add "web" for UI.
#   bz               8B 1-bit (default)     bz 27b           27B 1-bit
#   bz2              8B 2-bit               bz2 27b          27B 2-bit
#   bz web [args]    start with web UI      bz off | bz status   (off/status shared — one server on :11436)
# Switching model while one is up auto-restarts. apfel still on :11434.
_bz() {
  local bits="$1"; shift
  local port=11436 webui="--no-webui" size="8B" a
  for a in "$@"; do
    case "$a" in
      web)            webui="" ;;                  # opt into the web UI
      off|down|stop)  kill $(lsof -ti TCP:$port) 2>/dev/null && echo "bonsai stopped" || echo "not running"; return ;;
      status)         curl -s --max-time 1 http://localhost:$port/health 2>/dev/null | grep -q ok \
                        && echo "up on :$port ($(curl -s http://localhost:$port/v1/models 2>/dev/null | grep -o '[A-Za-z0-9._-]*\.gguf' | head -1))" \
                        || echo "down"; return ;;
      -h|--help|help) echo "bz|bz2 [web] [8b|27b]  |  bz off  |  bz status"; return ;;
      8b|8B)          size="8B" ;;
      27b|27B)        size="27B" ;;
      *) echo "bz: unknown '$a' — try: bz|bz2 [web] [8b|27b] | off | status"; return 1 ;;
    esac
  done
  local family file
  [ "$bits" = 1 ] && family="bonsai" || family="ternary"   # 1-bit=bonsai, 2-bit=ternary
  case "$family/$size" in
    bonsai/8B)   file="Bonsai-8B-Q1_0.gguf" ;;
    bonsai/27B)  file="Bonsai-27B-Q1_0.gguf" ;;
    ternary/8B)  file="Ternary-Bonsai-8B-Q2_0.gguf" ;;
    ternary/27B) file="Ternary-Bonsai-27B-Q2_0.gguf" ;;
  esac
  # already running? no-op if it's the same model, else restart to switch.
  if curl -s --max-time 1 http://localhost:$port/health 2>/dev/null | grep -q ok; then
    if curl -s http://localhost:$port/v1/models 2>/dev/null | grep -q "$file"; then
      echo "already up: $file on :$port"; return 0
    fi
    echo "switching -> $file"; kill $(lsof -ti TCP:$port) 2>/dev/null; sleep 1
  fi
  # ponytail: $webui unquoted on purpose — empty => web UI on, set => single --no-webui token
  ( cd "$HOME/work/bonsai/Bonsai-demo" && \
    BONSAI_FAMILY=$family BONSAI_MODEL="$size" BONSAI_CTX=32768 BONSAI_PORT=$port \
    nohup ./scripts/start_llama_server.sh $webui >"$HOME/Library/Logs/bonsai.log" 2>&1 & )
  printf "starting %s-bit %s (%s) on :%s" "$bits" "$size" "$family" "$port"
  [ -z "$webui" ] && printf " +webui http://localhost:%s" "$port"
  local i
  for i in {1..40}; do
    curl -s --max-time 1 http://localhost:$port/health 2>/dev/null | grep -q ok && { echo " ready"; return 0; }
    printf "."; sleep 1
  done
  echo " (still loading — see ~/Library/Logs/bonsai.log)"
}
bz()  { _bz 1 "$@"; }   # 1-bit (bonsai) — fast, default
bz2() { _bz 2 "$@"; }   # 2-bit (ternary) — sharper


