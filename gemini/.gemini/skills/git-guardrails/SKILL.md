---
name: git-guardrails
description: Safety checks for dangerous git operations. Use to prevent accidental data loss when using git commands.
---

# Git Guardrails

Always perform a safety check before executing potentially destructive Git commands.

## Dangerous Commands

- `git reset --hard`
- `git clean -fd`
- `git checkout .` (losing unstaged changes)
- `git push --force` (or `--force-with-lease`)

## Verification Steps

1. **Check Status**: Run `git status` to see current work.
2. **Stash First**: Suggest `git stash` before a hard reset or clean.
3. **Diff Check**: Show the diff of what will be lost.
4. **Explicit Confirmation**: Ask the user: "This will permanently delete [X]. Are you absolutely sure?"

## Automatic Behavior

If the user gives a directive that implies a destructive git command, proactively offer the safety steps above.
