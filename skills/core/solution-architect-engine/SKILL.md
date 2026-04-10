---
name: solution-architect-engine
description: |
  Always-on solution architecture enforcement engine. Silently applies best-practice
  architecture principles, future-proofing discipline, and proper development methodology
  to EVERY non-trivial response — code suggestions, system designs, technology selections,
  infrastructure decisions, and API contracts.

  AUTO-TRIGGER (always active as a background discipline) on:
  - Any code suggestion, refactor, or new implementation
  - Any architecture, infrastructure, or system design discussion
  - Any technology selection or framework recommendation
  - Any database schema, API design, or data model proposal
  - Any deployment, scaling, or infrastructure-as-code decision
  - Any suggestion that will live in production and face real-world change

  EXPLICIT TRIGGER on: "architect this", "solution architecture", "future-proof",
  "will this scale", "design review", "architecture review", "ADR", "tech selection",
  "should we use X or Y", "what's the right pattern", "how should I structure this",
  "is this the right approach", "evaluate this architecture", "scalability review".

  SILENT MODE (default): Apply all architectural discipline internally. Do NOT announce
  that you are running architecture checks — just produce architecturally sound output.
  Surface warnings only when a user's request would create significant technical debt,
  vendor lock-in, or scaling dead-ends.

  VERBOSE MODE: When explicitly triggered, provide full architectural reasoning,
  tradeoff analysis, ADR format, and future-proofing assessment.

  SKIP for: trivial scripts, one-off utilities, learning exercises, prototypes explicitly
  marked as throwaway. Even then, note if a "throwaway" is heading toward production.
metadata:
  author: aaron-deyoung
  version: "1.0"
  domain-category: core
  adjacent-skills: architecture-patterns, cloud-solution-architect, app-security-architect, code-review, database-design, docker-infrastructure
  last-reviewed: "2026-04-10"
  review-trigger: "New architectural patterns emerge, cloud provider major changes, user reports architectural debt from suggestions"
  capability-assumptions:
    - "Read/Grep/Glob for codebase analysis"
    - "Bash for verifying dependency versions, running linters, checking configs"
  fallback-patterns:
    - "If no codebase access: provide principles-based guidance with explicit assumptions"
    - "If unknown stack: ask one targeted question about the runtime environment before recommending"
  degradation-mode: "strict"
---

## Composability Contract
- Input expects: any code, design, or architecture proposal in the current session
- Output produces: architecturally sound suggestions with future-proofing applied
- Applies to: every other skill as a quality layer — especially code-review, database-design, docker-infrastructure
- Synergy: architecture-patterns (structural patterns), cloud-solution-architect (cloud-specific), app-security-architect (security layer)
- Orchestrator notes: runs as a silent architectural quality gate on all output; escalates to verbose mode only on explicit trigger or when detecting high-risk decisions

---

## Core Principles (enforce on every response)

### SOLID
- **S** — Single Responsibility: each module/class/function does one thing
- **O** — Open/Closed: extend behavior without modifying existing code
- **L** — Liskov Substitution: subtypes must be substitutable for their base types
- **I** — Interface Segregation: no client should depend on methods it doesn't use
- **D** — Dependency Inversion: depend on abstractions, not concretions

### DRY, KISS, YAGNI
- **DRY** — Extract shared logic, but not prematurely (rule of three)
- **KISS** — Simplest solution that meets requirements. Complexity must justify itself.
- **YAGNI** — Don't build for hypothetical future needs. Build for current needs with extension points.

### Separation of Concerns
- Business logic never touches transport (HTTP, gRPC, CLI)
- Data access isolated behind repositories/DAOs
- Configuration separate from code
- Side effects (I/O, network, disk) pushed to boundaries

### 12-Factor App
1. **Codebase** — one repo per deployable, tracked in version control
2. **Dependencies** — explicitly declared and isolated (requirements.txt, package.json, go.mod)
3. **Config** — stored in environment variables, never in code
4. **Backing services** — treat as attached resources (DB, cache, queue = URLs)
5. **Build/release/run** — strict separation of build, release, and run stages
6. **Processes** — stateless, share-nothing. Sticky sessions = anti-pattern.
7. **Port binding** — export services via port binding
8. **Concurrency** — scale out via the process model
9. **Disposability** — fast startup, graceful shutdown, SIGTERM handling
10. **Dev/prod parity** — keep dev, staging, production as similar as possible
11. **Logs** — treat as event streams (stdout), not files
12. **Admin processes** — run as one-off processes in identical environments

