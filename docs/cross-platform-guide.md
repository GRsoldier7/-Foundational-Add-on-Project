# Cross-Platform AI Tool Parity Guide

How to make one project's AI instructions work consistently across Claude Code, Codex CLI (OpenAI), and Opencode -- without maintaining three separate config systems from scratch.

---

## 1. The Cross-Platform Problem

Every major AI coding tool invented its own instruction format. Claude Code reads `CLAUDE.md`. Codex CLI reads `AGENTS.md`. Opencode reads `opencode.json`. None of them natively understands the others.

This creates three concrete problems:

**Skill lock-in.** The Foundation AddOn ships 60+ skills, but skills are a Claude Code concept. There is no equivalent runtime in Codex or Opencode. A skill like `/brainstorming` that enforces "design before building" has to be translated into plain-text instructions for other tools.

**Permission fragmentation.** Claude Code has a three-tier permission model (allow/deny/ask). Codex runs in a sandbox with its own defaults. Opencode delegates to the underlying provider. There is no universal permission spec.

**Context discovery mismatch.** Claude Code walks the directory tree merging every `CLAUDE.md` it finds. Codex walks the tree merging every `AGENTS.md`. Opencode merges JSON configs from global to project scope. Same idea, different files, different merge semantics.

The result: teams using multiple tools end up with instructions that drift apart, or worse, exist only for one tool while others run unguided.

This guide solves that by establishing a translation layer and a maintenance pattern.

---

## 2. File Format Reference

| Format | Used By | Location | Skills | MCP | Permissions | Sandbox | Max Practical Size | Auto-Discovery |
|--------|---------|----------|--------|-----|-------------|---------|-------------------|----------------|
| `CLAUDE.md` | Claude Code | Any directory (walks tree) | Native (Skill tool, /slash-commands) | Native (.mcp.json) | allow/deny/ask in settings.json | No built-in sandbox | ~20K tokens before context pressure | Yes -- merges every CLAUDE.md found in tree |
| `AGENTS.md` | Codex CLI, growing ecosystem | Any directory (walks tree) | No -- inline instructions only | No -- describe tools in prose | No -- advisory text only | Codex runs in network-disabled sandbox by default | ~15K tokens recommended | Yes -- merges every AGENTS.md found in tree |
| `opencode.json` | Opencode | Project root, `~/.config/opencode/` | No -- inline instructions only | No -- provider-dependent | No -- provider-dependent | Provider-dependent | JSON; instructions field is a string | Yes -- merges global, custom, project configs |
| `.cursorrules` | Cursor | Project root | No | No | No | No | ~6K tokens practical | Single file, no merge |
| `.github/copilot-instructions.md` | GitHub Copilot | `.github/` directory | No | No | No | No | ~8K tokens practical | Single file, no merge |

**Key takeaway:** AGENTS.md is the closest thing to a universal standard. It was formalized by the Linux Foundation's AI Agent Infrastructure Forum (AAIF) in December 2025 and has been adopted by 60,000+ repositories. It is free-form Markdown with no required schema. But "universal" still means "widely read," not "read by everything" -- Claude Code and Opencode do not natively consume it.

---

## 3. What Each Tool Can Express

This section maps Foundation AddOn capabilities to what each tool can actually handle.

### Skills

- **Claude Code:** Native. Invoked via the Skill tool or `/slash-commands`. The orchestrator auto-selects skills per request.
- **Codex CLI:** No skill runtime. Translate key skill behaviors into AGENTS.md sections with explicit instructions. Example: the `anti-hallucination` skill becomes a section titled "Accuracy Rules" with its confidence-tier definitions written out.
- **Opencode:** No skill runtime. Same translation approach, embedded in the `instructions` field of `opencode.json` or a referenced instruction file.

### MCP Servers

- **Claude Code:** Native. Configured in `.mcp.json`. Tools like Context7, Playwright, and Memory are available directly.
- **Codex CLI:** No MCP protocol. Describe available external tools in AGENTS.md as prose so the model knows what capabilities exist (e.g., "Use the GitHub CLI `gh` for PR operations" rather than referencing an MCP server).
- **Opencode:** Supports 75+ LLM providers via AI SDK but does not have MCP integration. Same prose-description approach.

### Permissions (Allow / Deny / Ask)

- **Claude Code:** Full three-tier model in `.claude/settings.json`. Specific commands can be auto-approved, blocked, or gated.
- **Codex CLI:** Runs in a network-disabled sandbox by default. No granular permission config. Advisory rules in AGENTS.md ("never run `rm -rf` without confirmation") are the closest equivalent.
- **Opencode:** Provider-dependent. No built-in permission model. Advisory rules in instructions.

### Operating Principles

All tools support this. Principles like "verify before claiming completion" and "design before building" translate directly into any instruction format as plain text. This is the highest-portability category.

### Coding Conventions

All tools support this. Style guides, naming conventions, and architectural patterns are plain text and work everywhere.

