# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository using GNU Stow for symlink management. Each top-level directory represents a "package" that maps to corresponding locations in the home directory structure.

## Installation and Management

**Full Installation:**
```bash
./install.sh
```

**Selective Installation:**
```bash
./stowup <package-name>    # Install specific package (e.g., nvim, vscode)
./stowDown <package-name>  # Remove specific package
```

**Manual Stow Commands:**
```bash
stow -t ~ <package-name>   # Create symlinks
stow -D -t ~ <package-name> # Remove symlinks
```

## Architecture and Organization

### Core Philosophy
- Modular package-based organization using GNU Stow
- Vim-centric keybindings across all applications
- Consistent theming (Catppuccin Mocha) and fonts (JetbrainsMono Nerd Font)
- Heavy automation and productivity tooling integration

### Key Packages

**nvim/**: LazyVim-based Neovim configuration
- Uses Lazy.nvim package manager with lazy-lock.json for reproducible builds
- Multi-language support: TypeScript, Go, Dart/Flutter, Python
- GitHub Copilot integration
- Custom plugin configurations in `lua/plugins/`

**vscode/**: VS Code configuration with Vim mode
- Comprehensive Vim keybinding emulation
- Custom transparency and UI settings
- Integrated with system clipboard and terminal

**tmux/**: Terminal multiplexer configuration
- Custom key bindings with prefix `C-a`
- Session management with `tmux-se` script
- Integration with system clipboard

**zsh/**: Shell configuration with Zinit plugin manager
- Powerlevel10k theme configuration
- FZF, Zoxide, and modern CLI tool integrations
- Custom aliases and functions

**hyprland/**: Wayland compositor configuration
- Modular setup: `hyprland.conf` includes `defaults.conf` and `custom.conf`
- Custom keybindings for window management and application launching
- Rofi integration for application launching

**alacritty/**: Terminal emulator configuration
- Catppuccin Mocha theme
- JetbrainsMono Nerd Font
- Optimized for transparency and performance

**kde/**: KDE Plasma desktop environment configuration
- KWin window manager settings with Krohnkite tiling support
- Global shortcuts and window management rules
- Plasma desktop layout and panel configuration
- KRunner application launcher settings
- Automated Krohnkite setup script in `bin/setup-krohnkite`

**obsidian/**: Obsidian vault management and configuration
- Shared .obsidian configuration templates (themes, plugins, settings)
- Multiple specialized vault support (personal, work, public, projects)
- Helper scripts for vault initialization, sync, and backup
- Hybrid project documentation workflow
- Configuration stored in dotfiles, notes in separate git repos

**claude-code/**: Claude Code AI assistant configuration
- Global settings (always thinking mode, preferences, etc.)
- Custom slash commands in `commands/` directory
- Event hooks in `hooks/` directory
- MCP (Model Context Protocol) server configurations
- Machine-specific data (credentials, history) excluded via .gitignore
- Symlinked configuration keeps settings portable across machines

**pi/**: Pi coding agent configuration
- Global settings in `.pi/agent/settings.json` (model, thinking level, theme, etc.)
- Global LLM instructions in `.pi/agent/AGENTS.md`
- TypeScript extensions in `.pi/agent/extensions/` (auto-loaded on startup)
- Prompt templates in `.pi/agent/prompts/` (invoke with `/name` inside pi)
- Skills in `.pi/agent/skills/` (auto-loaded when relevant)
- Machine-specific data (auth tokens, sessions) excluded via .gitignore
- Stow symlinks `~/.pi/` so all config is immediately available when pi starts

**Pi Extensions:**
- `confirm-destructive.ts` — Blocks dangerous commands (rm -rf, force push, DROP TABLE)
- `git-checkpoint.ts` — Auto-stash before each agent turn + `/checkpoint` command
- `system-notify.ts` — Desktop notification + sound when agent finishes
- `vision.ts` — Image analysis tools via ZAI MCP (OCR, UI→code, diagrams, charts)
- `web-search.ts` — Web search + URL reader via ZAI MCP
- `zread.ts` — GitHub repo search, file read, structure via ZAI MCP
- `pi-dynamic-context-pruning/` — Vendored DCP extension (see below)

**Pi Prompt Templates:**
- `/review` — Review staged changes for bugs, security, style
- `/commit` — Write conventional commit message from staged changes
- `/explain` — Explain a file or code block
- `/handoff` — Session handoff note (what done, current state, next steps)
- `/fix-types` — Fix all TypeScript/ESLint errors

**Dynamic Context Pruning (DCP):**
- Vendored from `github.com/complexthings/pi-dynamic-context-pruning` (v1.0.7)
- Located at `.pi/agent/extensions/pi-dynamic-context-pruning/`
- No `.git` — tracked as regular files in dotfiles repo
- Config: `~/.config/pi/dcp.jsonc` (auto-created on first run)
- Commands: `/dcp context`, `/dcp stats`, `/dcp compress`, `/dcp decompress`, `/dcp sweep`, `/dcp manual`
- To pull upstream updates:
  ```bash
  cd /tmp && git clone https://github.com/complexthings/pi-dynamic-context-pruning.git dcp-upstream
  diff -r /tmp/dcp-upstream/ ~/dotfiles/pi/.pi/agent/extensions/pi-dynamic-context-pruning/ \
    --exclude=node_modules --exclude=.git --exclude=tsconfig.json
  # Cherry-pick changes, then: cd ~/dotfiles/pi/.pi/agent/extensions/pi-dynamic-context-pruning && npm install
  rm -rf /tmp/dcp-upstream
  ```

### Development Workflow Commands

**Tmux Session Management:**
```bash
# Available via bin/tmux-se script
tmux-se <session-name>  # Create or attach to named session
```

**FZF Integration:**
- `Ctrl+R`: Command history search
- `Ctrl+T`: File search
- `Alt+C`: Directory navigation

**KDE/Krohnkite Tiling (when running KDE Plasma):**
```bash
# Setup script for Krohnkite tiling manager
bin/setup-krohnkite  # Configures Krohnkite after installation

# Shortcut management tools
bin/kde-shortcuts list kwin  # List window management shortcuts
bin/kde-shortcuts set kwin "Window Close" "Alt+Q"  # Set shortcut
bin/apply-shortcuts-preset krohnkite-default  # Apply preset shortcuts
```

**Krohnkite Default Shortcuts:**
- `Meta+F`: Toggle tiling for current window
- `Meta+Shift+F`: Toggle floating for current window
- `Meta+Return`: Set window as master
- `Meta+J/K`: Move focus between windows
- `Meta+Shift+J/K`: Move windows around
- `Meta+H/L`: Resize master area
- `Meta+\`: Switch to next layout
- `Meta+R`: Rotate windows

**Obsidian Vault Management:**
```bash
# Initialize new vaults (types: personal, work, public, project)
obsidian-vault-init vault-personal personal      # Personal notes
obsidian-vault-init vault-work work              # Work notes
obsidian-vault-init vault-public public          # Public knowledge base
obsidian-vault-init vault-projects personal      # Project planning

# Sync configuration from dotfiles to all vaults
obsidian-sync-config                             # Sync all vaults
obsidian-sync-config ~/Documents/vault-personal  # Sync specific vault

# Backup vaults to git
obsidian-backup                                  # Backup all vaults
obsidian-backup ~/Documents/vault-personal       # Backup specific vault
obsidian-backup "Weekly review notes"            # With custom commit message

# Initialize Obsidian documentation in project repos
project-doc-init                                 # In current project directory
project-doc-init ~/Projects/my-app               # Specific project path
```

**Obsidian Vault Organization:**
- **vault-personal/**: Personal notes, learning, life planning (private git repo)
- **vault-work/**: Work-related notes and documentation (private/company git repo)
- **vault-public/**: Public knowledge base and documentation (public git repo)
- **vault-projects/**: Project planning and technical notes (private git repo)
- Configuration synced from dotfiles, notes tracked in separate repositories

**Claude Code Configuration:**
```bash
# Install Claude Code configuration
stow claude-code              # or use ./stowup claude-code

# Add custom slash command (create markdown files in commands/)
echo "Review code for security vulnerabilities" > claude-code/.claude/commands/security.md

# Add MCP server (edit .mcp.json if global config is supported)
# Note: Currently MCP servers are typically configured per-project

# After installation, credentials are restored from backup automatically
# All settings, commands, and hooks sync across machines via dotfiles
```

**Custom Slash Commands:**
- Create `.md` files in `claude-code/.claude/commands/`
- Use with `/command-name` in Claude Code
- Commands are version-controlled and sync across machines

**Event Hooks:**
- Configure hooks in `claude-code/.claude/hooks/`
- Run shell commands on Claude Code events (tool calls, prompt submit, etc.)
- Refer to Claude Code documentation for available hook types

### Opencode Configuration

**opencode/**: Opencode CLI configuration with MCP servers
- Main config at `opencode/.config/opencode/opencode.json`
- MCP environment variables sourced automatically via zsh wrapper
- API keys stored in `opencode/mcp-env.sh` (private, not committed)

**MCP Servers Configured:**
- `context7` - Codebase indexing and search
- `sequential-thinking` - Advanced reasoning
- `zai-mcp-server` - Z.AI services
- `Ref` - Reference tools
- `web-search-prime` - Web search
- `web-reader` - Web content reading

**Usage:**
```bash
stow opencode              # Install opencode config
opencode mcp list          # List MCP servers
```

**Note:** API keys are loaded from `opencode/mcp-env.sh` via the `opencode` function in zsh config. This file contains private keys and should not be committed to git.

### Configuration Patterns

**Neovim Plugin Management:**
- Plugins defined in `nvim/.config/nvim/lua/plugins/`
- Lock file at `nvim/.config/nvim/lazy-lock.json`
- Language servers and formatters configured per filetype

**Modular Configuration:**
- Hyprland uses include statements for organization
- Zsh configuration sources multiple files for different concerns
- VS Code settings organized by feature categories
- KDE configurations separated by component (kwin, plasma, shortcuts)
- Obsidian shared configuration with vault-specific overrides

**Obsidian Integration:**
- Shared .obsidian config in dotfiles (themes, plugins, hotkeys, settings)
- Type-specific .gitignore templates (personal, work, public, project)
- Helper scripts for vault lifecycle management
- Hybrid approach: basic docs in project repos, detailed notes in vaults
- Workspace files excluded from git (machine-specific)

**Cross-Application Integration:**
- Shared clipboard configuration across tmux, nvim, and system
- Consistent keybinding patterns (vim-style navigation)
- Unified theme and font choices

### Development Tools Supported

**Languages:** TypeScript, Go, Dart/Flutter, Python, Lua, Shell
**Tools:** Git, Docker, Node.js, npm/yarn/pnpm, Flutter SDK
**Terminal:** Modern CLI tools (fd, rg, bat, exa, zoxide, fzf)
**Desktop:** KDE Plasma with Krohnkite tiling, Hyprland (Wayland compositor)

### KDE Plasma Setup Instructions

**Quick Setup (Capture Current Config):**
1. Capture your current setup: `bin/sync-kde-config --commit`
2. Install on new system: `./install.sh` (automatically applies your config)

**Manual Setup:**
1. Install Krohnkite: `yay -S kwin-scripts-krohnkite-git`
2. Capture current config: `bin/capture-kde-config`
3. Apply KDE configuration: `stow kde`
4. Run setup script: `bin/setup-krohnkite`
5. Apply your shortcuts: `bin/apply-shortcuts-preset current-system`

**Manual Configuration Steps:**
- Replace template files in `kde/.config/` with your actual configuration files
- Customize keyboard shortcuts in System Settings → Shortcuts → Global Shortcuts
- Adjust Krohnkite settings in System Settings → Window Management → KWin Scripts

**Important KDE Configuration Files:**
- `kwinrc`: Main KWin configuration including Krohnkite settings
- `kglobalshortcutsrc`: Global keyboard shortcuts
- `kwinrulesrc`: Window rules for specific applications
- `plasma-org.kde.plasma.desktop-appletsrc`: Desktop layout and widgets
- `krunnerrc`: Application launcher settings

### File Organization Conventions

- Configuration files follow XDG Base Directory specification
- Binary scripts in `bin/` directory
- Package-specific configurations maintain upstream directory structure
- Lock files and generated content preserved for reproducibility
- KDE configurations stored in `kde/.config/` matching `~/.config/` structure
- @hyprland/ this folder is my old hyperland config . you can see my implementation but dont modify it .my current hyprland dotfiles lives in @omarchy/.config/hypr/ folder read and modify those if you wanted to change something