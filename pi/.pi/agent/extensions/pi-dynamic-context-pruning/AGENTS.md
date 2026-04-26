# DCP — AGENTS.md

> Vendored pi extension. Not a standalone project. Part of [dotfiles](../../).

## What This Is

Dynamic Context Pruning extension for [pi coding agent](https://pi.dev). Manages conversation context in long sessions by compressing stale ranges, deduplicating tool outputs, and purging old errors.

## Commands

| Task | Command |
|------|---------|
| Type check | `npx tsc --noEmit` |
| Run tests | `bun run pruner.test.ts` |
| Install deps | `npm install` |

No build step. Pi loads `.ts` via jiti.

## Module Map

| File | Responsibility |
|------|---------------|
| `index.ts` | Extension entry — registers all hooks on `ExtensionAPI` |
| `config.ts` | JSONC config loading (defaults → global → env → project) |
| `state.ts` | `DcpState`, `CompressionBlock`, `ToolRecord` types + factories |
| `pruner.ts` | `applyPruning`, `injectNudge`, `getNudgeType`, `estimateTokens` |
| `compress-tool.ts` | `compress` tool registration (LLM-callable) |
| `commands.ts` | `/dcp` slash commands |
| `prompts.ts` | System prompt text, nudge templates |

## Import Rules

- Local imports use `.js` extension: `import { X } from "./state.js"`
- Type-only imports use `import type`
- Order: Node built-ins → external → local

## Architecture Constraints

- **Timestamps are stable IDs** — never use array indices for compression ranges
- **Assistant + toolResult pairs are atomic** — always expand ranges to include both
- **State is mutated in-place** via `resetState()` — never replace the state object
- **Config is read-only** after `loadConfig()` — never mutate

## Upstream Sync

```bash
cd /tmp && git clone https://github.com/complexthings/pi-dynamic-context-pruning.git dcp-upstream
diff -r /tmp/dcp-upstream/ ~/dotfiles/pi/.pi/agent/extensions/pi-dynamic-context-pruning/ \
  --exclude=node_modules --exclude=.git --exclude=tsconfig.json
```

## Dependencies

| Package | Role |
|---------|------|
| `jsonc-parser` | Parse JSONC config |
| `@mariozechner/pi-coding-agent` | Peer — ExtensionAPI types |
| `@mariozechner/pi-tui` | Peer — UI types |
| `@sinclair/typebox` | Peer — tool parameter schemas |
