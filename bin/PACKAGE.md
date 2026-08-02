# bin — Helper Scripts

Utility scripts for dotfiles management and system administration.

## Package Details

- **Type**: Scripts
- **Target**: `~/.local/bin`
- **Dependencies**: Stow, Git, Zsh

## Scripts

- `dotfiles-sync` — Sync dotfiles to git
- `display-arrange` *(macOS)* — Restore the dual-monitor layout: external
  monitor on top, built-in (main) display centered below. Requires
  `displayplacer` (`brew install displayplacer`). Pairs with the AeroSpace
  dual-monitor workspace scheme (1-10 built-in, 11-20 external).

## Install

```bash
stowup bin
```

## Note

Additional scripts exist in package-specific directories:
- `omp/.omp/agent/extensions/` — OMP extensions
- Obsidian vault scripts — Use from obsidian package