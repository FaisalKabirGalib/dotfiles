# herdr

Persistent terminal workspace manager configured with tmux-compatible bindings.

## Install

```bash
./stowup herdr bin
just herdr
```

`just herdr` (`scripts/setup-herdr.sh`) restores plugins and agent integrations
(`omp claude codex opencode antigravity-cli`) idempotently. Plugins are
declared in `~/.config/herdr/plugins.list` (stowed from
`herdr/.config/herdr/plugins.list`), not in the script — add a line there,
then run `just herdr`.

The `hp` project picker requires `fd`, `fzf`, and `jq`.

The Codex integration enables hooks in its machine-local `~/.codex/config.toml`.
Launch Herdr with `SUPER+CTRL+ENTER`.

## Workflow

`hp [path]` creates or focuses a project workspace and attaches Herdr when run
outside it. Herdr workspaces correspond to tmux sessions; tabs correspond to
tmux windows.

- `C-Space Shift+1..9`: select workspace
- `C-Space 1..9`: select tab
- `C-Space n`, `Alt-Left`, `Alt-Right`: navigate tabs
- `Alt-Up`, `Alt-Down`: navigate workspaces
- `Ctrl-h/j/k/l`: navigate Neovim splits and Herdr panes
- `C-Space o`, `C-Space Shift+o`: cycle panes
- `C-Space b`: toggle the left sidebar
