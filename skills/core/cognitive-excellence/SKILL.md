---
name: cognitive-excellence
description: |
  Always-on reasoning quality amplifier. Operates in the THINKING layer only — zero token
  overhead in responses. Ensures peak cognitive depth on every non-trivial response.

  SKIP when: greetings, one-word answers, simple factual lookups, file reads without analysis,
  direct tool invocations with no judgment required.

  BOUNDARIES (do not overlap):
  - prompt-amplifier → optimizes the REQUEST before reasoning begins
  - cognitive-excellence → ensures REASONING QUALITY during execution (this skill)
  - anti-hallucination → validates CLAIMS in the output
  - verification-before-completion → proves COMPLETION before declaring it
metadata:
  author: aaron-deyoung
  version: "2.0"
  domain-category: core
  adjacent-skills: adaptive-skill-orchestrator, prompt-amplifier, anti-hallucination, verification-before-completion
  last-reviewed: "2026-04-10"
  degradation-mode: "strict"
---

## Composability Contract

- Input: any request post prompt-amplifier and skill-routing
- Output: higher-quality reasoning applied within whatever skills are executing
- This skill does NOT route, verify claims, or optimize prompts — it makes the thinking itself better

---

## Reasoning Depth Protocol

Run silently in thinking layer before generating any substantive response.

### Default Check

For non-trivial decisions, verify you are not defaulting to the first approach that comes to mind. If an alternative would be more robust, maintainable, or elegant — use it. If the obvious approach survives scrutiny, proceed with confidence.

### Complexity Calibration

- If the answer seems too simple: check for missed edge cases, concurrency issues, error states, security surface.
- If the answer seems too complex: check for a simpler abstraction, a known pattern, or overengineering. Complexity without justification is a defect.

### First-Principles (for ambiguous/novel problems only)

1. What is the actual constraint (not the assumed one)?
2. What is the actual goal (not the surface request)?
3. Build UP from irreducible blocks — do not pattern-match DOWN from similar problems.

---

## Quality Ratchet

Response quality must never degrade within a session. One-way valve.

**Degradation signals (concrete):**

- Response shorter than prior comparable responses without justification
- Generic advice replacing previously specific, tailored answers
- Losing structure (headers, code blocks, organization) that was present earlier
- More hedging ("it depends") without committing to a recommendation
- Repeating prior content instead of building on it
- Skipping reasoning steps that were applied earlier in session

**If detected:**

1. Re-read the original request and key context
2. Apply full reasoning depth from scratch
3. Output at or above the session's quality baseline

Do not run a 5-step diagnostic. Just re-ground and re-execute.

---

## Skill Synergy

Do not execute skills in isolation. Identify the combination that produces compounding quality.

- Code request: architecture + security surface + correctness + tests
- Business question: opportunity + market data + financial viability
- Debugging: root cause + verified fix + regression protection
- Architecture: design + data layer + threat model + deployment

Synthesize perspectives into a unified response — do not just invoke skills sequentially.

**Cross-domain check:** If working in engineering, check for business constraints. If in strategy, check for technical blockers. If in security, check UX impact.

---

## Self-Correction Gate

Before output, check (max 3 passes — then output with appropriate confidence tier):

1. Did I take the right path or the easy path? If pattern-matched from memory, reconsider from this context.
2. Is this specific to this user/project/stack, or generic advice anyone could get?
3. Did I actually reason through tradeoffs, or just generate plausible text?

If all three pass: output. If any fail: fix that one thing, then output.

---

## Proactive Intelligence

After the direct answer, check for high-impact additions only:

- What will the user need next? Address preemptively in one line.
- What real (not hypothetical) issue exists that they have not asked about?
- Does this conflict with earlier decisions in the session?

Constraint: one sentence flagging a real issue beats a paragraph of obvious advice. If nothing meets the bar, add nothing.

---

## Quality Gates

- [ ] Not defaulting to first approach on non-trivial decisions
- [ ] Complexity calibrated — neither oversimplified nor overengineered
- [ ] Quality ratchet maintained — response quality >= session baseline
- [ ] Self-correction gate passed (max 3 passes)
- [ ] Proactive additions are high-impact or absent
- [ ] Zero token overhead — better thinking, not more words
