---
name: adaptive-skill-orchestrator
description: >
  Automatically analyzes every incoming request, selects the optimal skill combination
  from the full skill library, executes them in parallel where possible, and synthesizes
  the results. Replaces manual skill routing with an intelligent, self-optimizing
  dispatch layer that continuously improves its routing decisions. Supersedes the static
  master-orchestrator routing table with dynamic, context-aware selection.
type: skill
version: "2.0"
trigger: AUTO — activates on every non-trivial request before any other skill
priority: HIGHEST — runs before all other skills
allowed-tools:
  - Agent
  - TodoWrite
  - Read
  - Glob
  - Grep
  - Bash
  - WebSearch
  - WebFetch
metadata:
  author: Foundation AddOn
  category: core/meta
  composable: true
  parallel-safe: true
---

# Adaptive Skill Orchestrator

## Purpose

This skill is the **intelligent dispatch layer** for the entire Foundation AddOn skill library. Instead of a static routing table, it dynamically analyzes each request, maps it to the optimal skill combination, determines what can run in parallel, dispatches subagents accordingly, and synthesizes results into a single coherent output.

It is the difference between a routing table that tells you which bus to take and a GPS that finds the optimal multi-modal route in real-time.

---

## Phase 1: Request Decomposition

Before selecting any skills, break the request into atomic work units:

```
REQUEST ANALYSIS PROTOCOL
─────────────────────────
1. INTENT: What is the user ultimately trying to achieve? (outcome, not task)
2. DOMAIN: Which knowledge domains does this touch?
   - Engineering (code, DB, infra, security, testing)
   - Strategy (business, GTM, market, pricing, financial)
   - Growth (marketing, copywriting, brand, sales)
   - Tech stack (specific framework or tool)
   - Meta (skill building, orchestration, planning)
3. DECOMPOSE: Can this be broken into N independent subtasks?
   - Independent = no output of task A is required as input to task B
   - If yes → PARALLEL candidate
   - If no → SEQUENTIAL chain required
4. COMPLEXITY: Rate 1-5
   - 1-2: Single skill, no orchestration needed → invoke directly
   - 3: 2-3 skills, light orchestration
   - 4-5: Full parallel fan-out with synthesis agent
5. SECURITY GATE: Does this touch auth, permissions, secrets, or data sensitivity?
   - If yes → secure-by-design REQUIRED (not optional), sequential before implementation
6. ARCHITECTURE GATE: Does this involve multi-service design, scale decisions, or data architecture?
   - If yes → solution-architect-engine REQUIRED, future-proofing checklist before code
7. CONTEXT CHECK: What is current context fill level?
   - If >60% → context-guardian AMBER mode, prefer sequential, reduce parallel agents
   - If >80% → context-guardian RED mode, minimal operations, prepare session handoff
```

---

## Phase 2: Skill Selection Matrix

### Complete Skill Registry

For each domain, evaluate candidate skills and score against the request:

**CORE META-LAYER (always-on, non-selectable)**
| Skill | Trigger |
|-------|---------|
| anti-hallucination | Every response — suppress automatically |
| prompt-amplifier | Every request — silent optimization |
| session-optimizer | Context > 40% filled |
| verification-before-completion | Before any completion claim |
| **solution-architect-engine** | Every architecture/design decision — future-proofing checklist |
| **secure-by-design** | Every code-related response — security DNA layer |
| **context-guardian** | Continuous — escalates at 60% (AMBER) and 80% (RED) |
| **efficiency-engine** | Every response — maximum information density per token |
| **cognitive-excellence** | Every non-trivial response — peak reasoning quality |

**ORCHESTRATION LAYER (this skill selects from below)**

| Domain Signal | Primary Skill | Parallel-Safe Companion |
|---------------|---------------|------------------------|
| Request is complex, multi-domain | `writing-plans` | `brainstorming` |
| Bug, failure, "why is X broken" | `systematic-debugging` | `app-security-architect` |
| "Write tests / test this" | `testing-strategy` | `test-driven-development` |
| Code to review / security check | `code-review` | `app-security-architect` |
| Need to build X from scratch | `brainstorming` → `writing-plans` → `test-driven-development` | — |
| Skill creation / optimization | `skill-builder` + `skill-amplifier` | — |
| Large complex task, many subtasks | `parallel-execution-strategist` | — |
| Content for NotebookLM (podcast, quiz) | `notebooklm` | — |
| Knowledge graph / session memory | `knowledge-management` | — |
| Cross-platform AI instruction | `portable-ai-instructions` | — |
| Agentic system design | `polychronos-team` | `parallel-execution-strategist` |