---

## Future-Proofing Checklist (run mentally before every suggestion)

Before proposing any architecture, code pattern, or technology choice, silently evaluate:

```
[ ] Will this still work if traffic grows 10x? 100x?
[ ] What if we need to swap the database/queue/cache/cloud provider?
[ ] What if requirements change — how much do we rewrite vs extend?
[ ] Are we creating vendor lock-in? Is that acceptable and explicit?
[ ] Is there a simpler approach that achieves 90% of the benefit?
[ ] Does this introduce a single point of failure?
[ ] Can a new team member understand this in 15 minutes?
[ ] Will this be maintainable in 2 years when nobody remembers why it was built this way?
[ ] Are we depending on a library/service that could be abandoned?
[ ] Does this create implicit coupling that will bite us during refactoring?
```

If any check fails, either fix it before suggesting or explicitly flag the tradeoff.

---

## Scalability Patterns

### Horizontal Scaling
- Design stateless services from day one — session state in Redis/external store
- Use connection pooling (PgBouncer, HikariCP) — don't open DB connections per request
- Implement health checks and readiness probes for load balancer routing
- Plan for database read replicas before you need them (connection string abstraction)

### Caching Layers
- **L1** — In-process cache (LRU, TTL) for hot data that tolerates staleness
- **L2** — Distributed cache (Redis/Memcached) for shared state across instances
- **L3** — CDN/edge cache for static assets and API responses with proper Cache-Control
- Cache invalidation strategy defined BEFORE implementing caching
- Never cache without TTL. Never cache user-specific data without scoping.

### Event-Driven Architecture
- Use events for cross-service communication — not direct HTTP calls between services
- Event schema versioning from day one (Avro, Protobuf, or JSON Schema)
- Idempotent consumers — design for at-least-once delivery
- Dead letter queues for failed message processing
- Consider event sourcing only when audit trail is a hard requirement — it adds complexity

### Message Queues
- Use queues to decouple producers from consumers (RabbitMQ, SQS, Cloud Pub/Sub, NATS)
- Backpressure handling: what happens when the queue fills?
- Message ordering guarantees: do you need them? Most don't. If yes, partition by key.
- Poison message handling: max retries then dead letter

---

## Technology Selection Framework

When recommending any technology, evaluate against these criteria:

| Criterion | Question | Weight |
|-----------|----------|--------|
| **Maturity** | Is it past v1.0? Battle-tested in production? | High |
| **Community** | Active maintainers? >1 corporate backer? Stack Overflow/GitHub activity? | High |
| **Maintenance burden** | How much config/ops does it require? Is there a managed option? | High |
| **Lock-in risk** | Can we swap it out? Is there an abstraction layer? Open standard? | Medium |
| **Team fit** | Does the team know it? Learning curve vs. benefit? | Medium |
| **Total cost** | License + infrastructure + ops + opportunity cost of learning | Medium |
| **Integration** | Does it play well with the existing stack? | Medium |
| **Escape hatch** | If it fails or gets abandoned, what's the migration path? | High |

**Red flags:**
- Single maintainer open source with no corporate backing
- Requires proprietary protocol/format with no export path
- Pre-1.0 with breaking API changes every minor version
- Solves a problem the team doesn't actually have yet (YAGNI)
- "Hot" technology chosen for resume-driven development, not problem-fit

---

## API Design

### REST Best Practices
- Resource-oriented URLs: `/users/{id}/orders`, not `/getUserOrders`
- HTTP verbs match semantics: GET reads, POST creates, PUT replaces, PATCH updates, DELETE removes
- Consistent error response format with machine-readable error codes
- Pagination on all list endpoints from day one (cursor-based preferred over offset)
- Rate limiting with Retry-After headers
- HATEOAS only if clients will actually use it — otherwise it's dead weight

### GraphQL Best Practices
- Use only when clients genuinely need flexible queries (mobile + web with different data needs)
- Implement depth limiting and query complexity analysis to prevent abuse
- DataLoader pattern for N+1 prevention — mandatory, not optional
- Persisted queries in production to prevent arbitrary query execution

### Versioning and Backward Compatibility
- URL versioning (`/v1/`) for major breaking changes
- Additive changes (new fields, new endpoints) are NOT breaking — ship without version bump
- Never remove or rename a field without deprecation period
- Contract testing (Pact, Schemathesis) between services
- API changelog maintained alongside code

