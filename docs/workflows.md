# Development Workflows

Common workflows using Foundation AddOn skills. Each workflow is shown in its native Claude Code form (slash commands) and its adapted form for Codex/Opencode (explicit prompts via AGENTS.md).

The workflows are identical regardless of tool. Skills make them one-command in Claude Code. In other tools, the same discipline is encoded as explicit prompts.

---

## 1. Sprint Workflow (Full Feature Cycle)

### Claude Code (native)

```
/autoplan -> /plan-ceo-review -> /plan-eng-review -> (build with TDD) -> /review -> /cso -> /qa -> /ship
```

### Codex / Opencode (via AGENTS.md)

Each slash command maps to an explicit prompt:

**Step 1 -- Plan**
```
Generate an implementation plan for [feature]. Include: goals, file changes,
dependencies, verification steps, and estimated complexity.
```

**Step 2 -- CEO Review**
```
Review this plan as a CEO. Is this the right thing to build? Does the timing
make sense? What is the opportunity cost? Kill it or greenlight it.
```

**Step 3 -- Engineering Review**
```
Review this plan as an engineering lead. Lock the architecture: tech stack
choices, data model, API contracts, failure modes. Flag anything underspecified.
```

**Step 4 -- Build with TDD**
```
Implement using strict TDD. For each unit of work:
1. Write a failing test that captures the requirement
2. Write the minimal code to make it pass
3. Refactor while keeping tests green
```

**Step 5 -- Code Review**
```
Review this code for production readiness. Check: correctness, error handling,
performance, maintainability, test coverage. Flag anything you would reject in PR review.
```

**Step 6 -- Security Audit**
```
Perform a security audit using OWASP Top 10 and STRIDE. Check: injection,
broken auth, data exposure, misconfigurations, SSRF. Provide severity ratings.
```

**Step 7 -- QA**
```
Run QA: test the golden path end-to-end, then hit edge cases, error paths,
and boundary conditions. Report pass/fail for each scenario.
```

**Step 8 -- Ship**
```
Create a PR with: summary of changes, test plan, verification evidence,
and any deployment notes.
```

---

## 2. Debug Workflow

### Claude Code (native)

```
/systematic-debugging -> (root cause) -> /test-driven-development -> (fix) -> /verification-before-completion
```

### Codex / Opencode (via AGENTS.md)

**Step 1 -- Root Cause Analysis**
```
Debug this using 4-phase root cause analysis:
1. REPRODUCE: confirm the exact failure and its conditions
2. HYPOTHESIZE: list possible causes ranked by likelihood
3. VERIFY: test each hypothesis with evidence, not guesses
4. FIX: address the root cause, not the symptom
```

**Step 2 -- Capture the Bug in a Test**
```
Write a failing test that captures this bug before fixing it. The test must
fail now and pass after the fix, proving the bug is resolved.
```

**Step 3 -- Verify the Fix**
```
Before declaring this fixed, show me the evidence:
- The failing test now passes
- The original reproduction case works correctly
- No regressions in the existing test suite
```

---

## 3. Code Review Workflow

### Claude Code (native)

```
/code-review -> /cso -> /verification-before-completion
```

### Codex / Opencode (via AGENTS.md)

**Step 1 -- Code Review**
```
Review this code for: correctness, security vulnerabilities, performance
issues, error handling gaps, and maintainability concerns. Cite specific
line numbers.
```

**Step 2 -- Security Review**
```
Perform OWASP Top 10 and STRIDE security analysis on these changes.
For each finding: describe the risk, rate severity, and suggest a fix.
```

**Step 3 -- Verification**
```
Verify all claims with evidence before marking complete. Run the tests,
show the output, confirm behavior matches expectations.
```

---

## 4. New Feature Workflow

### Claude Code (native)

```
/brainstorming -> /writing-plans -> /test-driven-development -> /ship
```

### Codex / Opencode (via AGENTS.md)

**Step 1 -- Design Exploration**
```
Before building, explore the design space. Ask clarifying questions about
requirements. Propose 2-3 approaches with trade-offs: complexity, performance,
maintainability, and time to implement.
```

**Step 2 -- Implementation Plan**
```
Write a detailed implementation plan. Include: file paths for every change,
function signatures, data model changes, and a verification checklist.
```

**Step 3 -- TDD Implementation**
```
Implement using strict TDD: write failing test, implement minimal code,
refactor. Do not skip the red-green-refactor cycle.
```

**Step 4 -- Ship**
```
Create a PR with: summary, test plan, verification evidence, and any
migration or deployment notes.
```

---

## 5. Business / Strategy Workflow

### Claude Code (native)

```
/business-genius -> /market-intelligence -> /go-to-market-engine -> /pricing-strategist -> /financial-model-architect
```

### Codex / Opencode (via AGENTS.md)

These are strategy skills. The equivalent prompts:

**Step 1 -- Opportunity Analysis**
```
Analyze this business opportunity. Cover: timing (why now?), defensibility
(what is the moat?), solo-founder viability, and key risks.
```

**Step 2 -- Market Research**
```
Research market size: TAM, SAM, SOM with sources. Map the competitive
landscape: direct competitors, substitutes, and their weaknesses.
```

**Step 3 -- Go-to-Market**
```
Design go-to-market strategy: ideal customer profile (ICP), acquisition
channels ranked by cost and scalability, and a 90-day launch sequence.
```

**Step 4 -- Pricing**
```
Recommend a pricing model and packaging. Consider: willingness to pay,
competitor pricing, value metric, and tier structure.
```

**Step 5 -- Financial Model**
```
Build a financial model: unit economics (CAC, LTV, payback period),
runway calculation, and 3 scenarios (conservative, base, optimistic).
```

---

## 6. Daily Standup / Health Check

### Claude Code (native)

```
/health
```

### Codex / Opencode (via AGENTS.md)

```
Check project health:
- All tests pass
- No lint errors
- Git status is clean (no uncommitted changes)
- Recent commits follow conventions
- No dependency vulnerabilities
```

---

## 7. Cross-Platform Sync

### Claude Code (native)

```
/project-sync
```

### Codex / Opencode

```bash
bash /path/to/Foundation_AddOn_Project/scripts/init-project.sh --update .
```

This regenerates AGENTS.md and any platform-specific instruction files from the canonical skill definitions in the Foundation AddOn.

---

## Key Principle

The workflows are the same regardless of which AI coding tool you use. Foundation AddOn skills encode best practices as one-command shortcuts in Claude Code. In Codex, Opencode, Cursor, or any other tool, the same discipline is applied through explicit prompts written into AGENTS.md.

The discipline matters more than the tool. Whether you type `/cso` or paste a security audit prompt, the outcome is the same: OWASP + STRIDE analysis before code ships. The skills just remove the friction of remembering the right prompt every time.
