#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/scripts" && pwd)"

echo ""
echo "=============================================="
echo "  Dotfiles Installation"
echo "=============================================="
echo ""
echo "This script will:"
echo "  1. Install system packages (pacman)"
echo "  2. Install AUR packages (yay/paru)"
echo "  3. Stow dotfile packages"
echo "  4. Install the mise toolchain (runtimes, dev CLIs, coding agents)"
echo "  5. Set up zsh + zinit"
echo "  6. Bootstrap neovim"
echo ""
read -p "Continue? (Y/n): " -r
[[ "${REPLY,,}" == "n" ]] && echo "Cancelled." && exit 0

# Step 1: System packages
echo ""
echo "--- System Packages ---"
bash "$SCRIPTS_DIR/install-packages.sh"

# Step 2: AUR packages (skip if no helper)
echo ""
echo "--- AUR Packages ---"
if command -v yay &>/dev/null || command -v paru &>/dev/null; then
	bash "$SCRIPTS_DIR/install-aur.sh"
else
	echo "No AUR helper found. Skipping AUR packages."
	echo "Install yay or paru, then run: scripts/install-aur.sh"
fi

# Step 3: Stow dotfiles
echo ""
echo "--- Stowing Dotfiles ---"
bash "$SCRIPTS_DIR/stow-all.sh"

# Step 4: Toolchain (must follow stow: reads the stowed ~/.config/mise/config.toml)
echo ""
echo "--- Toolchain (mise) ---"
bash "$SCRIPTS_DIR/setup-mise.sh"

# Step 5: Shell setup
echo ""
echo "--- Shell Setup ---"
bash "$SCRIPTS_DIR/setup-shell.sh"

# Step 6: Neovim setup
echo ""
echo "--- Neovim Setup ---"
bash "$SCRIPTS_DIR/setup-neovim.sh"

# Done
echo ""
echo "=============================================="
echo "  Installation Complete"
echo "=============================================="
echo ""
echo "Next steps:"
echo "  - Log out and back in (or reboot)"
echo "  - Open nvim to install plugins"
echo "  - Run 'omp' then '/login' for the omp agent"
echo ""
