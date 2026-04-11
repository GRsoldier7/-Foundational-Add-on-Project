# Foundation AddOn — LLM-Agnostic Architecture Design

**Date:** 2026-04-11  
**Status:** Approved — ready for implementation planning  
**Approach:** Skill-First, Schema Derived (Top-Down)  
**Stack:** TypeScript + Bun  
**Spec Owner:** GRsoldier7  
**Spec Version:** 2.0 (fully patched — Tier 1 + Tier 2 gaps resolved, future-proofed)

---

## 1. Executive Summary

The Foundation AddOn is a VS Code workspace addon that provides a shared AI skill library and MCP server configuration to any companion project. Today it is Claude Code–specific (~100+ SKILL.md files, 90+ command stubs, baseline permissions). This design evolves it into a **truly LLM-agnostic layer** — a Canonical Core + Thin Adapter system — that compiles the same skill definitions into provider-native artifacts for Claude Code, Codex CLI, Qwen, and Gemini CLI, while also supporting live runtime API calls through any of those providers.

**Core principle:** Write once in canonical format. Generate anywhere. Install safely. Invoke from any provider.

**Why now:** The project is named `LLM_Agnostic` but is currently 100% Claude-specific. This design closes that gap.

**How:** Build 5 pilot skills in canonical format manually → prove the adapter layer with Claude → extend to all providers → automate with a CLI runner. Never break the existing Claude workflow. Generate into `dist/` staging — never directly overwrite live files.

---

## 2. Current State

| Component | Status |
|-----------|--------|
| `skills/` — 100+ Claude-native skills | ✅ Working, untouched |
| `.claude/commands/` — 90+ command stubs | ✅ Working, untouched |
| `.claude/skills/` — 5 community skills | ✅ Working, untouched |
| `mcp-config/recommended-servers.json` | ✅ Working, will be enhanced |
| `.claude/settings.json` — permissions | ✅ Working, untouched |
| `vaultwarden/` — credential stack | ✅ Working, untouched |
| Canonical core format | ❌ Does not exist |
| Adapter layer | ❌ Does not exist |
| CLI runner | ❌ Does not exist |
| Multi-provider support | ❌ Does not exist |
| Tests / CI | ❌ Does not exist |
| Plugin manifest | ❌ Does not exist |

**Invariant:** Nothing in the existing state gets deleted or broken. All new components are additive.

---

## 3. Design Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| DD-001 | Approach: Skill-First, Schema Derived | Avoids speculative infrastructure; schema emerges from 5 real pilot skills |
| DD-002 | Migration: Top 20% now, rest on-demand | No big-bang migration risk; 80+ skills stay Claude-native until real need |
| DD-003 | Both build-time generator AND runtime adapter | Generator for workspace setup; runtime for programmatic/API-level switching |
| DD-004 | TypeScript + Bun | All target CLIs are Node/TS; Bun gives <20ms startup + `--compile` single binary |
| DD-005 | Monorepo with `packages/` structure | Each package independently publishable to npm/Claude plugin marketplace |
| DD-006 | `dist/` for generated artifacts (gitignored) | Prevents generate from clobbering 90+ battle-tested `.claude/commands/` files |
| DD-007 | Native `.claude-plugin/` distribution | `/plugin install foundation-addon` UX; marketplace-ready from day one |
| DD-008 | 6-tier structure preserved in canonical layer | Mirrors existing mental model; enables tier-level generate targeting |
| DD-009 | Providers and MCPs in separate config files | Different concerns: LLM endpoints vs tool servers |
| DD-010 | T1–T4 tiered trust model | Runner executes skill code — needs a security boundary |
| DD-011 | Sentinel-fenced block strategy for AGENTS.md / GEMINI.md | Allows re-installs without destroying user-authored content in shared files |
| DD-012 | Backup-before-install with rollback | Any install is reversible; no destructive writes without a recovery path |
| DD-013 | Incremental compilation with SHA-256 content hashing | Skip unchanged skills on generate; large skill libraries don't penalize fast iteration |
| DD-014 | Parallel generation via Promise.all() | 100 skills × 4 providers completes in ~1 batch time, not 400 sequential ops |
| DD-015 | DAG-based skill composition at runtime only | Composition resolved at invoke time; generate treats each skill independently |

---

## 4. Repository Structure

