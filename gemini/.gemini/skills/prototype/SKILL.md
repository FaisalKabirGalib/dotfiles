---
name: prototype
description: Build throwaway prototypes (terminal apps or UI variations) to flush out designs. Use when user wants to "see it in action", "try out a design", or asks for a prototype.
---

# Prototype

Build a throwaway prototype to validate a design or technical approach.

## Principles

1. **Speed over quality**: Use hardcoded data, ignore edge cases, skip persistence.
2. **Focus on the core**: Only prototype the part of the system that is uncertain.
3. **Throwaway**: Explicitly mark code as throwaway. Do not integrate into the main codebase unless requested.
4. **Isolate**: Build in a separate directory or file (e.g., `prototype/`, `temp_poc.dart`).

## Workflow

1. Identify the core uncertainty (UX, API shape, performance).
2. Choose the minimal tech stack for the prototype.
3. Build the "tracer bullet" version.
4. Iterate until the design is validated or discarded.
5. Present findings to the user.
6. Delete or archive the prototype once the decision is made.
