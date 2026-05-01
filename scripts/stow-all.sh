#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

echo "Stowing all dotfile packages..."

for pkg in */; do
	pkg="${pkg%/}"
	[ -f "$pkg/PACKAGE.md" ] || continue
	echo "  stowing $pkg"
	stow -D "$pkg" 2>/dev/null || true
	stow "$pkg"
done

echo "All packages stowed."
