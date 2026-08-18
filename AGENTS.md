# AGENTS.md - Dotfiles Workspace Instructions

This workspace contains personal dotfiles managed with **GNU Stow**. It is optimized for a modular, Vim-centric, and aesthetically consistent Arch Linux environment.

## Project Overview

- **Management:** GNU Stow symlinks configurations from top-level directories to their targets (mostly `~/.config/`).
- **Structure:** One directory per application ("package").
- **Environment:** Arch Linux + Hyprland (`omarchy`) + Catppuccin Mocha.

## Tech Stack

- **Shell:** Zsh (Modular, Zinit manager)
- **Terminal:** Ghostty, Kitty
- **Editor:** Neovim (LazyVim, Lua-based)
- **Multiplexer:** Tmux (prefix `C-Space`)
- **Compositor:** Hyprland (configured via `omarchy`)
- **Automation:** Bash / POSIX Shell scripts

## Core Commands

### Installation & Bootstrapping
- `./install.sh`: Full system bootstrap (packages, stow, shell, nvim).
- `scripts/setup-neovim.sh`: Bootstraps LazyVim.
- `scripts/setup-shell.sh`: Configures Zsh and Zinit.

### Configuration Management (Stow)
- `./stowup`: Symlink ALL packages containing a `PACKAGE.md`.
- `./stowup <package>`: Symlink a specific package.
- `./stowDown`: Remove ALL symlinks.
- `./stowDown <package>`: Remove symlinks for a specific package.

## Development Conventions & Constraints

### 1. Symlink Sensitivity (CRITICAL)
Many files in this workspace are intended to be symlinked. AI tools may fail when writing to symlinks.
- **Guideline:** If a direct write/replace fails, use shell redirection: `cat > path/to/file << 'EOF' ... EOF`.

### 2. Git Workflow
The local environment may use automated checkpointing or stashing.
- **Guideline:** `git add` and `git commit` new files immediately to prevent them from being stashed or lost.

### 3. Modular Architecture
- **Guideline:** To add a new config, create a directory (e.g., `myapp`), replicate the home structure (e.g., `myapp/.config/myapp/`), and include a `PACKAGE.md`.

### 4. Configuration Standards
- **Keybindings:** Always prioritize Vim-style (`h/j/k/l`, `C-u`/`C-d`) in all tool configs.
- **Theming:** Strictly follow the **Catppuccin Mocha** palette.
- **Hyprland:** The active configuration is in **`omarchy/.config/hypr/`**. Ignore the legacy `@hyprland/` directory.

## Specialized Agent Contexts

- **Gemini CLI:** Config in `gemini/.gemini/`. Policies in `gemini/.gemini/policies/`.
- **Antigravity CLI (agy):** Config in `agy/.gemini/antigravity-cli/`. Custom agents in `agy/.gemini/antigravity-cli/plugins/custom-agents/agents/` (symlinked from `gemini/.gemini/agents/`).
- **Pi Agent:** Config and extensions in `pi/.pi/`.
- **Claude Code:** Custom commands in `claude-code/.claude/commands/`.
- **Opencode:** MCP server configuration in `opencode/.config/opencode/`.

## Knowledge Graph

- **Graph:** `.ua/knowledge-graph.json` maps the repository architecture, files, and relationships.
- **Metadata:** `.ua/meta.json` records the commit and analysis time.
- **Refresh:** Run `/understand` after structural changes; preserve `.ua/intermediate/scan-result.json` for incremental updates.