### Workflow Sequences

- **Claude Code:** `/autoplan` then `/plan-ceo-review` then `/plan-eng-review` then build then `/review` then `/ship`. Native orchestration.
- **Codex CLI / Opencode:** Write the workflow as numbered steps in AGENTS.md or instructions. The model follows them sequentially but there is no enforcement mechanism.

---

## 4. Translation Rules

### Skill Trigger to AGENTS.md Section

A Claude Code skill trigger like `/brainstorming`:

**In CLAUDE.md (Claude Code):**
```
Use the `/brainstorming` skill before any creative work -- creating features,
building components, adding functionality, or modifying behavior.
```

**Equivalent in AGENTS.md (Codex):**
```markdown
## Design Before Building

Before creating any new feature, component, or behavioral change:

1. Restate the goal in your own words. Identify what is ambiguous.
2. Ask clarifying questions if requirements are underspecified.
3. Propose 2-3 alternative approaches with tradeoffs.
4. Get explicit approval on the chosen approach before writing code.
5. Never skip this step, even for changes that seem straightforward.
```

The skill's logic is preserved. The invocation mechanism changes from a tool call to inline instructions.

### Permission Rule to AGENTS.md Advisory

**In `.claude/settings.json` (Claude Code):**
```json
{
  "deny": ["Bash(rm -rf /)", "Bash(sudo *)"]
}
```

**Equivalent in AGENTS.md (Codex):**
```markdown
## Safety Rules

- NEVER run `rm -rf /` or any recursive delete on system directories.
- NEVER use `sudo` for any operation.
- NEVER run `curl | bash` or `wget | sh` patterns.
- Before any destructive file operation, confirm with the user.
```

Advisory rules cannot enforce like Claude Code's deny list, but Codex's sandbox provides a secondary safety net.

### MCP Server Reference to Tool Description

**In `.mcp.json` (Claude Code):**
```json
{
  "context7": {
    "command": "npx",
    "args": ["-y", "@anthropic/context7-mcp"]
  }
}
```

**Equivalent in AGENTS.md (Codex):**
```markdown
## Available Tools

- **GitHub CLI (`gh`)**: Use for all GitHub operations -- PRs, issues, Actions,
  code search. Prefer `gh` over raw API calls.
- **Documentation lookup**: When unsure about library APIs, check official docs
  before generating code. Do not guess function signatures.
```

You cannot give Codex an MCP server, but you can tell it what tools are available in the environment and how to use them.

---

## 5. The AGENTS.md Bridge Pattern

AGENTS.md is the cross-platform bridge. The pattern:

```
AGENTS.md          -- Universal instruction set (works in Codex, readable by humans)
  |
CLAUDE.md          -- Adds Claude-specific extensions (skills, MCP, permissions)
  |
opencode.json      -- References AGENTS.md content in its instructions field
  |
.cursorrules       -- Condensed version for Cursor's size limits
```

### Writing AGENTS.md as the Base Layer

Put everything that is tool-agnostic into AGENTS.md:

