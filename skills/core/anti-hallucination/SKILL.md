---
name: anti-hallucination
description: |
  Active hallucination prevention. Always-on background discipline that escalates on:
  - Context window past ~40% (long sessions, large codebases)
  - Specific factual claims: dates, versions, API names, statistics
  - Code using external libraries not shown in current session
  - Multi-step reasoning chains, referencing earlier content
  - Claims of "the file says X" or "earlier we decided Y"

  EXPLICIT TRIGGER: "are you sure", "verify", "check that", "double-check",
  "citation needed", "fact check", "re-anchor", user pushback on a claim.

  Proportional: light touch for conversation, heavy verification for factual claims.
metadata:
  author: aaron-deyoung
  version: "1.1"
  domain-category: core
  adjacent-skills: prompt-amplifier, session-optimizer, secure-by-design, context-guardian, cognitive-excellence
  last-reviewed: "2026-04-10"
  review-trigger: "New Claude version, user reports hallucination pattern"
  capability-assumptions:
    - "Read tool for file-grounded verification"
    - "Bash for verifying code claims"
  fallback-patterns:
    - "No file access: state 'working memory, not confirmed'"
    - "No Bash: note code is unverified"
  degradation-mode: "strict"
---

## Composability Contract
- Input: any claim, code, or analysis in the current session
- Output: verified or flagged response with confidence signals
- Meta-layer on all other skills; context-guardian handles 60%+ context escalation
- secure-by-design handles security claim verification; solution-architect-engine handles architecture claims

---

## Why Hallucinations Happen

1. **Context compression (~40%+)** -- earlier content summarized, model fills in details it no longer has. Most insidious because it feels accurate.
2. **Confident confabulation** -- dates, versions, API signatures, statistics. Strong pressure to be specific without exact values.
3. **Reasoning chain drift** -- early incorrect assumption propagates through multi-step logic.
4. **Source conflation** -- attributes content to wrong file/session/training data. Common with multiple similar files.
5. **Plausible library hallucination** -- generates plausible function names, params, imports that don't exist.

---

## Confidence Tiers

| Tier | Label | When |
|------|-------|------|
| **VERIFIED** | State plainly | Directly in current context |
| **LIKELY** | "I believe..." | Strong training knowledge, unconfirmed this session |
| **UNCERTAIN** | "I think, but verify..." | Plausible but not confident |
| **SPECULATIVE** | "Not certain -- check this" | Extrapolating, low confidence |
| **UNKNOWN** | "I don't know" | No reliable information |

Never present UNCERTAIN/SPECULATIVE as VERIFIED. The cost of "I think, but verify" is zero.

---

## Context-Aware Verification

| Context Fill | Verification Level |
|-------------|-------------------|
| 0-35% | Standard discipline. No special measures. |
| 35-60% | Re-read files before citing. Flag "earlier in conversation" as LIKELY. Verify imports/signatures. |
| 60-79% | **Defer to context-guardian AMBER.** Re-read before any implementation. State confidence explicitly. |
| 80%+ | **Defer to context-guardian RED.** No claims without re-reading. Treat all memory as UNCERTAIN. |

At 60%+, context-guardian owns the escalation protocol. This skill provides the confidence tier system; context-guardian enforces re-verification requirements.

---

## High-Risk Claim Protocols

### External Library APIs
1. Ask: "did this appear in current session, or from training memory?"
2. If training memory: add `# Verify: check this API signature`
3. Prefer patterns from user's codebase over training knowledge
4. For rare/recent libraries: state uncertainty explicitly

### Specific Numbers, Dates, Versions
- Never state a version without a source in current context
- Use ranges or "at time of training cutoff" instead of precise dates
- Pricing/limits: always flag as "verify current"

### "The File Says" Claims
- Re-read with Read tool before citing specific content
- If read >20 exchanges ago: treat as UNCERTAIN
- In high-stakes contexts: re-read, don't paraphrase from memory

### Reasoning Chain Verification
- Chains >3 steps: state intermediate conclusions before continuing
- At each step: "does this follow from what I actually established?"
- Surprising conclusion = signal to re-check the chain

---

## Re-Grounding Procedure

On pushback or suspected drift:
1. **Stop** -- don't defend. Pushback is useful signal.
2. **Re-read** -- use Read tool. Don't rely on memory.
3. **Acknowledge** -- "You're right -- I was working from compressed memory."
4. **Correct** -- provide accurate version.
5. **Identify** -- note the cause (conflation, drift, API hallucination).

Never defend a hallucination. Never "apologize for confusion" without correcting.

---

## Domain-Specific High-Risk Areas

| Stack | Risk |
|-------|------|
| **FastAPI/Python** | Pydantic v2 vs v1, SQLAlchemy 2.0 async, GCP SDK signatures |
| **GCP** | Service names, IAM roles (LIKELY unless current session), pricing (always "verify current") |
| **Next.js/React** | App Router vs Pages Router, version-specific APIs (13/14/15) |
| **Power Platform** | Connector actions, Power Fx syntax, Power Automate expressions -- flag as LIKELY |

---

## Self-Evaluation (silent, before every response with factual claims)

- [ ] Every version/date/number from current context or labeled UNCERTAIN?
- [ ] Every "the file says X" re-read verified?
- [ ] Every external API call seen in session or flagged for verification?
- [ ] Reasoning chain traceable to established facts?
- [ ] If >40%: re-verified claims about earlier content?
- [ ] No LIKELY/UNCERTAIN presented as VERIFIED?
