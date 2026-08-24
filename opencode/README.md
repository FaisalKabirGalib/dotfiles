# OpenCode Configuration

This package contains OpenCode configuration for agents, commands, and MCP servers, managed via GNU Stow for easy synchronization across machines.

## Overview

OpenCode is a terminal-based AI coding assistant. This configuration includes:

- **9 Specialized Agents**: fullstack-developer, code-reviewer, debugger, error-detective, ai-engineer, ui-ux-designer, context-manager, prompt-engineer, search-specialist
- **8 Custom Commands**: code-review, architecture-review, create-feature, create-prd, refactor-code, explain-code, code-simplifier, todo
- **MCP Server Configuration**: Structure ready for adding Model Context Protocol servers
- **Global Settings**: Theme, model preferences, and autoupdate configuration

## Installation

### Using Stow (Recommended)

From the dotfiles repository root:

```bash
./stowup opencode
# Or manually: stow -t ~ opencode
```

This creates a symlink:
- `~/.config/opencode/` → `dotfiles/opencode/.config/opencode/`

### Verify Installation

```bash
ls -la ~/.config/opencode
opencode  # Launch OpenCode to test
```

## Usage

### Using Agents

Invoke agents with the `@` prefix:

```bash
@fullstack-developer help me build a REST API
@code-reviewer analyze the recent changes
@debugger investigate this error
```

### Using Commands

Execute commands with the `/` prefix:

```bash
/code-review src/
/architecture-review --modules
/create-feature user-authentication
/todo add "Fix navigation bug"
```

## Configuration Structure

```
opencode/
├── .config/opencode/
│   ├── opencode.jsonc       # Main configuration
│   ├── .gitignore           # Sensitive data exclusions
│   ├── agents/              # 9 specialized agents
│   │   ├── fullstack-developer.md
│   │   ├── code-reviewer.md
│   │   ├── debugger.md
│   │   ├── error-detective.md
│   │   ├── ai-engineer.md
│   │   ├── ui-ux-designer.md
│   │   ├── context-manager.md
│   │   ├── prompt-engineer.md
│   │   └── search-specialist.md
│   └── commands/            # 8 custom commands
│       ├── code-review.md
│       ├── architecture-review.md
│       ├── create-feature.md
│       ├── create-prd.md
│       ├── refactor-code.md
│       ├── explain-code.md
│       ├── code-simplifier.md
│       └── todo.md
├── README.md                # This file
└── .gitignore               # Root-level exclusions
```

## Adding Custom Agents

Create a new markdown file in `agents/` directory:

```bash
vim ~/.config/opencode/agents/my-agent.md
```

Example format:

```markdown
---
description: Brief description of what this agent does
mode: subagent
model: anthropic/claude-sonnet-4-5
tools:
  read: true
  write: true
  edit: true
  bash: true
---

You are a specialized agent for [specific task].

[Agent instructions here...]
```

Available models:
- `anthropic/claude-opus-4` - Most capable, for complex tasks
- `anthropic/claude-sonnet-4-5` - Balanced performance (default)
- `anthropic/claude-haiku-4-5` - Fast and efficient

## Adding Custom Commands

Create a new markdown file in `commands/` directory:

```bash
vim ~/.config/opencode/commands/my-command.md
```

Example format:

```markdown
---
description: Brief description of what this command does
tools:
  read: true
  bash: true
  grep: true
---

# My Command

Execute my command: $ARGUMENTS

## Instructions

1. Step one
2. Step two
3. ...

Use $ARGUMENTS to reference user-provided arguments.
Use !`command` to execute shell commands and embed output.
Use @file-path to reference files.
```

## MCP Server Configuration

### Adding an MCP Server

Edit `~/.config/opencode/opencode.json` and add to the `"mcp"` section:

#### Local MCP Server (stdio)

```json
{
  "mcp": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "{env:GITHUB_PERSONAL_TOKEN}"
      }
    }
  }
}
```

#### Remote MCP Server

```json
{
  "mcp": {
    "remote-api": {
      "type": "remote",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer {env:API_TOKEN}"
      }
    }
  }
}
```

### Environment Variables

Store sensitive data in environment variables, reference them with `{env:VAR_NAME}`:

```bash
# Add to ~/.bashrc or ~/.zshrc
export GITHUB_PERSONAL_TOKEN="your-token-here"
export API_TOKEN="your-api-token"
```

## Configuration Options

### Global Settings (opencode.json)

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",      // Primary model
  "small_model": "anthropic/claude-haiku-4-5",  // For lightweight tasks
  "theme": "opencode",                          // UI theme
  "autoupdate": true,                           // Auto-update OpenCode
  "mcp": {}                                     // MCP server configs
}
```

## What's Excluded from Git

The following files/directories are not tracked (machine-specific):

- `.env`, `.env.local`, `.env.*.local` - Environment variables
- `.credentials.json` - OAuth tokens and authentication
- `history.jsonl` - Command/interaction history
- `debug/` - Debug logs and session info
- `file-history/` - File edit history
- `shell-snapshots/` - Command execution snapshots
- `projects/` - Project-specific conversation data
- `todos/` - Task tracking data

## Differences from Claude Code

| Feature | Claude Code | OpenCode |
|---------|-------------|----------|
| **Config Location** | `~/.claude/` | `~/.config/opencode/` |
| **Agent Definition** | Markdown with `name:` field | Markdown, filename is name |
| **Tool Format** | List: `tools: Read, Write` | Object: `tools: {read: true}` |
| **Model Names** | `opus`, `sonnet`, `haiku` | `anthropic/claude-opus-4` |
| **Mode Field** | Not required | Required: `mode: subagent` |
| **Invocation** | Via Task tool | Direct: `@agent-name` |
| **Special Syntax** | `$ARGUMENTS`, `!`cmd``, `@file` | Same syntax supported |

## Troubleshooting

### Agents not appearing

```bash
# Verify files exist
ls ~/.config/opencode/agents/

# Check OpenCode recognizes them
opencode
# Type @ and see if agents autocomplete
```

### Commands not working

```bash
# Verify files exist
ls ~/.config/opencode/commands/

# Check OpenCode recognizes them
opencode
# Type / and see if commands autocomplete
```

### MCP servers not connecting

```bash
# Test environment variables
echo $GITHUB_PERSONAL_TOKEN

# Check OpenCode logs
tail -f ~/.config/opencode/debug/*.log
```

## Updating Configuration

Since this is managed by Stow, any changes you make to files in `~/.config/opencode/` are automatically reflected in your dotfiles repository (they're symlinked).

To sync changes:

```bash
cd ~/dotfiles
git add opencode/
git commit -m "Update OpenCode configuration"
git push
```

On another machine:

```bash
cd ~/dotfiles
git pull
./stowup opencode  # If not already installed
```

## Resources

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode GitHub](https://github.com/opencode-ai/opencode)
- [MCP Servers Documentation](https://opencode.ai/docs/mcp-servers/)
- [Configuration Schema](https://opencode.ai/config.json)

## License

This configuration follows the same license as your dotfiles repository.
