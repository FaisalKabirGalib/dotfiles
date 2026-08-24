# Tmux agent-status tools (2026-08-25)

**Recommendation:** for this TPM-based tmux setup, start with
[`samleeney/tmux-agent-status`](https://github.com/samleeney/tmux-agent-status).
It is the closest equivalent to Herdr awareness while retaining tmux: persistent
sidebar, status-line summary, notifications, and pane/session jumping.

```tmux
set -g @plugin 'samleeney/tmux-agent-status'
```

It tracks Claude Code and Codex with lifecycle hooks, so status transitions are
more authoritative than terminal-screen heuristics. It requires hook setup:
Codex must enable `[features] hooks = true` and have a hooks configuration.

## Candidates

| Tool | Fit and support | Trade-off |
| --- | --- | --- |
| [`tmux-agent-status`](https://github.com/samleeney/tmux-agent-status) | **Best direct TPM plugin.** Claude, Codex, and Devin hooks; custom agents via status files/extensions. Sidebar, compact status line, finish notifications, wait/park, and multi-session/pane tracking. | Hook configuration; Codex hooks are experimental upstream. |
| [`ccmux`](https://github.com/epilande/ccmux) | Broadest tmux manager: Claude, Codex, Cursor, OpenCode, Pi/OMP, Antigravity, Copilot, Gemini, custom agents; sidebar, daemon, worktrees, jump-to-attention. | Standalone CLI/TUI rather than TPM; setup installs integrations. |
| [`tmux-agent-indicator`](https://github.com/accessd/tmux-agent-indicator) | Lean feedback: `running`, `needs-input`, `done` through borders, titles, status icons, notifications; Claude/Codex hooks, OpenCode plugin, custom wrapper. TPM: `accessd/tmux-agent-indicator`. | Signals rather than a complete sidebar/dashboard. |
| [`tmux-deck`](https://github.com/takeshiD/tmux-deck) | Claude-focused tmux overview. Process detection by default, hook markers for pane state, and a background-agent view with transcript/screen previews. | Claude-centric; richer view depends on Claude background-session support. |
| [`recon`](https://github.com/gavraz/recon) | Visual Claude-only dashboard: working/input/idle/new states, session management, and a side-monitor visual view. | States are captured from Claude’s TUI/status text. |
| [`tmux-agent-sidebar`](https://github.com/y00rb/tmux-agent-sidebar) | Herdr-style cards for working/blocked/done/idle agents and jump-to-pane. | README calls TPM installation “after publishing” and names a different owner: treat as early/development. |

## “herdr / herd” clarification

The project is **[Herdr](https://herdr.dev/)**
([`motionharvest/herdr`](https://github.com/motionharvest/herdr)). It is a
replacement terminal multiplexer, not a tmux plugin. Its sidebar reports
`blocked`, `working`, `done` (unseen), and `idle`, using foreground-process and
terminal-output detection without hooks. It supports Claude Code, Codex,
OpenCode, and many others, with optional integrations for identity/state and
session restore. It can run inside tmux as the outer terminal environment, but
does not inspect tmux sessions launched within a Herdr pane. This repository
already contains a `herdr/` Stow package.

## Primary sources

- [`tmux-agent-status` README](https://github.com/samleeney/tmux-agent-status#readme): TPM installation, supported agents, sidebar/status-line features, Claude and Codex hook setup.
- [`ccmux` README](https://github.com/epilande/ccmux#readme): supported-agent setup, daemon/sidebar commands, lifecycle events.
- [`tmux-agent-indicator` README](https://github.com/accessd/tmux-agent-indicator#readme): visual state signals and integrations.
- [`tmux-deck` README](https://github.com/takeshiD/tmux-deck#claude-code-integration): markers, background-agent view, preview and hooks.
- [`recon` README](https://github.com/gavraz/recon#readme): dashboard and status detection.
- [`Herdr` README](https://github.com/motionharvest/herdr#agent-awareness) and [agent docs](https://herdr.dev/docs/agents/): states, detection, support and tmux relationship.
