#!/usr/bin/env bash

DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

stow_package() {
	local action="$1"
	local package="${2%/}"
	local path="$DOTFILES_ROOT/$package"

	if [[ ! -d "$path" || ! -f "$path/PACKAGE.md" ]]; then
		echo "error: '$package' is not a Stow package (missing PACKAGE.md)" >&2
		return 1
	fi

	case "$action" in
	stow)
		echo "stowing $package"
		stow -d "$DOTFILES_ROOT" -t "$HOME" -D "$package" >/dev/null 2>&1 || true
		stow -d "$DOTFILES_ROOT" -t "$HOME" "$package"
		;;
	unstow)
		echo "removing $package"
		stow -d "$DOTFILES_ROOT" -t "$HOME" -D "$package"
		;;
	*)
		echo "error: unsupported Stow action '$action'" >&2
		return 1
		;;
	esac
}

stow_all_packages() {
	local action="$1"
	local path package

	for path in "$DOTFILES_ROOT"/*/; do
		package="${path%/}"
		package="${package##*/}"
		[[ -f "$DOTFILES_ROOT/$package/PACKAGE.md" ]] || continue
		stow_package "$action" "$package"
	done
}
