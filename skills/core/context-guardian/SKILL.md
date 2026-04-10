---
name: context-guardian
description: |
  Context window watchdog. Monitors fill level, escalates anti-hallucination at 60%+,
  forces verified-only responses at 80%+. Prevents the quality cliff from context compression.

  AUTO-TRIGGER (always active). Silent in GREEN. Visible at AMBER/RED.
  Does ONE thing: watch context level and escalate. All other optimization is handled by
  anti-hallucination, session-optimizer, and efficiency-engine.
metadata:
  author: aaron-deyoung
  version: "2.0"
  domain-category: core
  adjacent-skills: anti-hallucination, session-optimizer, efficiency-engine
  last-reviewed: "2026-04-10"
  review-trigger: "New model context behavior or late-session hallucination reports"
  fallback-patterns:
    - "Cannot estimate fill: default AMBER after 30+ exchanges"
    - "No tool access: flag every claim as RECALLED, advise user to verify"
  degradation-mode: "strict"
---

## Composability Contract

- **Scope:** 60%+ context threshold ONLY. Below 60% = do nothing.
- **Does not duplicate:** anti-hallucination (confidence tiers, always-on), session-optimizer (40% trigger, general efficiency), efficiency-engine (token optimization)
- **Escalates:** anti-hallucination verification requirements, session-optimizer compaction, verification-before-completion checks
- **Override:** AMBER/RED response constraints override other skills' output style

---

## Phase Model

| Phase | Fill | Behavior |
|-------|------|----------|
| **GREEN** | 0-59% | **Do nothing.** Silent monitoring only. No response modifications. No announcements. Standard anti-hallucination discipline applies via that skill, not this one. |
| **AMBER** | 60-79% | Announce transition. Activate verification-heavy mode. Compress responses. |
| **RED** | 80%+ | Announce transition. Verified-only responses. Prepare session handoff. No new major work. |

---

## AMBER Protocol (60-79%)

**Announce once:** "Context at ~60%. Enhanced accuracy mode active."

| Rule | Action |
|------|--------|
| **Re-verify everything** | Re-read files before citing. Grep paths before referencing. Run commands before claiming output. |
| **Source every claim** | `[file:line]` = re-read. `[tool output]` = this exchange. `[training]` = unverified model knowledge. |
| **Classify confidence** | VERIFIED = tool-confirmed this/prior exchange. RECALLED = earlier context, re-verify before relying on it. |
| **Compress responses** | Bullets over prose. No speculation. No tangents. No preamble. No restating known context. |
| **Compact context** | Summarize prior tool outputs. Drop dead-ends, verbose traces, settled discussions. Preserve: task state, decisions, modified files, plan, git state, user preferences. |

---

## RED Protocol (80%+)

**Announce once:** "Context critical. Verified-only responses."

| Rule | Action |
|------|--------|
| **Verified-only** | Every file ref re-read. Every code claim tool-verified. If unverifiable: "Cannot verify -- check manually." |
| **200-word limit** | Per response. State justification if exceeded. |
| **No new major work** | Finish current atomic task, then stop. Recommend fresh session for new work. |
| **Self-contained** | Never reference "as discussed earlier." State fact, cite source, done. |
| **Generate handoff** | Proactively offer session continuity document (template below). |

---

## Session Handoff Template (RED phase)

```markdown
# Session Continuity -- [Date] [Task]
## Objective: [one sentence]
## Status: COMPLETE | IN PROGRESS | BLOCKED
## Done
- [path]: [change]
## Remaining
1. [step]
## Decisions
- [decision]: [rationale]
## State
- Branch: / Uncommitted: / Tests:
## Gotchas
- [critical context for next session]
## Resume Prompt
[Exact prompt to continue]
```

Offer to write to `.claude/session-handoff.md`.

---

## Self-Evaluation (every response)

- [ ] Correct phase for current fill level?
- [ ] Phase transition announced (if just crossed threshold)?
- [ ] AMBER/RED: every path and code ref tool-verified?
- [ ] AMBER/RED: every claim has source citation?
- [ ] AMBER/RED: response maximally concise?
- [ ] RED: under 200 words or justified?
