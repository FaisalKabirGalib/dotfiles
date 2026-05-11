---
name: to-issues
description: Break a plan or PRD into independently-grabbable GitHub/GitLab issues. Use when user wants to "create issues", "task out the work", or "plan the sprint".
---

# To-Issues

Break down a large plan into small, actionable, and independent issues.

## Guidelines

1. **Atomic**: Each issue should represent a single logical change.
2. **Independent**: Issues should ideally not depend on each other, or dependencies should be clearly marked.
3. **Actionable**: Include clear "Definition of Done" for each issue.
4. **Context-Rich**: Reference the PRD or design document.

## Issue Template

- **Title**: Clear and concise.
- **Description**: What needs to be done.
- **DOD**: Bullet points of what must be true for the issue to be closed.
- **Tech Notes**: Specific files or patterns to use.

## Process

1. Take the approved PRD or plan.
2. Generate a list of issues.
3. Review the list with the user.
4. (Optional) Use a CLI tool (like `gh issue create`) to actually create the issues if requested.
