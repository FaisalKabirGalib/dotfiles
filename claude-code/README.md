# Claude Code Configuration

This package manages global Claude Code configuration using GNU Stow.

## What's Included

- **settings.json**: Global Claude Code settings (plugins, preferences, etc.)
- **commands/**: Custom slash commands for Claude Code
- **skills/**: Auto-activating skills that provide contextual expertise
- **agents/**: Specialized subagents for specific tasks
- **hooks/**: Event hooks that run on tool calls
- **.env.template**: Template for environment variables (API tokens, etc.)
- **.claude.json.template**: Reference template for .claude.json structure with MCP server examples

## What's Excluded (via .gitignore)

The following machine-specific and sensitive files are excluded from version control:

**In ~/.claude/ directory:**
- `.credentials.json` - OAuth tokens and authentication
- `history.jsonl` - Command and interaction history
- `debug/` - Debug logs
- `file-history/` - File edit history
- `shell-snapshots/` - Shell execution snapshots
- `projects/` - Project-specific conversation data
- `todos/` - Task tracking data
- `.env` - Environment variables with API tokens and credentials

**Not managed by dotfiles:**
- `~/.claude.json` - MCP servers and user preferences (managed locally on each machine)

## Installation

```bash
# From dotfiles root
stow -t ~ claude-code

# Or use the helper script
./stowup claude-code
```

This will symlink:
- `~/.claude/settings.json` - Global settings
- `~/.claude/commands/` - Custom slash commands
- `~/.claude/skills/` - Auto-activating skills
- `~/.claude/agents/` - Specialized subagents
- `~/.claude/hooks/` - Event hooks

## Removal

```bash
# From dotfiles root
stow -D -t ~ claude-code

# Or use the helper script
./stowDown claude-code
```

## Adding Custom Slash Commands

Create markdown files in `commands/` directory:

```bash
# Example: .claude/commands/review.md
echo "Review the code for security vulnerabilities and best practices" > claude-code/.claude/commands/review.md
```

Then use with `/review` in Claude Code.

## Adding Skills

Skills auto-activate based on task context (unlike commands which are manually invoked).

Create skill directories with `SKILL.md` files:

```bash
# Create a new skill
mkdir -p claude-code/.claude/skills/skill-name
cat > claude-code/.claude/skills/skill-name/SKILL.md << 'EOF'
---
name: skill-name
description: When this skill should activate
version: 1.0.0
---

# Skill Title

Expert guidance for this domain.

## When This Skill Activates

Claude activates this when working on [specific tasks].

## Key Principles

1. Principle one
2. Principle two
3. Etc.
EOF
```

**Key differences from commands:**
- Skills auto-activate based on context matching the `description`
- Must be in subdirectories: `skills/skill-name/SKILL.md`
- File must be named `SKILL.md` (not `skill-name.md`)
- Cannot be manually invoked (unlike `/command-name`)

## Adding Agents

Agents are specialized subagents that can be invoked for specific tasks.

Create agent markdown files in `agents/` directory:

```bash
# Example: .claude/agents/security-expert.md
cat > claude-code/.claude/agents/security-expert.md << 'EOF'
---
description: Security specialist for identifying vulnerabilities, implementing secure coding practices, and conducting security audits
tools: Read, Grep, Bash
model: sonnet
---

You are a security expert specializing in application security.

When invoked:
1. Analyze the code for security vulnerabilities
2. Check for OWASP Top 10 issues
3. Review authentication and authorization
4. Identify potential security risks

Focus on:
- Input validation and sanitization
- Authentication and authorization
- SQL injection, XSS, CSRF vulnerabilities
- Secure data handling
- Cryptographic best practices
EOF
```

**Usage:** Agents can be invoked automatically by Claude or manually via the Task tool.

## Adding Event Hooks

Create hook scripts in `hooks/` directory. Refer to Claude Code documentation for available hook types and syntax.

## Managing MCP Servers

MCP servers are managed locally on each machine via `~/.claude.json`, which is **not tracked in dotfiles**.

### Adding MCP Servers

**Option 1: Use Claude Code CLI (Recommended)**
```bash
claude mcp add        # Interactive wizard to add MCP servers
claude mcp list       # List all configured MCP servers
claude mcp remove     # Remove an MCP server
```

**Option 2: Edit ~/.claude.json directly**
```bash
vim ~/.claude.json

# Add your MCP server to the mcpServers object:
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@example/mcp-server"],
      "env": {}
    }
  }
}
```

**MCP Server Types:**
- **stdio**: Standard input/output MCP servers (most common)
- **http**: HTTP-based MCP servers with headers support
- **sse**: Server-Sent Events MCP servers

See `.claude.json.template` for examples of all server types.

### Per-Project MCP Servers

You can also configure project-specific MCP servers in `.mcp.json` files within your project directories. These are loaded in addition to global servers.

## Environment Variables Setup

Claude Code requires environment variables for API access and configuration. These are handled securely using a template system:

```bash
# Set up your environment variables (do this once)
cd ~/.claude
cp .env.template .env
vim .env  # Edit with your actual values
```

**Required Environment Variables:**
- `ANTHROPIC_AUTH_TOKEN`: Your Anthropic API token (get from https://console.anthropic.com/account/keys)
- `ANTHROPIC_BASE_URL`: API base URL (default: https://api.anthropic.com)
- `API_TIMEOUT_MS`: Request timeout in milliseconds (default: 60000)
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`: Set to 1 to disable analytics (default: 0)

⚠️ **Important**: The `.env` file contains sensitive credentials and is excluded from git. Never commit this file.

## First-Time Setup

After stowing this package, complete the setup:

```bash
# 1. Set up environment variables
cd ~/.claude
cp .env.template .env
# Edit .env with your API token and other settings

# 2. Restore credentials (if you had previous Claude Code installation)
cp ~/.claude.backup-TIMESTAMP/.credentials.json ~/.claude/.credentials.json
```

## Syncing Settings Across Machines

Since this configuration is in your dotfiles repository, your Claude Code settings sync automatically:

**Setup on a new machine:**
```bash
# Clone dotfiles and install
cd ~/dotfiles
./stowup claude-code

# Set up environment variables
cd ~/.claude
cp .env.template .env
# Edit .env with your API token and settings

# MCP servers need to be configured manually on each machine
claude mcp add
```

**What Syncs Automatically:**
- ✅ Global settings (settings.json)
- ✅ Custom slash commands
- ✅ Auto-activating skills
- ✅ Specialized agents
- ✅ Event hooks
- ✅ Environment variable template (.env.template)

**What Stays Machine-Specific:**
- ❌ `.env` - Environment variables with API tokens (configure locally)
- ❌ `~/.claude.json` - MCP servers and preferences (configure locally)
- ❌ `.credentials.json` - OAuth tokens (regenerated on first login)
- ❌ Conversation history and session data
- ❌ Machine-specific data (stats, tips, cache)

## Philosophy

This package takes a **minimal approach** to Claude Code configuration:

- **Settings, commands, skills, agents, and hooks are shared** - These are portable and work the same across machines
- **Environment variables stay local** - API tokens and credentials are machine-specific and managed via .env files
- **MCP servers stay local** - Server paths, API keys, and configurations are machine-specific and managed locally
- **Clean separation** - Dotfiles handle the shareable parts, sensitive data stays on each machine

This keeps your dotfiles clean and secure, avoiding mixing shareable configurations with machine-specific secrets and credentials.