**STRATEGY (invoke when business/product context detected)**
| Signal | Skill |
|--------|-------|
| "What business / idea / opportunity" | `business-genius` + `market-intelligence` |
| "Go to market / launch / customers" | `go-to-market-engine` |
| "Business plan / pitch / investor" | `business-plan-architect` |
| "Pricing / how much to charge" | `pricing-strategist` |
| "Financial model / runway / unit economics" | `financial-model-architect` |
| "AI consulting / clients / operations" | `consulting-operations` |
| "What stage am I in / what to focus on" | `entrepreneurial-os` |
| "AI agents / agentic architecture" | `ai-agentic-specialist` |
| "TAM / competitive landscape" | `market-intelligence` |

**GROWTH (invoke when audience/marketing/brand context)**
| Signal | Skill |
|--------|-------|
| "Landing page / copy / email / ads" | `copywriting-conversion` |
| "LinkedIn / brand / thought leadership" | `personal-brand-builder` |
| "Content strategy / SEO / newsletter" | `content-marketing-machine` |
| "Viral loop / PLG / referral / growth" | `growth-hacking-engine` |
| "Social media / LinkedIn / X / YouTube" | `social-media-architect` |
| "Close deals / sales process" | `sales-closer` |
| "Community / Discord / membership" | `community-builder` |
| "Marketing strategy / positioning" | `marketing-strategist` |

**ENGINEERING (invoke when technical implementation)**
| Signal | Skill |
|--------|-------|
| "Docker / containers / compose" | `docker-infrastructure` or `docker-compose-production` |
| "Database schema / design" | `database-design` |
| "PostgreSQL / query / performance" | `postgresql-performance-patterns` + `postgresql-table-design` |
| "FastAPI / async / Python API" | `fastapi-async-postgres-architecture` |
| "n8n / workflow / automation" | `n8n-workflow-architect` |
| "MCP server / tool / custom MCP" | `mcp-server-builder` |
| "Data pipeline / ETL / Python" | `python-data-pipeline-patterns` |
| "Analytics / metrics / dashboards" | `data-analytics-engine` + `data-storytelling` |
| "SQL / query optimization" | `sql-optimization-patterns` |
| "Database migration / schema change" | `database-migration` + `alembic-async-migrations` |
| "dbt / data transform" | `dbt-transformation-patterns` |
| "Data quality / validation" | `data-quality-frameworks` |
| "Airflow / DAG / scheduling" | `airflow-dag-patterns` |

**TECH STACK (invoke when framework-specific)**
| Signal | Skill |
|--------|-------|
| "Next.js / React / TypeScript" | `nextjs-react-tailwind-shadcn` |
| "Tailwind / design system / CSS" | `tailwind-design-system` |
| "Vercel / deploy / edge" | `vercel-react-best-practices` + `vercel-composition-patterns` |
| "Prisma / ORM" | `prisma-database-setup` + `prisma-client-api` + `prisma-cli` |
| "Terraform / GCP / Cloud Run" | `terraform-gcp-cloud-run` |
| "Cloudflare / CDN / Workers" | `cloudflare` |
| "Frontend / UI design" | `frontend-design` + `web-design-guidelines` |
| "Design polish / animate / theme" | `design-polish`, `animate`, `theme-factory` |
| "pytest / async tests" | `pytest-async-testing-patterns` |
| "Data engineer / senior eng" | `senior-data-engineer` |

---

## Phase 3: Parallel Execution Decision

```
PARALLELIZATION RULES
──────────────────────
ALWAYS parallelize:
  - Research + implementation planning (one agent each)
  - Multiple independent skill analyses (security + performance + testing)
  - Market research + competitive analysis + financial modeling
  - Code review + security review (independent lenses)

NEVER parallelize (sequential only):
  - brainstorming → writing-plans → implementation (each depends on prior output)
  - systematic-debugging phases (each phase needs prior phase results)
  - TDD red → green → refactor
  - prompt-amplifier → execution (amplification must precede)

CONDITIONAL:
  - skill-builder + skill-amplifier: builder first, amplifier after (sequential)
  - but multiple skill-builder jobs are parallel-safe

CONTEXT-AWARE PARALLELIZATION:
  IF context > 60% (AMBER):
    → Prefer SEQUENTIAL over PARALLEL (parallel amplifies hallucination risk)
    → Consult efficiency-engine FIRST to optimize token usage
    → Limit to ≤2 parallel agents max
    → Reduce skill count: consolidate related work into fewer agents
  IF context > 80% (RED):
    → SEQUENTIAL ONLY — no parallel agents
    → Minimal skill selection — only what's strictly required
    → Prepare session handoff via context-guardian
```

