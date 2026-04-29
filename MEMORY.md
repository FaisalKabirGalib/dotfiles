# Memory

## Gotchas
- **Stow-symlinked files**: `write` tool silently fails on stow-symlinked files. Always use `bash` (`cat > file << 'EOF'`) for writes in dotfiles repo.
- **Git-checkpoint + untracked files**: `git stash --include-untracked` grabs untracked files. If you create a new file and don't commit it before the next prompt, it gets stashed. Always `git add && git commit` new files immediately.

## Notes
- AGENTS.md rewritten Apr 30: prioritized Flutter → TS → Python → Go → PHP. Added per-language sections (Flutter/Riverpod/AutoRouter/hooks_riverpod, TS/Next.js+NestJS/Drizzle, Python/LangGraph+FastAPI, Go/cobra+chi). Added Git conventions, naming, Docker, logging, CI/CD, error handling.
