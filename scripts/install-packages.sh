#!/usr/bin/env bash
set -euo pipefail

echo "Installing system packages..."

# Read packages from config, skip comments and blank lines
mapfile -t packages < <(grep -vE '^\s*#|^\s*$' "$(dirname "$0")/packages.txt")

sudo pacman -S --needed --noconfirm "${packages[@]}"
echo "System packages installed."
