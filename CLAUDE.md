# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles managed with **GNU Stow**. Each top-level directory is a "package" whose internal layout mirrors the home directory; stowing it symlinks the files into place. See `README.md` for the package/target table.

**One branch per machine — check which one you are on before assuming an OS.** This branch (`m2-pro`) and `mac-mini-m2` are **macOS (Apple Silicon)**; `arch` and `omarchy` are Arch Linux + Hyprland; `server` is headless. Packages that exist on one branch often do not exist on another.

## Stow Mechanics (read this before adding or moving config)

- A directory is treated as a stow package **only if it contains a `PACKAGE.md` file**. This marker is what the installer and helper scripts iterate over — a package without it is silently skipped.
- A package's directory structure mirrors its target. `nvim/.config/nvim/...` stows to `~/.config/nvim/...`; `bin/.local/bin/...` to `~/.local/bin/...`; default target is `$HOME`.
- Each package may carry a `.stow-local-ignore` to exclude machine-specific or non-symlinked files from stowing.

**`./stowup [pkg...]` and `./stowDown [pkg...]`**: with no args they loop over *every* `PACKAGE.md` package; with args they act only on the named packages. `stowup` does a `stow -D` then `stow` to restow cleanly. Equivalent raw commands:

```bash
stow -t ~ <package>      # symlink one package
stow -D -t ~ <package>   # remove one package
stow -R -t ~ <package>   # restow (after changing which files exist)
```

`bin/.local/bin/dotfiles-sync [packages...]` (available as `dotfiles-sync` once the `bin` package is stowed, since `~/.local/bin` is on `$PATH`) is a convenience restow (`stow -R`); with no args it restows `nvim opencode`.

**`.stow-local-ignore` gotcha:** when a package has a `.stow-local-ignore`, it *replaces* Stow's built-in default ignore list (which normally skips `.git`, `.gitignore`, etc.). Every package's ignore file must therefore explicitly list `\.git`, `\.gitignore`, `PACKAGE\.md`, `README\.md`, `LICENSE`, `\.stow-local-ignore` — otherwise Stow will try to symlink those repo-internal files into `$HOME`.

## Gotchas

- **Editing through a symlink can fail silently.** Always edit the real file in `~/dotfiles/<pkg>/`, never the stowed path under `~/.config/`. If a write to a symlinked path appears to succeed but the content is unchanged, that's why — redo it against the repo file.
- **Commit new files immediately.** Automated checkpointing runs `git stash --include-untracked`, which swallows uncommitted new files. `git add` + commit as soon as you create one.

## Task Runner & Tooling

A `justfile` is the single entrypoint (`just --list` to discover). Key recipes:

```bash
just                 # list commands
just install         # full setup (= ./install.sh)
just stow [pkg...]   # stow all, or named packages
just unstow [pkg...] # unstow all, or named packages
just doctor          # health check (see below)
just lint / just fmt # shellcheck / shfmt over shell scripts
just secrets         # gitleaks scan of the working tree
just install-hooks   # enable the .githooks pre-commit hook
```

- **`scripts/doctor.sh`** (`just doctor`) reports: packages missing a `PACKAGE.md`, packages whose target is a *real file* instead of a symlink (config drift — resolve with `stow --adopt <pkg>` after reviewing), and broken symlinks. Expect `auth.json`-type secrets to show as real files; that's intentional.
- **`.githooks/pre-commit`** runs `gitleaks` (secret scan of staged changes) and `shellcheck` (staged shell scripts). Enabled via `git config core.hooksPath .githooks`. Each check no-ops gracefully if its tool isn't installed. The tooling (`just`, `shellcheck`, `shfmt`, `gitleaks`, `stow`) is in `scripts/packages.txt`.

## Installation Flow

`./install.sh` is the orchestrator and calls, in order, the scripts in `scripts/`:

1. `install-packages.sh` — pacman packages listed in `scripts/packages.txt`
2. `install-aur.sh` — AUR packages in `scripts/aur-packages.txt` (skipped if no `yay`/`paru`)
3. `stow-all.sh` — stows all `PACKAGE.md` packages (same loop as `stowup`)
4. `setup-shell.sh` — zsh + zinit
5. `setup-neovim.sh` — Lazy.nvim bootstrap

When adding a new system dependency, add it to `scripts/packages.txt` or `scripts/aur-packages.txt` (one per line, `#` comments allowed) rather than hardcoding installs elsewhere.

## Adding a Package

1. `mkdir <pkg>` and recreate the target path inside (e.g. `mkdir -p <pkg>/.config/<pkg>`).
2. Place config files at their mirrored locations.
3. **Create `<pkg>/PACKAGE.md`** — without it the package is invisible to all tooling. Follow the existing format (title, "Package Details" with Type/Target/Dependencies, Install, Key Features).
4. Add a `.stow-local-ignore` if any files shouldn't be symlinked.
5. `stow -t ~ <pkg>`.

## Conventions

- **One package per application.** `PACKAGE.md` in every package is the source of per-package documentation — read it first when working on a package.
- Theme: **Catppuccin Mocha** everywhere. Font: **JetBrainsMono Nerd Font**. **Vim-style keybindings** across all apps.
- Machine-specific/secret files (auth tokens, SSH keys, credentials, agent sessions) are excluded via `.gitignore` and `.stow-local-ignore`.

## Desktop (macOS)

- `aerospace/` — AeroSpace tiling WM (`~/.config/aerospace/`). Monitor/workspace assignments are machine-specific; expect this file to differ between the two Mac branches.
- `sketchybar/` — status bar (`~/.config/sketchybar/`), Lua-configured.
- `raycast/` — launcher settings. Export-only: `.rayconfig` is imported/exported through the GUI, not symlinked.
- `ghostty/`, `wezterm/` — terminals.

The Hyprland/waybar setup and the `omarchy` skill belong to the `arch`/`omarchy` branches and are not present here.

## AI Agent Packages

This repo manages config for several coding agents, each its own stow package:

| Package | Target | Agent |
|---------|--------|-------|
| `claude-code` | `~/.claude/` | Claude Code (commands, hooks, `settings.json`) |
| `omp` | `~/.omp/agent/` | oh-my-pi (`omp`) — extensions, prompts, skills, `AGENTS.md` |
| `agy` | `~/.gemini/antigravity-cli/` | Antigravity CLI — custom agents live directly in `plugins/custom-agents/agents/` |

`opencode/` is a separate CLI; its MCP API keys load from `opencode/mcp-env.sh` (private, not committed) via the `opencode` zsh function.

## Other Notable Packages

- `nvim/` — LazyVim-based Neovim. Plugins in `lua/plugins/`, pinned via `lazy-lock.json`. Multi-language: TS, Go, Dart/Flutter, Python, Lua.
- `zsh/` — Zinit plugin manager, Powerlevel10k (`p10k/`), FZF (`Ctrl+R`/`Ctrl+T`), Zoxide.
- `tmux/` — prefix `C-Space`.
- `obsidian/` — shared `.obsidian` config templates + vault lifecycle scripts in `bin/` (`obsidian-vault-init`, `obsidian-sync-config`, `obsidian-backup`). Notes live in separate repos; only config is tracked here.
