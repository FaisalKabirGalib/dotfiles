---
name: grill-with-docs
description: Challenge a plan against the domain model, sharpen terminology, and update project documentation (AGENTS.md, ADRs). Use when user wants to refine a design, ensure consistency with documentation, or asks to "grill with docs".
---

# Grill With Docs

Challenge the current plan or design against the existing documentation and domain model.

## Process

1. **Review Documentation**: Read `AGENTS.md`, `CONTEXT.md`, and any ADRs (Architectural Decision Records).
2. **Terminology Check**: Ensure all names (classes, variables, events) match the project's domain glossary.
3. **Consistency Check**: Does the plan contradict any established architectural decisions?
4. **Identify Gaps**: Is there new terminology being introduced? Should it be added to the docs?
5. **Update Docs**: As decisions are made, update `AGENTS.md` or create new ADRs to record the rationale.

## Interaction

- Ask the user: "How does this plan fit into our existing domain model?"
- Point out specific contradictions: "ADR-001 says we use X for state management, but this plan suggests Y. Should we revisit the ADR?"
- Propose new terms: "We're using 'Shipment' here, but `AGENTS.md` uses 'Order'. Should we align them?"

## Goal

Prevent "software entropy" by keeping the implementation and documentation in sync.
