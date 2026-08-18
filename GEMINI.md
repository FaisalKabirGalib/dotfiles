# GEMINI.md - Dotfiles Configuration & Context

This repository contains personal dotfiles managed with **GNU Stow**. It is optimized for an **Arch Linux** environment running **Hyprland** with a **Catppuccin Mocha** theme.

## Project Overview

- **Management:** [GNU Stow](https://www.gnu.org/software/stow/) is used to symlink configurations from this directory to their respective targets (mostly `~/.config/`).
- **Core Stack:**
  - **OS:** Arch Linux
  - **Window Manager:** Hyprland (`omarchy` package)
  - **Shell:** Zsh (modular configuration)
  - **Terminal:** Ghostty
  - **Editor:** Neovim (LazyVim)
  - **Multiplexer:** Tmux (prefix `C-Space`)
- **Philosophy:**
  - One stow package per application.
  - Each package directory must contain a `PACKAGE.md` for discovery.
  - Composable scripts over monolithic installers.

## Important Constraints (CRITICAL)

- **Symlink Sensitivity:** The `write` tool (and some AI file-writing tools) may silently fail or behave unexpectedly when targeting stow-symlinked files. **Always use shell redirection** (e.g., `cat > file << 'EOF'`) if you encounter issues writing to files that might be symlinked.
- **Git Workflow:** This repo uses a "checkpoint" system that may stash untracked files. **Always `git add` and `git commit` new files immediately** after creation to prevent them from being lost in a stash during automated processes.
- **Hyprland Config:** The active Hyprland config lives in **`omarchy/.config/hypr/`**.
- **Stow Ignores:** Refer to `.stow-local-ignore` and `.gitignore` to identify files that should not be symlinked or committed (e.g., machine-specific secrets).

## Building and Running

### Full Installation
```bash
./install.sh  # Bootstraps the entire system (pacman, AUR, stow, shell, nvim)
```

### Package Management
```bash
./stowup <package>    # Symlink a specific package
./stowup              # Symlink ALL packages with a PACKAGE.md
./stowDown <package>  # Remove symlinks for a specific package
./stowDown            # Remove ALL symlinks
```

### Script Directory
- `scripts/install-packages.sh`: Installs system packages from `packages.txt`.
- `scripts/install-aur.sh`: Installs AUR packages from `aur-packages.txt`.
- `scripts/setup-neovim.sh`: Bootstraps Lazy.nvim.
- `scripts/setup-shell.sh`: Configures Zsh and zinit.

## Agent & Specialized Packages

### Oh-My-Pi (`omp/`)
- **Core:** Oh-My-Pi configuration in `~/.omp/agent/`.
- **Extensions and skills:** Stored under `.omp/agent/`.

### Claude Code (`claude-code/`)
- **Custom Commands:** Markdown-based commands in `.claude/commands/`.
- **MCP Config:** Integrated with Model Context Protocol servers.

### Opencode (`opencode/`)
- **MCP Servers:** Configured in `opencode.json` (e.g., `context7`, `zai-mcp-server`).
- **Environment:** API keys are loaded via `mcp-env.sh` (not committed).

### Obsidian (`obsidian/`)
- **Templates:** Shared `.obsidian` configurations for different vault types (personal, work, public).
- **Scripts:** `obsidian-vault-init`, `obsidian-sync-config`, and `obsidian-backup` for lifecycle management.

## Development Conventions

- **Theming:** Follow the **Catppuccin Mocha** palette for all UI changes.
- **Keybindings:** Prioritize **Vim-style** bindings (`h/j/k/l`, etc.) across all tool configurations.
- **Structure:** To add a new config:
  1. Create a directory (e.g., `myapp`).
  2. Replicate the home directory structure (e.g., `myapp/.config/myapp/`).
  3. Add a `PACKAGE.md` description.
  4. Run `./stowup myapp`.

## Key Files & Directories

- `stowup`: The primary script for applying configurations.
- `MEMORY.md`: Local "gotchas" and personal reminders.
- `bin/`: Custom CLI tools and scripts (linked to `~/.local/bin/`).
- `omarchy/`: Active Hyprland and Quickshell configuration.
- `nvim/`: Extensive Neovim IDE configuration (LazyVim).
- `zsh/`: Modular shell configuration using Zinit.
