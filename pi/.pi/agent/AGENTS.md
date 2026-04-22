# Pi Coding Agent - Global Instructions

## About Me
I'm a developer working primarily with TypeScript, Go, Dart/Flutter, Python, and Lua.
My system runs Arch Linux with Hyprland (Wayland) or KDE Plasma as desktop environment.
I use Neovim (LazyVim) as my primary editor, tmux for terminal multiplexing, and zsh as my shell.

## Environment
- **Shell**: zsh with Zinit, Powerlevel10k, fzf, zoxide
- **Editor**: Neovim (LazyVim) — prefer nvim for quick edits
- **Terminal multiplexer**: tmux (prefix: C-a)
- **Package manager**: pacman + yay (AUR)
- **Node**: use system node via npm
- **Version control**: git

## Code Style Preferences
- TypeScript: strict mode, prefer `const`, named exports, no default exports unless idiomatic
- Go: follow standard Go conventions, use `errors.New` / `fmt.Errorf` with `%w`
- Dart/Flutter: use Riverpod for state, follow Flutter best practices
- Python: use type hints, prefer `pathlib` over `os.path`
- Shell: prefer bash, use `set -e`, quote variables

## Workflow Preferences
- Always explain what you're about to do before making large changes
- Prefer small, focused commits — don't batch unrelated changes
- When editing config files, preserve existing style and comments
- Use ripgrep (`rg`) over grep, `fd` over find when available
- For Neovim plugins: edit files in `~/.config/nvim/lua/plugins/`

## Project Conventions
- Dotfiles managed with GNU Stow — each top-level dir is a stow package
- Config follows XDG Base Directory spec where possible
- Sensitive files (API keys, auth tokens) are never committed — check .gitignore

## Things to Avoid
- Don't run `sudo` without asking first
- Don't delete files without confirmation
- Don't modify `.env` files or `auth.json` files
- Don't commit `node_modules/`, build artifacts, or cache directories
