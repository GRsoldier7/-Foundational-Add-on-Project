## Systematic Debugging

Diagnose any bug, test failure, or unexpected behavior using four phases. Never propose a fix without first establishing root cause.

## Process

### Phase 1 Investigate
Read the error message and all relevant context before forming any hypothesis. Reproduce the issue if possible. Identify what system boundaries are involved.

### Phase 2 Analyze
Map what the code does vs what it should do. Identify the divergence point. List all possible causes without dismissing any yet.

### Phase 3 Hypothesize
Rank causes by likelihood. State your top hypothesis with evidence. State what would prove or disprove it.

### Phase 4 Implement
Fix only the root cause. Do not fix symptoms. If three fix attempts fail, stop and question the architecture.

## Iron Law

Do not propose a fix until you have stated the root cause. Root cause means the specific line, condition, or assumption that is wrong — not a category like "async timing issue" but the precise mechanism.

## Output Format

Root Cause: specific mechanism file colon line if known
Evidence: what proves this is the cause
Fix: minimal change that addresses root cause only
Verification: exact command to confirm the fix worked

## Constraints

- Never retry a failed fix without changing the approach
- Never blame external libraries without evidence
- If you cannot determine root cause, say so explicitly
