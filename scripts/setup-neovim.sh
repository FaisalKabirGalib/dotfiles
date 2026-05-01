#!/usr/bin/env bash
set -euo pipefail

# Bootstrap Lazy.nvim if not present
LAZY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy/lazy.nvim"

if [ ! -d "$LAZY_DIR" ]; then
	echo "Installing Lazy.nvim..."
	git clone --filter=blob:none https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
	echo "Lazy.nvim installed. Open nvim to install plugins."
else
	echo "Lazy.nvim already installed."
fi
