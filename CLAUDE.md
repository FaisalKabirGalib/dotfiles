# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for **Arch Linux + Hyprland**, managed with **GNU Stow**. Each top-level directory is a "package" whose internal layout mirrors the home directory; stowing it symlinks the files into place. See `README.md` for the package/target table.

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

`bin/dotfiles-sync [packages...]` is a convenience restow (`stow -R`); with no args it restows `nvim opencode`.

**`.stow-local-ignore` gotcha:** when a package has a `.stow-local-ignore`, it *replaces* Stow's built-in default ignore list (which normally skips `.git`, `.gitignore`, etc.). Every package's ignore file must therefore explicitly list `\.git`, `\.gitignore`, `PACKAGE\.md`, `README\.md`, `LICENSE`, `\.stow-local-ignore` — otherwise Stow will try to symlink those repo-internal files into `$HOME`.

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

## Toolchain: mise Owns Runtimes, pacman Owns the System

**Never add a language runtime or dev CLI to `scripts/packages.txt`.** They belong
in `mise/.config/mise/config.toml` (stow package `mise`, target `~/.config/mise/`).

| Manager | Owns |
|---------|------|
| `mise` | node, bun, python, go, rust, java, ruby, flutter (Dart comes bundled with it); dev CLIs — `uv`, `just`, `shellcheck`, `shfmt`, `gitleaks`, `terraform`, `awscli`, `sqlc`, `hugo`, `lazygit`, `lazydocker`, `tree-sitter`, `pnpm`, `npm:typescript`, `npm:ts-node`, `npm:wscat`; all AI coding agents |
| `pacman` | desktop, system libraries, and everyday CLI utilities Arch patches for security (`rg`, `fd`, `bat`, `eza`, `fzf`, `zoxide`, `starship`, `delta`, `nvim`, `tmux`, `docker`), plus `mise` and `stow` themselves |

Not in the mise registry, so they stay on pacman: `stow`, `composer`, `luarocks`,
`cursor-cli`. `deno` also stays — it is a hard dependency of `yt-dlp-ejs`.

**Precedence is the subtle part.** Omarchy *appends* `~/.local/share/mise/shims`
to `PATH` (`/usr/share/omarchy/default/bash/env-bootstrap`), which leaves
`/usr/bin` shadowing every mise runtime. `zsh/.config/zsh/80-mise.zsh` runs
`mise activate zsh`, which *prepends*. It is numbered `80` deliberately: it must
load after every `export PATH="...:$PATH"` in the earlier zsh modules.

AI agents are **not** installed directly. Omarchy's `omarchy-mise-install <pkg>
[cmd] [bin]` writes a self-updating wrapper into `~/.local/bin` that runs
`mise use -g <pkg>` on each invocation. Since `~/.config/mise/config.toml` is a
symlink into this repo, those writes land in the git tree — every wrapper-managed
tool is pinned `"latest"` there so the write stays content-neutral. `scripts/setup-mise.sh`
recreates the wrappers and no-ops off Omarchy.

Global npm packages (pi extensions, MCP servers) live in mise's node install
prefix and are **wiped when the pinned node version changes** — reinstall them
with `mise x node -- npm install -g ...` after a major node bump.

## Installation Flow

`./install.sh` is the orchestrator and calls, in order, the scripts in `scripts/`:

1. `install-packages.sh` — pacman packages listed in `scripts/packages.txt`
2. `install-aur.sh` — AUR packages in `scripts/aur-packages.txt` (skipped if no `yay`/`paru`)
3. `stow-all.sh` — stows all `PACKAGE.md` packages (same loop as `stowup`)
4. `setup-mise.sh` — `mise install` + coding-agent wrappers. **Must run after `stow-all.sh`**: it reads the stowed `~/.config/mise/config.toml`.
5. `setup-shell.sh` — zsh + zinit
6. `setup-neovim.sh` — Lazy.nvim bootstrap

When adding a new **system** dependency, add it to `scripts/packages.txt` or `scripts/aur-packages.txt` (one per line, `#` comments allowed) rather than hardcoding installs elsewhere. For a **runtime or dev CLI**, run `mise use -g <tool>` instead — it writes through the symlink into `mise/.config/mise/config.toml`.

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

## Desktop / Window Manager (Hyprland)

The **current** Hyprland config lives in `omarchy/.config/hypr/` (target `~/.config/hypr/`), alongside `omarchy/.config/omarchy/`. `omarchy/` also ships a Plymouth boot-splash theme under `usr/share/plymouth/`.

**Hyprland is configured in Lua, not `.conf`.** Since the Omarchy 4 ("Quattro") upgrade, `hyprctl systeminfo` reports `configProvider: lua` and Hyprland reads only `hyprland.lua` and the modules it requires (`monitors.lua`, `input.lua`, `bindings.lua`, `looknfeel.lua`, `autostart.lua`). Any `.conf` file placed here is silently ignored. Two consequences worth remembering:

- `hyprctl keyword ...` no longer works ("keyword can't work with non-legacy parsers"). Scripts that reconfigure Hyprland at runtime must be rewritten against the Lua API (`hl.config`, `hl.animation`, `hl.workspace_rule`, `hl.on(...)`).
- `hypridle.conf`, `hyprlock.conf` and `hyprsunset.conf` stay `.conf` — they are read by separate processes, not by Hyprland.

The Lua API is stubbed at `/usr/share/hypr/stubs/hl.meta.lua`, and Omarchy's helpers (`o.bind`, `o.window`, `o.launch_on_start`) at `/usr/share/omarchy/default/hypr/helpers.lua`. Read both before editing.

The status bar, launcher and notifications are Omarchy 4's own Quickshell shell, configured via `~/.config/omarchy/shell.json` — waybar, walker and swaync are no longer used here.

When editing Hyprland, terminal, theme, or other desktop/compositor config under `~/.config/`, **use the `omarchy` skill** — it is the required path for end-user desktop customization.

## AI Agent Packages

This repo manages config for several coding agents, each its own stow package:

| Package | Target | Agent |
|---------|--------|-------|
| `claude-code` | `~/.claude/` | Claude Code (commands, hooks, `settings.json`) |
| `pi` | `~/.omp/agent/` | oh-my-pi (`omp`) — extensions, prompts, skills, `AGENTS.md` |
| `gemini` | `~/.gemini/` | Gemini CLI — agents, policies, commands, skills, `AGENTS.md` |
| `agy` | `~/.gemini/antigravity-cli/` | Antigravity CLI — **symlinks its agents from the `gemini` package** to avoid duplication |
| `pi.old` | `~/.pi/` | Deprecated previous pi config, kept for reference |

`opencode/` is a separate CLI; its MCP API keys load from `opencode/mcp-env.sh` (private, not committed) via the `opencode` zsh function.

## Other Notable Packages

- `nvim/` — LazyVim-based Neovim. Plugins in `lua/plugins/`, pinned via `lazy-lock.json`. Multi-language: TS, Go, Dart/Flutter, Python, Lua.
- `zsh/` — Zinit plugin manager, Powerlevel10k (`p10k/`), FZF (`Ctrl+R`/`Ctrl+T`), Zoxide.
- `tmux/` — prefix `C-a`.
- `obsidian/` — shared `.obsidian` config templates + vault lifecycle scripts in `bin/` (`obsidian-vault-init`, `obsidian-sync-config`, `obsidian-backup`). Notes live in separate repos; only config is tracked here.
