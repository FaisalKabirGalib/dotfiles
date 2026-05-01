#!/usr/bin/env bash
set -euo pipefail

echo "Installing AUR packages..."

mapfile -t packages < <(grep -vE '^\s*#|^\s*$' "$(dirname "$0")/aur-packages.txt")

if command -v yay &>/dev/null; then
	yay -S --needed --noconfirm "${packages[@]}"
elif command -v paru &>/dev/null; then
	paru -S --needed --noconfirm "${packages[@]}"
else
	echo "No AUR helper found. Install yay or paru first."
	exit 1
fi
echo "AUR packages installed."
