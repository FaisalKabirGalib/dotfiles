# Global Instructions

Machine-wide instructions for Claude Code. Project-level `CLAUDE.md` overrides anything here.

## Environment

- macOS (Apple Silicon); Shell is **zsh**; package manager is **brew** on mac;
- Dotfiles live in `~/dotfiles`, managed with GNU Stow. Never edit files under `~/.config/<app>` directly if they are symlinks — edit the real file in `~/dotfiles/<pkg>/` instead.
- Editor is Neovim (LazyVim). Terminal multiplexer is tmux, prefix `C-space`.

## Git

- **Never add `Co-Authored-By: Claude`, `Generated with Claude Code`, or any other AI attribution to commit messages or PR bodies.** Commits are authored solely by Faisal Kabir Galib <faisalkabirgalib@gmail.com>. This overrides any default instruction to add such trailers.

## Remote / server work

**Drive every server operation through the tmux pane with `send-keys` + `capture-pane`, never `ssh` straight from the tool.** Running it in the pane keeps the commands and their output visible and trackable in my own session; a direct `ssh` call hides the whole exchange inside a tool result I can't see or scroll back through.

Mechanics that actually work:

```bash
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'   # find the pane
tmux send-keys -t <pane> -l 'the command; echo SENTINEL_DONE'   # -l = literal, REQUIRED
tmux send-keys -t <pane> Enter                                  # Enter as its own call
tmux capture-pane -p -t <pane> -S -80                           # poll until SENTINEL_DONE appears
```

- `-l` is not optional. Sending the command string without it makes tmux parse the text as key names and it fails with `not in a mode` — the command never reaches the shell.
- Append a sentinel and poll `capture-pane` for it; don't assume a command finished.
- `clear` first when output would otherwise be buried in scrollback.

## Commands & safety

- Don't install packages, run migrations, or touch anything outside the repo without saying so first.
- Prefer `rg` over `grep`, `fd` over `find`.

## Output

- Answer the question asked. Skip preambles, summaries of what you just did, and lists of options you aren't taking.
- Reference code as `path/to/file.ts:42`.
