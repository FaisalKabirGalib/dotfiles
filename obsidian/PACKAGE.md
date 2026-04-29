# obsidian — Obsidian Vault Management

Obsidian note-taking app configuration + vault management scripts.

## Package Details

- **Type**: Note-taking / Knowledge Management
- **Target**: `.obsidian` templates in vault directories
- **Dependencies**: Obsidian, Git

## Install

```bash
stowup obsidian
obsidian-vault-init <vault-name> <type>  # Initialize new vault
```

## Vault Types

| Type | Purpose | Git |
|------|---------|-----|
| personal | Private notes | Private repo |
| work | Work notes | Company repo |
| public | Public KB | Public repo |
| projects | Project planning | Private repo |

## Key Scripts

- `obsidian-sync-config` — Sync .obsidian config to vaults
- `obsidian-backup` — Backup vault to git
- `obsidian-vault-init` — Initialize new vault