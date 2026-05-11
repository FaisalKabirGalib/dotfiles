---
name: zoom-out
description: Provide a higher-level perspective on unfamiliar code or a complex system. Use when user asks "what's going on here?", "explain the big picture", or seems lost in the details.
---

# Zoom Out

Provide a high-level architectural overview of a module, feature, or the entire system.

## Process

1. **Map the landscape**: Identify the main components and their responsibilities.
2. **Trace the flow**: Describe the primary data or control flow through the system.
3. **Identify the core**: Highlight the "brain" or central logic of the area.
4. **Relate to domain**: Connect the code back to the user's domain concepts (from `AGENTS.md` or `CONTEXT.md`).
5. **Surface patterns**: Identify the design patterns and architectural style in use.

## Output Format

- **Summary**: 1-2 sentences on the primary purpose.
- **Key Components**: Bullet points of major modules/classes and what they do.
- **Primary Flow**: Sequential steps of a typical operation.
- **Architectural Style**: (e.g., Layered, Event-driven, Hexagonal).
- **Navigation Tips**: Where to find the most important logic.

## Goal

Reduce cognitive load for the user by abstracting away implementation details and highlighting the mental model.
