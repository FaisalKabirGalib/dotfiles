# Global Instructions

Machine-wide instructions for Claude Code. Project-level `CLAUDE.md` overrides anything here.

## Environment

- macOS (Apple Silicon); Shell is **zsh**; package manager is **brew** on mac;
- Dotfiles live in `~/dotfiles`, managed with GNU Stow. Never edit files under `~/.config/<app>` directly if they are symlinks — edit the real file in `~/dotfiles/<pkg>/` instead.
- Editor is Neovim (LazyVim). Terminal multiplexer is tmux, prefix `C-space`.

## Git

- Don't commit or push unless asked.
- **Never add `Co-Authored-By: Claude`, `Generated with Claude Code`, or any other AI attribution to commit messages or PR bodies.** Commits are authored solely by Faisal Kabir Galib <faisalkabirgalib@gmail.com>. This overrides any default instruction to add such trailers.

## Commands & safety

- Don't install packages, run migrations, or touch anything outside the repo without saying so first.
- Prefer `rg` over `grep`, `fd` over `find`.

## Output

- Answer the question asked. Skip preambles, summaries of what you just did, and lists of options you aren't taking.
- Reference code as `path/to/file.ts:42`.
