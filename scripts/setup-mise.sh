#!/usr/bin/env bash
set -euo pipefail

# Provision the toolchain described by mise/.config/mise/config.toml.
# Must run AFTER stow-all.sh, since it reads the stowed ~/.config/mise/config.toml.

if ! command -v mise &>/dev/null; then
	echo "mise not found. Install it first (pacman -S mise); it is in scripts/packages.txt."
	exit 1
fi

if [ ! -e "$HOME/.config/mise/config.toml" ]; then
	echo "No ~/.config/mise/config.toml. Run 'stowup mise' first."
	exit 1
fi

echo "Installing runtimes and dev CLIs from ~/.config/mise/config.toml..."
mise install

# AI coding agents ship as small auto-updating wrappers in ~/.local/bin, written
# by Omarchy's omarchy-mise-install. They self-install on first run, so this is
# only about creating the wrappers. Skipped entirely off Omarchy.
if command -v omarchy-mise-install &>/dev/null; then
	echo "Creating mise wrappers for coding agents..."
	while read -r spec; do
		[ -n "$spec" ] || continue
		# shellcheck disable=SC2086  # spec is intentionally word-split into args
		omarchy-mise-install $spec
	done <<-'AGENTS'
		claude
		codex
		gemini
		crush
		opencode
		copilot
		pi
		github:can1357/oh-my-pi omp
		npm:@xai-official/grok grok
		npm:@kitlangton/ghui ghui
		npm:playwright playwright
		aqua:modem-dev/hunk hunk
	AGENTS
else
	echo "omarchy-mise-install not found; skipping coding-agent wrappers."
fi

echo "Toolchain ready. Run 'mise ls' to review."
