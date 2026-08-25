#!/usr/bin/env bash
set -euo pipefail

upstream=https://github.com/thanhdat77/herdr-navigator.git
commit=e12a97c5d9ddcd76ba18c985909ffeb4827afa6a
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
patch_file="$repo_root/scripts/patches/herdr-navigator-v0.3.6-hierarchy.patch"
source_dir="${XDG_DATA_HOME:-$HOME/.local/share}/herdr/plugins-src/herdr-navigator-$commit"

if [[ ! -d $source_dir/.git ]]; then
	mkdir -p "${source_dir%/*}"
	git clone --filter=blob:none "$upstream" "$source_dir"
	git -C "$source_dir" checkout --detach "$commit"
fi

[[ $(git -C "$source_dir" remote get-url origin) == "$upstream" ]] || {
	printf 'unexpected Herdr Navigator origin: %s\n' "$source_dir" >&2
	exit 1
}

[[ $(git -C "$source_dir" rev-parse HEAD) == "$commit" ]] || {
	printf 'unexpected Herdr Navigator commit: %s\n' "$source_dir" >&2
	exit 1
}

if git -C "$source_dir" apply --check "$patch_file" 2>/dev/null; then
	git -C "$source_dir" apply "$patch_file"
elif ! git -C "$source_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
	printf 'Herdr Navigator source does not match the pinned extension\n' >&2
	exit 1
fi

cargo fmt --manifest-path "$source_dir/Cargo.toml" --check
cargo clippy --manifest-path "$source_dir/Cargo.toml" --all-targets --all-features --locked -- -D warnings
cargo test --manifest-path "$source_dir/Cargo.toml" --locked
cargo build --manifest-path "$source_dir/Cargo.toml" --release --locked

plugin_json=$(herdr plugin list --plugin herdr-navigator --json)
source_kind=$(jq -r '.result.plugins[0].source.kind // empty' <<<"$plugin_json")
plugin_root=$(jq -r '.result.plugins[0].plugin_root // empty' <<<"$plugin_json")
plugin_enabled=$(jq -r '.result.plugins[0].enabled // false' <<<"$plugin_json")
github_repo=$(jq -r '.result.plugins[0].source | if .kind == "github" then "\(.owner)/\(.repo)" else empty end' <<<"$plugin_json")
github_ref=$(jq -r '.result.plugins[0].source.requested_ref // .result.plugins[0].source.resolved_commit // empty' <<<"$plugin_json")
link_plugin=true

case $source_kind in
	github) herdr plugin uninstall herdr-navigator ;;
	local)
		[[ $(realpath -m "$plugin_root") == $(realpath -m "$source_dir") ]] || {
			printf 'herdr-navigator is linked from another directory: %s\n' "$plugin_root" >&2
			exit 1
		}
		[[ $plugin_enabled == true ]] || herdr plugin enable herdr-navigator
		link_plugin=false
		;;
	"") ;;
	*)
		printf 'unsupported herdr-navigator source: %s\n' "$source_kind" >&2
		exit 1
		;;
esac

if $link_plugin && ! herdr plugin link "$source_dir" --enabled; then
	if [[ -n $github_repo && -n $github_ref ]]; then
		if herdr plugin install "$github_repo" --ref "$github_ref" --yes; then
			[[ $plugin_enabled == true ]] || herdr plugin disable herdr-navigator
		fi
	fi
	exit 1
fi
herdr server reload-config
