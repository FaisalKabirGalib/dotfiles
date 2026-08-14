# Dotfiles

Personal dotfiles for Arch Linux + Hyprland. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone https://github.com/galiboo/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Or install individual packages:

```bash
./stowup <package>    # Install one package
./stowDown <package>  # Remove one package
./stowup              # Install all packages
./stowDown            # Remove all packages
```

## Packages

| Package | Target | Description |
|---------|--------|-------------|
| `bin` | `~/.local/bin/` | Custom scripts and CLI tools |
| `boot` | `/boot/` | Bootloader config (limine) |
| `claude-code` | `~/.claude/` | Claude Code agent config |
| `ghostty` | `~/.config/ghostty/` | Ghostty terminal |
| `kitty` | `~/.config/kitty/` | Kitty terminal |
| `nvim` | `~/.config/nvim/` | Neovim (LazyVim) |
| `obsidian` | `~/.obsidian/` | Obsidian vault templates & scripts |
| `omarchy` | `~/.config/hypr/` | Hyprland compositor (Lua config) |
| `opencode` | `~/.config/opencode/` | Opencode CLI config |
| `p10k` | `~/` | Powerlevel10k theme |
| `pi` | `~/.pi/` | Pi coding agent (extensions, skills, prompts) |
| `ssh` | `~/.ssh/` | SSH config (keys excluded) |
| `tmux` | `~/.config/tmux/` | Tmux (prefix C-a) |
| `vscode` | `~/.config/Code/` | VS Code with Vim mode |
| `yazi` | `~/.config/yazi/` | Yazi file manager |
| `zen-browser` | `~/.zen/` | Zen browser config |
| `zsh` | `~/.config/zsh/` | Zsh + zinit + aliases |

## Adding a Package

1. Create a directory: `mkdir myapp`
2. Mirror the target structure: `mkdir -p myapp/.config/myapp`
3. Add config files inside
4. Create `PACKAGE.md` with a description
5. Run `./stowup myapp`

## Scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | Full setup (packages + stow + shell + nvim) |
| `stowup` / `stowDown` | Symlink management |
| `scripts/install-packages.sh` | pacman packages from `scripts/packages.txt` |
| `scripts/install-aur.sh` | AUR packages from `scripts/aur-packages.txt` |
| `scripts/stow-all.sh` | Stow all packages |
| `scripts/setup-shell.sh` | zsh + zinit |
| `scripts/setup-neovim.sh` | Lazy.nvim bootstrap |

## Theme & Fonts

- **Theme**: Catppuccin Mocha (everywhere)
- **Font**: JetBrainsMono Nerd Font
- **Keybindings**: Vim-style across all apps

## Philosophy

- One stow package per application
- `PACKAGE.md` in every package for documentation
- Machine-specific files excluded via `.stow-local-ignore` and `.gitignore`
- Composable scripts over monolithic installers
