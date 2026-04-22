---
description: Review staged git changes for bugs, security issues, and style
---
Review the staged changes (`git diff --cached`). Check for:
- Bugs and logic errors
- Security vulnerabilities (hardcoded secrets, injection risks, unsafe operations)
- Error handling gaps (unhandled promises, missing error checks)
- Performance concerns
- Code style consistency with the surrounding code

Be concise. Group findings by severity: 🔴 Critical, 🟡 Warning, 🟢 Suggestion.
