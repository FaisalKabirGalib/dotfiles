# =============================================================================
# MISE — TOOLCHAIN ACTIVATION
# =============================================================================
# Single source of truth for language runtimes and dev CLIs. See mise/PACKAGE.md.
#
# Loaded last on purpose: `mise activate` PREPENDS its resolved tool dirs, so it
# has to run after every `export PATH="...:$PATH"` in the earlier modules.
# Omarchy only APPENDS ~/.local/share/mise/shims (see
# /usr/share/omarchy/default/bash/env-bootstrap), which leaves /usr/bin shadowing
# every mise-managed runtime — this activation is what fixes the precedence.

if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

for _mise_completion_tool in opencode codex; do
  _mise_completion_bin="$(whence -p "$_mise_completion_tool")"
  _mise_completion_file="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/_$_mise_completion_tool"
  if [[ -n "$_mise_completion_bin" && ( ! -s "$_mise_completion_file" || "$_mise_completion_bin" -nt "$_mise_completion_file" ) ]]; then
    mkdir -p "${_mise_completion_file:h}"
    command "$_mise_completion_tool" completion zsh >"$_mise_completion_file" 2>/dev/null
  fi
  [[ -s "$_mise_completion_file" ]] && source "$_mise_completion_file"
done
unset _mise_completion_tool _mise_completion_bin _mise_completion_file

# Bun completions. The ~/.bun/_bun file shipped by bun's own installer is gone,
# so cache them from whichever bun mise resolves. Invalidated against the global
# mise config rather than by shelling out to `bun --version` on every startup —
# `just tools` also clears the cache after an upgrade.
_bun_comp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/_bun"
if [[ ! -s "$_bun_comp" || "$HOME/.config/mise/config.toml" -nt "$_bun_comp" ]] \
  && command -v bun &>/dev/null; then
  mkdir -p "${_bun_comp:h}"
  bun completions >"$_bun_comp" 2>/dev/null
fi
[[ -s "$_bun_comp" ]] && source "$_bun_comp"
unset _bun_comp
