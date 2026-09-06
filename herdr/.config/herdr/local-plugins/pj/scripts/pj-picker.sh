#!/usr/bin/env bash
set -euo pipefail

plugin_root="${HERDR_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
config_dir="${HERDR_PLUGIN_CONFIG_DIR:-$plugin_root}"
config_file="$config_dir/config"
connect_script="$plugin_root/scripts/pj-connect.sh"

cfg() {
	local key="$1" default="$2" val
	if [ -f "$config_file" ]; then
		val=$(grep -E "^${key}=" "$config_file" 2>/dev/null | cut -d= -f2 | tr -d " '" || true)
		[ -n "$val" ] && { printf '%s\n' "$val"; return; }
	fi
	printf '%s\n' "$default"
}

cfg_bool() {
	case "$(cfg "$1" "$2")" in
		true|yes|1) printf '%s\n' true ;;
		*) printf '%s\n' false ;;
	esac
}

picker=$(cfg picker fzf)
sort=$(cfg sort alpha)
sort_direction=$(cfg sort_direction "")
icons=$(cfg_bool icons true)
ansi=$(cfg_bool ansi true)
worktrees=$(cfg worktrees auto)
max_depth=$(cfg max_depth "")
no_nested=$(cfg_bool no_nested false)

pj_flags="--shorten --sort $sort"
[ -n "$sort_direction" ] && pj_flags="$pj_flags --sort-direction $sort_direction"
[ "$icons" = true ] && pj_flags="$pj_flags --icons"
[ "$ansi" = true ] && pj_flags="$pj_flags --ansi"
[ -n "$max_depth" ] && pj_flags="$pj_flags --max-depth $max_depth"
[ "$no_nested" = true ] && pj_flags="$pj_flags --no-nested"
case "$worktrees" in
	yes) pj_flags="$pj_flags --worktrees" ;;
	no) pj_flags="$pj_flags --no-worktrees" ;;
esac

if [ "$picker" != fzf ] && [ "$picker" != auto ]; then
	echo "pj-herdr local plugin supports picker=fzf." >&2
	exit 1
fi

# fzf expands `{}` and the preview shell expands `$HOME`, so retain this as a
# literal script rather than interpolating it in the launcher shell.
# shellcheck disable=SC2016
preview_cmd='
  path=$(/usr/bin/printf "%s\\n" {} | /usr/bin/sed "s/^[^ ]* //" | /usr/bin/sed "s|^~|$HOME|")
  if [ -x /usr/bin/eza ]; then
    /usr/bin/eza --tree --color=always "$path"
  elif [ -x /usr/bin/tree ]; then
    /usr/bin/tree -C "$path"
  else
    /usr/bin/ls -la "$path"
  fi
'

reload_cmd="pj --clear-cache >/dev/null 2>&1; pj $pj_flags"
fzf_ansi=""
[ "$ansi" = true ] && fzf_ansi="--ansi"

result=$(eval "pj $pj_flags" \
	| fzf $fzf_ansi \
		--reverse \
		--preview "$preview_cmd" \
		--preview-window=right:50% \
		--header "enter: open workspace  ctrl-n: new workspace  ctrl-w: worktree  ctrl-e: edit  ctrl-t: new tab  ctrl-r: clear cache" \
		--expect "ctrl-n,ctrl-w,ctrl-e,ctrl-t,ctrl-r" \
		--bind "ctrl-r:reload($reload_cmd)" \
	|| true)

[ -z "$result" ] && exit 0
key=$(printf '%s' "$result" | head -1)
selection=$(printf '%s' "$result" | tail -1)
project_path=$(printf '%s' "$selection" | sed 's/^[^ ]* //' | sed "s|^~|$HOME|")

case "$key" in
	ctrl-n) "$connect_script" --new "$project_path" ;;
	ctrl-w) herdr worktree open --cwd "$project_path" --focus ;;
	ctrl-e) "${EDITOR:-vi}" "$project_path" ;;
	ctrl-t) herdr tab create --cwd "$project_path" --focus ;;
	ctrl-r) ;;
	*) "$connect_script" "$project_path" ;;
esac
