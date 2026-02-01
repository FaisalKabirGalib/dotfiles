---
name: code-quality
description: Expert guidance on code quality, best practices, refactoring, and maintainability. Activates when working on code improvements, reviews, or quality enhancements.
version: 1.0.0
---

# Code Quality Expert

Provide expert guidance on writing high-quality, maintainable code.

## When This Skill Activates

You're working on code quality improvements, refactoring, or ensuring best practices.

## Core Principles

1. **Simplicity**: Code should be simple and readable
2. **DRY**: Don't Repeat Yourself - eliminate duplication
3. **Single Responsibility**: Functions/classes should do one thing well
4. **Clear Naming**: Names should reveal intent
5. **Error Handling**: Graceful failure with clear messages

## Code Review Checklist

- [ ] Code is readable and self-documenting
- [ ] Functions are small and focused
- [ ] No code duplication
- [ ] Proper error handling
- [ ] Input validation
- [ ] Consistent style
- [ ] Meaningful names
- [ ] Comments explain "why", not "what"
- [ ] No hardcoded values
- [ ] Test coverage

## Refactoring Patterns

**Extract Method**: Break long functions into smaller ones
**Extract Class**: Group related behavior
**Rename Variable**: Use intention-revealing names
**Replace Magic Numbers**: Use named constants
**Simplify Conditionals**: Reduce nesting

## Common Code Smells

- Long methods (>20 lines)
- Duplicate code
- Complex conditionals
- Magic numbers
- Poor naming
- Large classes
- Feature envy
- data clumps
