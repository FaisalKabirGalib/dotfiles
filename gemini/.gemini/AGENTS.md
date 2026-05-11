# Global Developer Persona & Instructions

This file serves as the global system prompt for all Gemini CLI interactions. It defines my tech stack, coding standards, and project preferences.

## Identity & Tech Stack
- **Primary Languages**: Dart/Flutter (Mobile/Desktop), TypeScript (Next.js/NestJS), Python (AI/LangGraph), Go (CLI/Microservices).
- **OS**: Arch Linux + Hyprland.
- **Tools**: Neovim (LazyVim), Tmux (prefix `C-a`), Zsh.
- **CLIs**: `rg` (grep), `fd` (find), `bat` (cat), `fzf`.

## Core Mandates

### Type Safety — Non-Negotiable
- **Strict mode everywhere**: No `any`, no implicit `any`. Use `unknown` + narrowing.
- **Language-specific**: Type hints in Python, `declare(strict_types=1)` in PHP, sound null safety in Dart.
- **Constraint**: Never relax type constraints for convenience.

### Architecture & Patterns
- **FP/OOP Balance**: 
  - Use Functional Programming (hooks, data transforms) with Result types (`fpdart`, `neverthrow`).
  - Use OOP for service classes, repositories, and complex domain models (SOLID).
- **Structure**: Feature-based organization (Domain-Driven Design principles).
- **Separation**: Business logic must NEVER be in UI components/widgets.

## Language-Specific Guidelines

### Flutter (Primary)
- **State**: Riverpod (`AsyncNotifier` + `NotifierProvider`).
- **Hooks**: Prefer `HookConsumerWidget`.
- **Navigation**: AutoRouter (type-safe).
- **Storage**: Isar / Hive.
- **Immutability**: `freezed`.

### TypeScript / Backend
- **Frontend**: Next.js App Router (Server Components by default).
- **Backend**: NestJS (modular).
- **DB**: PostgreSQL + Drizzle ORM.
- **Validation**: Zod (schema-first).

### Python (AI)
- **Frameworks**: LangGraph, LangChain, or Mastra (TS).
- **API**: FastAPI + Pydantic.
- **Type Hints**: Mandatory everywhere.

### Go
- **Structure**: `cmd/`, `internal/`.
- **CLI**: cobra.
- **Errors**: Always wrap errors with context.

## Git & Workflow
- **Conventional Commits**: `feat:`, `fix:`, `refactor:`, etc.
- **Atomic Commits**: One logical change per commit.
- **Review**: Stage changes and show diff before committing.

## Subagents & Strategy
- **Parallelism**: Use parallel subagent calls for research/exploration.
- **Composition**: Prefer composition over inheritance.
- **Brevity**: Concise responses, no conversational filler.
