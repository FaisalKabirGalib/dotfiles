#!/usr/bin/env bash
set -euo pipefail

force_new=false
if [ "${1:-}" = "--new" ]; then
	force_new=true
	shift
fi

project_path="${1:?pj-connect.sh: PROJECT_PATH is required}"
project_name="$(basename "$project_path" | tr '.:' '_')"
herdr_bin="${HERDR_BIN_PATH:-herdr}"

if [ "$force_new" = true ]; then
	"$herdr_bin" workspace create --cwd "$project_path" --label "$project_name" --focus
	exit 0
fi

workspace_id=$("$herdr_bin" workspace list | jq -r \
	--arg path "$project_path" \
	--arg name "$project_name" '
		.result.workspaces[]
		| select(
			(.worktree.checkout_path // "") == $path
			or .label == $name
		)
		| .workspace_id
	' | head -1)

if [ -n "$workspace_id" ]; then
	"$herdr_bin" workspace focus "$workspace_id"
else
	"$herdr_bin" workspace create --cwd "$project_path" --label "$project_name" --focus
fi
