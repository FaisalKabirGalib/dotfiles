# herdr

Persistent, agent-aware terminal workspace manager with tmux-compatible bindings.

## Install

```bash
brew install herdr
./stowup herdr bin
just herdr
```

`just herdr` (`scripts/setup-herdr.sh`) restores plugins and agent integrations
(`omp claude opencode antigravity-cli`) idempotently. Plugins are
declared in `~/.config/herdr/plugins.list` (stowed from
`herdr/.config/herdr/plugins.list`), not in the script — add a line there,
then run `just herdr`.

Install Herdr's global agent skill with
`npx skills add herdrdev/herdr --skill herdr --global --yes`. Verify it with
`npx skills list -g`.

The `hp` project picker requires `fd`, `fzf`, and `jq`.

macOS has no global launcher binding for Herdr; run `hp` from any terminal, or
bind it in Raycast / the terminal if wanted.

## Workflow

`hp [path]` creates or focuses a project workspace and attaches Herdr when run
outside it. Herdr workspaces correspond to tmux sessions; tabs correspond to
tmux windows; panes are the real terminals where shells, editors, and agents
run. Agent integrations report when an agent is working, blocked, or done, and
allow supported conversations to resume after a server restart.

Git worktrees created from Herdr are stored in `~/Dev/herdr-worktrees`.

- `C-Space Shift+1..9`: select workspace
- `C-Space 1..9`: select tab
- `C-Space n`, `Alt-Left`, `Alt-Right`: navigate tabs
- `Alt-Up`, `Alt-Down`: navigate workspaces
- `Ctrl-h/j/k/l`: navigate Neovim splits and Herdr panes
- `C-Space o`, `C-Space Shift+o`: cycle panes
- `C-Space b`: toggle the left sidebar
