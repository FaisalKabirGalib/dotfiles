# gemini — Gemini CLI Configuration

Custom agents, policies, and settings for Gemini CLI.

## Package Details

- **Type**: AI Agent Configuration
- **Target**: `~/.gemini/`
- **Dependencies**: Gemini CLI

## Features

- **Custom Subagents**: Ported from specialized dotfiles agents.
- **Policies**: Automated tool permissions and security rules.
- **Hooks**: Integration with `plannotator` for plan reviews.
- **Memory**: Global personal memory synced via `AGENTS.md`.
- **Custom Commands**: Enhanced CLI capabilities like `/start`.

## Commands

| Command | Purpose |
|---------|---------|
| `/start` | Initialize project with `AGENTS.md` (replacing `/init`) |

## Subagents

| Agent | Purpose |
|-------|---------|
| `arch-expert` | Specialized in Arch Linux and Hyprland configuration |
| `code-reviewer` | Focuses on bug detection and stylistic consistency |
| `flutter-expert` | Expertise in Flutter, Riverpod, and AutoRouter |

## Install

```bash
./stowup gemini
```
