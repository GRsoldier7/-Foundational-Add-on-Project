---
name: solution-architect-engine
description: |
  Always-on architecture quality gate. Silently enforces SOLID, separation of concerns,
  future-proofing, and scalability on every non-trivial response. Surfaces warnings only
  for significant technical debt, vendor lock-in, or scaling dead-ends.

  AUTO-TRIGGER: any code suggestion, system design, tech selection, schema/API proposal,
  or infrastructure decision.

  EXPLICIT TRIGGER: "architect this", "solution architecture", "future-proof", "will this scale",
  "architecture review", "ADR", "tech selection", "what's the right pattern".

  SILENT MODE (default): apply discipline internally, surface warnings only for high-risk decisions.
  VERBOSE MODE: on explicit trigger — full tradeoff analysis, ADR format, future-proofing assessment.

  SKIP: trivial scripts, one-off utilities, prototypes marked throwaway. Flag if "throwaway" heads toward production.
metadata:
  author: aaron-deyoung
  version: "2.0"
  domain-category: core
  adjacent-skills: architecture-patterns, cloud-solution-architect, app-security-architect, code-review, database-design, docker-infrastructure
  last-reviewed: "2026-04-10"
  capability-assumptions:
    - "Read/Grep/Glob for codebase analysis"
    - "Bash for verifying deps, linters, configs"
  fallback-patterns:
    - "No codebase access: principles-based guidance with explicit assumptions"
    - "Unknown stack: ask one targeted question about runtime before recommending"
  degradation-mode: "strict"
---

## Composability Contract

- **Input:** any code, design, or architecture proposal
- **Output:** architecturally sound suggestions with future-proofing applied
- **Layer:** silent quality gate on all output; escalates to verbose on explicit trigger or high-risk detection
- **Synergy:** architecture-patterns (structural), cloud-solution-architect (cloud-specific), app-security-architect (security)
- **Boundary:** this skill enforces principles and flags violations. Deep-dive patterns, cloud design, schema design, and security review belong to adjacent skills — hand off, don't duplicate.

---

## Core Principles (enforce silently)

### SOLID + Fundamentals

- **Single Responsibility** — one thing per module/class/function
- **Open/Closed** — extend without modifying existing code
- **Liskov Substitution** — subtypes substitutable for base types
- **Interface Segregation** — no unused method dependencies
- **Dependency Inversion** — depend on abstractions, not concretions
- **DRY** — extract shared logic (rule of three before extracting)
- **KISS** — simplest solution that meets requirements
- **YAGNI** — build for current needs with extension points, not hypothetical futures

### Separation of Concerns
- Business logic never touches transport (HTTP, gRPC, CLI)
- Data access behind repositories/DAOs
- Config separate from code
- Side effects (I/O, network, disk) pushed to boundaries

### 12-Factor (cloud-native services only)

Dependencies explicit and isolated | Config in env vars | Backing services as attached resources | Stateless share-nothing processes | Fast startup, graceful shutdown | Logs as event streams (stdout) | Dev/prod parity

---

## Future-Proofing Gate (run mentally before every suggestion)

```
[ ] Survives 10x traffic without redesign?
[ ] Can swap DB/queue/cache/cloud provider?
[ ] Requirements change = extend, not rewrite?
[ ] Vendor lock-in explicit and accepted?
[ ] Simpler approach achieves 90% of benefit?
[ ] No single point of failure (or documented)?
[ ] New team member understands in 15 min?
[ ] Dependencies minimal and actively maintained?
```

Fail = fix before suggesting, or explicitly flag the tradeoff.

---

## Technology Selection (when recommending any technology)

| Criterion | Question | Weight |
|-----------|----------|--------|
| **Maturity** | Past v1.0? Battle-tested in production? | High |
| **Community** | Active maintainers? >1 corporate backer? | High |
| **Escape hatch** | Migration path if abandoned? | High |
| **Ops burden** | Config/ops required? Managed option available? | High |
| **Lock-in** | Abstraction layer? Open standard? | Medium |
| **Team fit** | Team knows it? Learning curve justified? | Medium |
| **Total cost** | License + infra + ops + learning | Medium |

**Red flags:** single maintainer / proprietary format with no export / pre-1.0 with breaking changes / solves a problem you don't have / resume-driven choice

---

## API Design (enforce when producing or reviewing APIs)

- Resource-oriented URLs, HTTP verbs match semantics
- Pagination on all list endpoints from day one (cursor-based preferred)
- Consistent error format with machine-readable codes
- Rate limiting with Retry-After headers
- Additive changes are NOT breaking — ship without version bump
- Never remove/rename fields without deprecation period
- Contract testing between services (Pact, Schemathesis)

---

## Scalability Patterns (apply when relevant)

- **Stateless from day one** — session state in external store
- **Connection pooling** — never open DB connections per request
- **Caching:** define invalidation strategy BEFORE caching; always use TTL; scope user-specific data
- **Events over HTTP** for cross-service communication; schema versioning from day one; idempotent consumers
- **Queues** for decoupling — define backpressure handling and poison message strategy

---

## Anti-Patterns (detect and flag)

| Anti-Pattern | Signal |
|-------------|--------|
| **God class/function** | >300 lines, >5 responsibilities |
| **Distributed monolith** | Microservices that must deploy together |
| **Resume-driven dev** | Tech chosen for novelty, not fit |
| **Premature optimization** | Optimizing without profiling data |
| **Config in code** | Hardcoded URLs, ports, credentials |
| **Implicit dependencies** | Services assume co-location or shared state |
| **Log and pray** | Catching exceptions with only a log line |
| **Stringly typed** | Business concepts as raw strings |

---

## ADR Template (verbose mode only)

Trigger for: database/framework selection, service architecture style, auth approach, hosting choice, any decision >1 week to reverse.

```markdown
# ADR-{NNN}: {Title}
## Status: Proposed | Accepted | Deprecated | Superseded by ADR-{NNN}
## Context: What problem? What constraints?
## Decision: What and why?
## Alternatives: What else evaluated? Why rejected?
## Consequences: Positive / Negative / Neutral
## Review Date: When revisit?
```

---

## Self-Evaluation (8 binary checks, run silently)

```
[ ] Follows SOLID/DRY/KISS/YAGNI? (or tradeoff justified)
[ ] Survives 10x traffic without redesign?
[ ] Vendor lock-in acknowledged if present?
[ ] No undocumented single points of failure?
[ ] Separation of concerns maintained?
[ ] Dependencies minimal, audited, pinned?
[ ] Solution complexity matches problem complexity?
[ ] Recommended because it's right, not because it's familiar?
```

---

## Failure Modes

- **Over-engineering:** match solution complexity to problem complexity. A 50-line script does not need DI, event sourcing, or K8s.
- **Analysis paralysis:** if two options are close, pick the one the team knows. Document in ADR.
- **12-factor dogma:** apply the spirit (config separation, explicit deps) to non-cloud workloads, not the letter.

---

## Composability

**Runs alongside (silent):** anti-hallucination, prompt-amplifier, verification-before-completion

**Hands off to:** architecture-patterns (Clean/Hex/DDD) | cloud-solution-architect (cloud-specific) | app-security-architect (OWASP/zero-trust) | database-design (schema/indexing) | docker-infrastructure (containers) | code-review (line-level quality)

**Receives from:** any skill producing code/architecture | adaptive-skill-orchestrator | brainstorming
