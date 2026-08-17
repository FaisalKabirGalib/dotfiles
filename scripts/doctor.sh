#!/usr/bin/env bash
# Health check for the dotfiles repo:
#   - every package directory has a PACKAGE.md marker
#   - stow can (re)apply each package without real conflicts (dry run)
#   - no broken symlinks in the common XDG config locations
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR" || exit 1

issues=0

echo "==> Checking PACKAGE.md markers"
for dir in */; do
	dir="${dir%/}"
	case "$dir" in
	scripts | shared) continue ;;
	esac
	if [ ! -f "$dir/PACKAGE.md" ]; then
		echo "  ! $dir has no PACKAGE.md (won't be stowed)"
		issues=$((issues + 1))
	fi
done

echo "==> Checking Stow ignore files"
required_ignores=(
	'PACKAGE\.md'
	'README\.md'
	'LICENSE'
	'\.git'
	'\.gitignore'
	'\.stow-local-ignore'
)
for dir in */; do
	dir="${dir%/}"
	[ -f "$dir/PACKAGE.md" ] || continue
	ignore_file="$dir/.stow-local-ignore"
	if [ ! -f "$ignore_file" ]; then
		echo "  ! $dir has no .stow-local-ignore"
		issues=$((issues + 1))
		continue
	fi
	for pattern in "${required_ignores[@]}"; do
		if ! grep -Fqx "$pattern" "$ignore_file"; then
			echo "  ! $ignore_file is missing: $pattern"
			issues=$((issues + 1))
		fi
	done
done

echo "==> Dry-run restow for each package (real conflicts only)"
for dir in */; do
	dir="${dir%/}"
	[ -f "$dir/PACKAGE.md" ] || continue
	# -R restow handles already-stowed links as no-ops; we only care about
	# targets that exist as real (non-symlink) files blocking the stow.
	conflicts="$(stow -n -R -d "$DOTFILES_DIR" -t "$HOME" "$dir" 2>&1 | grep -E 'cannot stow|existing target' || true)"
	if [ -n "$conflicts" ]; then
		echo "  ! $dir:"
		echo "$conflicts" | sed -E 's/.*over existing target ([^ ]+).*/      \1 (real file, not a symlink)/'
		issues=$((issues + 1))
	fi
done

echo "==> Checking for broken symlinks in ~/.config and ~ (top level)"
broken="$(find -L "$HOME/.config" "$HOME" -maxdepth 1 -type l 2>/dev/null)"
if [ -n "$broken" ]; then
	while IFS= read -r link; do
		printf '  ! broken: %s\n' "$link"
	done <<< "$broken"
	issues=$((issues + 1))
fi

echo ""
if [ "$issues" -eq 0 ]; then
	echo "✓ All checks passed."
else
	echo "✗ $issues issue(s) found. (Resolve real-file conflicts with: stow --adopt <pkg>, then review the diff)"
	exit 1
fi
