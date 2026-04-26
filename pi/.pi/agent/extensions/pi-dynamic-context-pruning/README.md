# Dynamic Context Pruning (DCP) — Personal Fork

Vendored from [complexthings/pi-dynamic-context-pruning](https://github.com/complexthings/pi-dynamic-context-pruning) (v1.0.7). Modified for personal use.

---

## What It Does

Reduces token usage in pi sessions through 5 mechanisms:

| Mechanism | How | When |
|-----------|-----|------|
| **Compression** | LLM summarizes stale conversation ranges → raw messages replaced with summaries | When context is high or `/dcp compress` |
| **Deduplication** | Same tool + same args = keep only last result | Every context event |
| **Error purge** | Old failed tool outputs replaced with tombstones | After 4 user turns |
| **Nudges** | Synthetic messages remind LLM to compress | Context > 80% or long tool chains |
| **Message IDs** | Every message gets `<dcp-id>m001</dcp-id>` for precise range targeting | Every context event |

## Commands

| Command | Description |
|---------|-------------|
| `/dcp` | Show help |
| `/dcp context` | Context window usage + session stats |
| `/dcp stats` | Tokens saved, prune count, blocks |
| `/dcp sweep [N]` | Prune last N tool outputs (default: all since last user msg) |
| `/dcp compress` | Trigger LLM compression now |
| `/dcp decompress` | List active compression blocks |
| `/dcp decompress N` | Restore block `bN` (re-expand in context) |
| `/dcp manual` | Show manual mode status |
| `/dcp manual on` | Disable autonomous nudges |
| `/dcp manual off` | Enable autonomous nudges |

## Config

Layered JSONC config (later overrides earlier):

1. Built-in defaults
2. `~/.config/pi/dcp.jsonc` — global
3. `<project>/.pi/dcp.jsonc` — project-local

Auto-created with defaults on first run.

### Key Settings

```jsonc
{
  // Start in manual mode (no autonomous compression)
  "manualMode": { "enabled": true, "automaticStrategies": true },

  "compress": {
    "maxContextPercent": 0.8,      // Above 80%: aggressive nudges
    "minContextPercent": 0.4,      // Below 40%: no nudges
    "nudgeFrequency": 5,          // Nudge every N context events
    "iterationNudgeThreshold": 15, // Nudge after N tool calls without user msg
    "nudgeForce": "soft",         // "soft" = housekeeping, "strong" = emergency
    "protectedTools": ["compress", "write", "edit"]
  },

  "strategies": {
    "deduplication": { "enabled": true },
    "purgeErrors": { "enabled": true, "turns": 4 }
  },

  "pruneNotification": "detailed"  // "off" | "minimal" | "detailed"
}
```

## File Structure

```
pi-dynamic-context-pruning/
├── index.ts           ← Entry point (pi auto-discovers)
├── config.ts          ← JSONC config loader (4-layer merge)
├── state.ts           ← Runtime state types + factories
├── pruner.ts          ← Core: applyPruning, nudges, message ID injection
├── compress-tool.ts   ← Registers `compress` LLM tool
├── commands.ts        ← Registers `/dcp` commands
├── prompts.ts         ← System prompt strings + nudge text
├── pruner.test.ts     ← Tests (run with bun)
├── tsconfig.json      ← For local type checking
└── package.json
```

## Type Check

```bash
cd ~/.pi/agent/extensions/pi-dynamic-context-pruning
npx tsc --noEmit
```

No build step needed — pi loads `.ts` directly via jiti.

## Local Changes from Upstream

- Fixed type error in `config.ts` (`unknown[]` → `any[]` for jsonc-parser compatibility)
- Added `tsconfig.json` for type checking
- Added dev dependencies (`typescript`, `@mariozechner/pi-coding-agent`, `@mariozechner/pi-tui`)

## Pull Upstream Updates

```bash
# 1. Clone upstream to temp
cd /tmp && git clone https://github.com/complexthings/pi-dynamic-context-pruning.git dcp-upstream

# 2. Diff against local
diff -r /tmp/dcp-upstream/ ~/dotfiles/pi/.pi/agent/extensions/pi-dynamic-context-pruning/ \
  --exclude=node_modules --exclude=.git --exclude=tsconfig.json

# 3. Cherry-pick changes you want
# 4. Re-install deps if package.json changed
cd ~/dotfiles/pi/.pi/agent/extensions/pi-dynamic-context-pruning && npm install

# 5. Type check
npx tsc --noEmit

# 6. Cleanup
rm -rf /tmp/dcp-upstream
```

## Upstream Source

- **Repo:** https://github.com/complexthings/pi-dynamic-context-pruning
- **Version:** 1.0.7
- **License:** Check upstream repo