### Fan-Out Template

When complexity ≥ 4:

```
ORCHESTRATOR (this skill)
├── Agent A: [skill-1] → handles [subtask-1]
├── Agent B: [skill-2] → handles [subtask-2]  ← parallel
├── Agent C: [skill-3] → handles [subtask-3]  ← parallel
└── SYNTHESIS AGENT: merges A+B+C outputs → final response
```

---

## Phase 4: Continuous Self-Optimization

After every orchestration run, update the routing model:

```
ROUTING FEEDBACK LOOP
──────────────────────
1. Did the user push back on the skill selection? → Record mismatch
2. Did any skill produce output that required significant rework? → Flag for substitution
3. Was a parallel run faster and just as accurate as sequential? → Update parallelization rules
4. Did a skill produce VERIFIED output on first pass? → Boost its priority for similar future requests

Persist: Save routing improvements to knowledge-management skill graph
```

---

## Phase 5: Synthesis Protocol

When multiple skills produce outputs:

1. **Deduplicate** — remove redundant recommendations across skill outputs
2. **Resolve conflicts** — if skills disagree, prefer: verified > likely > uncertain (anti-hallucination tiers)
3. **Layer** — strategy output frames the context; engineering output provides the implementation; growth output drives the distribution
4. **Single voice** — rewrite as one coherent response, not a list of skill outputs stitched together
5. **Verify** — run verification-before-completion before presenting final output
   - Flag any claims at anti-hallucination tiers UNCERTAIN or SPECULATIVE
   - Verify architectural decisions meet solution-architect-engine standards
   - Verify security decisions meet secure-by-design standards
   - Verify reasoning quality meets cognitive-excellence standards

---

## Activation Examples

### Example 1: "Help me launch my biohacking app"
```
Decompose: 3 independent domains (product, market, growth)
Select:
  ├── Agent A: market-intelligence (TAM, competitive landscape)
  ├── Agent B: go-to-market-engine (ICP, channels, launch sequence)
  └── Agent C: pricing-strategist (pricing model, tiers)
Parallelize: All 3 → synthesize into launch brief
```

### Example 2: "My FastAPI endpoint is returning 500s in production"
```
Decompose: Sequential debugging chain
Select:
  systematic-debugging (phase 1-4) →
  if security-related: app-security-architect →
  testing-strategy (add regression test) →
  verification-before-completion
Parallelize: None — each phase depends on prior
```

### Example 3: "Build me a data pipeline for video metadata"
```
Decompose: Design → implement → test → deploy (sequential stages, but design sub-tasks parallel)
Select:
  ├── brainstorming (architecture options)
  └── writing-plans (granular implementation plan)
  Then sequentially:
  python-data-pipeline-patterns → database-design → postgresql-performance-patterns →
  testing-strategy → docker-infrastructure → verification-before-completion
```

### Example 4: "Create a skill for the Foundation AddOn"
```
Decompose: Build → amplify (sequential, but research parallel)
Select:
  skill-builder (5-module pipeline) →
  skill-amplifier (8-pass optimization) →
  verification-before-completion
Parallelize: Research phase within skill-builder can fan out
```

---

## Failure Modes

**Failure: Over-orchestration of simple requests**
Detection: User asks "what does this function do?" — don't spin up 4 agents.
Fix: Complexity < 2 → skip orchestration, answer directly.

**Failure: Skill selected for wrong domain**
Detection: Output doesn't match user's implicit mental model.
Fix: Re-run Phase 1 decomposition with more careful INTENT extraction. Ask one clarifying question.

**Failure: Synthesis produces incoherent output**
Detection: Final response has contradictions or disconnected sections.
Fix: Run synthesis agent again with explicit conflict resolution instruction before responding.

---

## Quality Gates

- [ ] Request decomposed before any skill selected
- [ ] Security gate checked: if security-related, secure-by-design added?
- [ ] Architecture gate checked: if design-related, solution-architect-engine consulted?
- [ ] Context level checked: if >60%, efficiency-engine consulted before orchestration?
- [ ] Parallelization decision explicitly made (not defaulted)
- [ ] No skill selected without a matching domain signal
- [ ] Synthesis pass completed before presenting output
- [ ] verification-before-completion run on final output
- [ ] cognitive-excellence quality check passed on final output
- [ ] Routing feedback recorded for self-optimization
