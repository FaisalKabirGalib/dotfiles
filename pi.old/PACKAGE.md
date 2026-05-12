# pi — Pi Coding Agent

Pi coding agent configuration with extensions and skills.

## Package Details

- **Type**: AI Coding Agent
- **Target**: `~/.pi`
- **Dependencies**: Pi CLI

## Install

```bash
stowup pi
```

## Contents

- `settings.json` — Model, thinking level, theme
- `AGENTS.md` — Global instructions
- `extensions/` — TypeScript extensions (auto-loaded)
- `prompts/` — Prompt templates
- `skills/` — Specialized skill guides

## Key Extensions

- `confirm-destructive` — Block dangerous commands
- `git-checkpoint` — Auto-stash before each turn
- `system-notify` — Desktop notifications
- `vision` — Image analysis
- `web-search` — Web search
- `zread` — GitHub repo tools
- `pi-dynamic-context-pruning` — Context management

## Key Prompts

- `/review` — Code review
- `/commit` — Commit message
- `/explain` — Explain code
- `/handoff` — Session handoff
- `/fix-types` — Fix TypeScript errors