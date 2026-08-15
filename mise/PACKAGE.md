# mise — Toolchain Manager

Single source of truth for language runtimes and developer CLIs. Replaces nvm,
SDKMAN, standalone Bun/Flutter installs, and the pacman copies of dev tooling.

## Package Details

- **Type**: Runtime / tool version manager
- **Target**: `~/.config/mise/`
- **Dependencies**: `mise` (pacman; also shipped in Omarchy's base package set)

## Install

```bash
stowup mise
mise install        # or: just tools
```

`~/.config/mise/config.toml` pre-dates this package on existing machines, so the
first stow needs `stow --adopt -t ~ mise` (review `git diff` afterwards).

## Key Features

- `config.toml` is the tracked global tool list — `mise install` reproduces the
  entire toolchain on a fresh machine.
- Activated from `zsh/.config/zsh/80-mise.zsh` with `mise activate zsh`, which
  **prepends** its tool dirs. Omarchy only *appends* `~/.local/share/mise/shims`
  (`/usr/share/omarchy/default/bash/env-bootstrap`), so without this activation
  `/usr/bin` would shadow every mise-managed runtime.
- AI coding agents are installed as auto-updating wrappers in `~/.local/bin` by
  Omarchy's `omarchy-mise-install`. Those wrappers run `mise use -g <pkg>` on
  every invocation; pinning the same tools as `"latest"` here keeps that write
  content-neutral so it never dirties the git tree.

## Ownership Split

| Manager | Owns |
|---------|------|
| `mise` | language runtimes, dev CLIs, coding agents |
| `pacman` | desktop, system libraries, everyday CLI utilities (`rg`, `fd`, `bat`, `eza`, `fzf`, `zoxide`, `starship`, `delta`, `nvim`, `tmux`, `docker`) |

Not available in the mise registry, so they stay on pacman: `stow`, `composer`,
`luarocks`. `deno` also stays — it is a hard dependency of `yt-dlp-ejs`.
