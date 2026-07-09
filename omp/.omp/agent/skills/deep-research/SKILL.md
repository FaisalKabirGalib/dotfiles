---
name: deep-research
description: "Strategy for deep technical research using Gemini CLI delegation. Use when project requires understanding complex third-party APIs or legacy systems with poor documentation."
---

# Deep Technical Research Strategy

This skill leverages the Gemini CLI delegation to perform exhaustive documentation gathering and analysis.

## Phase 1: Mapping the Unknowns
- Identify all third-party libraries, external APIs, and internal modules that lack clear local documentation.
- Prioritize them based on their criticality to the current task.

## Phase 2: Information Gathering
- Use `web_search` with highly specific queries (e.g., "LibraryName v2.4 breaking changes", "how to implement X with Y framework").
- Collect multiple sources for the same topic to ensure accuracy.

## Phase 3: Fetching Deep Content
- Use `web_fetch` on the most promising documentation URLs.
- Ask Gemini to extract specific "How-To" patterns, type definitions, and common pitfalls.

## Phase 4: Synthesis & Application
- Consolidate the gathered information into a `KNOWLEDGE.md` or similar file in the project.
- Use this new context to guide implementation and design decisions.

**Heuristic**: If a search takes more than 3 turns to find the right info, refine your search strategy or ask the user for a specific URL.
