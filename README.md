# Foundation AddOn Project

A workspace addon that gives any project instant access to 60+ AI skills, battle-tested permissions, and MCP server configs. Add it to your VS Code workspace as a second root and every AI coding session starts with a full toolkit.

## Supported Tools

| Tool | Config File | Skill Support | Status |
|------|------------|---------------|--------|
| **Claude Code** | `CLAUDE.md` | Native (60+ skills via `/slash-commands`) | Full support |
| **Codex / ChatGPT** | `AGENTS.md` | Inline instructions (top 15 skills translated) | Full support |
| **Opencode** | `opencode.json` | Inline instructions + model routing | Full support |
| **Cursor** | `.cursorrules` | Coding patterns only | Partial |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Brief standards | Partial |

## Quick Start

**Step 1:** Clone this repo alongside your project:
```bash
git clone https://github.com/GRsoldier7/Foundation_AddOn_Project.git "! Foundation_AddOn_Project"
```

**Step 2:** Create a workspace file in your project root:
```json
{
  "folders": [
    { "path": "." },
    { "path": "../! Foundation_AddOn_Project" }
  ]
}
```

**Step 3:** Open the workspace in VS Code and start a Claude Code session. Skills, permissions, and operating principles load automatically.

**Step 4 (cross-platform):** Generate configs for Codex and Opencode:
```bash
bash "../! Foundation_AddOn_Project/scripts/init-project.sh" .
```

This creates `AGENTS.md`, `opencode.json`, `.claude/settings.json`, and `.foundation-sync.json` in your project.

## What You Get

### Skills (60+)
Modular instruction bundles that activate on demand. Nine always-on skills run silently on every response (anti-hallucination, security, context management). The rest activate by trigger phrase or `/slash-command`.

| Category | Count | Examples |
|----------|-------|---------|
| Always-On Meta | 9 | anti-hallucination, secure-by-design, context-guardian |
| Core | 10 | adaptive-skill-orchestrator, notebooklm, parallel-execution-strategist |
| Engineering | 10 | code-review, testing-strategy, app-security-architect |
| Superpowers | 5 | brainstorming, TDD, systematic-debugging, writing-plans |
| Strategy | 9 | business-genius, go-to-market-engine, pricing-strategist |
| Tech Stack | 25 | FastAPI, PostgreSQL, Next.js, Terraform, Docker, Prisma |
| gstack | 34 | Full virtual engineering team (plan, review, QA, ship) |
| Community | 5 | cloud-solution-architect, architecture-patterns, security-threat-model |

See [docs/skills-reference.md](docs/skills-reference.md) for the full catalog with triggers and cross-platform availability.

### Permissions (Three-Tier Model)
The `.claude/settings.json` implements a battle-tested allow/deny/ask model:

- **Allow:** All read ops, git, dev tools, build/test/lint, MCP servers — zero interruptions
- **Deny:** sudo, rm -rf, force push, terraform destroy, sensitive files — hard blocks
- **Ask:** git push, rm, docker run, unfamiliar commands — prompt only when context matters

The init script generates stack-aware permissions (Python projects get pytest/ruff; Node gets npm/eslint).

### MCP Servers (10 recommended)
Tiered installation — the first 7 need zero API keys:

1. Context7, 2. Filesystem, 3. Git, 4. Playwright, 5. Memory, 6. Fetch, 7. Sequential Thinking, 8. GitHub, 9. Tavily, 10. PostgreSQL

See [docs/setup-guide.md](docs/setup-guide.md) for install commands.

### Auto-Sync
Projects stay current as the Foundation AddOn evolves:

- **First time:** `scripts/init-project.sh` scaffolds cross-platform configs
- **Updates:** `/project-sync` in Claude Code or `init-project.sh --update` from any terminal
- **Tracking:** `.foundation-sync.json` stores last-synced commit, checksums, and custom section markers

See [docs/cross-platform-guide.md](docs/cross-platform-guide.md) for the full cross-tool parity system.

## Documentation

| Guide | What It Covers |
|-------|---------------|
| [Setup Guide](docs/setup-guide.md) | Prerequisites, workspace creation, MCP installation, verification |
| [Cross-Platform Guide](docs/cross-platform-guide.md) | Achieving parity across Claude Code, Codex, and Opencode |
| [Skills Reference](docs/skills-reference.md) | Full skill catalog with triggers and platform support |
| [Workflows](docs/workflows.md) | Sprint, debug, review, and feature workflows with cross-platform prompts |

## Common Workflows

```
Sprint:   /autoplan → /plan-ceo-review → /plan-eng-review → build → /review → /cso → /qa → /ship
Debug:    /systematic-debugging → root cause → /test-driven-development → fix → /verification-before-completion
Feature:  /brainstorming → /writing-plans → TDD → /ship
Review:   /code-review → /cso → /verification-before-completion
Sync:     /project-sync (or: bash scripts/init-project.sh --update .)
```

See [docs/workflows.md](docs/workflows.md) for Codex/Opencode equivalents of each workflow.

## Project Structure

```
.
├── CLAUDE.md                    # Claude Code master instructions
├── README.md                    # This file
├── docs/                        # Comprehensive documentation
├── scripts/
│   ├── init-project.sh          # Cross-platform project scaffolder
│   ├── apply-fan-fixes.sh       # Dell Inspiron 3030 fan control
│   └── fix-fan-control.sh       # Aquacomputer Quadro fan curve
├── skills/
│   ├── core/                    # Always-on + orchestration skills
│   ├── engineering/             # Code review, testing, security, infra
│   ├── gstack/                  # Virtual engineering team (34 skills)
│   ├── strategy/                # Business, market, pricing skills
│   ├── superpowers/             # TDD, debugging, brainstorming, plans
│   └── tech/                    # Framework-specific skills (25)
├── templates/                   # Cross-platform config templates
├── mcp-config/                  # Recommended MCP server configs
└── vaultwarden/                 # Self-hosted credential management
```

## Contributing

1. **Add a skill:** Use `/skill-builder` or create `skills/<category>/<name>/SKILL.md`
2. **Update permissions:** Edit `.claude/settings.json` (allow/deny/ask tiers)
3. **Add an MCP server:** Add entry to `mcp-config/recommended-servers.json`
4. **Generate community skills:** `npx ctx7 skills generate`