```
! Foundation_AddOn_Project - LLM_Agnostic/
│
├── .claude-plugin/                         ← Native Claude Code plugin manifest
│   ├── plugin.json                         ← Name, version, entry points, capabilities
│   └── marketplace.json                    ← Claude plugin marketplace metadata
│
├── packages/                               ← Monorepo — each package independently publishable
│   │
│   ├── canonical/                          ← Single source of truth for all skills
│   │   ├── manifest.yaml                   ← Registry: all skills, versions, dependencies
│   │   ├── VERSION                         ← Semver for the canonical layer
│   │   ├── .cache/
│   │   │   └── hashes.json                 ← SHA-256 hashes for incremental compilation (gitignored)
│   │   ├── skills/
│   │   │   ├── core/                       ← Tier 1: meta and orchestration
│   │   │   │   └── adaptive-skill-orchestrator/
│   │   │   │       ├── core.md             ← Provider-neutral natural language instructions
│   │   │   │       ├── spec.yaml           ← Metadata, inputs, capabilities, provider_hints
│   │   │   │       ├── tools/              ← JSON Schema tool definitions
│   │   │   │       └── tests/              ← Skill-level behavioral tests (.test.yaml)
│   │   │   ├── engineering/                ← Tier 2: code, security, data
│   │   │   ├── gstack/                     ← Tier 3: YC/gstack workflow skills
│   │   │   ├── strategy/                   ← Tier 4: business and product
│   │   │   ├── superpowers/                ← Tier 5: process meta-skills
│   │   │   └── tech/                       ← Tier 6: framework-specific
│   │   └── schema/
│   │       ├── spec.schema.json            ← JSON Schema for spec.yaml (versioned)
│   │       ├── manifest.schema.json        ← JSON Schema for manifest.yaml
│   │       ├── tool.schema.json            ← JSON Schema for tool definitions
│   │       └── lockfile.schema.json        ← JSON Schema for foundation-addon.lock.yaml
│   │
│   ├── adapters/                           ← Provider translators (TypeScript)
│   │   ├── src/
│   │   │   ├── base.ts                     ← BaseAdapter abstract class (CLMI contract)
│   │   │   ├── claude.ts                   ← → .claude/commands/ artifacts
│   │   │   ├── codex.ts                    ← → AGENTS.md sentinel blocks
│   │   │   ├── qwen.ts                     ← → qwen-skills.md sentinel blocks
│   │   │   ├── gemini.ts                   ← → GEMINI.md sentinel blocks
│   │   │   ├── utils/
│   │   │   │   ├── translate-tools.ts      ← Per-provider JSON Schema → native tool format
│   │   │   │   ├── sentinel.ts             ← Fenced block read/write/merge utilities
│   │   │   │   ├── tokenizer.ts            ← Token estimation for context window management
│   │   │   │   └── hash.ts                 ← SHA-256 hashing for incremental compilation
│   │   │   └── types.ts                    ← SkillSpec, CLMIMessage, NormalizedResponse, ToolResult
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   ├── runner/                             ← CLI + runtime engine (TypeScript + Bun)
│   │   ├── src/
│   │   │   ├── cli.ts                      ← Entry: foundation-addon <command> (Commander.js)
│   │   │   ├── commands/
│   │   │   │   ├── init.ts                 ← Bootstrap addon into consumer project + write lockfile
│   │   │   │   ├── generate.ts             ← Build-time: canonical → dist/{provider}/ (parallel)
│   │   │   │   ├── install.ts              ← Promote dist/ → live dirs (backup-first, sentinel merge)
│   │   │   │   ├── uninstall.ts            ← Remove sentinel blocks / delete generated files
│   │   │   │   ├── invoke.ts               ← Runtime: validate inputs → adapter API call
│   │   │   │   ├── test.ts                 ← Run .test.yaml assertions against provider
│   │   │   │   ├── validate.ts             ← Schema + lint + composition DAG validation
│   │   │   │   ├── migrate.ts              ← Legacy SKILL.md → canonical (with review checklist)
│   │   │   │   ├── rollback.ts             ← Restore from backup snapshots
│   │   │   │   ├── skill.ts                ← Subcommands: add, remove, list, update
│   │   │   │   ├── doctor.ts               ← Full env health check
│   │   │   │   └── dev.ts                  ← Dev mode: watch canonical/, auto-regenerate+install
│   │   │   ├── registry.ts                 ← Skill discovery, caching, semver resolution
│   │   │   ├── dag.ts                      ← Dependency graph resolver + cycle detector
│   │   │   ├── telemetry.ts                ← Local JSONL event log (opt-in)
│   │   │   ├── audit.ts                    ← Append-only audit log for all install/invoke ops
│   │   │   ├── trust.ts                    ← T1–T4 tiered trust enforcement
│   │   │   └── errors.ts                   ← Error taxonomy, exit codes, structured error format
│   │   ├── tsconfig.json
│   │   └── package.json
│   │
│   └── config/                             ← Configuration — separated by concern
│       ├── providers.yaml                  ← LLM endpoints: models, auth env var refs, rate limits, telemetry
│       ├── mcp-servers.yaml                ← MCP servers (migrated + enhanced from recommended-servers.json)
│       ├── provider-matrix.yaml            ← MCP + tool compatibility per provider (mcp_supported field)
│       ├── policies.yaml                   ← Permission tiers, trust levels, allow/deny patterns
│       └── schema/
│           └── *.schema.json               ← Schemas for all config files
│
├── dist/                                   ← Generated artifacts — GITIGNORED
│   ├── claude/
│   ├── codex/
│   ├── qwen/
│   └── gemini/
│
├── .foundation-addon/                      ← Runtime state — GITIGNORED
│   ├── telemetry.jsonl                     ← Local-only event log (opt-in)
│   ├── audit.jsonl                         ← Append-only audit log (always on)
│   └── backups/                            ← Pre-install snapshots (auto-pruned to 7 most recent)
│       └── {ISO-timestamp}/
│
├── tests/
│   ├── contract/                           ← Payload shape: input → expected adapter output
│   ├── golden/                             ← Cross-provider behavioral consistency traces
│   ├── fixtures/                           ← Shared test inputs, canned responses
│   └── integration/                        ← End-to-end: generate → install → invoke
│
├── docs/
│   ├── superpowers/specs/                  ← Design specs (this file)
│   ├── adr/                                ← Architecture Decision Records
│   ├── ARCHITECTURE.md
│   ├── MIGRATION.md
│   ├── QUICKSTART.md
│   └── PROVIDER-GUIDE.md
│
├── scripts/
│   ├── bootstrap.sh                        ← First-time setup: installs Bun, builds packages
│   ├── migrate-skill.ts                    ← Converts legacy commands/*.md → canonical/
│   └── audit-skills.ts                     ← Finds duplication, stale docs, missing tests
│
├── .github/
│   └── workflows/
│       ├── validate.yml                    ← validate + contract tests on every PR
│       ├── golden.yml                      ← Cross-provider behavioral traces nightly
│       └── release.yml                     ← Tags, CHANGELOG, publishes packages
│
├── skills/                                 ← EXISTING: Claude-native (untouched)
├── vaultwarden/                            ← EXISTING: untouched
├── .claude/                                ← EXISTING: untouched
├── CLAUDE.md                               ← Updated to reference new architecture
├── README.md                               ← Rewritten for new workflow
├── CHANGELOG.md
├── VERSION                                 ← Top-level semver
└── .gitignore                              ← Updated to exclude dist/, .foundation-addon/, .cache/
```

