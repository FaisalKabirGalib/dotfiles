# opencode — Opencode CLI + MCP Servers

Opencode CLI configuration with Model Context Protocol servers.

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

- `context7` — Library/framework documentation lookup
- `zai-mcp-server` — Z.AI services
- `web-search-prime` — Web search
- `web-reader` — Web content reading

## Note

API keys stored in `mcp-env.sh` (private, not committed to git).