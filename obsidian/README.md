# Obsidian Configuration

Obsidian vault management with dotfiles integration.

## Overview

This package provides a comprehensive setup for managing multiple Obsidian vaults with:
- **Shared configuration** stored in dotfiles (themes, plugins, settings)
- **Multiple specialized vaults** for different contexts (personal, work, public, projects)
- **Helper scripts** for vault initialization, synchronization, and backup
- **Hybrid project documentation** approach with Obsidian integration

## Architecture

### Directory Structure

```
obsidian/
├── .config/obsidian/
│   ├── shared-config/           # Base .obsidian config (committed to dotfiles)
│   │   ├── app.json
│   │   ├── appearance.json
│   │   ├── core-plugins.json
│   │   ├── graph.json
│   │   ├── themes/
│   │   └── .gitignore.base
│   ├── personal-config/         # Personal vault overrides
│   │   └── .gitignore.template
│   ├── work-config/             # Work vault overrides
│   │   └── .gitignore.template
│   └── public-config/           # Public vault overrides
│       └── .gitignore.template
└── .local/bin/
    ├── obsidian-vault-init      # Initialize new vault
    ├── obsidian-sync-config     # Sync config from dotfiles
    ├── obsidian-backup          # Backup vaults to git
    └── project-doc-init         # Add Obsidian to project repos
```

### Vault Organization

Vaults are stored outside dotfiles (typically in `~/Documents/`):

```
~/Documents/
├── vault-personal/              # Personal notes → Private git repo
├── vault-work/                  # Work notes → Private/company git repo
├── vault-public/                # Public knowledge base → Public git repo
└── vault-projects/              # Project notes → Private git repo
```

Each vault is a separate git repository with its own .gitignore and remote.

## Installation

### 1. Install Package

```bash
# From dotfiles root
./stowup  # Installs all packages including obsidian

# Or install just obsidian package
stow -t ~ obsidian
```

This creates:
- `~/.config/obsidian/` - Configuration templates
- `~/.local/bin/obsidian-*` - Helper scripts

### 2. Create Your First Vault

```bash
# Personal vault
obsidian-vault-init vault-personal personal

# Work vault
obsidian-vault-init vault-work work

# Public knowledge base
obsidian-vault-init vault-public public

# Projects vault
obsidian-vault-init vault-projects personal
```

### 3. Set Up Git Remotes

```bash
# For each vault, add a git remote
cd ~/Documents/vault-personal
git remote add origin git@github.com:yourusername/obsidian-notes-private.git
git push -u origin main

cd ~/Documents/vault-public
git remote add origin git@github.com:yourusername/obsidian-notes-public.git
git push -u origin main
```

## Helper Scripts

### obsidian-vault-init

Initialize a new Obsidian vault with configuration from dotfiles.

```bash
# Usage
obsidian-vault-init <vault-name> <type> [vault-path]

# Examples
obsidian-vault-init vault-personal personal
obsidian-vault-init vault-work work
obsidian-vault-init my-kb public ~/Projects/my-knowledge-base

# Types: personal, work, public, project
```

**What it does:**
1. Creates vault directory
2. Copies .obsidian config from dotfiles
3. Applies type-specific .gitignore
4. Creates folder structure based on type
5. Initializes git repository
6. Creates README with vault structure

### obsidian-sync-config

Sync Obsidian configuration from dotfiles to existing vaults.

```bash
# Sync all vaults
obsidian-sync-config

# Sync specific vault
obsidian-sync-config ~/Documents/vault-personal
```

**What it does:**
1. Detects vault type automatically
2. Copies shared config from dotfiles
3. Applies type-specific config
4. Preserves workspace files (machine-specific)

**When to use:**
- After updating .obsidian settings in dotfiles
- After installing new themes or plugins
- When setting up on a new machine

### obsidian-backup

Backup vaults to their git repositories.

