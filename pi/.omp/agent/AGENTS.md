# Developer Preferences

## Identity
Full-stack developer. Primary languages: Dart/Flutter, TypeScript, Python, Go, PHP (maintenance only).
OS: macOS (Apple Silicon, Mac Mini M2).
Shell: zsh | Editor: Neovim (LazyVim) | Multiplexer: tmux (prefix C-a)
Package manager: Homebrew | CLI: `rg` over grep, `fd` over find, `bat` over cat

### Project Split
- **Flutter** — Primary. Mobile + desktop apps.
- **TypeScript Backend** — Next.js (App Router, frontend) + NestJS (API backend). Separate services.
- **Python** — AI agent development (LangGraph, LangChain) with FastAPI endpoints. Prefer Mastra when TS is an option.
- **Go** — CLI tools and microservices.
- **PHP/Laravel** — Maintaining existing projects only. No new projects.

### Package Managers
- **JS/TS**: Bun → pnpm → npm (prefer Bun)
- **Dart**: pub
- **Python**: Poetry
- **PHP**: composer
- **Go**: go modules

---

## Type Safety — Non-Negotiable
Strong typing everywhere, even in dynamically-typed languages.

- **TypeScript**: strict mode, no `any`, no implicit `any`, use `unknown` + narrowing instead
- **Python**: type hints on every function signature, `mypy` or `pyright`, `TypedDict` / `dataclass` over plain dicts, `Protocol` over duck typing
- **PHP**: `declare(strict_types=1)`, typed properties, return types, union types — no loose comparisons
- **Go**: typed errors, avoid `interface{}`, use generics when appropriate
- **Dart**: sound null safety always, no `dynamic` unless truly unavoidable
- **Shell**: `set -e -u -o pipefail`, always quote variables

When a language is loose by default, make it strict explicitly. Never relax type constraints for convenience.

---

## FP & OOP Balance

### Functional Programming (FP)
- **Where it shines**: Hooks, data transformations, pure utilities, complex data pipelines.
- **Monads over Null**: Prefer `Option`/`Maybe` monads over null/nullable values. Use `Either`/`Result` for error handling.
  - TypeScript: `neverthrow`, or a simple `Result<T, E>` type
  - Dart: `fpdart` (`TaskEither`, `Option`, `Either`)
  - Python: `returns` library or explicit `Result` types
- Avoid shared mutable state; prefer immutable data structures.
- Side effects pushed to the edges (infrastructure layer).

### Object-Oriented Programming (OOP)
- **Where it shines**: Service classes, Repository implementations, Aggregate roots, complex Domain Models.
- Use classes to encapsulate state and behavior where identity and lifecycle matter.
- Follow **SOLID** principles strictly for class design and dependency management.

---

## Architecture

### Project Structure — Feature-Based
Always organize by feature/domain, not by type.

```
lib/                          # Flutter
  features/
    auth/
      data/            # repositories impl, data sources, DTOs
      domain/          # entities, value objects, repository interfaces
      presentation/    # screens, widgets, controllers
    orders/
      data/
      domain/
      presentation/
  shared/              # utils, error types, base classes, themes
  core/                # app-wide: DI, router, config

src/                          # TypeScript / Python / Go
  features/
    auth/
      domain/
      application/
      infrastructure/
      presentation/
  shared/
  infrastructure/
```

### Flutter
- **State Management**: Riverpod with `AsyncNotifier` + `NotifierProvider`. Class-based notifiers.
- **Hooks**: Prefer hook-based widgets (`hooks_riverpod`, `HookConsumerWidget`). `useListenable`, `useAnimationController`, `useEffect` over `initState`/`dispose`.
- **Navigation**: AutoRouter. Declarative, type-safe deep linking.
- **Local Storage**: Isar (NoSQL) / Hive. Isar for complex data, Hive for simple KV.
- **Immutable State**: `freezed` for data classes and union types.
- **Error Handling**: `fpdart` (`TaskEither`, `Option`, `Either`) for domain logic.
- **Architecture**: Feature-first. Notifiers glue domain to UI. Zero business logic in widgets.

### TypeScript Backend
- **Frontend**: Next.js App Router. Server Components by default. Client components only when needed (interactivity, hooks, browser APIs).
- **API Backend**: NestJS as separate service. Modular structure with modules/controllers/providers.
- **Database**: PostgreSQL + Drizzle ORM. Schema-first, SQL-like API, migration-driven.
- **Error Handling**: `neverthrow` for Result types. Domain layer returns `Result<T, E>`. Infrastructure throws, application layer catches and converts.
- **Validation**: Zod for runtime validation. Infer types from schemas.

### Python (AI/ML)
- **Agent Framework**: LangGraph for agent workflows, LangChain for tool chains. Prefer Mastra (TS) when appropriate.
- **API**: FastAPI for serving AI endpoints. Pydantic for validation.
- **Types**: Strict type hints everywhere. Pydantic models for API schemas.
- **Project Management**: Poetry for dependency management.

