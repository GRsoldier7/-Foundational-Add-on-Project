# Foundation AddOn Project

A workspace addon that gives any project instant access to 60+ AI skills, battle-tested permissions, and MCP server configs. The Foundation repo is a curated portable subset with selected specialty skills synced from the canonical [`My_AI_Skills`](https://github.com/GRsoldier7/My_AI_Skills) repo.

## Supported Tools

| Tool | Config File | Skill Support | Status |
|------|------------|---------------|--------|
| **Claude Code** | `CLAUDE.md` | Native (60+ skills via `/slash-commands`) | Full support |
| **Codex / ChatGPT** | `AGENTS.md` | Inline instructions (top 15 skills translated) | Full support |
| **Gemini CLI** | `GEMINI.md` | Inline instructions tuned for Gemini workflows | Full support |
| **Opencode** | `opencode.json` | Inline instructions + model routing | Full support |
| **Cursor** | `.cursorrules` | Coding patterns only | Partial |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Brief standards | Partial |

## Quick Start

**Step 1:** Clone this repo alongside your project:
```bash
git clone https://github.com/GRsoldier7/-Foundational-Add-on-Project.git "! Foundation_AddOn_Project"
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

**Step 4 (cross-platform):** Generate configs for Codex, Gemini, and Opencode:
```bash
bash "../! Foundation_AddOn_Project/scripts/init-project.sh" .
```

This creates `AGENTS.md`, `GEMINI.md`, `opencode.json`, `.claude/settings.json`,
`.ai-memory/project-profile.md`, and `.foundation-sync.json` in your project.

## What You Get

### Skills (60+)
Modular instruction bundles that activate on demand. The always-on layer handles anti-hallucination, security, context management, verification, and response efficiency. The routed skill library covers:

- Core orchestration and meta-skills
- Engineering and tech-stack implementation
- Strategy, growth, and product execution
- Faith, legal-financial, and Microsoft specialty domains
- gstack virtual team workflows
- Selected community skills under `.claude/skills/`

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

### Upstream Sync
Foundation is not a hand-maintained fork of every skill. Selected specialty skills are synced from the main skill repo:

- **Canonical upstream:** `https://github.com/GRsoldier7/My_AI_Skills`
- **Curated subset manifest:** [`config/upstream-skill-manifest.txt`](config/upstream-skill-manifest.txt)
- **Sync command:** `bash scripts/sync-upstream-skills.sh /path/to/My_AI_Skills`
- **Command mirror refresh:** `bash scripts/sync-claude-commands.sh`

## Documentation

| Guide | What It Covers |
|-------|---------------|
| [Setup Guide](docs/setup-guide.md) | Prerequisites, workspace creation, MCP installation, verification |
| [Cross-Platform Guide](docs/cross-platform-guide.md) | Achieving parity across Claude Code, Codex, Gemini, and Opencode |
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
├── AGENTS.md                    # Codex baseline instructions
├── GEMINI.md                    # Gemini baseline instructions
├── README.md                    # This file
├── commands/                    # Curated 15 thin command loaders
├── .ai-memory/                  # Project memory bootstrap
├── docs/                        # Comprehensive documentation
├── config/                      # Upstream sync manifest and repo metadata
├── install.sh                   # Convenience installer wrapper
├── install-permissions.sh       # Claude permissions re-sync wrapper
├── scripts/
│   ├── init-project.sh          # Cross-platform project scaffolder
│   ├── sync-upstream-skills.sh  # Sync curated upstream skill subset
│   ├── sync-claude-commands.sh  # Regenerate .claude/commands from skills/
│   ├── validate-foundation.py   # Repo integrity validator
│   └── test-init-project.sh     # Init-project smoke tests
├── skills/
│   ├── core/                    # Always-on + orchestration skills
│   ├── engineering/             # Code review, testing, security, infra
│   ├── faith/                   # Theology, lesson planning, life application
│   ├── growth/                  # Marketing, content, brand, community, sales
│   ├── gstack/                  # Virtual engineering team
│   ├── legal-financial/         # Business tax strategy
│   ├── microsoft/               # Power Platform and Microsoft 365 skills
│   ├── product/                 # Product and domain-specific business systems
│   ├── strategy/                # Business, market, pricing skills
│   ├── superpowers/             # TDD, debugging, brainstorming, plans
│   └── tech/                    # Framework-specific skills
├── templates/                   # Cross-platform config templates
├── mcp-config/                  # Recommended MCP server configs
├── vaultwarden/                 # Self-hosted credential management
└── contrib/local/aaron/         # Explicitly non-portable host operations
```

## Contributing

1. **Sync shared specialty skills:** Update `My_AI_Skills`, then run `bash scripts/sync-upstream-skills.sh /path/to/My_AI_Skills`
2. **Add Foundation-only skills:** Create `skills/<category>/<name>/SKILL.md` when the skill belongs in the portable addon itself
3. **Refresh command mirrors:** Run `bash scripts/sync-claude-commands.sh`
4. **Validate before commit:** Run `python3 scripts/validate-foundation.py` and `bash scripts/test-init-project.sh`
5. **Add an MCP server:** Update `mcp-config/recommended-servers.json`
