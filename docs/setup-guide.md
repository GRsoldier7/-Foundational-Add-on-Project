# Foundation AddOn Setup Guide

A step-by-step guide for setting up the Foundation AddOn with any new project.

---

## 1. Prerequisites

Before you begin, make sure you have:

- **VS Code** (or a compatible editor like Cursor)
- **Claude Code CLI** installed -- see [official docs](https://docs.anthropic.com/en/docs/claude-code) for the latest install method. Typically: `npm install -g @anthropic-ai/claude-code`
- **Git** -- the addon is a git repo and many skills depend on git operations
- **Node.js 18+** -- required for `npx` commands used by MCP servers
- **Python 3.10+** and `uvx` -- required by some MCP servers (install via `pip install uv`)

Optional:

- **Codex CLI** (OpenAI) -- if you want cross-platform parity
- **Opencode** -- if you want cross-platform parity

You also need the Foundation AddOn cloned somewhere on disk:

```bash
git clone <foundation-addon-repo-url> ~/Projects/Foundation_AddOn_Project
```

---

## 2. Quick Start (3 Steps)

### Step 1: Create a workspace file

In your project root, create a file called `your-project.code-workspace`:

```json
{
  "folders": [
    { "path": "." },
    { "path": "/home/youruser/Projects/Foundation_AddOn_Project" }
  ]
}
```

Replace the second path with wherever you cloned the addon.

### Step 2: Open the workspace in VS Code

```
File > Open Workspace from File... > select your-project.code-workspace
```

You should see two roots in the Explorer sidebar: your project and the Foundation AddOn.

### Step 3: Start a Claude Code session

Launch Claude Code from the terminal (inside VS Code or standalone):

```bash
claude
```

Claude Code auto-discovers both `CLAUDE.md` files -- yours and the addon's. All 60+ skills, permission rules, and operating principles are now active.

To verify, try running a skill:

```
/brainstorming What should the architecture look like?
```

If it responds with a structured brainstorming flow, the addon is working.

---

## 3. Cross-Platform Setup (Codex / Gemini / Opencode)

The Foundation AddOn is primarily built for Claude Code, but it can generate instruction files for Codex CLI, Gemini CLI, and Opencode.

See `docs/cross-platform-guide.md` for the full explanation of how each tool discovers instructions and the translation strategy.

**What gets generated:**

| File | Used By | Purpose |
|------|---------|---------|
| `AGENTS.md` | Codex CLI | Flattened skill instructions as prose |
| `GEMINI.md` | Gemini CLI | Gemini-specific instruction baseline |
| `opencode.json` | Opencode | Project-level config with instructions |
| `.claude/settings.json` | Claude Code | Permission rules for the companion project |
| `.ai-memory/project-profile.md` | All | Durable project memory bootstrap |
| `.foundation-sync.json` | All | Tracks sync state between addon and project |

Run the init script from your companion project root:

```bash
bash "/path/to/Foundation_AddOn_Project/scripts/init-project.sh" .
```

For update syncs later:

```bash
bash "/path/to/Foundation_AddOn_Project/scripts/init-project.sh" --update .
```

---

## 4. MCP Server Installation

MCP (Model Context Protocol) servers extend what Claude Code can do -- fetching docs, automating browsers, remembering context across sessions. Install them in tiers.

### Where to put configuration

MCP servers are configured in `.mcp.json` files:

- **Project-level** (recommended): `.mcp.json` in your project root. Only active for that project.
- **Global**: `~/.claude.json`. Active for all Claude Code sessions.

Add `.mcp.json` to your `.gitignore` -- it may contain API keys.

### Tier 1: Core (zero API keys)

Install these first. They work immediately with no accounts or keys.

**Context7** -- live library docs, eliminates hallucinated API syntax:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

**Filesystem** -- sandboxed file operations:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/your/project"]
    }
  }
}
```

**Git** -- native git operations:

```json
{
  "mcpServers": {
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/path/to/your/project"]
    }
  }
}
```

**Playwright** -- browser automation:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

**Memory** -- persistent knowledge graph across sessions:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": "/path/to/your/project/.memory/knowledge-graph.jsonl"
      }
    }
  }
}
```

**Fetch** -- converts URLs to clean markdown:

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    }
  }
}
```

**Sequential Thinking** -- structured problem-solving for hard problems:

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

To install all Tier 1 servers at once, combine them into a single `.mcp.json`. See `mcp-config/recommended-servers.json` in the addon for the complete reference file.

### Tier 2: Enhanced (free API keys required)

**GitHub** -- PRs, issues, Actions, code search. Requires a Personal Access Token:

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<your-token>"
      }
    }
  }
}
```