---

## 5. Canonical Core Format

### `spec.yaml` — Full Schema

```yaml
spec_version: "1.0"                      # Required. Schema version — enables forward migration.
name: code-review                        # Required. kebab-case, matches directory name.
version: "1.0.0"                         # Required. Semver. Input/capability changes = minor bump min.
description: "..."                       # Required. One sentence, provider-neutral.
tier: engineering                        # Required. core|engineering|gstack|strategy|superpowers|tech

inputs:                                  # Optional. Declares context the skill expects at invoke time.
  - name: code
    type: string                         # string | number | boolean | enum | image | audio | file
    required: true
    description: "Code to review"
  - name: focus
    type: enum
    values: [security, performance, correctness, all]
    default: all

capabilities:                            # Required. Declares permissions the skill needs.
  - code_analysis                        # Used by trust.ts to enforce T1–T4 tier
  - security_scanning
  - file_read

tools:                                   # Optional. JSON Schema files in tools/ subdirectory.
  - tools/search-code.json
  - tools/read-file.json

depends_on:                              # Optional. Skills this skill calls as sub-tasks (runtime DAG).
  - core/adaptive-skill-orchestrator     # Format: tier/skill-name

provider_hints:                          # Optional. ONLY place for provider-specific differences.
  claude:
    model: claude-opus-4-6
    system_prefix: "Use <thinking> tags for your analysis before responding."
    max_tokens: 8192
    temperature: 0.3
  codex:
    model: o4-mini
    system_prefix: "Think step by step before responding."
    max_tokens: 4096
  qwen:
    model: qwen-max
    max_tokens: 4096
  gemini:
    model: gemini-2.0-flash
    max_tokens: 4096

trust_tier: T2                           # Required. T1=read-only, T2=file-read, T3=file-write, T4=full
tags: [review, security, quality]
composable: true                         # Can be called as a sub-skill by other skills?
parallel_safe: true                      # Safe to run concurrently with other skills?
streaming: false                         # Does this skill support streaming responses?
author: foundation-addon
```

### `provider_hints` Formal Type (enforced by schema)

```typescript
interface ProviderHint {
  model?: string          // Provider-specific model ID
  system_prefix?: string  // Prepended to core.md content
  system_suffix?: string  // Appended to core.md content
  max_tokens?: number     // Output token cap for this provider
  temperature?: number    // 0.0–1.0; lower = more deterministic
}
// In spec.schema.json: provider_hints typed as Partial<Record<"claude"|"codex"|"qwen"|"gemini", ProviderHint>>
```

