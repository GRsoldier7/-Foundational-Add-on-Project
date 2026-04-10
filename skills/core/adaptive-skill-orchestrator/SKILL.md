---
name: adaptive-skill-orchestrator
description: >
  Intelligent dispatch layer for the full skill library. Dynamically analyzes each request,
  selects optimal skill combination, determines parallel vs sequential execution, dispatches,
  and synthesizes results. Supersedes static master-orchestrator routing.
type: skill
version: "2.1"
trigger: AUTO — every non-trivial request, before any other skill
priority: HIGHEST
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

## Phase 1: Request Decomposition

```
1. INTENT: What outcome does the user want? (not surface task)
2. DOMAIN: Engineering | Strategy | Growth | Tech Stack | Meta
3. DECOMPOSE: Independent subtasks? → PARALLEL. Dependencies? → SEQUENTIAL.
4. COMPLEXITY: 1-2 = single skill, direct. 3 = light orchestration. 4-5 = full fan-out.
5. SECURITY GATE: Touches auth/secrets/data sensitivity? → secure-by-design REQUIRED first.
6. ARCHITECTURE GATE: Multi-service/scale/data architecture? → solution-architect-engine REQUIRED first.
7. CONTEXT CHECK: >60% → context-guardian AMBER (prefer sequential, max 2 agents).
   >80% → RED (sequential only, minimal skills, prepare handoff).
```

---

## Phase 2: Skill Selection

### Always-On (non-selectable, auto-active)

anti-hallucination, prompt-amplifier, session-optimizer, verification-before-completion,
solution-architect-engine, secure-by-design, context-guardian, efficiency-engine, cognitive-excellence

### Orchestration Layer

| Signal | Primary Skill | Companion |
| ------ | ------------- | --------- |
| Complex, multi-domain | `writing-plans` | `brainstorming` |
| Bug, failure, "why broken" | `systematic-debugging` | `app-security-architect` |
| "Write tests" | `testing-strategy` | `test-driven-development` |
| Code/security review | `code-review` | `app-security-architect` |
| Build from scratch | `brainstorming` -> `writing-plans` -> `test-driven-development` | -- |
| Skill creation | `skill-builder` + `skill-amplifier` | -- |
| Large task, many subtasks | `parallel-execution-strategist` | -- |
| NotebookLM content | `notebooklm` | -- |
| Knowledge/memory | `knowledge-management` | -- |
| Agentic system | `polychronos-team` | `parallel-execution-strategist` |

### Strategy

| Signal | Skill |
| ------ | ----- |
| Business idea/opportunity | `business-genius` + `market-intelligence` |
| Go to market/launch | `go-to-market-engine` |
| Business plan/pitch | `business-plan-architect` |
| Pricing | `pricing-strategist` |
| Financial model/runway | `financial-model-architect` |
| Consulting/clients | `consulting-operations` |
| Stage/focus | `entrepreneurial-os` |
| AI agents/agentic | `ai-agentic-specialist` |

### Growth

| Signal | Skill |
| ------ | ----- |
| Landing page/copy/ads | `copywriting-conversion` |
| LinkedIn/brand | `personal-brand-builder` |
| Content/SEO/newsletter | `content-marketing-machine` |
| Viral/PLG/referral | `growth-hacking-engine` |
| Social media | `social-media-architect` |
| Sales/deals | `sales-closer` |
| Community/Discord | `community-builder` |
| Marketing strategy | `marketing-strategist` |

### Engineering

| Signal | Skill |
| ------ | ----- |
| Docker/containers | `docker-infrastructure` / `docker-compose-production` |
| Database schema | `database-design` |
| PostgreSQL/performance | `postgresql-performance-patterns` + `postgresql-table-design` |
| FastAPI/async | `fastapi-async-postgres-architecture` |
| n8n/workflow | `n8n-workflow-architect` |
| MCP server | `mcp-server-builder` |
| Data pipeline/ETL | `python-data-pipeline-patterns` |
| Analytics/metrics | `data-analytics-engine` + `data-storytelling` |
| SQL optimization | `sql-optimization-patterns` |
| DB migration | `database-migration` + `alembic-async-migrations` |
| dbt | `dbt-transformation-patterns` |
| Data quality | `data-quality-frameworks` |
| Airflow/DAG | `airflow-dag-patterns` |

### Tech Stack

| Signal | Skill |
| ------ | ----- |
| Next.js/React/TypeScript | `nextjs-react-tailwind-shadcn` |
| Tailwind/design system | `tailwind-design-system` |
| Vercel | `vercel-react-best-practices` + `vercel-composition-patterns` |
| Prisma | `prisma-database-setup` + `prisma-client-api` + `prisma-cli` |
| Terraform/GCP | `terraform-gcp-cloud-run` |
| Cloudflare | `cloudflare` |
| Frontend/UI | `frontend-design` + `web-design-guidelines` |
| Design polish | `design-polish`, `animate`, `theme-factory` |
| pytest/async | `pytest-async-testing-patterns` |

---

## Phase 3: Parallelization

**ALWAYS parallel:** research + planning, independent analyses (security + performance + testing), market + competitive + financial, code review + security review.

**NEVER parallel:** brainstorming -> plans -> implementation, debugging phases, TDD red -> green -> refactor, prompt-amplifier -> execution.

**CONTEXT-AWARE:**
- AMBER (>60%): prefer sequential, max 2 parallel agents, consult efficiency-engine first
- RED (>80%): sequential only, minimal skills, prepare handoff via context-guardian

### Fan-Out (complexity >= 4)

```
ORCHESTRATOR
  |- Agent A: [skill-1] -> [subtask-1]
  |- Agent B: [skill-2] -> [subtask-2]  <- parallel
  |- Agent C: [skill-3] -> [subtask-3]  <- parallel
  +- SYNTHESIS: merge outputs -> final response
```

---

## Phase 4: Self-Optimization

After orchestration: record user pushback (routing mismatch), skill rework (substitution candidate), parallel vs sequential accuracy, first-pass VERIFIED output (boost priority). Persist to knowledge-management.

---

## Phase 5: Synthesis

1. **Deduplicate** redundant recommendations across skill outputs
2. **Resolve conflicts** using anti-hallucination tiers: verified > likely > uncertain
3. **Layer** strategy (context) + engineering (implementation) + growth (distribution)
4. **Single voice** -- one coherent response, not stitched skill outputs
5. **Verify** via verification-before-completion before presenting

---

## Failure Modes

- **Over-orchestration:** Complexity < 2 = skip orchestration, answer directly.
- **Wrong skill:** Re-run Phase 1 with better INTENT extraction. Ask one clarifying question.
- **Incoherent synthesis:** Re-run synthesis with explicit conflict resolution.

---

## Quality Gates

- [ ] Request decomposed before skill selection
- [ ] Security gate checked (secure-by-design added if needed)
- [ ] Architecture gate checked (solution-architect-engine if needed)
- [ ] Context level checked (efficiency-engine consulted if >60%)
- [ ] Parallelization decision explicit
- [ ] No skill selected without matching domain signal
- [ ] Synthesis pass completed
- [ ] verification-before-completion run on final output