```bash
# Backup all vaults
obsidian-backup

# Backup specific vault
obsidian-backup ~/Documents/vault-personal

# With custom commit message
obsidian-backup "Weekly review notes"
obsidian-backup ~/Documents/vault-work "Project documentation updates"
```

**What it does:**
1. Checks for uncommitted changes
2. Stages all changes (respects .gitignore)
3. Creates timestamped commit
4. Pushes to remote if configured

**Tip:** Set up a cron job for automatic backups:
```bash
# Daily backup at 10 PM
0 22 * * * /home/yourusername/.local/bin/obsidian-backup
```

### project-doc-init

Initialize Obsidian-compatible documentation in a project repository.

```bash
# In project directory
cd ~/Projects/my-app
project-doc-init

# Or specify path
project-doc-init ~/Projects/my-app
```

**What it creates:**
```
project/
└── docs/
    ├── .obsidian/           # Obsidian config
    ├── .gitignore
    ├── README.md
    ├── Architecture.md
    ├── Setup.md
    ├── Contributing.md
    └── ADRs/                # Architecture Decision Records
```

**Hybrid workflow:**
1. Basic docs in project repo (README, Setup, etc.)
2. Detailed notes in vault-projects/
3. Link between both locations

## Workflows

### Daily Workflow

1. **Open your vaults in Obsidian**
   - Personal vault for daily notes, journaling, personal knowledge
   - Work vault for work notes, meeting notes
   - Projects vault for project planning and documentation

2. **Work on notes throughout the day**

3. **Backup at end of day**
   ```bash
   obsidian-backup
   ```

### New Project Setup

1. **Initialize project documentation**
   ```bash
   cd ~/Projects/new-project
   project-doc-init
   ```

2. **Create project note in vault-projects**
   - Open vault-projects in Obsidian
   - Create `new-project.md` with detailed notes
   - Link to project docs: `[[file://~/Projects/new-project/docs|Project Docs]]`

3. **Commit project docs to repo**
   ```bash
   git add docs/
   git commit -m "Add Obsidian documentation"
   ```

### Syncing Across Machines

1. **On new machine, clone dotfiles**
   ```bash
   git clone your-dotfiles-repo ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```

2. **Clone your vault repositories**
   ```bash
   cd ~/Documents
   git clone git@github.com:you/obsidian-notes-private.git vault-personal
   git clone git@github.com:you/obsidian-notes-public.git vault-public
   ```

3. **Sync configuration (if needed)**
   ```bash
   obsidian-sync-config
   ```

### Updating Obsidian Settings

1. **Make changes in one vault** (e.g., install new theme, change settings)

2. **Copy updated config to dotfiles**
   ```bash
   cp ~/Documents/vault-personal/.obsidian/appearance.json \
      ~/dotfiles/obsidian/.config/obsidian/shared-config/

   # Or manually edit files in dotfiles
   ```

3. **Commit to dotfiles**
   ```bash
   cd ~/dotfiles
   git add obsidian/
   git commit -m "Update Obsidian appearance settings"
   git push
   ```

4. **Sync to other vaults**
   ```bash
   obsidian-sync-config
   ```

## Git Strategy

### What's Committed Where

**Dotfiles Repository:**
- ✅ `.obsidian/` config files (app.json, appearance.json, themes, etc.)
- ✅ `.gitignore` templates
- ✅ Helper scripts
- ❌ Actual notes/content

**Vault Repositories:**
- ✅ Markdown notes and content
- ✅ Vault-specific .obsidian settings
- ✅ Attachments (images, PDFs, etc.)
- ❌ Workspace files (workspace.json)
- ❌ Cache files

### Repository Setup

**Recommended approach:**

1. **Dotfiles repo** (this repo) - Public
   - Obsidian configurations
   - Helper scripts

2. **obsidian-notes-private** - Private
   - vault-personal/
   - vault-work/
   - vault-projects/

3. **obsidian-notes-public** - Public
   - vault-public/

