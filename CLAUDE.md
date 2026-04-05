# Foundation AddOn — Master Instructions

## Purpose

This project is a **workspace addon** designed to be included alongside any other project in a VS Code multi-root workspace. It provides foundational AI skills, permission configurations, and MCP server recommendations that propel the companion project forward.

**How to use:** Add this folder to any `.code-workspace` file as a second root. Claude Code will resolve this CLAUDE.md alongside the companion project's instructions, giving every session access to the full skill library and permission configuration below.

---

## Skill Library

This addon ships with **16 specialist skills** organized into three tiers. Skills compose — use `master-orchestrator` routing to chain the right skills for any task.

### Always-On Meta-Layer (activate silently on every response)
- `anti-hallucination` — Confidence tiers (VERIFIED/LIKELY/UNCERTAIN/UNKNOWN), context drift prevention, re-grounding procedures
- `prompt-amplifier` — Silently optimizes every prompt before execution (silent + show modes)
- `session-optimizer` — Context window management; activates proactively at 40%+ context fill

### Core Skills (`skills/core/`)
| Skill | Purpose | Trigger |
|-------|---------|---------|
| **master-orchestrator** | Routes every request to the optimal skill chain | AUTO on every non-trivial request |
| **skill-builder** | Creates, audits, and improves skills (5-module pipeline) | `/skill-builder`, "create a skill", "audit this skill" |
| **skill-amplifier** | 8-pass optimization of any SKILL.md | `/skill-amplifier`, "optimize this skill", "amplify" |
| **anti-hallucination** | Context drift prevention, confidence tiers | ALWAYS ON |
| **prompt-amplifier** | Silent prompt optimization | ALWAYS ON |
| **session-optimizer** | Context window and session management | AUTO at 40%+ context |
| **parallel-execution-strategist** | Agent decomposition, fan-out patterns, worktree isolation | "parallelize", "fan out", "run agents" |
| **notebooklm** | NotebookLM CLI — podcasts, quizzes, slides, flashcards from any content | `/notebooklm`, "create a podcast", "generate a quiz", "flashcards" |

### Engineering Skills (`skills/engineering/`)
| Skill | Purpose | Trigger |
|-------|---------|---------|
| **code-review** | Expert code review: correctness, security, performance, failure handling | `/code-review`, "review this code", "check for bugs" |
| **testing-strategy** | pytest expert: fixtures, transaction-rollback, hypothesis, async | "write tests", "testing strategy", "how to test" |
| **app-security-architect** | OWASP Top 10, LLM security, GCP hardening, security review | "security review", "is this secure", "OWASP" |

### Superpowers (`skills/superpowers/`) — from obra/superpowers
| Skill | Purpose | Trigger |
|-------|---------|---------|
| **verification-before-completion** | Evidence before claims — run commands and read output before declaring success | AUTO before any completion claim |
| **test-driven-development** | Strict RED-GREEN-REFACTOR — no production code without a failing test first | "TDD", "test first", "write tests before code" |
| **systematic-debugging** | 4-phase root cause analysis; stop after 3 failed fixes and question architecture | "debug", "why is this failing", "root cause" |
| **brainstorming** | Hard-gates implementation behind design approval; ask before building | "brainstorm", "design this", "let's think through" |
| **writing-plans** | Granular implementation plans with 2-5 min tasks, exact file paths, zero placeholders | "write a plan", "plan this", "implementation plan" |

---

## Skill Routing (How master-orchestrator works)

For every non-trivial request, the orchestrator identifies which skills apply and chains them:

```
Code change requested → brainstorming → writing-plans → TDD → code-review → verification
Bug report received  → systematic-debugging → testing-strategy → verification
New skill needed     → skill-builder → skill-amplifier → verification
Security concern     → app-security-architect → code-review
Content creation     → notebooklm (for audio/visual output)
Complex task         → parallel-execution-strategist → fan out subagents
```

---

## Permission Architecture

The `.claude/settings.json` in this project implements a three-tier permission model:

