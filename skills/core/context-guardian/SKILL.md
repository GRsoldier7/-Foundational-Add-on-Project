---
name: context-guardian
description: |
  Dedicated context window watchdog that monitors usage and dramatically escalates
  anti-hallucination countermeasures at 60%+ context fill. This is the single most
  important accuracy skill — it prevents the quality cliff that occurs when context
  fills up and the model begins confabulating from compressed memory.

  Unlike session-optimizer (general session management, triggers at 40%) and
  anti-hallucination (general confidence tiers, always-on), this skill is a
  PURPOSE-BUILT WATCHDOG targeting the 60% threshold where hallucination risk
  spikes dramatically, implementing aggressive countermeasures that the other
  skills do not.

  AUTO-TRIGGER (always active — monitors context usage continuously).
  No explicit trigger needed. This skill runs silently in GREEN phase and
  activates visibly the moment context crosses 60%.

  NEVER degrades processing quality. Full reasoning is maintained at all phases.
  The skill makes responses MORE careful and MORE concise — not less intelligent.
metadata:
  author: aaron-deyoung
  version: "1.0"
  domain-category: core
  adjacent-skills: anti-hallucination, session-optimizer, verification-before-completion, prompt-amplifier
  last-reviewed: "2026-04-10"
  review-trigger: "New Claude model with different context behavior, user reports late-session hallucination"
  capability-assumptions:
    - "Read tool required for file re-verification"
    - "Grep/Glob tools required for path and symbol verification"
    - "Bash tool useful for running verification commands"
  fallback-patterns:
    - "If unable to estimate context fill: default to AMBER behavior after 30+ exchanges"
    - "If no tool access: flag every claim as RECALLED and advise user to verify"
  degradation-mode: "strict"
---

## Composability Contract
- Input expects: continuous monitoring of context window state across all interactions
- Output produces: phase announcements, compacted context, session continuity documents, verified-only responses
- Applies to: every skill and every response as a meta-layer watchdog
- Synergizes with: anti-hallucination (escalates its protocols), session-optimizer (triggers its compaction), verification-before-completion (enforces its checks more aggressively)
- Orchestrator notes: this skill overrides response style at AMBER/RED — other skills must respect its constraints

---

## Phase Model

### Phase 1: GREEN (0-59% Context Fill)

**Status:** Normal operations.

Standard anti-hallucination discipline applies. No additional measures from this skill.
Context-guardian runs silently, monitoring fill level. No announcements to user.

**Active behavior:**
- Track context consumption patterns (large file reads, verbose tool outputs, long exchanges)
- Estimate remaining capacity for the current task
- No response modifications

---

### Phase 2: AMBER (60-79% Context Fill) — ALERT MODE

**Trigger:** Context crosses ~60% estimated fill.

**Immediate action — announce to user:**
> "Context at ~60%. Activating enhanced accuracy mode."

**Response protocol changes (ALL responses in AMBER phase):**

1. **Verification-heavy mode**
   - Re-read any file before citing its contents — never quote from memory
   - Grep/Glob to verify every file path mentioned before including it in a response
   - Never claim a function, class, variable, or import exists without tool verification
   - Run the command before claiming what it outputs

2. **Source citation on every claim**
   - Every technical claim must cite its source:
     - `[file:line]` — verified by re-reading
     - `[tool output]` — from a tool call in this exchange
     - `[training data]` — from model knowledge, flagged as unverified
   - No unsourced technical claims permitted

3. **Confidence labeling escalation**
   - **VERIFIED** — just read/ran it in this exchange or the immediately prior exchange
   - **RECALLED** — from earlier in this context window (treat as potentially compressed)
   - Every RECALLED item that matters to correctness: re-verify before relying on it
   - If re-verification is impractical, state: "I need to re-verify this — treating as uncertain"

4. **Response compression**
   - Maximum precision, minimum words
   - Bullet lists over paragraphs
   - No speculative suggestions — only verified, concrete actions
   - No restating what the user already knows
   - No preamble or pleasantries in technical responses

5. **Smart compaction — preserve critical state, drop noise**
   - Summarize prior tool outputs instead of preserving raw content
   - Drop all exploration dead-ends and abandoned approaches
   - Drop verbose error traces (keep error message + root cause only)
   - **Preserve:** task state, decisions made, file paths modified, current plan, user preferences, uncommitted work status

6. **No new speculation**
   - Do not introduce alternative approaches unless asked
   - Do not suggest "you might also want to..." tangents
   - Stay on the verified path

---

### Phase 3: RED (80%+ Context Fill) — CRITICAL MODE

**Trigger:** Context crosses ~80% estimated fill.

**Immediate action — announce to user:**
> "Context critical. Switching to minimal verified-only responses."

**Response protocol changes (ALL responses in RED phase):**

1. **Verified-only responses**
   - Only respond with directly verifiable facts
   - Every file reference: re-read it first, no exceptions
   - Every code claim: verify with tool, no exceptions
   - If unable to verify: say "I cannot verify this in the remaining context — please check manually"

2. **Strict length limit**
   - Every response under 200 words unless the task absolutely requires more
   - If more is needed, state why before exceeding the limit

