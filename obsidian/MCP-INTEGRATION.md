# Obsidian MCP Integration Guide

MCP (Model Context Protocol) integration allows Claude Code to access your Obsidian vaults directly, enabling it to read and reference your documentation while helping with code.

## What is MCP?

The Model Context Protocol is an open-source protocol by Anthropic that enables AI systems like Claude to securely connect with various data sources. It allows Claude Code to:
- Read notes from your Obsidian vaults
- Search across your documentation
- Reference project-specific knowledge
- Access architecture decisions, workflows, and technical docs

## Configured Vaults

Three Obsidian MCP servers are configured in `~/.claude.json`:

### 1. obsidian-projects
**Path:** `~/Documents/vault-projects`
**Purpose:** Project-specific documentation, architecture, technical notes
**Use for:** Code projects, design decisions, implementation details

### 2. obsidian-work
**Path:** `~/Documents/vault-work`
**Purpose:** Work-related documentation, processes, meeting notes
**Use for:** Work projects, team documentation, workflows

### 3. obsidian-personal
**Path:** `~/Documents/vault-personal`
**Purpose:** Personal knowledge base, learning notes, reference materials
**Use for:** Learning resources, personal reference, study notes

## How to Use

### In Claude Code CLI

**Enable/Disable MCP Servers:**
```bash
# List all MCP servers
claude mcp list

# Enable a specific Obsidian vault
@obsidian-projects

# Disable by @mentioning again
@obsidian-projects
```

**Ask Claude to Reference Vaults:**
```bash
# Example prompts:
"Check my obsidian-projects vault for the dotfiles architecture"
"What does my obsidian-work vault say about our deployment process?"
"Search obsidian-personal for notes about Go programming"
```

**@-Mention to Toggle:**
When you @-mention an MCP server in your prompt, it toggles that server on/off for the conversation.

### Available Tools

The Obsidian MCP server provides these tools to Claude:

1. **read_note** - Read a specific note by path
2. **search_notes** - Search notes by content or title
3. **list_notes** - List all notes in the vault
4. **list_tags** - List all tags used in vault
5. **search_by_tag** - Find notes with specific tags

### Project Documentation Workflow

1. **Create Project Documentation:**
   ```bash
   # In your vault-projects
   nvim ~/Documents/vault-projects/my-project.md
   ```

2. **Document Your Project:**
   - Architecture decisions
   - Setup instructions
   - API documentation
   - Known issues and solutions
   - Code patterns and conventions

3. **Reference in Claude Code:**
   ```bash
   # In your project directory
   claude
   > @obsidian-projects help me refactor this code according to our architecture docs
   ```

4. **Claude Can Now:**
   - Read your project documentation
   - Follow your established patterns
   - Reference your architecture decisions
   - Use your documented conventions

## Example Use Cases

### 1. Code with Architecture Context
```bash
cd ~/Projects/my-app
claude
> @obsidian-projects I'm adding a new API endpoint. Check the architecture docs
  and help me implement it following our patterns.
```

### 2. Reference Work Processes
```bash
claude
> @obsidian-work What's our standard deployment checklist? Help me create a
  deployment script that follows it.
```

### 3. Learning Reference
```bash
claude
> @obsidian-personal I'm learning Go. Check my notes and help explain this
  concurrency pattern in the context of what I already know.
```

## Configuration

### MCP Server Configuration
Located in: `~/.claude.json`

```json
{
  "mcpServers": {
    "obsidian-projects": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "@mauricio.wolff/mcp-obsidian@latest",
        "~/Documents/vault-projects"
      ],
      "env": {}
    }
  }
}
```

### Adding New Vaults

To add more vaults to MCP:

```bash
# Edit ~/.claude.json
jq '.mcpServers += {
  "obsidian-myproject": {
    "type": "stdio",
    "command": "npx",
    "args": [
      "@mauricio.wolff/mcp-obsidian@latest",
      "/path/to/your/vault"
    ],
    "env": {}
  }
}' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
```

## Best Practices

### 1. Organize Project Documentation

**Structure your vault-projects:**
```
vault-projects/
├── dotfiles-project.md       # Your dotfiles documentation
├── webapp-project.md          # Web app architecture
├── api-project.md             # API documentation
└── mobile-app-project.md      # Mobile app notes
```

### 2. Use Consistent Formatting

**In your project docs, include:**
- **Overview:** What the project does
- **Architecture:** System design, components
- **Tech Stack:** Technologies and versions
- **Setup:** Installation and configuration
- **Workflows:** Common development tasks
- **Conventions:** Code patterns and standards
- **Links:** Related documentation

### 3. Keep Documentation Updated

```bash
# After major changes, update your docs
nvim ~/Documents/vault-projects/myproject.md

# Commit changes
obsidian-backup
```

### 4. Use Tags for Organization

In your notes, use tags:
```markdown
# My Project

#project #architecture #typescript #nodejs

## Overview
...
```

Then Claude can search by tag:
```bash
> @obsidian-projects find all notes tagged with #architecture
```

## Troubleshooting

### MCP Server Not Working

**Check if MCP server is configured:**
```bash
jq '.mcpServers' ~/.claude.json
```

**Test the MCP server manually:**
```bash
npx @mauricio.wolff/mcp-obsidian@latest ~/Documents/vault-projects
```

### Vault Not Accessible

**Verify vault path:**
```bash
ls ~/Documents/vault-projects
```

**Check permissions:**
```bash
ls -la ~/Documents/vault-projects
```

### Claude Can't Find Notes

**Ensure notes are in the vault:**
```bash
tree ~/Documents/vault-projects
```

**Check note format (must be .md):**
```bash
find ~/Documents/vault-projects -name "*.md"
```

## Advanced Usage

### Per-Project Configuration

You can also configure MCP servers per-project in `.claude/settings.json`:

```json
{
  "mcpServers": {
    "project-docs": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "@mauricio.wolff/mcp-obsidian@latest",
        "./docs"
      ]
    }
  }
}
```

This allows project-specific documentation to be accessible only when working in that project.

### Hybrid Approach

Combine Obsidian vaults with in-project docs:

1. **vault-projects** - High-level architecture, cross-project patterns
2. **Project `docs/`** - Project-specific technical details
3. **Project `README.md`** - Quick start and overview

## Security Notes

- **vault-personal** contains your personal notes - be mindful when enabling
- **vault-work** may contain sensitive work information - use appropriately
- **vault-projects** is great for technical documentation
- MCP servers run locally - no data is sent to external services
- You control which vaults Claude can access

## Resources

- [MCP Obsidian Server (bitbonsai)](https://github.com/bitbonsai/mcp-obsidian)
- [Model Context Protocol Docs](https://modelcontextprotocol.io)
- [Claude Code MCP Guide](https://docs.claude.com/en/docs/claude-code/mcp)
- [Obsidian Vault Management](./README.md)

## Tips

1. **Start Simple:** Begin with vault-projects for technical docs
2. **Be Specific:** Tell Claude which vault to search
3. **Update Regularly:** Keep documentation current
4. **Use Tags:** Helps Claude find relevant notes
5. **Link Notes:** Use `[[note-name]]` links in Obsidian
6. **Test First:** Verify MCP server works before relying on it

Happy documenting! 🚀
