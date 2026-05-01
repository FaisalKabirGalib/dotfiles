#!/usr/bin/env bash
set -euo pipefail

# Change default shell to zsh
if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
	echo "Changing default shell to zsh..."
	chsh -s "$(which zsh)"
	echo "Default shell changed (takes effect on next login)."
else
	echo "Zsh is already the default shell."
fi

# Install zinit if not present
if [ ! -d "$HOME/.local/share/zinit/zinit.git" ]; then
	echo "Installing zinit plugin manager..."
	bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
	echo "Zinit installed."
else
	echo "Zinit already installed."
fi