---

## Data Architecture

### Normalization vs. Denormalization
- **Start normalized** (3NF) — denormalize only when you have measured read performance problems
- Denormalization is a caching strategy — it duplicates data, so define the source of truth
- Use materialized views or CQRS read models before denormalizing tables
- Document every denormalization decision with the query pattern that justified it

### Migration Strategy
- Every schema change goes through a versioned migration (Alembic, Flyway, Prisma Migrate)
- Migrations must be reversible (up AND down) for rollback capability
- Zero-downtime migration pattern: add column (nullable) -> backfill -> add constraint -> remove old
- Never rename columns in a single migration — add new, migrate data, drop old
- Test migrations against a production-size dataset, not an empty dev database

### Backup and Recovery
- Automated backups with tested restore procedures — untested backups are not backups
- Define RPO (Recovery Point Objective) and RTO (Recovery Time Objective) before choosing a backup strategy
- Point-in-time recovery (PITR) for databases with WAL archiving
- Backup verification: automated restore-and-query test on a schedule

---

## Infrastructure as Code

- All infrastructure defined in code (Terraform, Pulumi, CDK) — no manual console changes
- State stored remotely with locking (S3 + DynamoDB, GCS + Cloud Storage)
- Modules for reusable infrastructure components
- `plan` before `apply` — always. Review the diff.
- Separate state files per environment (dev/staging/prod)
- Secrets managed via secret manager (Vault, GCP Secret Manager, AWS Secrets Manager) — never in IaC state
- Drift detection: scheduled `plan` runs to catch manual changes

---

## Observability (built-in from day one)

### Logging
- Structured logs (JSON) with consistent fields: timestamp, level, service, trace_id, message
- Log levels used correctly: ERROR = action needed, WARN = degraded but functioning, INFO = business events, DEBUG = development only
- No sensitive data in logs (PII, tokens, passwords)
- Correlation IDs propagated across service boundaries
- Log aggregation (ELK, Loki, Cloud Logging) — never rely on local log files in production

### Metrics
- RED metrics for services: Rate, Errors, Duration
- USE metrics for resources: Utilization, Saturation, Errors
- Business metrics alongside technical metrics (orders/min, signups/hour)
- Prometheus/OpenTelemetry format for portability
- Dashboards for the 3 audiences: ops (alerts), eng (debugging), business (KPIs)

### Tracing
- Distributed tracing (OpenTelemetry) across all service boundaries
- Trace context propagation via W3C Trace Context headers
- Sample rate appropriate to traffic volume (100% in dev, 1-10% in high-traffic prod)
- Trace-to-log correlation via trace_id

### Alerting
- Alert on symptoms (error rate, latency), not causes (CPU usage)
- Every alert has a runbook — if it fires at 3 AM, what do you do?
- Severity levels: P1 (revenue impact, page now), P2 (degraded, fix within hours), P3 (fix this sprint)
- Alert fatigue prevention: if an alert fires and nobody acts, delete or fix it

---

## Testing Pyramid

```
        /  E2E  \          ~5-10% — critical user journeys only
       / Integr. \         ~20-30% — API contracts, DB queries, service interactions
      /   Unit    \        ~60-70% — business logic, pure functions, edge cases
```

### Enforcement Rules
- Unit tests: fast (<100ms each), no I/O, no network, no database
- Integration tests: test real interactions (DB, HTTP, queues) with containers (testcontainers)
- E2E tests: cover critical paths only — they're slow and brittle, so keep the count low
- Every bug fix includes a regression test that fails without the fix
- Test behavior, not implementation — tests should survive refactoring
- CI pipeline fails on test failure, coverage regression, or lint errors

---

## Architecture Decision Records (ADR)

When a significant architectural choice is made, document it:

```markdown
# ADR-{NNN}: {Title}

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-{NNN}

## Context
What problem are we solving? What constraints exist?

## Decision
What did we choose and why?

## Alternatives Considered
What else did we evaluate? Why was it rejected?

## Consequences
- Positive: what gets better
- Negative: what gets harder or riskier
- Neutral: what changes but doesn't improve or degrade

## Review Date
When should we revisit this decision?
```

Trigger ADR creation for: database selection, framework selection, service architecture style,
authentication/authorization approach, hosting/cloud provider choice, build/deploy pipeline,
any decision that would take >1 week to reverse.

---

## Dependency Management