- Project architecture overview
- Coding conventions and style rules
- Operating principles (verify before completing, test before shipping, etc.)
- Safety rules (translated from Claude Code's deny list)
- Workflow steps (translated from skill sequences)
- Technology-specific instructions (framework patterns, database conventions)

### CLAUDE.md as the Extension Layer

CLAUDE.md should not duplicate AGENTS.md content. Instead, it adds what only Claude Code can use:

- Skill references and trigger mappings
- MCP server configuration pointers
- Permission architecture description
- Workspace integration instructions (multi-root setup)

If your project has both files, Claude Code reads CLAUDE.md (its native format). It does not read AGENTS.md automatically. The CLAUDE.md can reference shared content:

```markdown
## Project Instructions

See AGENTS.md for coding conventions, architecture overview, and operating
principles. Those apply here as well.

## Claude-Specific Extensions

### Skills
- Use `/brainstorming` before any creative work.
- Use `/code-review` before merging.
...
```

### opencode.json Referencing AGENTS.md

Opencode's instructions field accepts a string. For longer instructions, point to a file:

```json
{
  "instructions": "Follow all instructions in AGENTS.md at the project root. Additional rules: ..."
}
```

Whether the model actually reads the referenced file depends on the provider and tool version. For reliability, inline the most critical rules directly and reference AGENTS.md for the full set.

### Symlink Strategy: When to Use, When Not To

**Do not symlink AGENTS.md to CLAUDE.md.** Claude Code needs skill references, MCP pointers, and permission descriptions that AGENTS.md cannot express. Maintaining them as separate files is the correct approach.

**You can symlink** `.cursorrules` to a condensed version of AGENTS.md if you want Cursor coverage without another file to maintain. Keep it under 6K tokens.

---

## 6. The project-sync System

The Foundation AddOn includes `scripts/init-project.sh` and a `/project-sync` workflow to keep cross-platform files current.

The sync system handles:

- Generating AGENTS.md from the Foundation AddOn's skill library and operating principles
- Keeping CLAUDE.md and AGENTS.md in sync when the source of truth changes
- Validating that platform-specific files do not contradict each other

See `docs/setup-guide.md` for the full setup walkthrough, including how to run the initial sync and how to configure it for CI.

---

## 7. Platform-Specific Gotchas

### Claude Code

- **Context pressure is real.** The 60+ skill library is not loaded upfront -- the orchestrator loads skills on demand. But a large CLAUDE.md still consumes context on every turn. Keep it under 20K tokens. If your companion project's CLAUDE.md is also large, the combined context cost adds up.
- **Multi-root workspace merging.** When the Foundation AddOn is a second workspace root, Claude Code merges both CLAUDE.md files. Conflicting instructions in the two files can cause unpredictable behavior. Keep the Foundation AddOn's CLAUDE.md as the authority on skills and permissions; keep the companion project's CLAUDE.md focused on project-specific conventions.
- **Settings.json is committed.** The `.claude/settings.json` file is checked into git. Never put secrets or API keys in it. Use environment variables or the Bitwarden integration.

### Codex CLI

- **Network-disabled sandbox.** Codex runs commands in a sandbox with no network access by default. Tools that need network (npm install, pip install, API calls) will fail unless you configure the sandbox policy. This is a feature, not a bug, but it trips people up.
- **AGENTS.md size limits.** There is no hard limit, but Codex processes instructions before each task. Very long AGENTS.md files (30K+ tokens) slow down task startup and reduce the context available for actual work. Target 15K tokens or less.
- **No enforcement mechanism.** AGENTS.md is advisory. Unlike Claude Code's deny list, there is nothing preventing Codex from ignoring an instruction. The sandbox is your real safety net.
- **Tree walk behavior.** Codex checks each directory level for AGENTS.md, from root to the file being edited. A monorepo can have AGENTS.md at the root and in subdirectories. More specific files supplement (not replace) parent files.

### Opencode

- **Provider diversity.** Opencode supports 75+ LLM providers via the AI SDK. Instruction-following quality varies dramatically between providers. Test your instructions against your specific provider.
- **JSON config limitations.** The `opencode.json` instructions field is a JSON string. Multi-line instructions require `\n` escaping or a reference to an external file. This makes complex instructions harder to maintain than Markdown-based formats.
- **No native AGENTS.md support.** Opencode does not walk the tree for AGENTS.md. You must either inline instructions in `opencode.json` or configure the tool to read a specific file, depending on provider capabilities.
- **Config merge order.** Global config (`~/.config/opencode/`) merges with custom config, then project config. Later configs override earlier ones. Be aware of which layer sets which rules.

### Cursor and Copilot

- **Size constraints.** `.cursorrules` works best under 6K tokens. `.github/copilot-instructions.md` works best under 8K tokens. Neither supports the full Foundation AddOn instruction set -- prioritize the most impactful rules.
- **No merge behavior.** Both use a single file with no directory-tree merging. Monorepo setups need a single file at the root that covers all subdirectories.

---

## 8. Quick Decision Matrix

| I want to... | Edit this file |
|---------------|---------------|
| Add a coding convention (all tools) | `AGENTS.md` (then sync to CLAUDE.md) |
| Add a safety rule (all tools) | `AGENTS.md` (then sync to CLAUDE.md deny list) |
| Add or modify a skill | `skills/` directory + CLAUDE.md trigger reference |
| Configure an MCP server | `.mcp.json` (Claude Code only) |
| Change permission rules | `.claude/settings.json` (Claude Code only) |
| Add an operating principle | `AGENTS.md` (universal) |
| Define a workflow sequence | `AGENTS.md` steps + CLAUDE.md /slash-command references |
| Add project architecture docs | `AGENTS.md` (universal) |
| Set Opencode-specific behavior | `opencode.json` instructions field |
| Set Cursor-specific behavior | `.cursorrules` (condensed from AGENTS.md) |
| Set Copilot-specific behavior | `.github/copilot-instructions.md` |
| Change something for Claude Code only | `CLAUDE.md` |
| Change something for Codex only | `AGENTS.md` (Codex-specific section) |
| Change something for all tools at once | `AGENTS.md` then run `/project-sync` |

---

## Summary

The practical path to cross-platform parity:

1. **Write AGENTS.md as your universal base.** It is the open standard with the broadest adoption.
2. **Extend with CLAUDE.md for Claude Code.** Skills, MCP, and permissions only work here.
3. **Reference from opencode.json for Opencode.** Inline critical rules, point to AGENTS.md for the rest.
4. **Condense into .cursorrules and copilot-instructions.md** if your team uses those tools.
5. **Run /project-sync** to keep everything aligned when the source of truth changes.

No symlinks. No duplication. One source of truth in AGENTS.md, extended per tool where needed.
