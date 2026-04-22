# pi/

Pi coding agent configuration managed via GNU Stow.

## Structure

```
pi/
└── .pi/
    └── agent/
        ├── settings.json        # Global settings (model, theme, thinking level, etc.)
        ├── AGENTS.md            # Global instructions loaded into every session
        ├── extensions/          # TypeScript extensions (auto-loaded)
        │   ├── confirm-destructive.ts   # Confirms dangerous bash commands
        │   ├── protected-paths.ts       # Blocks writes to sensitive files
        │   └── git-checkpoint.ts        # Auto git stash before agent turns
        ├── prompts/             # Prompt templates (invoke with /name)
        │   ├── review.md        # /review  — review staged git changes
        │   ├── commit.md        # /commit  — generate conventional commit message
        │   ├── explain.md       # /explain — explain a file or code block
        │   ├── fix-types.md     # /fix-types — fix all TS/lint errors
        │   └── handoff.md       # /handoff — write a session summary
        ├── skills/              # Agent skills (auto-loaded based on task)
        └── themes/              # Custom themes
```

## What's NOT committed

- `auth.json` — OAuth tokens and API keys (machine-specific)
- `sessions/` — Session history (machine-specific)
- `git/`, `npm/` — Packages installed via `pi install` (reinstall on new machine)

## Install

```bash
cd ~/dotfiles
stow pi
```

This symlinks `pi/.pi/` → `~/.pi/`, making all config available immediately when pi starts.

## First-time setup on a new machine

```bash
# 1. Install pi
npm install -g @mariozechner/pi-coding-agent

# 2. Stow this package
cd ~/dotfiles && stow pi

# 3. Authenticate (credentials stored in ~/.pi/agent/auth.json — NOT synced)
pi
/login   # Select your provider inside pi

# 4. Reinstall any pi packages you had previously
pi install npm:@foo/pi-tools
```

## Adding extensions

Drop a `.ts` file in `pi/.pi/agent/extensions/` — it will be auto-loaded next time pi starts (or `/reload` inside pi).

## Adding prompt templates

Drop a `.md` file in `pi/.pi/agent/prompts/` — invoke with `/filename` (without `.md`) inside pi.

## Adding skills

Create a directory in `pi/.pi/agent/skills/<skill-name>/` with a `SKILL.md` file.
