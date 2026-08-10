# claude-code — Claude Code AI Assistant

Machine-wide Claude Code configuration: global instructions, slash commands, skills, and settings.

## Package Details

- **Type**: AI Assistant Config
- **Target**: `~/.claude`
- **Dependencies**: Claude Code CLI

## Install

```bash
stowup claude-code
```

## Contents

- `CLAUDE.md` — global instructions loaded in every project on this machine. Project-level `CLAUDE.md` overrides it.
- `settings.json` — model, permissions allowlist, Stop-notification hook, statusline, enabled plugins and marketplaces.
- `statusline.sh` — custom statusline command.
- `commands/` — custom slash commands: `/create-prd`, `/todo`, `/plannotator-annotate`, `/plannotator-last`, `/plannotator-review`.
- `skills/dart-signals/` — Dart Signals + flutter_hooks guidance.
- `plugins/blocklist.json` — user-curated plugin blocklist. Marketplace and cache dirs under `plugins/` are gitignored; Claude Code redownloads them on demand.

## Not tracked

`.claude/.gitignore` excludes credentials, `history.jsonl`, per-project session data, shell snapshots, and plugin caches.

MCP servers are **not** in this package — Claude Code reads them from `~/.claude.json` (user scope) or a project `.mcp.json`, never from `settings.json`. Re-add them on a new machine with `claude mcp add`.

## Scopes cheat-sheet

| Scope | File | Applies to |
|-------|------|------------|
| Global | `~/.claude/CLAUDE.md` + `~/.claude/settings.json` | every project on this machine |
| Project | `<repo>/CLAUDE.md` + `<repo>/.claude/settings.json` | that repo only, overrides global |
| MCP (user) | `~/.claude.json` | every project, machine-local, not tracked |
