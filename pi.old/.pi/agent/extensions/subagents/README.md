# Minimal Subagents

A pi extension that registers a single `subagent` tool with three agents:

| Agent | Tools | Model | Purpose |
|-------|-------|-------|---------|
| **scout** | read, grep, find, ls | fast (current session model) | Fast codebase recon |
| **researcher** | web_search, web_fetch | current session model | Web research |
| **worker** | read, write, edit, safe_bash | current session model | Code changes |

## Usage

**Single mode:**
```json
{ "agent": "scout", "task": "Find all auth-related files in src/" }
```

**Parallel mode:**
```json
{ "tasks": [
  { "agent": "scout", "task": "Map the database layer" },
  { "agent": "researcher", "task": "Best practices for connection pooling" }
]}
```

**Chain mode** (sequential pipeline, each step gets previous output):
```json
{ "chain": [
  { "agent": "scout", "task": "Find all auth files in src/" },
  { "agent": "worker", "task": "Based on the findings: {previous}\n\nAdd rate limiting to all auth endpoints" },
  { "agent": "scout", "task": "Review the changes for security issues: {previous}" }
]}
```

Template variables in chain tasks:
- `{task}` — the first step's task (the original user task)
- `{previous}` — output from the prior step

If a step's task is omitted, it defaults to `{previous}` (step 2+) or empty (step 1). Chain stops on first failure.

Max 4 concurrent subagents (configurable). Each runs as an isolated `pi` process with no inherited context — all context must be in the task description.

## Slash Commands

- `/run <agent> <task>` — run a single subagent directly, result shown as notification

## Recursion Guard

Subagents cannot spawn subagents beyond the depth limit. Controlled via environment variables:
- `PI_SUBAGENT_DEPTH` — current nesting depth (auto-incremented)
- `PI_SUBAGENT_MAX_DEPTH` — maximum allowed depth (default: 2)

## Config

Optional `config.json` next to `index.ts`:

```json
{ "maxConcurrency": 4 }
```

## UI

Default view shows medium detail (agent status, task preview, recent tools). Expand to see full task, all tool calls, complete output, and token usage.

Chain mode shows a flow visualization: `✓scout → ●worker → ○reviewer`

## Registering Agents from Other Extensions

Other extensions can dynamically register and unregister agents at runtime. This is useful for domain-specific agents that should only be available when a particular extension is active.

### 1. Define agent `.md` files

Create markdown files with YAML frontmatter in your extension's directory (e.g. `my-extension/agents/my-agent.md`):

```markdown
---
name: my-agent
description: Does a specific thing
tools: web_search, video_extract
model: claude-sonnet-4-20250514
---

You are an agent that does a specific thing...
```

Frontmatter fields:
- **name** (required) — unique agent name, used in `{ agent: "my-agent" }` calls
- **description** — short description
- **tools** — comma-separated list of tools the agent needs (builtin or extension)
- **model** — model identifier (defaults to current session model)

The markdown body becomes the agent's system prompt.

### 2. Register agents via `globalThis.__pi_subagents`

Pi loads extensions via jiti, which creates separate module instances. Direct imports from the subagents extension will reference a different `agents` array than the one the `subagent` tool uses. Use the `globalThis` bridge instead:

```typescript
import { parseFrontmatter } from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

interface AgentConfig {
  name: string;
  description: string;
  tools: string[];
  model?: string;
  systemPrompt: string;
  filePath: string;
}

const AGENTS_DIR = path.join(path.dirname(new URL(import.meta.url).pathname), "agents");

function registerMyAgents(): void {
  const subagents = (globalThis as any).__pi_subagents as
    | { registerAgent: (config: AgentConfig) => void; unregisterAgent: (name: string) => void }
    | undefined;
  if (!subagents) return; // subagents extension not loaded

  for (const entry of fs.readdirSync(AGENTS_DIR)) {
    if (!entry.endsWith(".md")) continue;
    const filePath = path.join(AGENTS_DIR, entry);
    const content = fs.readFileSync(filePath, "utf-8");
    const { frontmatter, body } = parseFrontmatter<Record<string, string>>(content);
    if (!frontmatter.name) continue;

    const tools = (frontmatter.tools || "").split(",").map(t => t.trim()).filter(Boolean);
    try {
      subagents.registerAgent({
        name: frontmatter.name,
        description: frontmatter.description || "",
        tools,
        model: frontmatter.model || undefined,
        systemPrompt: body,
        filePath,
      });
    } catch {
      // Already registered — skip
    }
  }
}
```

Call `registerMyAgents()` when your extension activates (e.g. in a command handler). The agents become available to the `subagent` tool immediately.

### 3. Adding custom tool support

If your agents need tools beyond the built-in set, those tools must be mapped in the `CUSTOM_TOOL_EXTENSIONS` record in `subagents/index.ts`:

```typescript
const CUSTOM_TOOL_EXTENSIONS: Record<string, string> = {
  web_search: path.join(EXT_BASE, "web-search", "index.ts"),
  web_fetch: path.join(EXT_BASE, "web-fetch", "index.ts"),
  safe_bash: path.join(TOOLS_DIR, "safe-bash.ts"),
  video_extract: path.join(EXT_BASE, "video-extract", "index.ts"),
  youtube_search: path.join(EXT_BASE, "youtube-search", "index.ts"),
  google_image_search: path.join(EXT_BASE, "google-image-search", "index.ts"),
};
```

Built-in tools (`read`, `write`, `edit`, `bash`, `grep`, `find`, `ls`) work automatically. Any other tool the agent lists in its frontmatter must have a corresponding entry here pointing to the extension's `index.ts`.

## Structure

```
subagents/
├── index.ts           # Extension entry point
├── agents/            # Built-in agent configs (frontmatter + system prompt)
└── tools/             # Extensions loaded into subagent processes
    └── safe-bash.ts   # bash with dangerous command blocking
```
