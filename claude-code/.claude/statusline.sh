#!/usr/bin/env bash
# Claude Code statusLine renderer. Reads the statusline JSON payload on stdin.
# Catppuccin Mocha palette, JetBrainsMono Nerd Font glyphs.

input=$(cat)

model=$(jq -r '.model.display_name // "Claude"' <<<"$input")
cwd=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
project_dir=$(jq -r '.workspace.project_dir // empty' <<<"$input")
cost=$(jq -r '.cost.total_cost_usd // empty' <<<"$input")
duration_ms=$(jq -r '.cost.total_duration_ms // empty' <<<"$input")

if [ -n "$project_dir" ] && [ -n "$cwd" ] && [ "$cwd" != "$project_dir" ] && [[ "$cwd" == "$project_dir"/* ]]; then
  dir="$(basename "$project_dir")/${cwd#"$project_dir"/}"
else
  dir=$(basename "${cwd:-$PWD}")
fi

branch=""
if [ -n "$cwd" ] && git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

duration=""
if [ -n "$duration_ms" ] && [ "$duration_ms" != "null" ]; then
  secs=$((duration_ms / 1000))
  mins=$((secs / 60))
  rem=$((secs % 60))
  if [ "$mins" -gt 0 ]; then duration="${mins}m${rem}s"; else duration="${rem}s"; fi
fi

cost_str=""
if [ -n "$cost" ] && [ "$cost" != "null" ]; then
  cost_str=$(printf '$%.2f' "$cost")
fi

# Catppuccin Mocha: mauve, blue, green, yellow, peach, surface2 (separator)
mauve='38;2;203;166;247'
blue='38;2;137;180;250'
green='38;2;166;227;161'
yellow='38;2;249;226;175'
peach='38;2;250;179;135'
sep_color='38;2;108;112;134'

sep=$(printf '\033[%sm \033[0m' "$sep_color")

out=$(printf '\033[%sm \033[0m' "$mauve")
out="$out$model"
out="$out$sep$(printf '\033[%sm \033[0m' "$blue")$dir"
[ -n "$branch" ] && out="$out$sep$(printf '\033[%sm \033[0m' "$green")$branch"
[ -n "$cost_str" ] && out="$out$sep$(printf '\033[%sm\033[0m' "$yellow")$cost_str"
[ -n "$duration" ] && out="$out$sep$(printf '\033[%sm \033[0m' "$peach")$duration"

printf '%s\n' "$out"
