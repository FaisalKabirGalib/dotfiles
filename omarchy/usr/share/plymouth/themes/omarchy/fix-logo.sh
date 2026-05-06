#!/bin/bash
set -euo pipefail

THEME_DIR="/usr/share/plymouth/themes/omarchy"
CUSTOM_LOGO="/home/galib/dotfiles/omarchy/usr/share/plymouth/themes/omarchy/logo.png"

if [ ! -f "$CUSTOM_LOGO" ]; then
    echo "Error: Custom logo not found at $CUSTOM_LOGO"
    exit 1
fi

# Remove symlink or existing file
echo "Removing existing logo..."
sudo rm -f "$THEME_DIR/logo.png"

# Copy custom logo directly (not symlink — root partition is encrypted at boot)
echo "Copying custom logo..."
sudo cp "$CUSTOM_LOGO" "$THEME_DIR/logo.png"

# Verify it's a real file, not symlink
if [ -L "$THEME_DIR/logo.png" ]; then
    echo "Error: logo.png is still a symlink!"
    exit 1
fi

echo "Rebuilding UKI with limine-mkinitcpio..."
if command -v limine-mkinitcpio &>/dev/null; then
    sudo limine-mkinitcpio
else
    echo "limine-mkinitcpio not found, falling back to mkinitcpio -P"
    sudo mkinitcpio -P
fi

echo ""
echo "✓ Done! Reboot to see your custom logo."