**Tavily** -- AI-optimized web search. Free tier available at tavily.com:

```json
{
  "mcpServers": {
    "tavily": {
      "command": "npx",
      "args": ["-y", "tavily-mcp@latest"],
      "env": {
        "TAVILY_API_KEY": "<your-key>"
      }
    }
  }
}
```

**PostgreSQL** -- direct SQL execution. Requires a connection string:

```json
{
  "mcpServers": {
    "postgres": {
      "command": "uvx",
      "args": ["postgres-mcp"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@host:5432/dbname"
      }
    }
  }
}
```

### Tier 3: Specialist

Install as needed for your project:

- **Docker** -- container lifecycle management (`github.com/docker/docker-mcp`)
- **Sentry** -- error tracking with stack traces (requires `SENTRY_AUTH_TOKEN`)
- **Firecrawl** -- advanced web scraping with JS rendering (requires `FIRECRAWL_API_KEY`)
- **Qdrant** -- vector storage for RAG and semantic memory

See `mcp-config/recommended-servers.json` for full configuration details.

---

## 5. Verifying the Setup

Run these checks to confirm everything is working:

**Check skills load:**

```
/health
```

This runs a system health check. If skills are loading, you will see confirmation.

**Test a skill manually:**

```
/brainstorming How should we structure the API?
```

You should get a structured design exploration, not a direct code dump.

**Check MCP servers are available:**

In a Claude Code session, ask:

```
What MCP servers are connected?
```

Context7 should appear as `mcp__context7` (or similar). If you installed Playwright, it should appear as `mcp__playwright`.

**Check permissions:**

Run a git command -- it should execute without asking for approval:

```
git status
```

Try a denied command -- it should be blocked:

```
sudo ls
```

If git auto-allows and sudo blocks, the permission architecture from `.claude/settings.json` is active.

---

## 6. Keeping Up to Date

The Foundation AddOn is actively maintained. To stay current:

**Pull the latest:**

```bash
cd /path/to/Foundation_AddOn_Project && git pull
```

Since it is a separate workspace root, pulling updates does not touch your project's git history.

**Check for new skills:**

After pulling, new skills appear automatically in your next Claude Code session. The addon's `CLAUDE.md` is re-read on every session start.

**Check for new MCP servers:**

Review `mcp-config/recommended-servers.json` after pulling. New servers are added with full configuration and install instructions.

---

## 7. Troubleshooting

### Skills not loading

**Symptom:** Running `/brainstorming` or other skill commands does nothing or returns a generic response.

**Fix:** Confirm the workspace file lists the Foundation AddOn as a second root. Claude Code must see the addon's `CLAUDE.md` to discover skills. Open the `.code-workspace` file and verify both paths are correct and that the addon directory exists at that path.

### MCP server not found

**Symptom:** `mcp__context7` or other MCP tools are not available in the session.

**Fix:**
1. Check that `.mcp.json` exists in your project root (or `~/.claude.json` for global).
2. Verify `npx` and `uvx` are on your PATH. Run `which npx` and `which uvx`.
3. Try running the server command manually to see errors: `npx -y @upstash/context7-mcp@latest`

### Permission denied unexpectedly

**Symptom:** A command you expect to auto-allow is prompting for approval.

**Fix:** The addon's `.claude/settings.json` defines the allow/deny/ask rules. If your companion project has its own `.claude/settings.json`, rules are merged -- check both files. The deny list takes precedence over allow.

### AGENTS.md not picked up by Codex

**Symptom:** Codex CLI ignores your instructions.

**Fix:** `AGENTS.md` must be in your project root (not the addon root). Codex walks the directory tree looking for `AGENTS.md` files. Make sure the file exists where Codex can find it, and verify with `codex --help` that you are running from the correct directory.

### Opencode ignoring instructions

**Symptom:** Opencode does not apply your project rules.

**Fix:** Check `opencode.json` in your project root. Opencode merges configs from global to project scope -- project overrides global. Verify the file is valid JSON with `python -m json.tool opencode.json`.

### High context usage / session degradation

**Symptom:** Claude Code becomes slower or less accurate deep into a session.

**Fix:** The addon includes a `context-guardian` skill that monitors context fill. At 60%, it switches to sequential-only operations. At 80%, it recommends a session handoff. If you notice degradation, start a new session. The `session-optimizer` skill helps manage this automatically.

---

## Further Reading

- `CLAUDE.md` -- full skill library reference, permission architecture, and operating principles
- `docs/cross-platform-guide.md` -- detailed Codex/Opencode translation strategy
- `docs/skills-reference.md` -- complete skill catalog with examples
- `mcp-config/recommended-servers.json` -- all MCP server configurations with install instructions
