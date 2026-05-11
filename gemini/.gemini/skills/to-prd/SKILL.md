---
name: to-prd
description: Synthesize conversation context and research into a Product Requirements Document (PRD). Use when user wants to "write a PRD", "document the requirements", or "finalize the scope".
---

# To-PRD

Synthesize the current understanding of a feature or project into a structured PRD.

## Structure

1. **Problem Statement**: What are we solving? Who is it for?
2. **User Stories**: Functional requirements from the user's perspective.
3. **Technical Constraints**: Tech stack, performance needs, security requirements.
4. **Scope**: What is included and what is explicitly **out of scope**.
5. **Success Criteria**: How do we know it's done and working?
6. **Timeline/Phases**: High-level implementation plan.

## Process

- Review the entire conversation history.
- Extract key decisions and requirements.
- Identify ambiguities and ask the user for clarification before finalizing.
- Present a draft PRD for approval.
- Once approved, save to the project's documentation (e.g., `docs/PRD.md`).
