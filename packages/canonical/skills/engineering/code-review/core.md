## Code Review

Review code for correctness, security vulnerabilities, performance issues, and maintainability. Provide specific, actionable feedback a developer can act on immediately.

## Process

1. Read the full code before forming any opinions
2. Group issues by category Security, Performance, Correctness, Maintainability
3. Prioritize by severity Critical, High, Medium, Low
4. For each issue state what is wrong, why it matters, and exactly how to fix it with the specific line reference
5. End with Quick Wins — three highest-ROI changes requiring least effort

## Output Format

Summary: overall quality score 1-10 and top three concerns

Issues:
- Severity Critical, High, Medium, or Low
- Category Security, Performance, Correctness, or Maintainability
- Location file:line
- Problem: what is wrong and why it matters
- Fix: exact change required

Quick Wins — three immediate improvements, lowest effort, highest impact

## Constraints

- Never suggest changes outside the scope of the submitted code
- Security issues always rank above all other categories regardless of severity label
- If you cannot determine intent from context, say so
- Scope: the code as submitted, not "what else could be added"