**Alternative: Separate repos per vault**
- obsidian-personal (private)
- obsidian-work (private/company)
- obsidian-public (public)
- obsidian-projects (private)

## Customization

### Adding Custom Vault Types

1. **Create config directory**
   ```bash
   mkdir -p obsidian/.config/obsidian/custom-config
   ```

2. **Add .gitignore template**
   ```bash
   cp obsidian/.config/obsidian/personal-config/.gitignore.template \
      obsidian/.config/obsidian/custom-config/
   # Edit as needed
   ```

3. **Use with obsidian-vault-init**
   - Edit the script to recognize your custom type
   - Or use `personal` type and manually customize

### Modifying Folder Structures

Edit the `obsidian-vault-init` script around line 160+ to customize folder structures for each vault type.

### Changing Default Vault Location

Set the `DEFAULT_VAULTS_DIR` environment variable:

```bash
# In ~/.zshrc or ~/.bashrc
export DEFAULT_VAULTS_DIR="$HOME/Vaults"
```

## Tips and Best Practices

### Vault Separation

- **Personal vault**: Truly personal notes, journal, life planning
- **Work vault**: Work notes that belong to company (assume they can see it)
- **Public vault**: Knowledge you want to share, blog posts, tutorials
- **Projects vault**: Personal project planning and technical notes

### .gitignore Patterns

Customize your vault's `.gitignore` based on privacy needs:

```gitignore
# Personal vault - exclude sensitive folders
Private/
Financial/
Health/
Journal/Private/
*.secret.md

# Work vault - exclude confidential content
Confidential/
HR/
Legal/
Clients/SensitiveClient/

# Public vault - minimal ignores, meant to share
Drafts/  # Keep drafts private until ready
```

### Workspace Files

Never commit `workspace.json` or `workspace-mobile.json`:
- They're machine-specific (window positions, tab layouts)
- They change constantly
- They cause git conflicts
- Already excluded in .gitignore templates

### Plugin Management

**Community plugins:**
1. Install plugins in one vault
2. Copy `community-plugins.json` to shared-config if wanted globally
3. Run `obsidian-sync-config` to apply to all vaults

**Plugin settings:**
- Be selective about which plugin settings to share
- Some plugins have machine-specific paths
- Keep plugin data.json files vault-specific unless needed globally

### Themes

Your custom Omarchy theme is in `shared-config/themes/`. To add more:

```bash
# Download theme to any vault
# Then copy to shared-config
cp ~/Documents/vault-personal/.obsidian/themes/NewTheme \
   ~/dotfiles/obsidian/.config/obsidian/shared-config/themes/

# Sync to all vaults
obsidian-sync-config
```

## Troubleshooting

### Scripts not found after stowing

```bash
# Verify stow created symlinks
ls -la ~/.local/bin/obsidian-*

# If not, restow
cd ~/dotfiles
stow -R obsidian
```

### Can't push to git remote

```bash
# Check if remote is configured
cd ~/Documents/vault-personal
git remote -v

# Add remote if missing
git remote add origin git@github.com:you/repo.git

# Push with upstream
git push -u origin main
```

### Config not syncing

```bash
# Verify dotfiles location
echo $DOTFILES_DIR  # Should be $HOME/dotfiles

# Set if needed
export DOTFILES_DIR="$HOME/dotfiles"

# Run sync with verbose output
obsidian-sync-config ~/Documents/vault-personal
```

### Vault type detection wrong

The `obsidian-sync-config` script detects type from folder name. If detection is wrong:
- Rename vault to include type keyword (vault-personal, vault-work, etc.)
- Or modify detection logic in script

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Overall dotfiles documentation
- [Obsidian Documentation](https://help.obsidian.md/)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/)

## Support

For issues or questions:
1. Check this README
2. Check script help: `obsidian-vault-init --help`
3. Refer to main [CLAUDE.md](../CLAUDE.md)
