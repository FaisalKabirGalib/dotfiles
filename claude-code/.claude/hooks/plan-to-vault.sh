#!/usr/bin/env bash
# PostToolUse:ExitPlanMode — file each approved plan in the Obsidian vault.
set -euo pipefail

VAULT="$HOME/Documents/My notes"

in=$(cat)
plan=$(jq -r '.tool_input.plan // empty' <<<"$in")
[ -n "$plan" ] || exit 0

cwd=$(jq -r '.cwd // empty' <<<"$in")
repo=$(basename "$(git -C "${cwd:-$PWD}" rev-parse --show-toplevel 2>/dev/null || echo "${cwd:-$PWD}")")

dir="$VAULT/Plans/$repo"
mkdir -p "$dir"
{
  printf -- '---\ncreated: %s\nrepo: %s\nproject: "[[%s]]"\ntags: [plan]\n---\n\n' \
    "$(date +%F)" "$repo" "$repo"
  printf '%s\n' "$plan"
} > "$dir/$(date +%Y-%m-%d-%H%M%S).md"