### ALLOW (auto-approved, no prompt)
- **All read operations** — Read, Glob, Grep, Agent
- **Git operations** — status, log, diff, add, commit, branch, checkout, stash, fetch, merge, rebase, tag, show, blame
- **File navigation** — ls, pwd, find, tree, cat, head, tail, wc, sort, diff, mkdir, cp, mv, touch
- **Development tools** — npm/node, python/pip/uv, ruff, pyright, pytest, docker (inspect/logs/build/run), gh CLI, terraform (plan/validate/fmt/init)
- **Web fetch** — GitHub, docs sites, package registries, NotebookLM, MCP endpoints
- **MCP servers** — filesystem, git, memory, fetch, sequential-thinking, context7, playwright
- **NotebookLM** — full CLI access for podcast/quiz/slide generation

### DENY (blocked, never allowed)
- **Privilege escalation** — sudo, chmod 777, chown
- **Destructive system ops** — rm -rf /, dd, mkfs, fdisk, shutdown, reboot, kill -9 1
- **Pipe-to-shell attacks** — curl|bash, curl|sh, wget|bash, wget|sh
- **Dangerous git** — force push to main/master
- **Dangerous infrastructure** — terraform destroy, terraform apply -auto-approve, docker system prune -a
- **Sensitive files** — .env, credentials, secrets, passwords, tokens (both read and edit)
- **Protected directories** — .git/**, /etc/**

### ASK (everything else)
All operations not explicitly allowed or denied will prompt for approval. This includes:
- `git push` (non-force)
- `rm` (non-root)
- Editing config files
- Web fetches to unlisted domains
- Any new/unfamiliar bash commands

---

## MCP Server Recommendations

See `mcp-config/recommended-servers.json` for the full configuration. Priority install order:

| Priority | Server | What It Does | API Key? |
|----------|--------|-------------|----------|
| 1 | **Context7** | Live library docs — eliminates hallucinated API syntax | No |
| 2 | **Filesystem** | Sandboxed file operations | No |
| 3 | **Git** | Native git operations | No |
| 4 | **Playwright** | Browser automation via accessibility tree | No |
| 5 | **Memory** | Persistent knowledge graph across sessions | No |
| 6 | **Fetch** | URL fetcher, HTML to markdown | No |
| 7 | **Sequential Thinking** | Structured problem-solving for hard problems | No |
| 8 | **GitHub** | PRs, issues, Actions, code search | Yes (PAT) |
| 9 | **Tavily** | AI-optimized web search | Yes (free tier) |
| 10 | **PostgreSQL** | Direct SQL execution and schema inspection | No |

Servers 1-7 require zero API keys and provide immediate value on any project.

---

## Operating Principles

1. **Verify before claiming completion.** Run the command, read the output, THEN claim success. Never declare victory without evidence.
2. **Design before building.** Use brainstorming to validate the approach before writing code. Ask clarifying questions when underspecified.
3. **Test before shipping.** No production code without a failing test first (RED-GREEN-REFACTOR).
4. **Systematic debugging only.** 4-phase root cause analysis. If 3+ fix attempts fail, stop and question the architecture.
5. **Anti-hallucination always on.** Label confidence levels. Cite sources. Never fabricate data, APIs, or function signatures.
6. **Context is precious.** Load skills on demand, not upfront. Return summaries, not raw data. Use progressive disclosure.
7. **Security by default.** Never expose secrets. Least privilege. Validate at system boundaries.
8. **Parallel when possible.** Use the parallel-execution-strategist to fan out independent work across subagents.

---

## Workspace Integration

When this project is added to a VS Code workspace alongside another project:

1. **CLAUDE.md resolution** — Claude Code reads this file alongside the companion project's CLAUDE.md, merging instructions
2. **Skills are available** — All skills in `skills/` can be invoked via the Skill tool from either project context
3. **Permissions apply** — The `.claude/settings.json` here provides baseline permissions; the companion project can layer additional rules
4. **MCP servers** — Configure recommended servers in your user or project `.mcp.json`

### Quick Setup
```json
// your-project.code-workspace
{
  "folders": [
    { "path": "./your-actual-project" },
    { "path": "./! Foundation_AddOn_Project" }
  ]
}
```
