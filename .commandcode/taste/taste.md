# Taste (Continuously Learned by [CommandCode][cmd])

[cmd]: https://commandcode.ai/

# dotfiles
- Keep git hygiene clean: gitignore caches, binaries/blobs, ssh keys, and data caches so nothing unintended gets tracked. Confidence: 0.80
- Use JetBrainsMono Nerd Font across terminal/dotfiles configs (ghostty, sketchybar, wezterm). Confidence: 0.75
- Use Catppuccin Mocha color scheme throughout dotfiles configs. Confidence: 0.60
- Use GNU Stow for dotfiles packages (with .stow-local-ignore listing PACKAGE.md, .git, etc.). Confidence: 0.65
- Prefer keeping configs modular/version-controlled rather than fragile inline blobs. Confidence: 0.60

# aerospace
- Use this keybinding scheme: cmd-hjkl = focus between windows, ctrl-hjkl = pane/split navigation, ctrl-1..0 = switch workspace, ctrl+shift+1..0 = move window to workspace, all other window ops (toggle float, fullscreen, etc.) use cmd key. Confidence: 0.75
- Use control as the mod key instead of alt/option in aerospace config. Confidence: 0.65

# homebrew
- Keep typescript installed globally via Homebrew — a global tsc is needed; do not remove it during cleanup or move it into mise/bun. Confidence: 0.90

# workflow
- Prefers the agent act directly (install/uninstall/run immediately) rather than modifying scripts/config files like install.sh when offered the choice. Confidence: 0.75
- Tends to communicate bug/fix requests tersely and imperatively (e.g. "check ... fix it") without elaborate context. Confidence: 0.55
- Delegates judgment calls to the agent — trusts it to decide what's redundant/unnecessary and clean it up autonomously. Confidence: 0.70
- Prefers a lean, consolidated toolset: approved removing duplicate/redundant apps (extra terminals, browsers, editors, overlapping CLI tools, and unused plugin snippets). Confidence: 0.72
