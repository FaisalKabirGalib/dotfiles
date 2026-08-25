#!/usr/bin/env bash
set -euo pipefail

# Restore herdr plugins + agent integrations declared in
# ~/.config/herdr/plugins.list (stowed from herdr/.config/herdr/plugins.list).
# herdr has no config-driven plugin restore of its own (plugin state lives only
# in ~/.config/herdr/plugins.json, written by `herdr plugin install`), so this
# script is the TPM-equivalent: plugins.list is the declared source of truth
# (like tmux.conf's `@plugin` lines), this script is the generic installer
# (like tpm/bin/install_plugins).

if ! command -v herdr &>/dev/null; then
	echo "herdr not found. Install it first (pacman -S herdr); it is in scripts/packages.txt."
	exit 1
fi

PLUGINS_LIST="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/plugins.list"

if [ ! -e "$PLUGINS_LIST" ]; then
	echo "No $PLUGINS_LIST. Run 'stowup herdr' first; skipping plugin installs."
else
	INSTALLED="$(herdr plugin list 2>/dev/null || true)"

	grep -v '^\s*#' "$PLUGINS_LIST" | while IFS=' ' read -r repo ref; do
		[ -n "$repo" ] || continue
		if grep -qF "$repo" <<<"$INSTALLED"; then
			echo "herdr plugin already installed: $repo"
			continue
		fi
		echo "Installing herdr plugin: $repo${ref:+ @ $ref}"
		# shellcheck disable=SC2086  # ref is intentionally word-split into --ref "$ref" when set
		herdr plugin install "$repo" ${ref:+--ref "$ref"} --yes
	done
fi

echo "Restoring agent integrations..."
for integration in omp claude codex opencode antigravity-cli; do
	herdr integration install "$integration"
done

echo "herdr plugins and integrations restored."
