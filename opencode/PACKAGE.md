# opencode — Opencode CLI + MCP Servers

Opencode CLI configuration with Model Context Protocol servers.

When OpenCode runs inside tmux, its bundled local plugin reports `working`,
`needs input`, and `done` states to `tmux-agent-status`, alongside Claude Code
and Codex.

## Package Details

- **Type**: CLI Tool / MCP
- **Target**: `~/.config/opencode`
- **Dependencies**: Opencode CLI, API keys

## Install

```bash
stowup opencode
source opencode/mcp-env.sh  # Load API keys
```

## MCP Servers Configured

- `context7` — Codebase indexing/search
- `sequential-thinking` — Advanced reasoning
- `zai-mcp-server` — Z.AI services
- `Ref` — Reference tools
- `web-search-prime` — Web search
- `web-reader` — Web content reading

## Note

API keys stored in `mcp-env.sh` (private, not committed to git).
