#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/stow-common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/stow-common.sh"

echo "Stowing all dotfile packages..."
stow_all_packages stow

echo "All packages stowed."
