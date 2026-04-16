# Foundation AddOn -- Skills Reference

A categorized catalog of all 60+ skills shipped with the Foundation AddOn Project. Use this as a quick-lookup guide to find the right skill for any task.

---

## 1. How Skills Work

Skills are modular instruction bundles (SKILL.md files) that Claude Code loads on demand. There are three activation modes:

- **Always-on** -- Nine meta-layer skills run silently on every response. You never invoke them; they enforce quality, security, and efficiency automatically.
- **Auto-routed** -- The `adaptive-skill-orchestrator` analyzes each request and selects the optimal skill combination. Describe what you need and routing happens behind the scenes.
- **Explicit** -- Invoke a skill directly with a `/slash-command` or a trigger phrase (e.g., "write tests", "security review").

Skills are composable. The orchestrator can chain and parallelize multiple skills for a single request (e.g., `secure-by-design` + `brainstorming` running in parallel, then `TDD`, then `code-review`).

---

## 2. Cross-Platform Availability

The Foundation AddOn is designed for Claude Code but the top skills can be used across platforms via equivalent instruction files.

| Skill | Claude Code | Codex / Opencode | Cursor / Other |
|-------|-------------|-------------------|----------------|
| adaptive-skill-orchestrator | Native (auto) | AGENTS.md equivalent | Manual paste |
| anti-hallucination | Native (always-on) | AGENTS.md equivalent | Manual paste |
| prompt-amplifier | Native (always-on) | AGENTS.md equivalent | Manual paste |
| secure-by-design | Native (always-on) | AGENTS.md equivalent | Manual paste |
| context-guardian | Native (always-on) | AGENTS.md equivalent | Manual paste |
| efficiency-engine | Native (always-on) | AGENTS.md equivalent | Manual paste |
| code-review | `/code-review` | AGENTS.md equivalent | Manual paste |
| testing-strategy | Trigger phrase | AGENTS.md equivalent | Manual paste |
| systematic-debugging | Trigger phrase | AGENTS.md equivalent | Manual paste |
| brainstorming | Trigger phrase | AGENTS.md equivalent | Manual paste |
| writing-plans | Trigger phrase | AGENTS.md equivalent | Manual paste |
| test-driven-development | Trigger phrase | AGENTS.md equivalent | Manual paste |
| skill-builder | `/skill-builder` | Run manually | Run manually |
| notebooklm | `/notebooklm` | Run manually | Run manually |
| parallel-execution-strategist | Trigger phrase | Run manually | N/A |

All other skills: native in Claude Code, run manually elsewhere by pasting the SKILL.md content into your prompt or instruction file.

---

## 3. Skills by Category

### Always-On Meta-Layer

These activate silently on every response. No trigger needed.

| Skill | Purpose | Platform |
|-------|---------|----------|
| anti-hallucination | Confidence tiers (VERIFIED / LIKELY / UNCERTAIN / UNKNOWN), context drift prevention, claim verification | CC / Codex / OC |
| prompt-amplifier | 8-layer silent prompt optimization including reasoning transparency and security awareness | CC / Codex / OC |
| session-optimizer | Context window management; activates proactively at 40%+ context fill | CC |
| verification-before-completion | Evidence before claims; runs before any completion declaration | CC / Codex / OC |
| solution-architect-engine | Future-proofing checklist on every design decision (SOLID, 12-factor, scalability, ADRs) | CC / Codex / OC |
| secure-by-design | Zero-trust, least privilege, input validation on every code output | CC / Codex / OC |
| context-guardian | 60% AMBER / 80% RED watchdog with anti-hallucination escalation | CC / Codex / OC |
| efficiency-engine | Maximum information density per token, zero waste, zero quality loss | CC / Codex / OC |
| cognitive-excellence | Peak reasoning quality, synergistic skill activation, quality ratchet (never degrade) | CC / Codex / OC |

CC = Claude Code, Codex = OpenAI Codex / Opencode, OC = Other clients (Cursor, etc.)

### Core Skills -- `skills/core/`

| Skill | Purpose | Trigger | Platform |
|-------|---------|---------|----------|
| adaptive-skill-orchestrator | Auto-selects and parallelizes best skills; security and architecture gates | AUTO on every non-trivial request | CC |
| master-orchestrator | Static routing table fallback | `/master-orchestrator` | CC |
| skill-builder | Creates, audits, and improves skills (5-module pipeline) | `/skill-builder`, "create a skill" | CC |
| skill-amplifier | 8-pass optimization of any SKILL.md | `/skill-amplifier`, "optimize this skill" | CC |
| parallel-execution-strategist | Agent decomposition, fan-out patterns, worktree isolation | "parallelize", "fan out", "run agents" | CC |
| notebooklm | NotebookLM CLI -- podcasts, quizzes, slides, flashcards from any content | `/notebooklm`, "create a podcast" | CC |
| knowledge-management | Organize, retrieve, and connect knowledge across projects | "save this", "recall", "knowledge graph" | CC |
| polychronos-team | Multi-agent orchestration framework (strategic + architecture + implementation) | "polychronos", "agent team" | CC |
| portable-ai-instructions | Cross-platform AI instruction templates | "portable instructions" | CC / Codex / OC |
| project-sync | Auto-update cross-platform configs when Foundation AddOn changes | `/project-sync` | CC |

