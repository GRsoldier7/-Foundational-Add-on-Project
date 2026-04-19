## Writing Plans

Create a complete bite-sized implementation plan from an approved design spec. Every step must contain everything a developer needs — exact file paths, complete code, exact commands, expected output.

## Process

1. **Scope check** — confirm the spec covers one deliverable, decompose if needed
2. **Map files** — list every file to create or modify with its single responsibility
3. **Write tasks** — TDD order: write failing test, run to confirm failure, write minimal implementation, run to confirm passing, commit
4. **Self-review** — check spec coverage, placeholder scan, type consistency

## Task Structure

- Files section with exact paths to create and modify
- Failing test written first with complete test code
- Command to run the failing test and its expected output
- Minimal implementation with complete code
- Command to run the passing test and its expected output
- Git commit command with message

## Hard Rules — plan failures, never do these

- No TBD, TODO, or "implement later"
- No "add appropriate error handling" without showing the code
- No "similar to Task N" — repeat the code
- No references to types or functions not defined in any task
- No steps that describe what to do without showing how

## Output Format

Save the plan to docs/superpowers/plans/YYYY-MM-DD-feature.md. After saving, offer the user a choice of subagent-driven or inline execution.

## Constraints

- Each task equals 2-5 minutes of work
- Every step has a verification command and expected output
- Commit after every task, not after every step
