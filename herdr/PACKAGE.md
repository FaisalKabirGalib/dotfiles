# herdr

Persistent terminal workspace manager configured with tmux-compatible bindings.

## Install

```bash
./stowup herdr bin
herdr plugin install lmilojevicc/herdr-splits.nvim \
  --ref 94f30cf4e9ac76ddf185a3acd0977be728fa4106 --yes
scripts/setup-herdr-navigator.sh

for integration in omp claude codex opencode antigravity-cli; do
  herdr integration install "$integration"
done
```

The `hp` project picker requires `fd`, `fzf`, and `jq`. Navigator optionally
uses Zoxide; its pinned local extension requires Git, Cargo, and `jq` to build.

The Codex integration enables hooks in its machine-local `~/.codex/config.toml`.
Launch Herdr with `SUPER+CTRL+ENTER`.

## Workflow

`hp [path]` creates or focuses a project workspace and attaches Herdr when run
outside it. Herdr workspaces correspond to tmux sessions; tabs correspond to
tmux windows.

- `C-Space s`: workspace, tab, pane, agent, session, Zoxide, and root navigator
- Navigator `j`/`k`, `/`, `Tab`: move, search, and cycle source filters
- Navigator `C-w/t/p/a/l/z/r`: filter workspace/tab/pane/agent/session/Zoxide/root
- Navigator `C-o`: toggle live terminal preview
- Navigator `C-d` or `C-x`: confirm close/delete for the selected entity
- Navigator `y`, `n`, `Esc`: confirm or cancel deletion
- `C-Space Shift+1..9`: select workspace
- `C-Space 1..9`: select tab
- `C-Space n`, `Alt-Left`, `Alt-Right`: navigate tabs
- `Alt-Up`, `Alt-Down`: navigate workspaces
- `Ctrl-h/j/k/l`: navigate Neovim splits and Herdr panes
- `C-Space o`, `C-Space Shift+o`: cycle panes
- `C-Space b`: toggle the left sidebar
