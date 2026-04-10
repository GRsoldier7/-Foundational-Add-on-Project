---
name: prompt-amplifier
description: |
  Always-on prompt optimization. Silently enhances underspecified requests before execution.

  AUTO-TRIGGER (silent) when:
  - Request is vague, underspecified, or missing critical context
  - Multi-step request without success criteria
  - Business/technical question where injecting user context would dramatically improve output
  - Any prompt where 3 sentences of context would produce 10x better result

  EXPLICIT TRIGGER: "amplify this", "optimize this prompt", "enhance my prompt",
  "help me ask this right", "prompt engineer this".

  SILENT MODE (default): apply internally, respond with improved result.
  SHOW MODE: when user wants the rewritten prompt to copy-paste elsewhere.
  SKIP: greetings, trivial questions, already-excellent prompts with role + constraints + format.
metadata:
  author: aaron-deyoung
  version: "1.1"
  domain-category: core
  adjacent-skills: polychronos-team, skill-builder, portable-ai-instructions, cognitive-excellence
  last-reviewed: "2026-04-10"
  review-trigger: "New Claude capabilities, model-specific optimization changes"
  capability-assumptions:
    - "No external tools required"
  fallback-patterns:
    - "Tools unavailable: text-based guidance"
  degradation-mode: "graceful"
---

## Composability Contract

- Input: any user prompt or skill request
- Output: enriched request producing higher-quality response
- Hands off to: polychronos-team (well-specified inputs), any domain skill
- Receives from: any user prompt, polychronos-team PM for re-specification
- cognitive-excellence handles reasoning quality; this skill handles request clarity

---

## Amplification Process

### Step 1: Analyze

Before touching anything, identify:
- **Real goal** -- outcome, not surface request
- **What's missing** -- context, constraints, audience, format, success criteria
- **What assumptions** need stating

### Step 2: Clarify (only if essential)

At most 1-2 laser-targeted questions, only when the answer fundamentally changes output.

Make smart assumptions and note them rather than interrogating. Move fast.

### Step 3: Amplify (apply relevant layers only)

| Layer | Action | Skip When |
| ----- | ------ | --------- |
| **1. Role framing** | Specific expertise persona (not generic "expert") | Role is obvious from context |
| **2. Context injection** | Domain background, constraints, stack, skill level | Already provided |
| **3. Structural scaffolding** | Sections, format, definition of "done" | Simple question |
| **4. Success criteria** | Make implicit expectations explicit | Criteria are clear |
| **5. Anti-pattern prevention** | Preempt common failure modes | Low-risk request |
| **6. Reasoning triggers** | "Think step by step", "show reasoning" | Factual lookup |

**In deep context (>60%):** apply only layers that measurably change output quality. Skip 1-3 if request is already clear. Consult efficiency-engine for token budget.

### Step 4: Format

Present as a ready-to-use prompt (SHOW MODE) or apply silently (SILENT MODE).

---

## Cross-Model Optimization

When target model is specified:
- **Claude:** Role definitions, detailed context, XML structure tags, reasoning requests
- **GPT-4:** System/user separation, few-shot examples, numbered steps
- **Gemini:** Structured data, tables, explicit output format
- **Code models:** Exact language/framework/version, imports, error handling expectations

---

## Anti-Patterns

| Anti-Pattern | Fix |
| ------------ | --- |
| Amplifying already-good prompts | Check first: does it have role + constraints + format + criteria? |
| Interrogation (5+ questions) | Max 1-2 questions; assume and note the rest |
| Amplifying without token awareness | In deep context, only layers that change output quality |
| Adding words without changing output | Ask: would a different model produce better output with this vs original? |

---

## Quality Gates

- [ ] Specific role framing (not generic "expert")
- [ ] Critical missing context injected
- [ ] Output format and success criteria explicit
- [ ] At least one anti-pattern prevention included
- [ ] Prompt length proportional to task complexity
- [ ] Clarifying questions <= 2 and decision-changing

---

## Failure Modes

**Same output quality despite longer prompt:** Diagnose which layer added signal. Strip the rest.

**Changed user's intent:** Return to original. Ask the one question that prevents misinterpretation.