### Hard Rules for `spec.yaml`
1. No provider-specific syntax anywhere except inside `provider_hints`
2. All `tools:` references must have a corresponding JSON Schema file in `tools/`
3. `version` follows semver — any `inputs` or `capabilities` change requires a minor bump minimum
4. `trust_tier` must be declared — no implicit trust
5. `spec_version` must match a known schema version — the validator routes to the correct JSON Schema

### `core.md` Format Rules
1. **No XML tags** — `<thinking>`, `<answer>`, etc. go in `provider_hints.{provider}.system_prefix`
2. **No model names or API references** — write to behavior, not infrastructure
3. **No "As an AI…" framing** — write to what the skill does, not what it is
4. **Max `##` heading depth** — deeper nesting signals the skill is doing too much
5. **150–400 words** for most skills — over 600 words = decompose into sub-skills
6. **Structure:** Purpose → Process → Output Format → Constraints
7. **No MCP-specific tool names** — reference capability by function name only (e.g., `read_file`, not `mcp__filesystem__read_file`)

### Tool Definition Schema (`tools/*.json`)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "name": "read_file",
  "description": "Read the contents of a file by path",
  "parameters": {
    "type": "object",
    "properties": {
      "path": { "type": "string", "description": "Path to the file" }
    },
    "required": ["path"]
  }
}
```

Provider translation by `translate-tools.ts`:
- **Claude:** `{ name, description, input_schema }` — JSON Schema native, zero conversion
- **Codex / Qwen:** `{ type: "function", function: { name, description, parameters } }`
- **Gemini:** `{ functionDeclarations: [{ name, description, parameters }] }`

### Skill Test Format (`tests/*.test.yaml`)

```yaml
name: detects-eval-security-issue
input:
  code: "function foo() { return eval(x) }"
  focus: security
provider: all                            # "all" runs against every provider; or specify one
assertions:
  - type: contains
    value: "eval"
  - type: contains
    value: "security"
  - type: not_contains
    value: "looks good"
  - type: matches_regex
    value: "Critical|High"
```

---

## 6. Adapter Layer

### `BaseAdapter` Abstract Class

```typescript
// packages/adapters/src/base.ts
export abstract class BaseAdapter {
  abstract readonly provider: string
  abstract readonly contextLimitTokens: number    // Provider's context window size

  // Build-time: compile canonical skill → workspace artifact string
  abstract generateArtifact(spec: SkillSpec, core: string): string

  // Runtime: translate canonical skill + messages → provider API payload
  abstract formatPrompt(spec: SkillSpec, core: string, messages: CLMIMessage[]): unknown

  // Runtime: normalize provider response → CLMI NormalizedResponse
  abstract parseResponse(raw: unknown): NormalizedResponse

  // Translate JSON Schema tool definitions → provider-native tool format
  abstract translateTools(tools: JSONSchema[]): unknown[]
}
```

### CLMI Types

```typescript
interface CLMIMessage {
  role: 'user' | 'assistant' | 'system' | 'tool'
  content: string
  tool_calls?: ToolCall[]
  tool_results?: ToolResult[]
}

interface ToolCall {
  id: string
  name: string
  input: Record<string, unknown>
}

interface ToolResult {
  tool_call_id: string    // Matches the ToolCall.id that triggered this
  tool_name: string       // For logging and debugging
  content: string         // Stringified result — all providers normalize to string
  is_error: boolean
  duration_ms?: number
}

interface NormalizedResponse {
  content: string
  stop_reason: 'end' | 'tool_use' | 'max_tokens' | 'error'
  tool_calls?: ToolCall[]
  usage?: { input_tokens: number; output_tokens: number }
  stream?: ReadableStream<string>    // Present when streaming: true in spec.yaml
}
```

### Provider Artifact Formats

**Claude** → `.claude/commands/{name}.md` (individual file per skill, overwrite-safe):
```markdown
---
name: {spec.name}
description: {spec.description}
type: skill
---
{provider_hints.claude.system_prefix}

{core.md content}
```

**Codex / Qwen / Gemini** → fenced sentinel blocks in shared file:
```markdown
<!-- foundation-addon:start:{spec.name} -->
## Skill: {spec.name}
> {spec.description}

{provider_hints.{provider}.system_prefix}

{core.md content}
<!-- foundation-addon:end:{spec.name} -->
```

On re-install: `sentinel.ts` rewrites only the content between the start/end tags. User content outside all foundation-addon blocks is never touched.

### MCP / Tool-Calling Compatibility Matrix

| Provider | MCP Protocol | Function Calling | `mcp_supported` in provider-matrix.yaml |
|----------|-------------|-----------------|----------------------------------------|
| Claude Code | ✅ Native | ✅ `@anthropic-ai/sdk` | `true` |
| Codex CLI | ❌ | ✅ OpenAI function format | `false` (flip to `true` when supported) |
| Qwen | ❌ | ✅ OpenAI-compatible | `false` |
| Gemini CLI | ❌ | ✅ `functionDeclarations` | `false` |

**Implication:** All canonical `tools/*.json` must be pure JSON Schema. The Claude adapter maps them to MCP calls in Claude Code context, or Anthropic `tool_use` in runtime context. Non-Claude adapters use direct function calling. When a provider ships MCP support, flip `mcp_supported: true` in `provider-matrix.yaml` — the adapter auto-upgrades.

---

## 7. CLI Runner

**Stack:** Commander.js + Bun  
**Build:** `bun build packages/runner/src/cli.ts --compile --outfile foundation-addon`  
**Distribution:** Single binary, zero runtime dependencies

### Full Command Reference

```
foundation-addon init [--project-path <path>]
  Bootstrap addon into consumer project.
  Writes foundation-addon.lock.yaml with declared skills + versions.
  Sets up .foundation-addon/ state directory.
  Installs .claude-plugin/ if not present.

foundation-addon generate [--target <claude|codex|qwen|gemini|all>]
                          [--skill <tier/name>] [--tier <tier>]
                          [--force]
  Compile canonical → dist/{provider}/ (parallel via Promise.all).
  Incremental: skips skills with unchanged SHA-256 hash (unless --force).
  Never writes to live tool directories — use install to promote.

foundation-addon install [--target <provider>] [--into <path>]
                         [--skill <tier/name>] [--dry-run] [--global]
  Backup target files to .foundation-addon/backups/{timestamp}/ first.
  Promote dist/{provider}/ → live tool dirs using sentinel merge.
  --dry-run: show full diff, touch nothing.
  --global: install to ~/.claude/commands/ (Claude only).
  Install paths:
    claude  → .claude/commands/{name}.md (individual files)
    codex   → AGENTS.md (sentinel blocks)
    qwen    → qwen-skills.md (sentinel blocks)
    gemini  → GEMINI.md (sentinel blocks)

foundation-addon uninstall [--target <provider>] [--from <path>]
                           [--skill <tier/name>] [--dry-run]
  For .claude/commands/: delete the generated file.
  For sentinel-based files: remove the fenced block, leave surrounding content.
  --dry-run: show what would be removed, touch nothing.

foundation-addon invoke <tier/skill-name> [--provider <provider>]
                        [--input <json>] [--stream]
                        [--max-tokens <n>] [--no-truncate]
  Validate inputs against spec.yaml Zod schema before calling adapter.
  Estimate token count; warn at 80%, truncate at 95% (unless --no-truncate).
  Call provider API through adapter. Return NormalizedResponse.
  --stream: streaming output (requires streaming: true in spec.yaml).

foundation-addon test [--skill <tier/name>] [--provider <provider>]
                      [--golden] [--update-golden]
  Run .test.yaml assertions for the specified skill.
  --golden: use cached responses from tests/golden/ (for CI, no API calls).
  --update-golden: re-run live and save responses as new golden traces.

foundation-addon validate [--skill <tier/name>] [--fix]
                          [--migrate-spec]
  Validate spec.yaml against versioned schema (routes by spec_version).
  Lint core.md for format violations (XML tags, word count, heading depth).
  Validate composition DAG (circular deps, missing deps).
  --fix: auto-correct minor issues (whitespace, heading depth).
  --migrate-spec: bump spec_version + patch deprecated fields.

foundation-addon migrate <skill-path-or-glob> [--dry-run] [--ai]
  Convert legacy .claude/commands/*.md → canonical core.md + spec.yaml.
  Outputs review checklist: detected provider syntax, word count warnings,
  missing inputs, MCP tool references needing JSON Schema conversion.
  --ai: call Claude API for intelligent content extraction (vs regex-only).

foundation-addon rollback [--to <timestamp>] [--target <provider>]
                          [--list]
  --list: show all available backups with timestamps and changed files.
  --to <timestamp>: restore specific backup.
  No flags: restore most recent backup.
  Auto-prunes backups older than 7 most recent.

foundation-addon skill add <tier/name> [--version <semver-range>]
foundation-addon skill remove <tier/name>
foundation-addon skill list [--tier <tier>] [--outdated]
foundation-addon skill update [<tier/name>] [--all]
  Manage which skills are declared in foundation-addon.lock.yaml.
  skill add writes to lockfile + runs generate + install for that skill.

foundation-addon dev [--target <provider>] [--port <n>]
  Development mode: watch packages/canonical/ for changes.
  Auto-regenerates and auto-installs on save.
  Hot-reload for rapid skill iteration.

foundation-addon doctor
  Full environment health check:
  - Bun version (warn if < 1.0)
  - API key presence per provider (present/missing — NEVER logs values)
  - Config file validity (providers.yaml, mcp-servers.yaml, policies.yaml)
  - dist/ populated state per provider
  - .foundation-addon/ state directory integrity
  - plugin.json validity
  - foundation-addon.lock.yaml consistency with installed skills
  Outputs a structured health report with ✅/⚠️/❌ per check.
```

### Per-Project Lockfile (`foundation-addon.lock.yaml`)

Written by `init`, managed by `skill add/remove/update`:

```yaml
spec_version: "1.0"
addon_version: "0.1.0"
targets: [claude, codex]
skills:
  core/adaptive-skill-orchestrator: "^1.0.0"
  engineering/code-review: "^1.0.0"
  superpowers/systematic-debugging: "^1.0.0"
  superpowers/brainstorming: "^1.0.0"
  superpowers/writing-plans: "^1.0.0"
```

`install` reads the lockfile, resolves semver ranges, only installs declared skills at declared versions. Reproducible installs across machines.

---

## 8. Error Taxonomy

All commands exit with deterministic codes. Machine-readable errors on stderr with `--json`:

```typescript
interface StructuredError {
  code: ErrorCode
  message: string
  skill?: string
  provider?: string
  field?: string          // For validation errors: which field failed
  fix?: string            // Always included — human-readable suggested fix
}
```

| Exit Code | Name | When |
|-----------|------|------|
| 0 | Success | Command completed successfully |
| 1 | ValidationError | spec.yaml schema fails, core.md lint fails, input validation fails |
| 2 | AdapterError | Provider API timeout, malformed response, rate limit |
| 3 | FilesystemError | Permission denied, path not found, disk full |
| 4 | ConfigError | Missing API key, invalid providers.yaml, missing lockfile |
| 5 | TrustViolation | Skill exceeds declared trust_tier at runtime |
| 6 | CompositionError | Circular dependency, missing dependency in DAG |
| 7 | ContextOverflow | Prompt exceeds provider context limit and --no-truncate set |

---

## 9. Context Window Management

Each adapter declares `contextLimitTokens`. The runner enforces a three-tier strategy before every API call:

| Token Estimate vs Limit | Action |
|------------------------|--------|
| < 80% | Proceed normally |
| 80–95% | Warn user, proceed |
| > 95% | Truncate oldest non-system messages (log count), warn, proceed |
| > 95% with `--no-truncate` | Exit code 7, structured error |

Truncation is always logged to the audit trail. Token estimation uses tiktoken approximation (±10% accuracy — sufficient for threshold decisions).

---

## 10. Telemetry

**Default: OFF.** Opt-in via `config/providers.yaml`.  
**Scope: Local-only.** Zero network calls unless `webhook_url` is configured.  
**PII policy:** No code content, no prompts, no responses. Only event metadata.

```yaml
# config/providers.yaml
telemetry:
  enabled: false          # Opt-in required
  webhook_url: null       # Optional: POST events to n8n / home server dashboard
```

### Event Schema (`.foundation-addon/telemetry.jsonl`)

```json
{
  "event": "skill.invoked",
  "timestamp": "2026-04-11T10:00:00Z",
  "skill": "engineering/code-review",
  "provider": "claude",
  "addon_version": "0.1.0",
  "duration_ms": 1234,
  "error_code": null
}
```

### Event Types
- `skill.invoked`, `skill.completed`, `skill.failed`
- `generate.started`, `generate.completed`
- `install.started`, `install.completed`
- `validate.passed`, `validate.failed`

### Audit Log (`.foundation-addon/audit.jsonl`) — Always On

Separate from telemetry. Append-only. Records every install, uninstall, rollback, and invoke with full traceability. Never pruned. Used for compliance and debugging.

```json
{
  "action": "install",
  "timestamp": "2026-04-11T10:00:00Z",
  "target": "claude",
  "skills": ["engineering/code-review"],
  "backup_path": ".foundation-addon/backups/2026-04-11T10:00:00Z/"
}
```

---

## 11. Install Safety: Conflict Resolution & Rollback

### Sentinel Block Strategy

For shared artifact files (`AGENTS.md`, `GEMINI.md`, `qwen-skills.md`), each skill's generated content is wrapped in sentinel comments:

```
<!-- foundation-addon:start:engineering/code-review -->
...generated content for this skill...
<!-- foundation-addon:end:engineering/code-review -->
```

`sentinel.ts` utilities:
- **Write:** insert sentinel block if not present; replace content between sentinels if present
- **Remove:** delete the sentinel block and its content; surrounding content untouched
- **List:** find all foundation-addon-managed blocks in a file
- **Validate:** check for corrupted/unclosed sentinel pairs

User content outside all foundation-addon sentinel blocks is guaranteed to never be modified.

### Backup & Rollback

Before any `install` or `uninstall` operation:
1. Snapshot all target files to `.foundation-addon/backups/{ISO-timestamp}/`
2. Write backup manifest listing what was snapshotted
3. On install failure: auto-rollback to the snapshot taken before this operation
4. Manual rollback: `foundation-addon rollback [--to <timestamp>]`
5. Auto-prune: keep the 7 most recent backups (configurable in `policies.yaml`)

---

## 12. Skill Composition Model

`depends_on` in spec.yaml declares runtime dependencies. The runner builds a DAG and validates it at `validate` time.

**Cycle detection:** `validate` runs Kahn's algorithm on the full dependency graph. Any cycle = exit code 6 with the cycle path shown.

**Invoke-time resolution:**
1. Load requested skill + all transitive dependencies
2. Topological sort → execution order (leaf nodes first)
3. Execute in order; pass outputs as context to dependent skills
4. Final output = requesting skill's response

**Generate-time behavior:** Each skill generates independently. No composition resolution at build time. This keeps generated artifacts simple and self-contained.

---

## 13. Trust Model (T1–T4)

`trust.ts` enforces the declared `trust_tier` at runtime for `invoke` operations.

| Tier | Name | Capabilities Allowed | Requires |
|------|------|---------------------|----------|
| T1 | Sandboxed | Read-only filesystem, no network, no subprocess | Default for new skills |
| T2 | Standard | File read (declared paths only), limited network (HTTPS GET) | Explicit declaration |
| T3 | Extended | File read + write, subprocess (no shell), full network | Code review by maintainer |
| T4 | Full System | Unrestricted | Explicit user approval at runtime |

T4 skills prompt the user for confirmation before execution, even if they have approved T4 globally.

---

## 14. Phase Roadmap

### Phase 1 — Foundation
**Goal: `foundation-addon generate --target claude` working on all 5 pilot skills**

Deliverables:
- `packages/canonical/schema/spec.schema.json` (v1.0, with all fields from this spec)
- `core.md` lint rules
- `packages/adapters/src/base.ts` + `types.ts`
- `packages/adapters/src/claude.ts` (reference implementation)
- `packages/adapters/src/utils/translate-tools.ts` (Claude section)
- `packages/adapters/src/utils/sentinel.ts`
- `packages/adapters/src/utils/hash.ts`
- `packages/adapters/src/utils/tokenizer.ts`
- `packages/runner/src/cli.ts` (Commander.js entry)
- `foundation-addon generate --target claude` (parallel, incremental)
- `foundation-addon install --target claude --dry-run`
- `foundation-addon validate`
- `foundation-addon doctor`
- `packages/runner/src/errors.ts` (full error taxonomy)
- `packages/runner/src/audit.ts`
- 5 pilot skills in canonical format:
  - `core/adaptive-skill-orchestrator`
  - `superpowers/systematic-debugging`
  - `engineering/code-review`
  - `superpowers/brainstorming`
  - `superpowers/writing-plans`
- Contract tests: Claude adapter payload matches Anthropic SDK TypeScript spec
- `foundation-addon.lock.yaml` for the addon project itself

**Phase Gate:** `foundation-addon generate --target claude` + `install --dry-run` produces valid `.claude/commands/` artifact diffs for all 5 pilot skills. `foundation-addon validate` passes clean. `doctor` shows all green.

---

### Phase 2 — Multi-Provider
**Goal: All 4 providers generating + installing + runtime invoke live**

Deliverables:
- `packages/adapters/src/codex.ts`
- `packages/adapters/src/qwen.ts`
- `packages/adapters/src/gemini.ts`
- `packages/adapters/src/utils/translate-tools.ts` (all 4 providers)
- `foundation-addon generate --target all` (fully parallel)
- `foundation-addon install` (with backup + sentinel + `--dry-run`)
- `foundation-addon uninstall`
- `foundation-addon invoke` (runtime API, input validation, context management)
- `foundation-addon rollback`
- `foundation-addon skill add/remove/list/update`
- `foundation-addon init` (writes lockfile)
- `packages/runner/src/dag.ts` (dependency resolver)
- `packages/runner/src/telemetry.ts`
- `packages/config/providers.yaml`, `mcp-servers.yaml`, `provider-matrix.yaml`, `policies.yaml`
- `.claude-plugin/plugin.json`
- Migrate remaining top-20% skills (~15 more → 20 total canonical)
- Contract tests for all 4 adapters
- `foundation-addon test --golden` passing for all 5 pilot skills

**Phase Gate:** `foundation-addon invoke superpowers/systematic-debugging --provider codex` returns a valid NormalizedResponse. `generate --target all` + `install --dry-run` produces valid artifact diffs for all 4 providers across all 20 migrated skills. `rollback` successfully restores from backup.

---

### Phase 3 — Quality & Scale
**Goal: All 100+ skills migrated, CI-enforced, production-grade distribution**

Deliverables:
- `foundation-addon migrate` (with `--ai` option)
- Bulk migration of remaining 80+ Claude-native skills
- `foundation-addon test` full suite (all skills, golden traces)
- `foundation-addon dev` (watch mode)
- Golden trace tests: <15% behavioral divergence across providers for pilot skills
- `.github/workflows/validate.yml` (on every PR)
- `.github/workflows/golden.yml` (nightly cross-provider)
- `.github/workflows/release.yml` (tags, CHANGELOG, publishes packages)
- `docs/ARCHITECTURE.md`, `docs/MIGRATION.md`, `docs/QUICKSTART.md`, `docs/PROVIDER-GUIDE.md`
- `docs/adr/` — Architecture Decision Records for all 15 DDs
- Trust tier enforcement for T3/T4 skills
- Updated `CLAUDE.md`, `README.md`, `CHANGELOG.md`
- `scripts/audit-skills.ts` running in CI

**Phase Gate:** All 100+ skills in canonical format. All three CI workflows green. Golden traces show <15% behavioral divergence for the 5 pilot skills across all 4 providers. `foundation-addon doctor` shows all green on a fresh clone.

---

## 15. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Prompt portability ≠ response quality portability | High | Medium | `provider_hints.model` per-provider tuning; document expectations in `MIGRATION.md` |
| Migration script produces imperfect `core.md` | High | Low | `migrate --dry-run` review checklist; `--ai` for intelligent extraction; human gate before commit |
| `.claude-plugin/` API immaturity | Medium | Low | Plugin manifest is thin loader — all logic in `packages/`; easy to retrofit |
| Provider tool-calling format drift | Medium | Medium | All translation isolated in `translate-tools.ts` — one file per format change |
| MCP tools not portable to non-Claude | Certain | Medium | Pure JSON Schema tools; MCP bridge in Claude adapter only; `mcp_supported` flag for future |
| Install clobbers user content | Low | High | Sentinel blocks protect user content; backup-before-install; `--dry-run` default in docs |
| Circular skill dependencies introduced | Low | Medium | DAG cycle detection in `validate`; exit code 6 with cycle path shown |
| Context overflow silently truncates important content | Medium | Medium | 80%/95% warning/truncation thresholds; audit log records all truncation events; `--no-truncate` flag |

---

## 16. Future-Proofing & Extensibility

These are not in scope for any current phase but the architecture explicitly supports them without rework:

| Capability | How It's Enabled |
|------------|-----------------|
| **Streaming responses** | `NormalizedResponse.stream?: ReadableStream<string>` + `streaming: true` in spec.yaml |
| **Multi-modal inputs** | `inputs[].type` supports `image \| audio \| file` already in schema |
| **MCP support for new providers** | Flip `mcp_supported: true` in `provider-matrix.yaml` — adapter auto-upgrades |
| **Hot reload dev mode** | `foundation-addon dev --watch` watches `canonical/`, auto-generates + installs |
| **Webhook telemetry** | `telemetry.webhook_url` in `providers.yaml` — POST events to n8n / home server |
| **Registry federation** | `foundation-addon skill add github:user/repo` — pull external canonical skills |
| **AI-assisted migration** | `migrate --ai` — calls Claude API for intelligent SKILL.md content extraction |
| **Semantic skill search** | Qdrant MCP + skill embeddings → `foundation-addon skill search "debug async code"` |
| **Token cost tracking** | `usage` field in `NormalizedResponse` already captures input/output tokens; cost layer adds per-provider pricing |
| **Plugin marketplace publishing** | `.claude-plugin/marketplace.json` is already in place |

---

## 17. Pilot Skills — Phase 1 Migration Targets

| Skill | Tier | Why This One First |
|-------|------|--------------------|
| `adaptive-skill-orchestrator` | core | Meta-routing logic — tests complex prompt + decision branching |
| `systematic-debugging` | superpowers | 4-phase sequential process — tests structured multi-step reasoning |
| `code-review` | engineering | Most universally useful — good test of tool use + output structure |
| `brainstorming` | superpowers | Multi-turn dialog — tests conversational flow handling |
| `writing-plans` | superpowers | Structured output — tests plan generation format |

---

*Spec Version 2.0 — written 2026-04-11. Fully patched (Tier 1 + Tier 2). Future-proofed. Ready for implementation planning.*