- **Minimize** — every dependency is a liability. Can you write 20 lines instead of importing a package?
- **Audit** — `npm audit`, `pip-audit`, `safety check` in CI. Block on HIGH/CRITICAL.
- **Pin versions** — exact versions in lockfiles (package-lock.json, poetry.lock, requirements.txt with ==)
- **Review updates** — Dependabot/Renovate PRs reviewed, not auto-merged
- **License compliance** — know your dependency licenses. GPL in a proprietary codebase = legal risk.
- **Transitive dependencies** — audit the tree, not just direct deps. Supply chain attacks target deep deps.
- **Vendoring** — for critical dependencies, consider vendoring to insulate from registry outages

---

## Anti-Patterns (detect and flag)

| Anti-Pattern | Detection Signal | Correction |
|-------------|-----------------|------------|
| **God class/function** | >300 lines, >5 responsibilities | Extract into focused modules |
| **Distributed monolith** | Microservices that must deploy together | Merge or properly decouple |
| **Resume-driven development** | Technology chosen for novelty, not fit | Evaluate against selection framework |
| **Premature optimization** | Optimizing without profiling data | Measure first, optimize the bottleneck |
| **Config in code** | Hardcoded URLs, ports, credentials | Extract to env vars / config service |
| **Implicit dependencies** | Services assume co-location or shared state | Make dependencies explicit and injectable |
| **Test-after (or never)** | Tests written as afterthought or skipped | TDD or at minimum test-with |
| **Log and pray** | Catching exceptions with only a log line | Handle, retry, or propagate with context |
| **Shared mutable state** | Global variables, singletons holding state | Dependency injection, explicit state passing |
| **Stringly typed** | Business concepts as raw strings everywhere | Value objects, enums, typed IDs |

---

## Self-Evaluation (run silently before every non-trivial response)

Before presenting any code, architecture, or technology suggestion:

```
[ ] Does this follow SOLID, DRY, KISS, YAGNI? If violating one, is the tradeoff justified?
[ ] Would this survive a 10x traffic increase without redesign?
[ ] Is there vendor lock-in? If yes, is it acknowledged and acceptable?
[ ] Are there single points of failure? If yes, are they documented?
[ ] Is the testing strategy clear (what level of testing, what coverage)?
[ ] Is observability built in (logging, metrics, error tracking)?
[ ] Are dependencies minimal, audited, and pinned?
[ ] Does this separate concerns (business logic / transport / data access / config)?
[ ] Could a new developer understand and modify this in 2 years?
[ ] Am I recommending this because it's the right solution, or because it's familiar?
```

If any check fails: fix it before presenting, or explicitly flag the tradeoff with the rationale.

---

## Failure Modes and Fallbacks

**Failure: Over-engineering a simple request**
Detection: User asks for a quick script and gets a full microservices architecture.
Fallback: Match solution complexity to problem complexity. A 50-line script doesn't need dependency injection, event sourcing, or Kubernetes. Apply KISS. Note if the "simple" thing is heading toward production — that changes the calculus.

**Failure: Analysis paralysis on technology selection**
Detection: Spending more time evaluating tools than it would take to build with any of them.
Fallback: If two options are close, pick the one the team already knows. Document the decision in an ADR so it can be revisited if circumstances change.

**Failure: Applying 12-factor dogmatically to non-cloud workloads**
Detection: Forcing statelessness or port binding on a desktop tool or CLI script.
Fallback: 12-factor principles are guidelines for cloud-native services. Apply the spirit (separation of config, explicit dependencies) without forcing the letter on everything.

---

## Composability

**Runs alongside (silent meta-layer):**
- `anti-hallucination` — accuracy gate
- `prompt-amplifier` — input quality gate
- `verification-before-completion` — output verification gate
- `solution-architect-engine` — architectural quality gate (this skill)

**Hands off to (when explicit deep-dive needed):**
- `architecture-patterns` — Clean Architecture, Hexagonal, DDD structural patterns
- `cloud-solution-architect` — cloud-specific design (GCP, AWS, Azure)
- `app-security-architect` — security review, OWASP, zero-trust
- `database-design` — schema design, normalization, indexing
- `docker-infrastructure` — containerization, compose, orchestration
- `code-review` — line-level code quality and correctness

**Receives from:**
- Any skill producing code or architecture — this skill wraps all output as a quality layer
- `adaptive-skill-orchestrator` — routed here for architecture-heavy requests
- `brainstorming` — validates design proposals before implementation begins
