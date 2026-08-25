# Coding Preferences

## Style
- No comments unless asked
- Concise, minimal output
- Follow existing code conventions in the codebase

## Behavior
- Don't be preachy or verbose
- One-word answers when appropriate
- No unnecessary preamble/postamble
- Answer directly without elaboration

## Output
- Keep responses under 4 lines unless detail requested
- No introductions or conclusions
- Just give the answer or solution

## Tools
- Prefer modern CLI tools (fd, rg, bat, exa, zoxide)
- Use appropriate specialized tools for each task
- Batch independent operations in parallel

## Herdr Coordination
- When `HERDR_ENV=1`, use Herdr for a long-running server, watcher, test process, or independent coding agent when a sibling pane materially helps the task.
- Before controlling it, follow the installed `herdr` skill or run `herdr --skill`.
- Use the current workspace and working directory, parse IDs from command responses, and use `--no-focus` for background work.
- Do not control Herdr outside a Herdr pane, change focus, close user-owned panes, or stop the server unless the user explicitly asks.

## Image Attachments
- Use the active model's native image attachment support for user-provided images.
- Use Z.AI image-analysis MCP tools only when native image input is unavailable or the provider rejects the attachment.
