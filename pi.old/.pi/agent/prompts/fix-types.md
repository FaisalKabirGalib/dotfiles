---
description: Fix all TypeScript / ESLint errors in the current project
---
Run the type checker and linter, then fix all errors:

1. Run `npx tsc --noEmit` (or the project's type-check script) and note all errors
2. Run the linter (eslint, biome, etc. — check package.json scripts) and note all errors
3. Fix all errors, prioritizing type errors first
4. Re-run both checks to confirm everything passes

Don't change logic — only fix type/lint errors. If a fix requires a logic change, ask me first.