### Go
- **Project Layout**: Standard Go project layout. `cmd/`, `internal/`, `pkg/` when needed.
- **CLI**: cobra for CLI tools. pflag for flags.
- **HTTP**: chi or echo for APIs. stdlib `net/http` for simple services.
- **Error Wrapping**: Always wrap with `fmt.Errorf("doing X: %w", err)`. Use `errors.Is` / `errors.As` for checking.
- **Context**: Always pass `context.Context` as first param. Propagate cancellation.

### PHP/Laravel (Maintenance Only)
- Follow existing project conventions. Don't introduce new patterns.
- `declare(strict_types=1)` always.
- Eloquent ORM, Laravel validation rules, API resources for JSON responses.

### Domain-Driven Design (DDD)
- Entities have identity; Value Objects are equal by value.
- Repository interfaces in domain layer; implementations in data/infrastructure.
- Use cases orchestrate domain logic — one use case per user story.

---

## UI Development

### Business Logic / UI Separation — Always
- Zero business logic in UI components/widgets.
- UI layer only: render state, dispatch actions, handle user input.
- **Flutter**: Riverpod providers → AsyncNotifiers → HookConsumerWidgets. `fpdart` for logic, `freezed` for state.
- **React/Next.js**: Server Components for data fetching. Client state minimal — Zustand or React context for UI-only concerns.

### Styling
- **Flutter**: Theme system with design tokens. `ThemeData` extensions. No hardcoded colors or spacing.
- **React**: Tailwind CSS. Component-level co-location. Design tokens via `tailwind.config.ts`.
- Responsive by default.

---

## API Development

### OpenAPI First
- Define API contract in OpenAPI 3.x spec alongside implementation.
- Docs powered by **Scalar** (preferred over Swagger UI).
- Versioning: path-based (`/v1/`).

### API Design Rules
- RESTful resource naming: plural nouns, no verbs in paths.
- Consistent response envelope: `{ data, error, meta }`.
- Pagination: cursor-based preferred.

---

## Testing Strategy
- **Only write tests when explicitly asked.**
- When asked: unit test business logic, integration test APIs.
- No UI tests (browser/widget) unless specifically requested.
- Frameworks: Go `testing`, TS `vitest`, Python `pytest`, PHP `PHPUnit`, Dart `flutter_test`.

---

## Git Conventions
- **Conventional Commits**: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`, `ci:`.
- Imperative mood: "add auth module" not "added auth module".
- Scope when relevant: `feat(auth): add OAuth2 flow`.
- Small, atomic commits. One logical change per commit.
- Don't commit unless asked. Stage changes and show diff for review.

---

## Naming Conventions
Follow each language's idioms:
- **TypeScript**: camelCase variables/functions, PascalCase classes/interfaces/types, kebab-case file names.
- **Dart**: camelCase variables/functions, PascalCase classes, snake_case file names.
- **Go**: PascalCase exported, camelCase unexported, snake_case file names.
- **Python**: snake_case everything, PascalCase classes, UPPER_CASE constants.
- **PHP**: camelCase methods, PascalCase classes, snake_case file names. Follow Laravel conventions.

---

## Deployment & Infrastructure

### Docker — Always
- Every service runs in a container.
- Multi-stage Dockerfiles: build stage → minimal runtime image.
- **Base images**: Distroless where possible (`gcr.io/distroless` for Go/TS). Alpine when a shell is needed.
- `docker-compose.yml` for local development.
- Health checks on every service.

### Traefik — Preferred Reverse Proxy
- Traefik for routing, TLS termination, and service discovery.
- Label-based configuration for Docker deployments.

### Logging & Observability
- **Structured logging**: JSON format. pino (TS/NestJS), slog (Go), structlog (Python).
- Log levels: ERROR (failures), WARN (degraded), INFO (business events), DEBUG (dev only).
- Request/response logging with correlation IDs.

### CI/CD
- GitHub Actions. Lint → type-check → test → build → deploy.
- Fail fast. Run cheapest checks first.

### Secret Management
- `.env` files for local dev (never committed).
- Environment variables for secrets. No secrets in code or Docker images.
- Production: platform-native secret management (Docker secrets, cloud KMS).

---

## Error Handling Strategy
- **Domain layer**: Return `Result<T, E>` / `Either<L, R>`. Never throw.
- **Infrastructure layer**: Try-catch, wrap in domain-specific errors, return Result.
- **API layer**: Map domain errors to HTTP status codes. Consistent error response shape.
- **UI layer**: Fold over Result. Show user-friendly messages. Log technical details.
- Error types are typed domain errors, not generic strings.

---

## Subagents & Parallelism
- Prefer parallel subagent calls for any multi-step exploration or research.
- Spawn parallel scouts to explore different codebase areas simultaneously.
- Use chain mode (scout → researcher → worker) for multi-step workflows.
- Single subagent for focused one-area tasks.
- Direct read/grep/find/ls only for quick targeted lookups between subagent calls.
- NEVER explore sequentially when parallel subagents can do it faster.

## Behaviour
- Explain what you're going to do before making large changes.
- Small focused changes — don't batch unrelated things.
- Preserve existing code style and comments when editing.
- If unsure about intent, ask rather than assume.
- Don't run `sudo`, delete files, or force-push without asking first.
- No comments in code unless explicitly asked.
- Concise responses — no preamble, no filler, no conclusions.
