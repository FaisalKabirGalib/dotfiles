# Developer Preferences

## Identity
Full-stack developer. Primary languages: TypeScript, Go, Dart/Flutter, Python, PHP, Lua, Shell.
OS: Arch Linux. Desktop: Hyprland (Wayland) or KDE Plasma.
Shell: zsh | Editor: Neovim (LazyVim) | Multiplexer: tmux (prefix C-a)
Package manager: pacman + yay | Prefer: `rg` over grep, `fd` over find, `bat` over cat

---

## Type Safety — Non-Negotiable
Strong typing everywhere, even in dynamically-typed languages.

- **TypeScript**: strict mode, no `any`, no implicit `any`, use `unknown` + narrowing instead
- **Python**: type hints on every function signature, use `mypy` or `pyright`, `TypedDict` / `dataclass` over plain dicts, `Protocol` over duck typing
- **PHP**: declare strict types (`declare(strict_types=1)`), typed properties, return types, union types — no loose comparisons
- **Go**: already strict — use typed errors, avoid `interface{}`, use generics when appropriate
- **Dart**: sound null safety always, no `dynamic` unless truly unavoidable
- **Shell**: `set -e -u -o pipefail`, always quote variables

When a language is loose by default, make it strict explicitly. Never relax type constraints for convenience.

---

## FP & OOP Balance
Balance Functional Programming and OOP for the best mix of readability, scalability, and performance.

### Functional Programming (FP)
- **Where it shines**: Hooks, data transformations, pure utilities, complex data pipelines.
- **Monads over Null**: Prefer `Option`/`Maybe` monads over null/nullable values. Use `Either`/`Result` for error handling.
  - TypeScript: `neverthrow`, or a simple `Result<T, E>` type
  - Dart: `fpdart` (`TaskEither`, `Option`, `Either`)
  - Python: `returns` library or explicit `Result` types
- Avoid shared mutable state; prefer immutable data structures.
- Side effects should be pushed to the edges (infrastructure layer).

### Object-Oriented Programming (OOP)
- **Where it shines**: Service classes, Repository implementations, Aggregate roots, and complex Domain Models.
- Use classes to encapsulate state and behavior where identity and lifecycle matter.
- Follow **SOLID** principles strictly for class design and dependency management.

---

## Architecture

### Project Structure — Feature-Based
Always organize by feature/domain, not by type.

```
src/
  features/
    auth/
      domain/          # entities, value objects, repository interfaces
      application/     # use cases, DTOs, service classes (OOP)
      infrastructure/  # DB adapters, HTTP clients (OOP)
      presentation/    # controllers, UI components, hooks (FP)
    orders/
      domain/
      application/
      infrastructure/
      presentation/
  shared/              # utils (FP), error types, base classes
  infrastructure/      # app-wide: DB connection, HTTP server, config
```

### Domain-Driven Design (DDD)
- Entities have identity; Value Objects are equal by value.
- Repository interfaces live in domain; implementations (classes) in infrastructure.
- Use Cases orchestrate domain logic — one use case per user story.

---

## UI Development

### Business Logic / UI Separation — Always
- Zero business logic in UI components/widgets.
- UI layer only: render state, dispatch actions, handle user input.
- **Flutter**: Riverpod (providers → notifiers → UI), `fpdart` for logic, `freezed` for immutable state.
- **React/Next.js**: Zustand or TanStack Query for server state; local state for UI-only concerns.

### Styling
- Design tokens / theme system over hardcoded values.
- Responsive by default.

---

## API Development & Testing

### Testing Strategy
- **Only write tests when explicitly asked**. 
- When asked: Focus on unit testing business logic and integration testing APIs.
- No UI tests (browser/widget tests) unless specifically requested.
- Test framework: whatever is idiomatic (Go: `testing`, TS: `vitest`, Python: `pytest`, PHP: `PHPUnit`).

### OpenAPI First
- Define API contract in OpenAPI 3.x spec alongside implementation.
- Docs powered by **Scalar** (preferred over Swagger UI).
- Versioning: path-based (`/v1/`).

### API Design Rules
- RESTful resource naming: plural nouns, no verbs in paths.
- Consistent response envelope: `{ data, error, meta }`.
- Pagination: cursor-based preferred.

---

## Deployment & Infrastructure

### Docker — Always
- Every service runs in a container.
- Multi-stage Dockerfiles: build stage → minimal runtime image.
- `docker-compose.yml` for local development.

### Traefik — Preferred Reverse Proxy
- Traefik for routing, TLS termination, and service discovery.
- Label-based configuration for Docker deployments.

---

## Behaviour
- Explain what you're going to do before making large changes.
- Small focused changes — don't batch unrelated things.
- Preserve existing code style and comments when editing.
- If unsure about intent, ask rather than assume.
- Don't run `sudo`, delete files, or force-push without asking first.
- No comments in code unless explicitly asked.
- Concise responses — no preamble, no filler, no conclusions.