3. **Session handoff preparation**
   - Proactively suggest starting a new session
   - Generate a session continuity document containing:
     - **Task state:** what was the goal, what is done, what remains
     - **Key decisions:** choices made and their rationale
     - **File paths modified:** every file touched with a one-line summary of changes
     - **Current plan:** next steps in order
     - **Blockers/gotchas:** anything the next session needs to know
     - **Commands to re-establish state:** git status, branch, uncommitted files
   - Offer to write this document to a file (e.g., `.claude/session-handoff.md`)

4. **No new major work**
   - Complete the current atomic task, then stop
   - Do not start new multi-step work in RED phase
   - If the user requests new major work: recommend a fresh session with the handoff document

5. **Maximum compaction**
   - Every response is self-contained — do not reference "as we discussed earlier"
   - State the fact, cite the source, move on

---

## Anti-Hallucination Escalation Protocol (60%+)

These checks run on EVERY response once AMBER phase activates:

### File Path Verification
Before mentioning any file path in a response:
```
1. Glob or Grep to confirm the path exists
2. If the path was "remembered" from earlier: re-verify — it may be misremembered
3. If verification fails: do NOT include the path — say "path needs verification"
```

### Code Reference Verification
Before quoting or referencing any code:
```
1. Re-read the specific lines with the Read tool
2. Never quote code from memory — the compressed version may have wrong variable names,
   wrong parameters, or wrong line numbers
3. If re-reading would consume too much context: reference by file:line only,
   do not inline the code
```

### Symbol Existence Verification
Before claiming any function, class, variable, or import exists:
```
1. Grep for the symbol name in the relevant files
2. If not found: do not claim it exists
3. If found in a different location than expected: correct the reference
```

### Claim Classification
Every technical claim in AMBER/RED gets one of:
- **VERIFIED** — confirmed by tool use in this or immediately prior exchange
- **RECALLED** — from earlier context, may be compressed/inaccurate
- **TRAINING** — from model knowledge, not confirmed in this session

Rule: never present RECALLED or TRAINING as VERIFIED.

---

## Compaction Strategy

### When AMBER activates, immediately compact:

**Drop (safe to lose):**
- Raw search results where only 1-2 results mattered
- Full file contents that were read for a single line of information
- Exploration paths that were abandoned
- Verbose error stack traces (keep message + cause)
- Repeated similar tool outputs
- Conversational back-and-forth that led to a settled decision

**Summarize (reduce but retain essence):**
- Long tool outputs → one-line summary of finding
- Multi-file reads → list of files with key takeaway per file
- Design discussions → final decision only
- Debug sessions → root cause + fix applied

**Preserve (never drop):**
- Current task objective and progress
- All decisions made and their rationale
- Every file path created or modified
- Current working plan / next steps
- User-stated preferences and constraints
- Git state: branch, uncommitted changes, recent commits
- Error patterns that are still relevant
- Anything the user explicitly asked to remember

---

## Session Continuity Document Format

When RED phase triggers, generate this for handoff:

```markdown
# Session Continuity — [Date] [Brief Task Description]

## Objective
[One sentence: what we set out to do]

## Status
[COMPLETE | IN PROGRESS | BLOCKED]

## Completed
- [File path]: [What was done]
- [File path]: [What was done]

## Remaining
1. [Next step]
2. [Next step]

## Key Decisions
- [Decision]: [Rationale]

## State
- Branch: [branch name]
- Uncommitted: [yes/no, what files]
- Tests: [passing/failing, which]

## Gotchas
- [Anything the next session must know]

## Resume Command
[Exact prompt to give Claude in the next session to pick up where this left off]
```

---

## Interaction with Adjacent Skills

| Skill | How context-guardian interacts |
|-------|------------------------------|
| **anti-hallucination** | Context-guardian escalates anti-hallucination's confidence tier requirements at 60%. In GREEN, standard tiers apply. In AMBER, RECALLED tier is treated as requiring re-verification. In RED, only VERIFIED claims are permitted. |
| **session-optimizer** | Session-optimizer handles general efficiency. Context-guardian triggers session-optimizer's compaction protocols at 60% and handoff protocols at 80%. |
| **verification-before-completion** | In AMBER/RED, verification-before-completion checks are mandatory and expanded — every file path, every test result, every claim must be tool-verified before declaring completion. |
| **prompt-amplifier** | In AMBER/RED, prompt-amplifier switches to compression mode — optimize for precision and brevity over richness. |

---

## Self-Evaluation (runs continuously)

At every response, silently assess:
- [ ] What is the estimated context fill percentage?
- [ ] Am I in the correct phase (GREEN/AMBER/RED)?
- [ ] If AMBER/RED: did I announce the phase transition to the user?
- [ ] If AMBER/RED: is every file path in my response tool-verified?
- [ ] If AMBER/RED: is every code reference freshly read, not from memory?
- [ ] If AMBER/RED: does every technical claim have a source citation?
- [ ] If AMBER/RED: is my response as concise as it can be without losing accuracy?
- [ ] If RED: is my response under 200 words (or justified if over)?
- [ ] If RED: have I offered session handoff?
- [ ] Am I maintaining full reasoning quality despite being more concise?

If any check fails: correct before sending the response.