### Engineering Skills -- `skills/engineering/`

| Skill | Purpose | Trigger | Platform |
|-------|---------|---------|----------|
| code-review | Expert review: correctness, security, performance, failure handling | `/code-review`, "review this code" | CC / Codex / OC |
| testing-strategy | pytest expert: fixtures, transaction rollback, hypothesis, async | "write tests", "testing strategy" | CC / Codex / OC |
| app-security-architect | OWASP Top 10, LLM security, GCP hardening | "security review", "is this secure" | CC / Codex / OC |
| database-design | Schema design, normalization, indexing strategy | "design the database", "schema" | CC |
| docker-infrastructure | Docker best practices, multi-stage builds, compose | "docker", "containerize" | CC |
| mcp-server-builder | Build custom MCP servers and tools | "build an MCP", "custom tool" | CC |
| github-repo-optimizer | Repo health audit, Actions, Dependabot, branch protection, security | "optimize repo", "repo audit" | CC |
| bitwarden-vault | Safe credential retrieval, vault organization, session management | "bitwarden", "vault", "credentials" | CC |
| n8n-workflow-architect | n8n workflow design, automation, API integrations | "n8n", "workflow", "automate" | CC |
| data-analytics-engine | Metrics, dashboards, analytics pipelines | "analytics", "metrics", "dashboard" | CC |

### Superpowers -- `skills/superpowers/` (from obra/superpowers)

| Skill | Purpose | Trigger | Platform |
|-------|---------|---------|----------|
| brainstorming | Design approval before building | "brainstorm", "design this" | CC / Codex / OC |
| test-driven-development | Strict RED-GREEN-REFACTOR cycle | "TDD", "test first" | CC / Codex / OC |
| systematic-debugging | 4-phase root cause analysis | "debug", "why is this failing" | CC / Codex / OC |
| writing-plans | Granular implementation plans | "write a plan", "plan this" | CC / Codex / OC |
| verification-before-completion | Evidence before claims | AUTO before completion | CC / Codex / OC |

### Strategy Skills -- `skills/strategy/`

| Skill | Purpose | Trigger | Platform |
|-------|---------|---------|----------|
| business-genius | Opportunity analysis, timing, moat, solo-founder viability | "business idea", "opportunity" | CC |
| entrepreneurial-os | Founder operating system, stage-gate model | "what stage am I in", "focus" | CC |
| business-plan-architect | Business plan, pitch deck, investor memo | "business plan", "pitch" | CC |
| go-to-market-engine | ICP, channel selection, launch sequencing | "go to market", "launch", "customers" | CC |
| market-intelligence | TAM/SAM/SOM, competitive landscape | "market size", "competitors" | CC |
| pricing-strategist | Pricing model, packaging, willingness-to-pay research | "pricing", "how much to charge" | CC |
| financial-model-architect | Unit economics, runway, 3-scenario model | "financial model", "runway" | CC |
| consulting-operations | AI consulting ops, client management | "consulting", "client" | CC |
| ai-agentic-specialist | Agentic architecture, agent design patterns | "AI agents", "agentic" | CC |

### Tech Stack Skills -- `skills/tech/` (25 skills)

Framework-specific skills. Invoke by naming the technology (e.g., "build a FastAPI endpoint", "optimize this SQL").

| Skill | Domain |
|-------|--------|
| fastapi-async-postgres-architecture | FastAPI + async PostgreSQL |
| postgresql-table-design | PostgreSQL schema design |
| postgresql-performance-patterns | PostgreSQL query and index tuning |
| sql-optimization-patterns | General SQL optimization |
| nextjs-react-tailwind-shadcn | Next.js + React + Tailwind + shadcn/ui |
| tailwind-design-system | Tailwind CSS design systems |
| frontend-design | General frontend design |
| web-design-guidelines | Web design principles |
| prisma-cli | Prisma CLI operations |
| prisma-client-api | Prisma Client API usage |
| prisma-database-setup | Prisma database configuration |
| vercel-composition-patterns | Vercel composition patterns |
| vercel-react-best-practices | Vercel + React best practices |
| terraform-gcp-cloud-run | Terraform for GCP Cloud Run |
| docker-compose-production | Production Docker Compose |
| cloudflare | Cloudflare configuration |
| alembic-async-migrations | Alembic async database migrations |
| database-migration | General database migration |
| dbt-transformation-patterns | dbt transformation patterns |
| airflow-dag-patterns | Airflow DAG patterns |
| python-data-pipeline-patterns | Python data pipelines |
| pytest-async-testing-patterns | pytest async testing |
| data-quality-frameworks | Data quality frameworks |
| data-storytelling | Data storytelling and visualization |
| senior-data-engineer | Senior data engineer practices |

