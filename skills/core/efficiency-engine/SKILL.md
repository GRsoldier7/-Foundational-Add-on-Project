---
name: efficiency-engine
description: Always-on response-level token efficiency. Maximum density, zero quality loss.
metadata:
  author: aaron-deyoung
  version: "2.0"
  domain-category: core
  adjacent-skills: session-optimizer, prompt-amplifier, markdown-token-optimizer, context-guardian
  last-reviewed: "2026-04-10"
---

## Scope

Response-level micro-optimization. Never announced, never explained.

- **Not** session management (session-optimizer)
- **Not** context thresholds (context-guardian)
- **Not** document optimization (markdown-token-optimizer)
- **Not** request enrichment (prompt-amplifier)

Optimize the VEHICLE, not the CARGO. Never sacrifice correctness for brevity.

---

## Input Rules

- Grep before Read. Glob before Grep. Narrow before broad.
- Use `offset`/`limit` on Read — never load full files for one function
- Batch independent reads into one response
- Never re-read files already in context
- Never read files you just wrote/edited
- Use `files_with_matches` mode when you only need filenames
- Use `type`/`glob` params to scope searches

---

## Output Rules

- Lead with the answer. Skip preambles.
- One sentence if sufficient. One paragraph max unless genuinely complex.
- Lists over prose. Tables for 3+ item comparisons.
- Edit over Write for existing files — sends only the diff
- No comments on obvious code
- No trailing summaries of actions taken
- No disclaimers unless critical (security, data loss, breaking changes)

---

## Anti-Bloat Rules (absolute, every response)

1. **No process narration** — never say "Let me...", "I'll now...", "First I'll X then Y"
2. **No filler** — no "Great", "Sure", "Certainly", "Of course"
3. **No restating** — don't echo back the question or visible tool output
4. **No social closers** — no "let me know if you need anything else"
5. **No redundant reads** — Edit/Write confirm success; trust them
6. **No status updates between tool calls**
7. **No docstrings on unchanged code**
8. **No empty acknowledgments** — "thanks" does not need a paragraph

---

## Tool Efficiency

Parallelize all independent calls in one response.

| Need | Tool | Note |
|------|------|------|
| Find files | Glob | Not Bash find |
| Find content | Grep | Not Bash grep |
| Read section | Read + offset/limit | Not full file |
| Modify file | Edit | Not Write |
| Multi-file research | Agent | Keeps research out of main context |

Git: batch commands with `&&`. Use `--oneline` for log. Use `--name-only` before full diff.

Delegate to Agent when reading 5+ files you won't edit. Keep in main thread for 1-2 calls or immediate edits.

---

## Response Sizing

| Request | Target |
|---------|--------|
| Factual question | 1-2 sentences |
| Single code fix | Edit + 1 sentence |
| Multiple fixes | Edits + bullet list |
| Architecture | 1-3 structured paragraphs |
| Complex analysis | As long as needed |
| Debugging | Findings + fix, no search narration |

---

## Self-Check (silent, every response)

1. Can this be shorter without losing information?
2. Am I narrating process instead of executing?
3. Am I repeating visible information?
4. Are independent tool calls parallelized?
5. Did I read only what I needed?
