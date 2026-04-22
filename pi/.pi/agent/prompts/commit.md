---
description: Write a conventional commit message for staged changes
---
Look at the staged changes (`git diff --cached`) and write a conventional commit message.

Format:
```
<type>(<scope>): <short summary>

<optional body explaining WHY, not WHAT>
```

Types: feat, fix, refactor, chore, docs, style, test, perf, ci, build

Keep the subject line under 72 characters. Only include a body if the change needs explanation.
Output ONLY the commit message, nothing else.