### gstack Skills -- `skills/gstack/` (34 skills from garrytan/gstack)

A virtual engineering team from Y Combinator CEO Garry Tan's battle-tested Claude Code setup.

**Typical sprint workflow:** `/autoplan` then `/plan-ceo-review` then `/plan-eng-review` then build then `/review` then `/cso` then `/qa` then `/ship`

| Skill | Role |
|-------|------|
| autoplan | Auto-generate implementation plan |
| plan-ceo-review | CEO reviews the plan before code |
| plan-eng-review | Eng manager locks architecture |
| plan-design-review | Designer reviews UX/UI approach |
| plan-devex-review | DevEx review for DX and tooling |
| review | Production code review -- finds real bugs |
| design-review | Design review against mockups |
| cso | Chief Security Officer -- OWASP + STRIDE audit |
| qa | QA lead with browser automation |
| qa-only | Headless QA run only |
| ship | One-command PR creation + deploy |
| land-and-deploy | Land branch + deploy to production |
| retro | Engineering retrospective |
| browse | CLI browser automation (Playwright) |
| investigate | Deep investigation agent |
| checkpoint | Save/restore work checkpoints |
| freeze / unfreeze | Lock/unlock branches for release |
| canary | Canary deployment management |
| guard | Protect critical paths |
| health | System health check |
| learn | Learn from the codebase |
| office-hours | Open Q&A mode |
| pair-agent | Pair programming agent |
| codex | Code style and conventions |
| document-release | Generate release notes |
| benchmark | Performance benchmarking |
| careful | Careful/conservative mode |
| design-consultation | Design consultation |
| design-html | HTML design generation |
| design-shotgun | Rapid design variants |
| devex-review | Developer experience review |
| setup-deploy | Configure deployment pipeline |
| connect-chrome | Connect to existing Chrome instance |

### Community Skills -- `.claude/skills/` (5 from ctx7)

| Skill | Source | Purpose |
|-------|--------|---------|
| cloud-solution-architect | Microsoft | Azure Architecture Center best practices, WAF 5-pillar review, 44 cloud design patterns |
| architecture-patterns | wshobson | Clean Architecture, Hexagonal, DDD -- tactical code structure patterns |
| security-threat-model | davila7 | Repository-grounded threat modeling with abuse paths and mitigations |
| markdown-output-optimizer | Microsoft | Analyze markdown files for output efficiency and bloat reduction |
| nowait-reasoning-optimizer | davila7 | NOWAIT technique for 27-51% reasoning token reduction in R1-style models |

---

## 4. Skill Discovery

Three ways to find the right skill:

1. **Just describe what you need.** The `adaptive-skill-orchestrator` runs on every non-trivial request and routes to the best skill(s) automatically. Say "review this for security" and it chains `secure-by-design` + `app-security-architect` + `verification-before-completion`.

2. **Use trigger phrases.** Each skill responds to natural-language triggers listed in the tables above. Examples: "write tests", "debug this", "business plan", "brainstorm", "TDD".

3. **Use `/master-orchestrator` directly.** For explicit routing when you want to override auto-selection or chain a specific workflow.

4. **Browse this catalog.** Ctrl+F for your technology, domain, or problem type.

---

## 5. Adding New Skills

### Build from scratch

Use `/skill-builder` (or say "create a skill"). It runs a 5-module pipeline: needs analysis, architecture, implementation, testing, and documentation. Output is a complete SKILL.md ready to drop into `skills/`.

Use `/skill-amplifier` to take an existing SKILL.md through an 8-pass optimization.

### Install from the community

```bash
npx ctx7 skills search <keyword>       # Search the skills registry
npx ctx7 skills install /owner/repo    # Install from a GitHub repo
npx ctx7 skills generate               # AI-guided skill wizard (6/week free, 10/week Pro)
npx ctx7 skills suggest                # Auto-recommend skills for your project
```

### Skill file conventions

- One directory per skill under the appropriate tier (`skills/core/`, `skills/engineering/`, etc.)
- Each directory contains a `SKILL.md` with the full instruction set
- Slash commands are registered in `.claude/commands/` (one `.md` file per command)
- Skills should declare their trigger phrases in the SKILL.md header for orchestrator discovery
