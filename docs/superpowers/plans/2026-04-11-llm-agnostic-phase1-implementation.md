# Foundation AddOn — Phase 1 (Foundation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the monorepo scaffold, Claude adapter, 5 canonical pilot skills, and `foundation-addon generate --target claude` CLI — proving the full build-time pipeline from spec.yaml → .claude/commands/ artifact.

**Architecture:** Bun workspace monorepo with four packages: `canonical` (skill source of truth), `adapters` (provider translators), `runner` (CLI), `config` (YAML configs). The Claude adapter reads `core.md` + `spec.yaml`, generates `.claude/commands/{name}.md` artifacts into `dist/claude/`. The `install` command promotes those artifacts safely with backup. The `validate` command enforces spec.schema.json + core.md lint rules.

**Tech Stack:** TypeScript + Bun (runtime + test runner + bundler), Commander.js (CLI subcommands), Ajv (JSON Schema validation), js-yaml (YAML parsing), Node.js `crypto` (SHA-256 hashing)

**Spec:** `docs/superpowers/specs/2026-04-11-llm-agnostic-architecture-design.md`

---

## File Map

All files created in Phase 1. Zero existing files modified.

```
packages/
  canonical/
    package.json
    VERSION
    manifest.yaml
    .cache/               ← gitignored
    schema/
      spec.schema.json    ← JSON Schema for spec.yaml (v1.0)
      tool.schema.json    ← JSON Schema for tool definitions
    skills/
      core/adaptive-skill-orchestrator/
        spec.yaml
        core.md
      superpowers/systematic-debugging/
        spec.yaml
        core.md
      engineering/code-review/
        spec.yaml
        core.md
        tools/read-file.json
      superpowers/brainstorming/
        spec.yaml
        core.md
      superpowers/writing-plans/
        spec.yaml
        core.md

  adapters/
    package.json
    tsconfig.json
    src/
      types.ts            ← SkillSpec, CLMIMessage, NormalizedResponse, ToolResult, JSONSchema
      base.ts             ← BaseAdapter abstract class
      claude.ts           ← ClaudeAdapter (generateArtifact + translateTools)
      utils/
        translate-tools.ts ← JSON Schema → Anthropic tool format
        sentinel.ts        ← Fenced block read/write/merge/remove/list
        hash.ts            ← SHA-256 content hashing
        tokenizer.ts       ← Token count estimation + context warning

  runner/
    package.json
    tsconfig.json
    src/
      cli.ts              ← Commander.js entry point
      errors.ts           ← Error taxonomy, exit codes, StructuredError, FoundationAddonError
      audit.ts            ← Append-only .foundation-addon/audit.jsonl
      registry.ts         ← Skill discovery, loadSkill(), discoverSkills()
      commands/
        generate.ts       ← generate command (parallel, incremental, Claude only)
        validate.ts       ← validate command (Ajv schema + core.md lint)
        install.ts        ← install command (backup-first, --dry-run)
        doctor.ts         ← doctor command (env health check)

  config/
    package.json
    providers.yaml
    mcp-servers.yaml
    provider-matrix.yaml
    policies.yaml

.claude-plugin/
  plugin.json
  marketplace.json

tests/
  contract/
    claude-adapter.test.ts
    fixtures/
      mock-spec.ts

dist/                     ← gitignored
.foundation-addon/        ← gitignored
package.json              ← workspace root
bunfig.toml
tsconfig.base.json
.gitignore                ← updated
VERSION                   ← 0.1.0
foundation-addon.lock.yaml
```

---

## Task 1: Monorepo Scaffold

**Files:**
- Create: `package.json` (workspace root)
- Create: `bunfig.toml`
- Create: `tsconfig.base.json`
- Create: `packages/canonical/package.json`
- Create: `packages/adapters/package.json`
- Create: `packages/adapters/tsconfig.json`
- Create: `packages/runner/package.json`
- Create: `packages/runner/tsconfig.json`
- Create: `packages/config/package.json`
- Create: `.gitignore`
- Create: `VERSION`

- [ ] **Step 1: Create workspace root `package.json`**

```json
{
  "name": "foundation-addon",
  "version": "0.1.0",
  "private": true,
  "workspaces": ["packages/*"],
  "scripts": {
    "build": "bun build packages/runner/src/cli.ts --compile --outfile foundation-addon",
    "test": "bun test",
    "validate": "bun run packages/runner/src/cli.ts validate",
    "generate": "bun run packages/runner/src/cli.ts generate"
  }
}
```

- [ ] **Step 2: Create `bunfig.toml`**

```toml
[install]
exact = false

[test]
preload = []
```

- [ ] **Step 3: Create `tsconfig.base.json`**

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

- [ ] **Step 4: Create `packages/adapters/package.json`**

```json
{
  "name": "@foundation-addon/adapters",
  "version": "0.1.0",
  "module": "src/index.ts",
  "types": "src/index.ts",
  "private": true,
  "dependencies": {
    "@anthropic-ai/sdk": "^0.39.0",
    "ajv": "^8.17.1",
    "js-yaml": "^4.1.0",
    "zod": "^3.24.1"
  },
  "devDependencies": {
    "@types/js-yaml": "^4.0.9",
    "@types/node": "^20.0.0",
    "typescript": "^5.4.5"
  }
}
```

- [ ] **Step 5: Create `packages/adapters/tsconfig.json`**

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"]
}
```

- [ ] **Step 6: Create `packages/runner/package.json`**

```json
{
  "name": "@foundation-addon/runner",
  "version": "0.1.0",
  "bin": { "foundation-addon": "src/cli.ts" },
  "private": true,
  "dependencies": {
    "@foundation-addon/adapters": "workspace:*",
    "ajv": "^8.17.1",
    "chalk": "^5.3.0",
    "commander": "^12.1.0",
    "js-yaml": "^4.1.0"
  },
  "devDependencies": {
    "@types/js-yaml": "^4.0.9",
    "@types/node": "^20.0.0",
    "typescript": "^5.4.5"
  }
}
```

- [ ] **Step 7: Create `packages/runner/tsconfig.json`**

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"]
}
```

- [ ] **Step 8: Create `packages/canonical/package.json`**

```json
{
  "name": "@foundation-addon/canonical",
  "version": "0.1.0",
  "private": true
}
```

- [ ] **Step 9: Create `packages/config/package.json`**

```json
{
  "name": "@foundation-addon/config",
  "version": "0.1.0",
  "private": true
}
```

- [ ] **Step 10: Create `VERSION`**

```
0.1.0
```

- [ ] **Step 11: Create `.gitignore`** (appending to existing)

```
# Foundation AddOn generated artifacts — never commit
dist/
.foundation-addon/
packages/canonical/.cache/

# Build output
foundation-addon
foundation-addon.exe
packages/*/dist/
node_modules/
```

- [ ] **Step 12: Install dependencies**

```bash
cd "z:/MiniPC_Docker_Automation/Projects_Repos/! Foundation_AddOn_Project - LLM_Agnostic"
bun install
```

Expected: lockfile created, node_modules populated across all packages.

- [ ] **Step 13: Verify workspace is wired**

```bash
bun pm ls
```

Expected: lists `@foundation-addon/adapters`, `@foundation-addon/runner`, `@foundation-addon/canonical`, `@foundation-addon/config`

- [ ] **Step 14: Commit**

```bash
git add package.json bunfig.toml tsconfig.base.json VERSION .gitignore packages/*/package.json packages/*/tsconfig.json bun.lockb
git commit -m "feat: initialize Bun workspace monorepo for LLM-agnostic foundation"
```

---

## Task 2: JSON Schema Definitions

**Files:**
- Create: `packages/canonical/schema/spec.schema.json`
- Create: `packages/canonical/schema/tool.schema.json`

- [ ] **Step 1: Write the failing test**

Create `tests/contract/schema-validation.test.ts`:

```typescript
import { test, expect, describe } from 'bun:test'
import Ajv from 'ajv'
import { readFileSync } from 'fs'
import { join } from 'path'

const SCHEMA_DIR = join(import.meta.dir, '../../packages/canonical/schema')

function loadSchema(name: string) {
  return JSON.parse(readFileSync(join(SCHEMA_DIR, name), 'utf8'))
}

describe('spec.schema.json', () => {
  test('validates a minimal valid spec', () => {
    const ajv = new Ajv()
    const schema = loadSchema('spec.schema.json')
    const validate = ajv.compile(schema)

    const validSpec = {
      spec_version: '1.0',
      name: 'code-review',
      version: '1.0.0',
      description: 'Expert code review for correctness and security',
      tier: 'engineering',
      capabilities: ['code_analysis'],
      trust_tier: 'T2',
      author: 'foundation-addon',
    }

    expect(validate(validSpec)).toBe(true)
  })

  test('rejects spec missing required field "author"', () => {
    const ajv = new Ajv()
    const schema = loadSchema('spec.schema.json')
    const validate = ajv.compile(schema)

    const invalidSpec = {
      spec_version: '1.0',
      name: 'code-review',
      version: '1.0.0',
      description: 'Expert code review',
      tier: 'engineering',
      capabilities: ['code_analysis'],
      trust_tier: 'T2',
      // missing author
    }

    expect(validate(invalidSpec)).toBe(false)
  })

  test('rejects invalid trust_tier value', () => {
    const ajv = new Ajv()
    const schema = loadSchema('spec.schema.json')
    const validate = ajv.compile(schema)

    const invalidSpec = {
      spec_version: '1.0',
      name: 'code-review',
      version: '1.0.0',
      description: 'Expert code review',
      tier: 'engineering',
      capabilities: ['code_analysis'],
      trust_tier: 'T5', // invalid
      author: 'foundation-addon',
    }

    expect(validate(invalidSpec)).toBe(false)
  })

  test('rejects invalid tier value', () => {
    const ajv = new Ajv()
    const schema = loadSchema('spec.schema.json')
    const validate = ajv.compile(schema)

    const invalidSpec = {
      spec_version: '1.0',
      name: 'code-review',
      version: '1.0.0',
      description: 'Expert code review',
      tier: 'invalid-tier', // not in enum
      capabilities: ['code_analysis'],
      trust_tier: 'T2',
      author: 'foundation-addon',
    }

    expect(validate(invalidSpec)).toBe(false)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bun test tests/contract/schema-validation.test.ts
```

Expected: FAIL — `spec.schema.json not found`

- [ ] **Step 3: Create `packages/canonical/schema/spec.schema.json`**

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://foundation-addon/spec.schema.json",
  "title": "SkillSpec",
  "type": "object",
  "required": ["spec_version", "name", "version", "description", "tier", "capabilities", "trust_tier", "author"],
  "additionalProperties": false,
  "properties": {
    "spec_version": { "type": "string", "enum": ["1.0"] },
    "name": { "type": "string", "pattern": "^[a-z][a-z0-9-]*$" },
    "version": { "type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$" },
    "description": { "type": "string", "minLength": 10, "maxLength": 200 },
    "tier": {
      "type": "string",
      "enum": ["core", "engineering", "gstack", "strategy", "superpowers", "tech"]
    },
    "inputs": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "type"],
        "additionalProperties": false,
        "properties": {
          "name": { "type": "string" },
          "type": { "type": "string", "enum": ["string", "number", "boolean", "enum", "image", "audio", "file"] },
          "required": { "type": "boolean", "default": false },
          "description": { "type": "string" },
          "values": { "type": "array", "items": { "type": "string" } },
          "default": {}
        }
      }
    },
    "capabilities": {
      "type": "array",
      "items": { "type": "string" },
      "minItems": 1
    },
    "tools": {
      "type": "array",
      "items": { "type": "string", "pattern": "^tools/[a-z][a-z0-9-]*\\.json$" }
    },
    "depends_on": {
      "type": "array",
      "items": { "type": "string", "pattern": "^[a-z]+/[a-z][a-z0-9-]*$" }
    },
    "provider_hints": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "claude": { "$ref": "#/definitions/ProviderHint" },
        "codex": { "$ref": "#/definitions/ProviderHint" },
        "qwen": { "$ref": "#/definitions/ProviderHint" },
        "gemini": { "$ref": "#/definitions/ProviderHint" }
      }
    },
    "trust_tier": { "type": "string", "enum": ["T1", "T2", "T3", "T4"] },
    "tags": { "type": "array", "items": { "type": "string" } },
    "composable": { "type": "boolean" },
    "parallel_safe": { "type": "boolean" },
    "streaming": { "type": "boolean" },
    "author": { "type": "string", "minLength": 1 }
  },
  "definitions": {
    "ProviderHint": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "model": { "type": "string" },
        "system_prefix": { "type": "string" },
        "system_suffix": { "type": "string" },
        "max_tokens": { "type": "integer", "minimum": 1 },
        "temperature": { "type": "number", "minimum": 0, "maximum": 1 }
      }
    }
  }
}
```

- [ ] **Step 4: Create `packages/canonical/schema/tool.schema.json`**

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://foundation-addon/tool.schema.json",
  "title": "ToolDefinition",
  "type": "object",
  "required": ["name", "description", "parameters"],
  "additionalProperties": false,
  "properties": {
    "$schema": { "type": "string" },
    "name": { "type": "string", "pattern": "^[a-z][a-z0-9_]*$" },
    "description": { "type": "string", "minLength": 5 },
    "parameters": {
      "type": "object",
      "required": ["type", "properties"],
      "properties": {
        "type": { "type": "string", "enum": ["object"] },
        "properties": { "type": "object" },
        "required": { "type": "array", "items": { "type": "string" } }
      }
    }
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
bun test tests/contract/schema-validation.test.ts
```

Expected: All 4 tests PASS

- [ ] **Step 6: Commit**

```bash
git add packages/canonical/schema/ tests/contract/schema-validation.test.ts
git commit -m "feat: add spec.schema.json and tool.schema.json with contract tests"
```

---

## Task 3: Adapter Types + BaseAdapter

**Files:**
- Create: `packages/adapters/src/types.ts`
- Create: `packages/adapters/src/base.ts`
- Create: `packages/adapters/src/index.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/contract/base-adapter.test.ts`:

```typescript
import { test, expect, describe } from 'bun:test'
import { BaseAdapter } from '../../packages/adapters/src/base'
import type { SkillSpec, CLMIMessage, NormalizedResponse, JSONSchema } from '../../packages/adapters/src/types'

// Concrete stub to test the abstract contract
class StubAdapter extends BaseAdapter {
  readonly provider = 'stub'
  readonly contextLimitTokens = 1000

  generateArtifact(spec: SkillSpec, core: string): string {
    return `${spec.name}:${core}`
  }
  formatPrompt(_spec: SkillSpec, _core: string, _messages: CLMIMessage[]): unknown {
    return { stub: true }
  }
  parseResponse(_raw: unknown): NormalizedResponse {
    return { content: 'stub', stop_reason: 'end' }
  }
  translateTools(_tools: JSONSchema[]): unknown[] {
    return []
  }
}

describe('BaseAdapter contract', () => {
  test('concrete adapter fulfills abstract interface', () => {
    const adapter = new StubAdapter()
    expect(adapter.provider).toBe('stub')
    expect(adapter.contextLimitTokens).toBe(1000)
  })

  test('generateArtifact is callable', () => {
    const adapter = new StubAdapter()
    const spec = {
      spec_version: '1.0', name: 'test', version: '1.0.0',
      description: 'Test skill', tier: 'core' as const,
      capabilities: ['test'], trust_tier: 'T1' as const, author: 'test',
    }
    const result = adapter.generateArtifact(spec, 'core content')
    expect(result).toBe('test:core content')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bun test tests/contract/base-adapter.test.ts
```

Expected: FAIL — `Cannot find module '../../packages/adapters/src/base'`

- [ ] **Step 3: Create `packages/adapters/src/types.ts`**

```typescript
export type ProviderName = 'claude' | 'codex' | 'qwen' | 'gemini'
export type TrustTier = 'T1' | 'T2' | 'T3' | 'T4'
export type Tier = 'core' | 'engineering' | 'gstack' | 'strategy' | 'superpowers' | 'tech'
export type InputType = 'string' | 'number' | 'boolean' | 'enum' | 'image' | 'audio' | 'file'

export interface ProviderHint {
  model?: string
  system_prefix?: string
  system_suffix?: string
  max_tokens?: number
  temperature?: number
}

export interface SkillInput {
  name: string
  type: InputType
  required?: boolean
  description?: string
  values?: string[]
  default?: unknown
}

export interface SkillSpec {
  spec_version: string
  name: string
  version: string
  description: string
  tier: Tier
  inputs?: SkillInput[]
  capabilities: string[]
  tools?: string[]
  depends_on?: string[]
  provider_hints?: Partial<Record<ProviderName, ProviderHint>>
  trust_tier: TrustTier
  tags?: string[]
  composable?: boolean
  parallel_safe?: boolean
  streaming?: boolean
  author: string
}

export interface JSONSchema {
  $schema?: string
  name: string
  description: string
  parameters: {
    type: 'object'
    properties: Record<string, unknown>
    required?: string[]
  }
}

export interface ToolCall {
  id: string
  name: string
  input: Record<string, unknown>
}

export interface ToolResult {
  tool_call_id: string
  tool_name: string
  content: string
  is_error: boolean
  duration_ms?: number
}

export interface CLMIMessage {
  role: 'user' | 'assistant' | 'system' | 'tool'
  content: string
  tool_calls?: ToolCall[]
  tool_results?: ToolResult[]
}

export interface NormalizedResponse {
  content: string
  stop_reason: 'end' | 'tool_use' | 'max_tokens' | 'error'
  tool_calls?: ToolCall[]
  usage?: { input_tokens: number; output_tokens: number }
  stream?: ReadableStream<string>
}
```

- [ ] **Step 4: Create `packages/adapters/src/base.ts`**

```typescript
import type { SkillSpec, CLMIMessage, NormalizedResponse, JSONSchema } from './types.js'

export abstract class BaseAdapter {
  abstract readonly provider: string
  abstract readonly contextLimitTokens: number

  /** Build-time: compile canonical skill → workspace artifact string */
  abstract generateArtifact(spec: SkillSpec, core: string): string

  /** Runtime: translate canonical skill + messages → provider API payload */
  abstract formatPrompt(spec: SkillSpec, core: string, messages: CLMIMessage[]): unknown

  /** Runtime: normalize provider response → CLMI NormalizedResponse */
  abstract parseResponse(raw: unknown): NormalizedResponse

  /** Translate JSON Schema tool definitions → provider-native tool format */
  abstract translateTools(tools: JSONSchema[]): unknown[]
}
```

- [ ] **Step 5: Create `packages/adapters/src/index.ts`**

```typescript
export { BaseAdapter } from './base.js'
export { ClaudeAdapter } from './claude.js'
export * from './types.js'
```

- [ ] **Step 6: Run test to verify it passes**

```bash
bun test tests/contract/base-adapter.test.ts
```

Expected: 2 tests PASS

- [ ] **Step 7: Commit**

```bash
git add packages/adapters/src/types.ts packages/adapters/src/base.ts packages/adapters/src/index.ts tests/contract/base-adapter.test.ts
git commit -m "feat: add CLMI types and BaseAdapter abstract class"
```

---

## Task 4: Utility Functions (hash, tokenizer, sentinel)

**Files:**
- Create: `packages/adapters/src/utils/hash.ts`
- Create: `packages/adapters/src/utils/tokenizer.ts`
- Create: `packages/adapters/src/utils/sentinel.ts`

- [ ] **Step 1: Write the failing tests**

Create `tests/contract/utils.test.ts`:

```typescript
import { test, expect, describe } from 'bun:test'
import { sha256, hashSkillSources } from '../../packages/adapters/src/utils/hash'
import { estimateTokens, checkContextUsage } from '../../packages/adapters/src/utils/tokenizer'
import { insertOrReplace, removeBlock, listBlocks, startTag, endTag } from '../../packages/adapters/src/utils/sentinel'

describe('hash', () => {
  test('sha256 returns 64-char hex string', () => {
    const result = sha256('hello world')
    expect(result).toHaveLength(64)
    expect(result).toMatch(/^[0-9a-f]+$/)
  })

  test('same input produces same hash', () => {
    expect(sha256('test')).toBe(sha256('test'))
  })

  test('different input produces different hash', () => {
    expect(sha256('test1')).not.toBe(sha256('test2'))
  })

  test('hashSkillSources combines all inputs', () => {
    const h1 = hashSkillSources('core', 'spec', ['tool1'])
    const h2 = hashSkillSources('core', 'spec', ['tool2'])
    expect(h1).not.toBe(h2)
  })
})

describe('tokenizer', () => {
  test('estimateTokens approximates by character count', () => {
    const tokens = estimateTokens('hello world')
    expect(tokens).toBeGreaterThan(0)
    expect(typeof tokens).toBe('number')
  })

  test('checkContextUsage returns "none" below 80%', () => {
    expect(checkContextUsage(700, 1000)).toBe('none')
  })

  test('checkContextUsage returns "warn" at 85%', () => {
    expect(checkContextUsage(850, 1000)).toBe('warn')
  })

  test('checkContextUsage returns "truncate" at 96%', () => {
    expect(checkContextUsage(960, 1000)).toBe('truncate')
  })
})

describe('sentinel', () => {
  test('insertOrReplace appends new block to empty file', () => {
    const result = insertOrReplace('', 'my-skill', 'skill content')
    expect(result).toContain(startTag('my-skill'))
    expect(result).toContain('skill content')
    expect(result).toContain(endTag('my-skill'))
  })

  test('insertOrReplace replaces existing block content', () => {
    const original = insertOrReplace('', 'my-skill', 'old content')
    const updated = insertOrReplace(original, 'my-skill', 'new content')
    expect(updated).toContain('new content')
    expect(updated).not.toContain('old content')
  })

  test('insertOrReplace preserves content outside sentinels', () => {
    const existing = 'User content here\n'
    const result = insertOrReplace(existing, 'my-skill', 'skill content')
    expect(result).toContain('User content here')
    expect(result).toContain('skill content')
  })

  test('removeBlock removes sentinel block and its content', () => {
    const withBlock = insertOrReplace('before\n', 'my-skill', 'skill content')
    const removed = removeBlock(withBlock, 'my-skill')
    expect(removed).not.toContain('skill content')
    expect(removed).not.toContain(startTag('my-skill'))
    expect(removed).toContain('before')
  })

  test('removeBlock is a no-op when block not present', () => {
    const content = 'no blocks here'
    expect(removeBlock(content, 'missing-skill')).toBe(content)
  })

  test('listBlocks returns all skill names in file', () => {
    let content = ''
    content = insertOrReplace(content, 'skill-a', 'content a')
    content = insertOrReplace(content, 'skill-b', 'content b')
    const blocks = listBlocks(content)
    expect(blocks).toContain('skill-a')
    expect(blocks).toContain('skill-b')
    expect(blocks).toHaveLength(2)
  })
})
```

- [ ] **Step 2: Run to verify failure**

```bash
bun test tests/contract/utils.test.ts
```

Expected: FAIL — modules not found

- [ ] **Step 3: Create `packages/adapters/src/utils/hash.ts`**

```typescript
import { createHash } from 'crypto'

export function sha256(content: string): string {
  return createHash('sha256').update(content, 'utf8').digest('hex')
}

export function hashSkillSources(
  coreMd: string,
  specYaml: string,
  toolJsons: string[]
): string {
  const combined = [coreMd, specYaml, ...toolJsons.sort()].join('\n---\n')
  return sha256(combined)
}
```

- [ ] **Step 4: Create `packages/adapters/src/utils/tokenizer.ts`**

```typescript
// Approximation: ~4 characters per token (conservative estimate, ±10%)
const CHARS_PER_TOKEN = 4

export function estimateTokens(text: string): number {
  return Math.ceil(text.length / CHARS_PER_TOKEN)
}

export function estimatePromptTokens(
  systemPrompt: string,
  messages: { content: string }[]
): number {
  const allContent = [systemPrompt, ...messages.map((m) => m.content)].join(' ')
  return estimateTokens(allContent)
}

export type ContextWarning = 'none' | 'warn' | 'truncate'

export function checkContextUsage(
  estimatedTokens: number,
  limitTokens: number
): ContextWarning {
  const ratio = estimatedTokens / limitTokens
  if (ratio >= 0.95) return 'truncate'
  if (ratio >= 0.80) return 'warn'
  return 'none'
}
```

- [ ] **Step 5: Create `packages/adapters/src/utils/sentinel.ts`**

```typescript
const START_PREFIX = '<!-- foundation-addon:start:'
const END_PREFIX = '<!-- foundation-addon:end:'
const SENTINEL_SUFFIX = ' -->'

export function startTag(skillName: string): string {
  return `${START_PREFIX}${skillName}${SENTINEL_SUFFIX}`
}

export function endTag(skillName: string): string {
  return `${END_PREFIX}${skillName}${SENTINEL_SUFFIX}`
}

export function insertOrReplace(
  existingContent: string,
  skillName: string,
  newBlock: string
): string {
  const start = startTag(skillName)
  const end = endTag(skillName)
  const block = `${start}\n${newBlock}\n${end}`

  const startIdx = existingContent.indexOf(start)
  if (startIdx === -1) {
    // Not present: append
    const sep = existingContent.length > 0 && !existingContent.endsWith('\n') ? '\n' : ''
    return `${existingContent}${sep}\n${block}\n`
  }

  const endIdx = existingContent.indexOf(end, startIdx)
  if (endIdx === -1) {
    throw new Error(
      `Corrupted sentinel: found start tag but no end tag for skill "${skillName}"`
    )
  }

  return (
    existingContent.slice(0, startIdx) +
    block +
    existingContent.slice(endIdx + end.length)
  )
}

export function removeBlock(existingContent: string, skillName: string): string {
  const start = startTag(skillName)
  const end = endTag(skillName)

  const startIdx = existingContent.indexOf(start)
  if (startIdx === -1) return existingContent

  const endIdx = existingContent.indexOf(end, startIdx)
  if (endIdx === -1) {
    throw new Error(
      `Corrupted sentinel: found start tag but no end tag for skill "${skillName}"`
    )
  }

  let before = existingContent.slice(0, startIdx)
  const after = existingContent.slice(endIdx + end.length)

  if (before.endsWith('\n\n')) before = before.slice(0, -1)

  return before + after
}

export function listBlocks(content: string): string[] {
  const blocks: string[] = []
  const pattern = /<!-- foundation-addon:start:([^>]+) -->/g
  let match
  while ((match = pattern.exec(content)) !== null) {
    blocks.push(match[1])
  }
  return blocks
}
```

- [ ] **Step 6: Run tests to verify all pass**

```bash
bun test tests/contract/utils.test.ts
```

Expected: All 14 tests PASS

- [ ] **Step 7: Commit**

```bash
git add packages/adapters/src/utils/ tests/contract/utils.test.ts
git commit -m "feat: add hash, tokenizer, and sentinel utilities with tests"
```

---

## Task 5: Error Taxonomy + Audit Log

**Files:**
- Create: `packages/runner/src/errors.ts`
- Create: `packages/runner/src/audit.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/contract/errors.test.ts`:

```typescript
import { test, expect, describe } from 'bun:test'
import { ErrorCode, FoundationAddonError, formatError } from '../../packages/runner/src/errors'

describe('ErrorCode', () => {
  test('Success is 0', () => expect(ErrorCode.Success).toBe(0))
  test('ValidationError is 1', () => expect(ErrorCode.ValidationError).toBe(1))
  test('AdapterError is 2', () => expect(ErrorCode.AdapterError).toBe(2))
  test('FilesystemError is 3', () => expect(ErrorCode.FilesystemError).toBe(3))
  test('ConfigError is 4', () => expect(ErrorCode.ConfigError).toBe(4))
  test('TrustViolation is 5', () => expect(ErrorCode.TrustViolation).toBe(5))
  test('CompositionError is 6', () => expect(ErrorCode.CompositionError).toBe(6))
  test('ContextOverflow is 7', () => expect(ErrorCode.ContextOverflow).toBe(7))
})

describe('FoundationAddonError', () => {
  test('wraps structured error', () => {
    const err = new FoundationAddonError({
      code: ErrorCode.ValidationError,
      message: 'spec is invalid',
      skill: 'code-review',
      fix: 'Check your spec.yaml',
    })
    expect(err.structured.code).toBe(1)
    expect(err.message).toBe('spec is invalid')
    expect(err.structured.skill).toBe('code-review')
  })
})

describe('formatError', () => {
  test('plain text includes all fields', () => {
    const formatted = formatError(
      { code: ErrorCode.ValidationError, message: 'bad spec', skill: 'my-skill', fix: 'fix it' },
      false
    )
    expect(formatted).toContain('ValidationError')
    expect(formatted).toContain('bad spec')
    expect(formatted).toContain('my-skill')
    expect(formatted).toContain('fix it')
  })

  test('json mode returns parseable JSON with error key', () => {
    const formatted = formatError(
      { code: ErrorCode.ConfigError, message: 'missing key' },
      true
    )
    const parsed = JSON.parse(formatted)
    expect(parsed.error.code).toBe(4)
    expect(parsed.error.message).toBe('missing key')
  })
})
```

- [ ] **Step 2: Run to verify failure**

```bash
bun test tests/contract/errors.test.ts
```

Expected: FAIL — module not found

- [ ] **Step 3: Create `packages/runner/src/errors.ts`**

```typescript
export enum ErrorCode {
  Success = 0,
  ValidationError = 1,
  AdapterError = 2,
  FilesystemError = 3,
  ConfigError = 4,
  TrustViolation = 5,
  CompositionError = 6,
  ContextOverflow = 7,
}

export interface StructuredError {
  code: ErrorCode
  message: string
  skill?: string
  provider?: string
  field?: string
  fix?: string
}

export class FoundationAddonError extends Error {
  constructor(public readonly structured: StructuredError) {
    super(structured.message)
    this.name = 'FoundationAddonError'
  }
}

export function formatError(err: StructuredError, json: boolean): string {
  if (json) return JSON.stringify({ error: err })

  const lines = [`Error [${ErrorCode[err.code]}]: ${err.message}`]
  if (err.skill) lines.push(`  Skill:    ${err.skill}`)
  if (err.provider) lines.push(`  Provider: ${err.provider}`)
  if (err.field) lines.push(`  Field:    ${err.field}`)
  if (err.fix) lines.push(`  Fix:      ${err.fix}`)
  return lines.join('\n')
}
```

- [ ] **Step 4: Create `packages/runner/src/audit.ts`**

```typescript
import { join, resolve } from 'path'
import { appendFileSync, mkdirSync } from 'fs'

const ADDON_DIR = resolve(process.cwd(), '.foundation-addon')
const AUDIT_FILE = join(ADDON_DIR, 'audit.jsonl')

export interface AuditEntry {
  action: 'generate' | 'install' | 'uninstall' | 'validate' | 'invoke' | 'rollback'
  timestamp: string
  target?: string
  skills?: string[]
  provider?: string
  backup_path?: string
  success: boolean
  error_code?: number
}

export function auditLog(entry: AuditEntry): void {
  try {
    mkdirSync(ADDON_DIR, { recursive: true })
    appendFileSync(AUDIT_FILE, JSON.stringify(entry) + '\n', 'utf8')
  } catch {
    // Audit log failure is non-fatal — never block the main operation
  }
}
```

- [ ] **Step 5: Run tests to verify all pass**

```bash
bun test tests/contract/errors.test.ts
```

Expected: All 11 tests PASS

- [ ] **Step 6: Commit**

```bash
git add packages/runner/src/errors.ts packages/runner/src/audit.ts tests/contract/errors.test.ts
git commit -m "feat: add error taxonomy with exit codes and append-only audit log"
```

---

## Task 6: Claude Adapter + Tool Translation

**Files:**
- Create: `packages/adapters/src/utils/translate-tools.ts`
- Create: `packages/adapters/src/claude.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/contract/claude-adapter.test.ts`:

```typescript
import { test, expect, describe } from 'bun:test'
import { ClaudeAdapter } from '../../packages/adapters/src/claude'
import type { SkillSpec, JSONSchema } from '../../packages/adapters/src/types'

const MOCK_SPEC: SkillSpec = {
  spec_version: '1.0',
  name: 'code-review',
  version: '1.0.0',
  description: 'Expert code review for correctness, security, and performance',
  tier: 'engineering',
  capabilities: ['code_analysis'],
  trust_tier: 'T2',
  author: 'foundation-addon',
  provider_hints: {
    claude: {
      system_prefix: 'Use <thinking> tags for your analysis.',
      model: 'claude-opus-4-6',
    },
  },
}

const MOCK_CORE = `## Code Review\n\nReview code for issues.\n\n## Process\n1. Read the code\n2. Find issues`

describe('ClaudeAdapter', () => {
  const adapter = new ClaudeAdapter()

  test('provider is "claude"', () => {
    expect(adapter.provider).toBe('claude')
  })

  test('contextLimitTokens is 200000', () => {
    expect(adapter.contextLimitTokens).toBe(200_000)
  })

  test('generateArtifact produces YAML frontmatter block', () => {
    const artifact = adapter.generateArtifact(MOCK_SPEC, MOCK_CORE)
    expect(artifact).toStartWith('---\n')
    expect(artifact).toContain('name: code-review')
    expect(artifact).toContain('description: Expert code review for correctness, security, and performance')
    expect(artifact).toContain('type: skill')
    // Frontmatter ends with ---
    const lines = artifact.split('\n')
    const secondDash = lines.slice(1).findIndex(l => l === '---')
    expect(secondDash).toBeGreaterThan(-1)
  })

  test('generateArtifact injects system_prefix from provider_hints.claude', () => {
    const artifact = adapter.generateArtifact(MOCK_SPEC, MOCK_CORE)
    expect(artifact).toContain('Use <thinking> tags for your analysis.')
  })

  test('generateArtifact includes core.md content after frontmatter', () => {
    const artifact = adapter.generateArtifact(MOCK_SPEC, MOCK_CORE)
    expect(artifact).toContain('## Code Review')
    expect(artifact).toContain('Review code for issues.')
  })

  test('generateArtifact works without provider_hints', () => {
    const specWithoutHints: SkillSpec = { ...MOCK_SPEC, provider_hints: undefined }
    const artifact = adapter.generateArtifact(specWithoutHints, MOCK_CORE)
    expect(artifact).toContain('name: code-review')
    expect(artifact).toContain('## Code Review')
  })

  test('translateTools converts JSON Schema to Anthropic input_schema format', () => {
    const schema: JSONSchema = {
      name: 'read_file',
      description: 'Read a file by path',
      parameters: {
        type: 'object',
        properties: { path: { type: 'string', description: 'File path' } },
        required: ['path'],
      },
    }
    const tools = adapter.translateTools([schema])
    expect(tools).toHaveLength(1)
    expect(tools[0]).toMatchObject({
      name: 'read_file',
      description: 'Read a file by path',
      input_schema: schema.parameters,
    })
  })

  test('translateTools handles empty array', () => {
    expect(adapter.translateTools([])).toHaveLength(0)
  })

  test('formatPrompt throws until Phase 2', () => {
    expect(() => adapter.formatPrompt(MOCK_SPEC, MOCK_CORE, [])).toThrow()
  })

  test('parseResponse throws until Phase 2', () => {
    expect(() => adapter.parseResponse({})).toThrow()
  })
})
```

- [ ] **Step 2: Run to verify failure**

```bash
bun test tests/contract/claude-adapter.test.ts
```

Expected: FAIL — `ClaudeAdapter` not found

- [ ] **Step 3: Create `packages/adapters/src/utils/translate-tools.ts`**

```typescript
import type { JSONSchema } from '../types.js'

export interface AnthropicTool {
  name: string
  description: string
  input_schema: Record<string, unknown>
}

export function toClaudeTool(schema: JSONSchema): AnthropicTool {
  return {
    name: schema.name,
    description: schema.description,
    input_schema: schema.parameters as Record<string, unknown>,
  }
}

export function toClaudeTools(schemas: JSONSchema[]): AnthropicTool[] {
  return schemas.map(toClaudeTool)
}
```

- [ ] **Step 4: Create `packages/adapters/src/claude.ts`**

```typescript
import { BaseAdapter } from './base.js'
import { toClaudeTools } from './utils/translate-tools.js'
import type { SkillSpec, CLMIMessage, NormalizedResponse, JSONSchema } from './types.js'
import type { AnthropicTool } from './utils/translate-tools.js'

export class ClaudeAdapter extends BaseAdapter {
  readonly provider = 'claude'
  readonly contextLimitTokens = 200_000

  generateArtifact(spec: SkillSpec, core: string): string {
    const hint = spec.provider_hints?.claude
    const prefix = hint?.system_prefix ? `${hint.system_prefix}\n\n` : ''
    const suffix = hint?.system_suffix ? `\n\n${hint.system_suffix}` : ''

    return [
      '---',
      `name: ${spec.name}`,
      `description: ${spec.description}`,
      'type: skill',
      '---',
      '',
      `${prefix}${core}${suffix}`,
    ].join('\n')
  }

  translateTools(tools: JSONSchema[]): AnthropicTool[] {
    return toClaudeTools(tools)
  }

  /** Phase 2: implement runtime API calls */
  formatPrompt(_spec: SkillSpec, _core: string, _messages: CLMIMessage[]): unknown {
    throw new Error('Runtime invoke is not implemented until Phase 2. Use generate + install for build-time workflows.')
  }

  /** Phase 2: implement response normalization */
  parseResponse(_raw: unknown): NormalizedResponse {
    throw new Error('Runtime invoke is not implemented until Phase 2. Use generate + install for build-time workflows.')
  }
}
```

- [ ] **Step 5: Run tests to verify all pass**

```bash
bun test tests/contract/claude-adapter.test.ts
```

Expected: All 10 tests PASS

- [ ] **Step 6: Commit**

```bash
git add packages/adapters/src/claude.ts packages/adapters/src/utils/translate-tools.ts tests/contract/claude-adapter.test.ts
git commit -m "feat: add ClaudeAdapter with generateArtifact, translateTools, and contract tests"
```

---

## Task 7: Skill Registry

**Files:**
- Create: `packages/runner/src/registry.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/contract/registry.test.ts`:

```typescript
import { test, expect, describe, beforeAll } from 'bun:test'
import { writeFileSync, mkdirSync } from 'fs'
import { join, resolve } from 'path'
import { discoverSkills, loadSkill } from '../../packages/runner/src/registry'

// We'll test against the real pilot skills once they exist in Task 10+
// For now, create a minimal fixture skill
const FIXTURE_DIR = resolve(
  import.meta.dir,
  '../../packages/canonical/skills/core/test-fixture-skill'
)

beforeAll(() => {
  mkdirSync(join(FIXTURE_DIR, 'tools'), { recursive: true })
  writeFileSync(
    join(FIXTURE_DIR, 'spec.yaml'),
    [
      'spec_version: "1.0"',
      'name: test-fixture-skill',
      'version: 1.0.0',
      'description: A fixture skill for registry tests',
      'tier: core',
      'capabilities: [test]',
      'trust_tier: T1',
      'author: test',
    ].join('\n')
  )
  writeFileSync(
    join(FIXTURE_DIR, 'core.md'),
    '## Test Fixture\n\nThis is a test fixture skill.'
  )
})

describe('registry', () => {
  test('loadSkill returns spec, core, and toolPaths', () => {
    const loaded = loadSkill('core/test-fixture-skill')
    expect(loaded.spec.name).toBe('test-fixture-skill')
    expect(loaded.core).toContain('Test Fixture')
    expect(loaded.toolPaths).toEqual([])
    expect(loaded.tier).toBe('core')
  })

  test('loadSkill throws on missing skill', () => {
    expect(() => loadSkill('core/nonexistent-skill')).toThrow()
  })

  test('discoverSkills finds fixture skill in core tier', () => {
    const skills = discoverSkills('core')
    expect(skills).toContain('core/test-fixture-skill')
  })

  test('discoverSkills with no tier returns skills across all tiers', () => {
    const skills = discoverSkills()
    expect(skills.length).toBeGreaterThan(0)
  })
})
```

- [ ] **Step 2: Run to verify failure**

```bash
bun test tests/contract/registry.test.ts
```

Expected: FAIL — module not found

- [ ] **Step 3: Create `packages/runner/src/registry.ts`**

```typescript
import { readFileSync, existsSync, readdirSync, statSync } from 'fs'
import { join, resolve, dirname } from 'path'
import yaml from 'js-yaml'
import type { SkillSpec } from '@foundation-addon/adapters'

// Resolve canonical skills directory relative to this file
const CANONICAL_SKILLS_DIR = resolve(
  dirname(import.meta.path),
  '../../../canonical/skills'
)

export interface LoadedSkill {
  spec: SkillSpec
  core: string
  toolPaths: string[]
  skillDir: string
  tier: string
}

export function resolveSkillDir(tierAndName: string): string {
  const parts = tierAndName.split('/')
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    throw new Error(
      `Invalid skill reference: "${tierAndName}". Expected format: tier/skill-name`
    )
  }
  return join(CANONICAL_SKILLS_DIR, parts[0], parts[1])
}

export function loadSkill(tierAndName: string): LoadedSkill {
  const skillDir = resolveSkillDir(tierAndName)
  const tier = tierAndName.split('/')[0]!

  const specPath = join(skillDir, 'spec.yaml')
  const corePath = join(skillDir, 'core.md')

  if (!existsSync(specPath)) {
    throw new Error(`spec.yaml not found: ${specPath}`)
  }
  if (!existsSync(corePath)) {
    throw new Error(`core.md not found: ${corePath}`)
  }

  const spec = yaml.load(readFileSync(specPath, 'utf8')) as SkillSpec
  const core = readFileSync(corePath, 'utf8')

  // Resolve tool JSON paths declared in spec.tools
  const toolPaths = (spec.tools ?? []).map((toolRef) =>
    join(skillDir, toolRef)
  )

  return { spec, core, toolPaths, skillDir, tier }
}

export function discoverSkills(tier?: string): string[] {
  const skills: string[] = []

  const tiers = tier
    ? [tier]
    : readdirSync(CANONICAL_SKILLS_DIR).filter((d) =>
        statSync(join(CANONICAL_SKILLS_DIR, d)).isDirectory()
      )

  for (const t of tiers) {
    const tierDir = join(CANONICAL_SKILLS_DIR, t)
    if (!existsSync(tierDir)) continue

    const names = readdirSync(tierDir).filter((d) =>
      statSync(join(tierDir, d)).isDirectory()
    )
    for (const name of names) {
      skills.push(`${t}/${name}`)
    }
  }

  return skills
}
```

- [ ] **Step 4: Run tests to verify all pass**

```bash
bun test tests/contract/registry.test.ts
```

Expected: All 4 tests PASS

- [ ] **Step 5: Commit**

```bash
git add packages/runner/src/registry.ts tests/contract/registry.test.ts
git commit -m "feat: add skill registry with loadSkill and discoverSkills"
```

---

## Task 8: CLI Entry + Validate Command

**Files:**
- Create: `packages/runner/src/commands/validate.ts`
- Create: `packages/runner/src/cli.ts`

- [ ] **Step 1: Write the failing test for validate**

Create `tests/contract/validate.test.ts`:

```typescript
import { test, expect, describe } from 'bun:test'
import { lintCore } from '../../packages/runner/src/commands/validate'

describe('lintCore', () => {
  test('returns no issues for clean core.md', () => {
    const clean = '## Purpose\n\nReview code carefully.\n\n## Process\n\n1. Read it.\n2. Report.'
    expect(lintCore(clean, 'test/skill')).toHaveLength(0)
  })

  test('flags XML tags', () => {
    const withXml = '## Purpose\n\n<thinking>Do this</thinking>\n\nReview code.'
    const issues = lintCore(withXml, 'test/skill')
    expect(issues.some(i => i.includes('XML tags'))).toBe(true)
  })

  test('flags MCP tool references', () => {
    const withMcp = '## Purpose\n\nUse mcp__filesystem__read_file to read.\n'
    const issues = lintCore(withMcp, 'test/skill')
    expect(issues.some(i => i.includes('MCP tools'))).toBe(true)
  })

  test('flags deep headings (####)', () => {
    const withDeepHeading = '## Top\n\n#### Too deep\n\nContent here.'
    const issues = lintCore(withDeepHeading, 'test/skill')
    expect(issues.some(i => i.includes('####'))).toBe(true)
  })

  test('flags excessive word count over 600', () => {
    const longContent = Array(150).fill('word word word word word').join(' ')
    const issues = lintCore(longContent, 'test/skill')
    expect(issues.some(i => i.includes('words'))).toBe(true)
  })
})
```

- [ ] **Step 2: Run to verify failure**

```bash
bun test tests/contract/validate.test.ts
```

Expected: FAIL — module not found

- [ ] **Step 3: Create `packages/runner/src/commands/validate.ts`**

```typescript
import { readFileSync, existsSync } from 'fs'
import { join, resolve, dirname } from 'path'
import Ajv from 'ajv'
import yaml from 'js-yaml'
import { discoverSkills, loadSkill } from '../registry.js'
import { ErrorCode, FoundationAddonError } from '../errors.js'

const SPEC_SCHEMA_PATH = resolve(
  dirname(import.meta.path),
  '../../../canonical/schema/spec.schema.json'
)

export interface ValidateOptions {
  skill?: string
  fix?: boolean
}

export async function runValidate(options: ValidateOptions): Promise<void> {
  const ajv = new Ajv({ allErrors: true })
  const specSchema = JSON.parse(readFileSync(SPEC_SCHEMA_PATH, 'utf8'))
  const validateSchema = ajv.compile(specSchema)

  const skillRefs = options.skill ? [options.skill] : discoverSkills()
  const errors: string[] = []

  for (const skillRef of skillRefs) {
    let loaded
    try {
      loaded = loadSkill(skillRef)
    } catch (e) {
      errors.push(`${skillRef}: Failed to load — ${(e as Error).message}`)
      continue
    }

    const valid = validateSchema(loaded.spec)
    if (!valid) {
      for (const err of validateSchema.errors ?? []) {
        errors.push(`${skillRef}: ${err.instancePath || '(root)'} ${err.message}`)
      }
    }

    // Lint core.md
    errors.push(...lintCore(loaded.core, skillRef))
  }

  if (errors.length > 0) {
    console.error(`\n✗ Validation failed — ${errors.length} issue(s):`)
    errors.forEach((e) => console.error(`  • ${e}`))
    throw new FoundationAddonError({
      code: ErrorCode.ValidationError,
      message: `${errors.length} validation issue(s) found`,
      fix: 'Fix each issue above. Run with --fix to auto-correct minor formatting issues.',
    })
  }

  console.log(`\n✓ All ${skillRefs.length} skills validated successfully`)
}

/** Exported for testing */
export function lintCore(core: string, skillRef: string): string[] {
  const issues: string[] = []
  const wordCount = core.split(/\s+/).filter(Boolean).length

  if (/<[a-z][\w-]*>/i.test(core)) {
    issues.push(
      `${skillRef}: core.md contains XML tags — move provider-specific syntax to provider_hints.{provider}.system_prefix`
    )
  }

  if (/mcp__\w+__\w+/.test(core)) {
    issues.push(
      `${skillRef}: core.md references MCP tools directly — use generic tool names in tools/*.json instead`
    )
  }

  if (/^####/m.test(core)) {
    issues.push(
      `${skillRef}: core.md uses #### headings — maximum heading depth is ##`
    )
  }

  if (wordCount > 600) {
    issues.push(
      `${skillRef}: core.md has ${wordCount} words (limit: 600) — consider decomposing into sub-skills`
    )
  }

  return issues
}
```

- [ ] **Step 4: Create `packages/runner/src/cli.ts`**

```typescript
#!/usr/bin/env bun
import { Command } from 'commander'
import { runGenerate } from './commands/generate.js'
import { runValidate } from './commands/validate.js'
import { runInstall } from './commands/install.js'
import { runDoctor } from './commands/doctor.js'
import { formatError, ErrorCode } from './errors.js'
import type { FoundationAddonError } from './errors.js'

const program = new Command()

program
  .name('foundation-addon')
  .description('LLM-agnostic skill library and MCP configuration manager')
  .version('0.1.0')

program
  .command('generate')
  .description('Compile canonical skills to provider artifacts in dist/')
  .option('-t, --target <provider>', 'Target provider: claude|codex|qwen|gemini|all', 'claude')
  .option('-s, --skill <ref>', 'Specific skill (format: tier/name)')
  .option('--tier <tier>', 'Generate all skills in a tier')
  .option('--force', 'Bypass incremental compilation cache', false)
  .action(async (opts) => {
    await handle(() => runGenerate(opts))
  })

program
  .command('validate')
  .description('Validate spec.yaml files and lint core.md content')
  .option('-s, --skill <ref>', 'Validate a specific skill only')
  .option('--fix', 'Auto-correct minor formatting issues', false)
  .action(async (opts) => {
    await handle(() => runValidate(opts))
  })

program
  .command('install')
  .description('Promote dist/ artifacts to live tool directories')
  .option('-t, --target <provider>', 'Target provider', 'claude')
  .option('-i, --into <path>', 'Override default install path')
  .option('-s, --skill <ref>', 'Install a specific skill only')
  .option('--dry-run', 'Show what would change without writing', false)
  .option('--global', 'Install to global ~/.claude/commands/', false)
  .action(async (opts) => {
    await handle(() => runInstall({ ...opts, dryRun: opts.dryRun }))
  })

program
  .command('doctor')
  .description('Run environment health checks')
  .action(async () => {
    await handle(() => runDoctor())
  })

async function handle(fn: () => Promise<void>): Promise<void> {
  try {
    await fn()
  } catch (err) {
    if (err && typeof err === 'object' && 'structured' in err) {
      const e = err as InstanceType<typeof FoundationAddonError>
      console.error(formatError(e.structured, false))
      process.exit(e.structured.code)
    }
    console.error(err instanceof Error ? err.message : String(err))
    process.exit(1)
  }
}

program.parseAsync(process.argv)
```

- [ ] **Step 5: Run validate tests**

```bash
bun test tests/contract/validate.test.ts
```

Expected: All 5 tests PASS

- [ ] **Step 6: Commit**

```bash
git add packages/runner/src/commands/validate.ts packages/runner/src/cli.ts tests/contract/validate.test.ts
git commit -m "feat: add validate command with schema + core.md lint, and CLI entry"
```

---

## Task 9: Generate Command

**Files:**
- Create: `packages/runner/src/commands/generate.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/contract/generate.test.ts`:

```typescript
import { test, expect, describe, afterEach } from 'bun:test'
import { existsSync, rmSync, readFileSync, writeFileSync, mkdirSync } from 'fs'
import { join, resolve } from 'path'
import { runGenerate } from '../../packages/runner/src/commands/generate'

const DIST_CLAUDE = resolve(process.cwd(), 'dist/claude')
const FIXTURE_SKILL = 'core/test-fixture-skill' // created in Task 7

afterEach(() => {
  // Clean up dist after each test
  if (existsSync(DIST_CLAUDE)) rmSync(DIST_CLAUDE, { recursive: true, force: true })
})

describe('runGenerate', () => {
  test('creates dist/claude/ directory', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    expect(existsSync(DIST_CLAUDE)).toBe(true)
  })

  test('generates .md artifact for fixture skill', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    const files = readdirSync(DIST_CLAUDE)
    expect(files.some(f => f.endsWith('.md'))).toBe(true)
  })

  test('generated artifact contains SKILL.md frontmatter', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    const files = readdirSync(DIST_CLAUDE)
    const content = readFileSync(join(DIST_CLAUDE, files[0]!), 'utf8')
    expect(content).toContain('---')
    expect(content).toContain('type: skill')
  })

  test('second generate skips unchanged skills (incremental)', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    // Capture stdout to verify skip message
    const logs: string[] = []
    const orig = console.log
    console.log = (...args) => logs.push(args.join(' '))
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL })
    console.log = orig
    expect(logs.some(l => l.includes('unchanged'))).toBe(true)
  })

  test('--force bypasses cache', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    const logs: string[] = []
    const orig = console.log
    console.log = (...args) => logs.push(args.join(' '))
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    console.log = orig
    // With force, nothing should be skipped
    expect(logs.some(l => l.includes('Generated 1'))).toBe(true)
  })
})

function readdirSync(dir: string): string[] {
  const { readdirSync: rd } = require('fs')
  return rd(dir)
}
```

- [ ] **Step 2: Run to verify failure**

```bash
bun test tests/contract/generate.test.ts
```

Expected: FAIL — module not found

- [ ] **Step 3: Create `packages/runner/src/commands/generate.ts`**

```typescript
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs'
import { join, resolve, dirname } from 'path'
import { ClaudeAdapter } from '@foundation-addon/adapters'
import { discoverSkills, loadSkill } from '../registry.js'
import { hashSkillSources } from '../../../adapters/src/utils/hash.js'
import { auditLog } from '../audit.js'
import { ErrorCode, FoundationAddonError } from '../errors.js'

const DIST_DIR = resolve(process.cwd(), 'dist')
const CACHE_FILE = resolve(
  dirname(import.meta.path),
  '../../../canonical/.cache/hashes.json'
)

function loadHashCache(): Record<string, string> {
  if (!existsSync(CACHE_FILE)) return {}
  try {
    return JSON.parse(readFileSync(CACHE_FILE, 'utf8'))
  } catch {
    return {}
  }
}

function saveHashCache(cache: Record<string, string>): void {
  mkdirSync(join(CACHE_FILE, '..'), { recursive: true })
  writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 2), 'utf8')
}

export interface GenerateOptions {
  target: string
  skill?: string
  tier?: string
  force?: boolean
}

export async function runGenerate(options: GenerateOptions): Promise<void> {
  if (options.target !== 'claude') {
    throw new FoundationAddonError({
      code: ErrorCode.AdapterError,
      message: `Target "${options.target}" is not supported in Phase 1.`,
      fix: 'Use --target claude. Multi-provider support arrives in Phase 2.',
    })
  }

  const adapter = new ClaudeAdapter()
  const skillRefs = options.skill
    ? [options.skill]
    : discoverSkills(options.tier)

  const cache = options.force ? {} : loadHashCache()
  const newCache: Record<string, string> = { ...cache }

  const outDir = join(DIST_DIR, 'claude')
  mkdirSync(outDir, { recursive: true })

  let skipped = 0
  let generated = 0

  // Parallel generation across all skills (DD-014)
  await Promise.all(
    skillRefs.map(async (skillRef) => {
      const loaded = loadSkill(skillRef)
      const toolContents = loaded.toolPaths.map((p) => readFileSync(p, 'utf8'))
      const currentHash = hashSkillSources(
        loaded.core,
        JSON.stringify(loaded.spec),
        toolContents
      )

      if (!options.force && cache[skillRef] === currentHash) {
        skipped++
        return
      }

      const artifact = adapter.generateArtifact(loaded.spec, loaded.core)
      const outFile = join(outDir, `${loaded.spec.name}.md`)
      writeFileSync(outFile, artifact, 'utf8')
      newCache[skillRef] = currentHash
      generated++
    })
  )

  saveHashCache(newCache)

  auditLog({
    action: 'generate',
    timestamp: new Date().toISOString(),
    target: 'claude',
    skills: skillRefs,
    success: true,
  })

  console.log(
    `Generated ${generated} skill(s)` +
    (skipped > 0 ? ` (${skipped} unchanged, skipped)` : '')
  )
}
```

- [ ] **Step 4: Run tests to verify all pass**

```bash
bun test tests/contract/generate.test.ts
```

Expected: All 4 tests PASS

- [ ] **Step 5: Commit**

```bash
git add packages/runner/src/commands/generate.ts tests/contract/generate.test.ts
git commit -m "feat: add generate command with parallel execution and incremental SHA-256 hashing"
```

---

## Task 10: Install + Doctor Commands

**Files:**
- Create: `packages/runner/src/commands/install.ts`
- Create: `packages/runner/src/commands/doctor.ts`

- [ ] **Step 1: Create `packages/runner/src/commands/install.ts`**

```typescript
import {
  readFileSync, writeFileSync, readdirSync,
  existsSync, mkdirSync, copyFileSync,
} from 'fs'
import { join, resolve, dirname } from 'path'
import { auditLog } from '../audit.js'
import { ErrorCode, FoundationAddonError } from '../errors.js'

const DIST_DIR = resolve(process.cwd(), 'dist')
const BACKUP_BASE = resolve(process.cwd(), '.foundation-addon/backups')

export interface InstallOptions {
  target: string
  into?: string
  skill?: string
  dryRun?: boolean
  global?: boolean
}

export async function runInstall(options: InstallOptions): Promise<void> {
  const sourceDir = join(DIST_DIR, options.target)
  const targetDir = options.into ?? getDefaultTargetDir(options.target, options.global)

  if (!existsSync(sourceDir)) {
    throw new FoundationAddonError({
      code: ErrorCode.FilesystemError,
      message: `No generated artifacts found at ${sourceDir}`,
      fix: `Run: foundation-addon generate --target ${options.target}`,
    })
  }

  let files = readdirSync(sourceDir).filter((f) => f.endsWith('.md'))
  if (options.skill) {
    const skillFileName = options.skill.split('/')[1] + '.md'
    files = files.filter((f) => f === skillFileName)
  }

  if (files.length === 0) {
    console.log('No artifacts to install.')
    return
  }

  if (options.dryRun) {
    console.log(`\n[DRY RUN] Would install ${files.length} file(s) to ${targetDir}:`)
    files.forEach((f) => {
      const exists = existsSync(join(targetDir, f))
      console.log(`  ${exists ? '~' : '+'} ${join(targetDir, f)}`)
    })
    return
  }

  // Backup before install (DD-012)
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
  const backupDir = join(BACKUP_BASE, timestamp)
  mkdirSync(backupDir, { recursive: true })
  mkdirSync(targetDir, { recursive: true })

  files.forEach((f) => {
    const target = join(targetDir, f)
    if (existsSync(target)) copyFileSync(target, join(backupDir, f))
  })

  // Install
  files.forEach((f) => {
    writeFileSync(
      join(targetDir, f),
      readFileSync(join(sourceDir, f), 'utf8'),
      'utf8'
    )
  })

  auditLog({
    action: 'install',
    timestamp: new Date().toISOString(),
    target: options.target,
    skills: files.map((f) => f.replace('.md', '')),
    success: true,
    backup_path: backupDir,
  })

  console.log(`\n✓ Installed ${files.length} skill(s) to ${targetDir}`)
  console.log(`  Backup saved: ${backupDir}`)
}

function getDefaultTargetDir(target: string, global?: boolean): string {
  if (target === 'claude') {
    return global
      ? join(process.env.HOME ?? process.env.USERPROFILE ?? '~', '.claude', 'commands')
      : join(process.cwd(), '.claude', 'commands')
  }
  throw new FoundationAddonError({
    code: ErrorCode.ConfigError,
    message: `Install path for target "${target}" is not implemented in Phase 1.`,
    fix: 'Phase 2 adds Codex, Qwen, and Gemini install paths.',
  })
}
```

- [ ] **Step 2: Create `packages/runner/src/commands/doctor.ts`**

```typescript
import { existsSync } from 'fs'
import { resolve, dirname } from 'path'

interface Check {
  name: string
  status: '✅' | '⚠️' | '❌'
  detail: string
}

export async function runDoctor(): Promise<void> {
  const checks: Check[] = []

  // Bun runtime version
  const bunVer = (process.versions as Record<string, string>).bun
  checks.push({
    name: 'Bun runtime',
    status: bunVer ? '✅' : '❌',
    detail: bunVer ? `v${bunVer}` : 'Not running under Bun — install from bun.sh',
  })

  // spec.schema.json
  const schemaPath = resolve(
    dirname(import.meta.path),
    '../../../canonical/schema/spec.schema.json'
  )
  checks.push({
    name: 'spec.schema.json',
    status: existsSync(schemaPath) ? '✅' : '❌',
    detail: existsSync(schemaPath) ? 'Found' : `Missing: ${schemaPath}`,
  })

  // providers.yaml
  const providersPath = resolve(
    dirname(import.meta.path),
    '../../../config/providers.yaml'
  )
  checks.push({
    name: 'providers.yaml',
    status: existsSync(providersPath) ? '✅' : '⚠️',
    detail: existsSync(providersPath)
      ? 'Found'
      : `Not found at ${providersPath} — create from spec Section 7`,
  })

  // API keys (never log values)
  const providerKeys = [
    { env: 'ANTHROPIC_API_KEY', label: 'Claude (ANTHROPIC_API_KEY)' },
    { env: 'OPENAI_API_KEY', label: 'Codex (OPENAI_API_KEY)' },
  ]
  for (const { env, label } of providerKeys) {
    checks.push({
      name: `API key: ${label}`,
      status: process.env[env] ? '✅' : '⚠️',
      detail: process.env[env]
        ? 'Present (value hidden)'
        : `${env} not set in environment`,
    })
  }

  // dist/claude/ populated
  const distDir = resolve(process.cwd(), 'dist/claude')
  checks.push({
    name: 'dist/claude/',
    status: existsSync(distDir) ? '✅' : '⚠️',
    detail: existsSync(distDir)
      ? 'Populated'
      : 'Empty — run: foundation-addon generate --target claude',
  })

  // .claude-plugin/plugin.json
  const pluginPath = resolve(process.cwd(), '.claude-plugin/plugin.json')
  checks.push({
    name: '.claude-plugin/plugin.json',
    status: existsSync(pluginPath) ? '✅' : '⚠️',
    detail: existsSync(pluginPath) ? 'Found' : 'Missing — create in Task 11',
  })

  // Print report
  console.log('\n  Foundation AddOn — Doctor Report')
  console.log('  ' + '─'.repeat(44))
  checks.forEach((c) => console.log(`  ${c.status}  ${c.name}: ${c.detail}`))

  const failures = checks.filter((c) => c.status === '❌').length
  const warnings = checks.filter((c) => c.status === '⚠️').length
  console.log(`\n  ${checks.length} checks — ${failures} failure(s), ${warnings} warning(s)\n`)

  if (failures > 0) process.exit(1)
}
```

- [ ] **Step 3: Smoke-test install + doctor via CLI**

```bash
# Verify generate then install --dry-run works end-to-end
bun run packages/runner/src/cli.ts generate --target claude --skill core/test-fixture-skill --force
bun run packages/runner/src/cli.ts install --target claude --dry-run
```

Expected output:
```
Generated 1 skill(s)
[DRY RUN] Would install 1 file(s) to .claude/commands/:
  + .claude/commands/test-fixture-skill.md
```

- [ ] **Step 4: Smoke-test doctor**

```bash
bun run packages/runner/src/cli.ts doctor
```

Expected: Report with ✅/⚠️ checks, no ❌ (spec.schema.json and Bun should be green)

- [ ] **Step 5: Commit**

```bash
git add packages/runner/src/commands/install.ts packages/runner/src/commands/doctor.ts
git commit -m "feat: add install (backup-first, dry-run) and doctor (env health check) commands"
```

---

## Task 11: Config Files + Plugin Manifest

**Files:**
- Create: `packages/config/providers.yaml`
- Create: `packages/config/mcp-servers.yaml`
- Create: `packages/config/provider-matrix.yaml`
- Create: `packages/config/policies.yaml`
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create `packages/config/providers.yaml`**

```yaml
# LLM provider endpoints and model defaults
# Auth values are NEVER stored here — reference env var names only

spec_version: "1.0"

telemetry:
  enabled: false          # Opt-in required. See spec Section 13.
  webhook_url: null       # Optional: POST events to n8n / home server

providers:
  claude:
    api_key_env: ANTHROPIC_API_KEY
    default_model: claude-opus-4-6
    context_limit_tokens: 200000
    rate_limit_rpm: 60

  codex:
    api_key_env: OPENAI_API_KEY
    default_model: o4-mini
    context_limit_tokens: 128000
    rate_limit_rpm: 60

  qwen:
    api_key_env: QWEN_API_KEY
    default_model: qwen-max
    context_limit_tokens: 32000
    rate_limit_rpm: 60

  gemini:
    api_key_env: GEMINI_API_KEY
    default_model: gemini-2.0-flash
    context_limit_tokens: 1000000
    rate_limit_rpm: 60
```

- [ ] **Step 2: Create `packages/config/provider-matrix.yaml`**

```yaml
# Which capabilities each provider supports
# mcp_supported: flip to true when a provider ships MCP protocol support

spec_version: "1.0"

providers:
  claude:
    mcp_supported: true
    function_calling: true
    streaming: true
    vision: true
    tool_format: anthropic

  codex:
    mcp_supported: false
    function_calling: true
    streaming: true
    vision: false
    tool_format: openai

  qwen:
    mcp_supported: false
    function_calling: true
    streaming: true
    vision: false
    tool_format: openai  # OpenAI-compatible

  gemini:
    mcp_supported: false
    function_calling: true
    streaming: true
    vision: true
    tool_format: gemini
```

- [ ] **Step 3: Create `packages/config/mcp-servers.yaml`**

```yaml
# MCP server configurations
# Migrated and enhanced from mcp-config/recommended-servers.json

spec_version: "1.0"

tiers:
  tier1_core: "Install first — zero API keys, universal value"
  tier2_enhanced: "High value, some require free API keys"
  tier3_specialist: "Domain-specific power tools"

servers:
  context7:
    tier: tier1_core
    why: "Fetches up-to-date, version-specific docs. Eliminates hallucinated API syntax."
    install: "npx -y @upstash/context7-mcp@latest"
    api_key_required: false
    command: npx
    args: ["-y", "@upstash/context7-mcp@latest"]

  filesystem:
    tier: tier1_core
    why: "Sandboxed file operations. 14 tools for read/write/search/move."
    install: "npx -y @modelcontextprotocol/server-filesystem <allowed-dirs>"
    api_key_required: false
    command: npx
    args: ["-y", "@modelcontextprotocol/server-filesystem"]

  sequential-thinking:
    tier: tier1_core
    why: "Structured problem-solving. Prevents jumping to conclusions on hard problems."
    api_key_required: false
    command: npx
    args: ["-y", "@modelcontextprotocol/server-sequential-thinking"]

  github:
    tier: tier2_enhanced
    why: "Full GitHub integration — PRs, issues, Actions, code search."
    api_key_required: true
    api_key_env: GITHUB_PERSONAL_ACCESS_TOKEN

  tavily:
    tier: tier2_enhanced
    why: "AI-optimized web search. Purpose-built for developer queries."
    api_key_required: true
    api_key_env: TAVILY_API_KEY

  qdrant:
    tier: tier3_specialist
    why: "Vector storage for semantic skill search. Required for foundation-addon skill search command."
    api_key_required: false
```

- [ ] **Step 4: Create `packages/config/policies.yaml`**

```yaml
# Permission tiers and trust levels

spec_version: "1.0"

trust_tiers:
  T1:
    name: Sandboxed
    capabilities: [filesystem_read_declared, https_get]
    description: "Read-only filesystem access to declared paths only. HTTPS GET requests only."

  T2:
    name: Standard
    capabilities: [filesystem_read_any, https_any, tool_use]
    description: "File read (any path), full HTTPS, tool use via JSON Schema tools."

  T3:
    name: Extended
    capabilities: [filesystem_read_any, filesystem_write_declared, subprocess_no_shell, https_any, tool_use]
    description: "File read + write to declared paths. Subprocess execution (no shell). Full HTTPS."
    requires_review: true

  T4:
    name: Full System
    capabilities: [unrestricted]
    description: "Unrestricted system access. Requires explicit user approval at runtime."
    requires_runtime_approval: true

backups:
  max_backups: 7          # Auto-prune to this many most-recent backups
  backup_dir: .foundation-addon/backups
```

- [ ] **Step 5: Create `.claude-plugin/plugin.json`**

```json
{
  "name": "foundation-addon",
  "version": "0.1.0",
  "description": "LLM-agnostic skill library and MCP configuration — write once, generate anywhere",
  "author": "GRsoldier7",
  "homepage": "https://github.com/GRsoldier7/foundation-addon",
  "entry": "packages/runner/src/cli.ts",
  "capabilities": ["skills", "mcp-config", "permissions"],
  "skills_dir": "packages/canonical/skills",
  "config_dir": "packages/config",
  "commands": {
    "generate": "Compile canonical skills to provider artifacts",
    "install": "Install generated artifacts to provider tool directories",
    "validate": "Validate all spec.yaml and core.md files",
    "doctor": "Run environment health checks"
  },
  "min_claude_code_version": "1.0.0"
}
```

- [ ] **Step 6: Create `.claude-plugin/marketplace.json`**

```json
{
  "name": "Foundation AddOn — LLM-Agnostic",
  "short_description": "Write skills once. Generate for Claude, Codex, Qwen, and Gemini.",
  "category": "productivity",
  "tags": ["skills", "llm-agnostic", "mcp", "multi-provider", "code-review", "debugging"],
  "screenshots": [],
  "license": "MIT"
}
```

- [ ] **Step 7: Commit**

```bash
git add packages/config/ .claude-plugin/
git commit -m "feat: add config YAML files and .claude-plugin/ native distribution manifest"
```

---

## Task 12: Pilot Skill 1 — adaptive-skill-orchestrator

**Files:**
- Create: `packages/canonical/skills/core/adaptive-skill-orchestrator/spec.yaml`
- Create: `packages/canonical/skills/core/adaptive-skill-orchestrator/core.md`

- [ ] **Step 1: Create `spec.yaml`**

```yaml
spec_version: "1.0"
name: adaptive-skill-orchestrator
version: "1.0.0"
description: "Intelligent dispatch layer — analyzes requests and routes to optimal skill combination"
tier: core

capabilities:
  - routing
  - skill_invocation
  - context_analysis

provider_hints:
  claude:
    system_prefix: "You are an intelligent orchestration layer. Use <thinking> tags to reason about which skills apply before responding."
    model: claude-opus-4-6
    max_tokens: 4096
  codex:
    model: o4-mini
    system_prefix: "You are an intelligent orchestration layer. Think step by step about which skills and approaches apply."

trust_tier: T2
tags: [orchestration, routing, meta]
composable: false
parallel_safe: false
streaming: false
author: foundation-addon
```

- [ ] **Step 2: Create `core.md`**

```markdown
## Adaptive Skill Orchestrator

Analyze every request and select the optimal combination of skills before taking action.

## Process

1. **Decompose** the request into intent, domain, and discrete subtasks
2. **Score complexity** on a 1–5 scale: 1–2 = single skill direct, 3 = light orchestration, 4–5 = full fan-out
3. **Apply gates** — security gate (any auth/secrets/data sensitivity? → secure-by-design first), architecture gate (multi-service/scale? → solution-architect-engine first)
4. **Check context** — if >60%, prefer sequential execution; if >80%, minimal skills only
5. **Select skills** — pick the primary skill and any companions that run in parallel
6. **Dispatch** — execute in the determined order and mode
7. **Synthesize** — combine outputs into a single coherent response

## Always-On Skills (non-selectable)

anti-hallucination, prompt-amplifier, session-optimizer, verification-before-completion, secure-by-design, solution-architect-engine, context-guardian, efficiency-engine, cognitive-excellence

## Output Format

State which skills you are activating and why before proceeding. Then execute them.

## Constraints

- Never skip the routing analysis, even for seemingly simple requests
- Questions are tasks — always check for applicable skills
- If a skill exists for the task, use it — do not rationalize your way out
```

- [ ] **Step 3: Validate the skill**

```bash
bun run packages/runner/src/cli.ts validate --skill core/adaptive-skill-orchestrator
```

Expected: `✓ All 1 skills validated successfully`

- [ ] **Step 4: Commit**

```bash
git add packages/canonical/skills/core/adaptive-skill-orchestrator/
git commit -m "feat: add canonical pilot skill — adaptive-skill-orchestrator"
```

---

## Task 13: Pilot Skill 2 — systematic-debugging

**Files:**
- Create: `packages/canonical/skills/superpowers/systematic-debugging/spec.yaml`
- Create: `packages/canonical/skills/superpowers/systematic-debugging/core.md`

- [ ] **Step 1: Create `spec.yaml`**

```yaml
spec_version: "1.0"
name: systematic-debugging
version: "1.0.0"
description: "Four-phase root cause analysis — investigate, analyze, hypothesize, implement"
tier: superpowers

inputs:
  - name: error_description
    type: string
    required: true
    description: "The error message, test failure, or unexpected behavior to debug"
  - name: context
    type: string
    required: false
    description: "Relevant code, stack traces, or environment details"

capabilities:
  - code_analysis
  - file_read

provider_hints:
  claude:
    system_prefix: "Use <thinking> tags to work through each phase before presenting findings."
    model: claude-opus-4-6
    max_tokens: 8192
  codex:
    model: o4-mini

trust_tier: T2
tags: [debugging, root-cause, investigation]
composable: true
parallel_safe: false
streaming: false
author: foundation-addon
```

- [ ] **Step 2: Create `core.md`**

```markdown
## Systematic Debugging

Diagnose any bug, test failure, or unexpected behavior using four phases. Never propose a fix without first establishing root cause.

## Process

### Phase 1: Investigate
Read the error message and all relevant context before forming any hypothesis. Reproduce the issue if possible. Identify what system boundaries are involved.

### Phase 2: Analyze
Map what the code does vs what it should do. Identify the divergence point. List all possible causes without dismissing any yet.

### Phase 3: Hypothesize
Rank causes by likelihood. State your top hypothesis with evidence. State what would prove or disprove it.

### Phase 4: Implement
Fix only the root cause. Do not fix symptoms. If three fix attempts fail, stop and question the architecture — the problem may be deeper than it appears.

## Iron Law

Do not propose a fix until you have stated the root cause. "Root cause" means the specific line, condition, or assumption that is wrong — not a category ("async timing issue") but the precise mechanism.

## Output Format

**Root Cause:** [specific mechanism — file:line if known]  
**Evidence:** [what proves this is the cause]  
**Fix:** [minimal change that addresses root cause only]  
**Verification:** [exact command to confirm the fix worked]

## Constraints

- Never retry a failed fix without changing the approach
- Never blame external libraries without evidence
- If you cannot determine root cause, say so explicitly rather than guessing
```

- [ ] **Step 3: Validate**

```bash
bun run packages/runner/src/cli.ts validate --skill superpowers/systematic-debugging
```

Expected: `✓ All 1 skills validated successfully`

- [ ] **Step 4: Commit**

```bash
git add packages/canonical/skills/superpowers/systematic-debugging/
git commit -m "feat: add canonical pilot skill — systematic-debugging"
```

---

## Task 14: Pilot Skill 3 — code-review

**Files:**
- Create: `packages/canonical/skills/engineering/code-review/spec.yaml`
- Create: `packages/canonical/skills/engineering/code-review/core.md`
- Create: `packages/canonical/skills/engineering/code-review/tools/read-file.json`

- [ ] **Step 1: Create `tools/read-file.json`**

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "name": "read_file",
  "description": "Read the contents of a source file by path",
  "parameters": {
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "Absolute or relative path to the file to read"
      }
    },
    "required": ["path"]
  }
}
```

- [ ] **Step 2: Create `spec.yaml`**

```yaml
spec_version: "1.0"
name: code-review
version: "1.0.0"
description: "Expert code review for correctness, security, performance, and maintainability"
tier: engineering

inputs:
  - name: code
    type: string
    required: true
    description: "Code to review — inline content or file path"
  - name: focus
    type: enum
    values: [security, performance, correctness, all]
    default: all
    required: false

capabilities:
  - code_analysis
  - security_scanning
  - file_read

tools:
  - tools/read-file.json

provider_hints:
  claude:
    system_prefix: "Use <thinking> tags to analyze the code before presenting your review."
    model: claude-opus-4-6
    max_tokens: 8192
  codex:
    model: o4-mini

trust_tier: T2
tags: [review, security, quality, correctness]
composable: true
parallel_safe: false
streaming: false
author: foundation-addon
```

- [ ] **Step 3: Create `core.md`**

```markdown
## Code Review

Review code for correctness, security vulnerabilities, performance issues, and maintainability. Provide specific, actionable feedback a developer can act on immediately.

## Process

1. Read the full code before forming any opinions
2. Group issues by category: Security → Performance → Correctness → Maintainability
3. Prioritize by severity within each category: Critical > High > Medium > Low
4. For each issue: state what is wrong, why it matters, and exactly how to fix it with the specific line reference
5. End with Quick Wins — the 3 highest-ROI changes requiring least effort

## Output Format

**Summary** — Overall quality score (1–10) and top 3 concerns, one sentence each

**Issues:**
- Severity: [Critical | High | Medium | Low]
- Category: [Security | Performance | Correctness | Maintainability]
- Location: file:line
- Problem: what is wrong and why it matters
- Fix: exact change required

**Quick Wins** — 3 immediate improvements, lowest effort, highest impact

## Constraints

- Never suggest changes outside the scope of the submitted code
- Security issues always rank above all other categories regardless of severity label
- If you cannot determine intent from context, say so — do not assume
- Scope: the code as submitted. Not "what else could be added."
```

- [ ] **Step 4: Validate**

```bash
bun run packages/runner/src/cli.ts validate --skill engineering/code-review
```

Expected: `✓ All 1 skills validated successfully`

- [ ] **Step 5: Commit**

```bash
git add packages/canonical/skills/engineering/code-review/
git commit -m "feat: add canonical pilot skill — code-review with read-file tool"
```

---

## Task 15: Pilot Skills 4 + 5 — brainstorming + writing-plans

**Files:**
- Create: `packages/canonical/skills/superpowers/brainstorming/spec.yaml`
- Create: `packages/canonical/skills/superpowers/brainstorming/core.md`
- Create: `packages/canonical/skills/superpowers/writing-plans/spec.yaml`
- Create: `packages/canonical/skills/superpowers/writing-plans/core.md`

- [ ] **Step 1: Create `brainstorming/spec.yaml`**

```yaml
spec_version: "1.0"
name: brainstorming
version: "1.0.0"
description: "Collaborative design session — explore intent, propose approaches, get design approval before building"
tier: superpowers

capabilities:
  - context_analysis
  - design_reasoning

provider_hints:
  claude:
    system_prefix: "Use <thinking> tags to explore the design space before presenting options."
    model: claude-opus-4-6
    max_tokens: 8192
  codex:
    model: o4-mini

trust_tier: T1
tags: [design, planning, architecture, pre-implementation]
composable: true
parallel_safe: false
streaming: false
author: foundation-addon
```

- [ ] **Step 2: Create `brainstorming/core.md`**

```markdown
## Brainstorming

Help turn ideas into fully-formed designs through structured dialogue. Never write code or take implementation action until the design is presented and approved.

## Process

1. **Explore context** — read relevant files, docs, and recent changes before asking questions
2. **Ask clarifying questions** — one at a time, focused on purpose, constraints, and success criteria. Multiple choice preferred.
3. **Propose 2–3 approaches** — with trade-offs and a clear recommendation with reasoning
4. **Present design sections** — scale each section to its complexity; get approval after each section
5. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
6. **Transition** — invoke writing-plans skill once the design is approved

## Hard Gate

Do not invoke any implementation skill, write any code, or scaffold any project until the user has explicitly approved the design. Every project, no matter how simple, goes through this process.

## Output Format

Present one question or design element at a time. Never present multiple questions in a single message.

## Constraints

- One question per message — if a topic needs more exploration, break it into sequential messages
- If the scope covers multiple independent subsystems, decompose into sub-projects before proceeding
- The only skill invoked after brainstorming is writing-plans
```

- [ ] **Step 3: Create `writing-plans/spec.yaml`**

```yaml
spec_version: "1.0"
name: writing-plans
version: "1.0.0"
description: "Create granular TDD implementation plans with exact file paths and complete code for every step"
tier: superpowers

depends_on:
  - superpowers/brainstorming

capabilities:
  - context_analysis
  - code_generation

provider_hints:
  claude:
    system_prefix: "Be extremely specific. No placeholders. Complete code in every step. Exact file paths always."
    model: claude-opus-4-6
    max_tokens: 16384
  codex:
    model: o4-mini

trust_tier: T1
tags: [planning, tdd, implementation, tasks]
composable: false
parallel_safe: false
streaming: false
author: foundation-addon
```

- [ ] **Step 4: Create `writing-plans/core.md`**

```markdown
## Writing Plans

Create a complete, bite-sized implementation plan from an approved design spec. Every step must contain everything a developer needs — exact file paths, complete code, exact commands, expected output.

## Process

1. **Scope check** — confirm the spec covers one deliverable. If it covers multiple independent subsystems, propose decomposition before writing the plan.
2. **Map files** — list every file to create or modify with its single responsibility. Lock in decomposition decisions here.
3. **Write tasks** — TDD order: write failing test → run to confirm failure → write minimal implementation → run to confirm passing → commit
4. **Self-review** — check spec coverage, placeholder scan, type consistency

## Task Structure (required for every task)

- Files section: exact paths to create and modify
- Failing test written first with complete test code
- Command to run the failing test and its expected output
- Minimal implementation with complete code
- Command to run the passing test and its expected output
- Git commit command with message

## Hard Rules (plan failures — never do these)

- No "TBD", "TODO", or "implement later"
- No "add appropriate error handling" without showing the code
- No "similar to Task N" — repeat the code; engineers may read tasks out of order
- No references to types or functions not defined in any task
- No steps that describe what to do without showing how

## Output Format

Save the plan to `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`. After saving, offer the user a choice of subagent-driven or inline execution.

## Constraints

- Each task = 2–5 minutes of work
- Every step has a verification command and expected output
- Commit after every task, not after every step
```

- [ ] **Step 5: Validate both new skills**

```bash
bun run packages/runner/src/cli.ts validate --skill superpowers/brainstorming && \
bun run packages/runner/src/cli.ts validate --skill superpowers/writing-plans
```

Expected: Both validated successfully

- [ ] **Step 6: Commit**

```bash
git add packages/canonical/skills/superpowers/brainstorming/ packages/canonical/skills/superpowers/writing-plans/
git commit -m "feat: add canonical pilot skills — brainstorming and writing-plans (5/5 pilots complete)"
```

---

## Task 16: Foundation AddOn Lockfile + End-to-End Gate Test

**Files:**
- Create: `foundation-addon.lock.yaml`
- Create: `tests/integration/phase1-gate.test.ts`

- [ ] **Step 1: Create `foundation-addon.lock.yaml`**

```yaml
spec_version: "1.0"
addon_version: "0.1.0"
targets: [claude]
skills:
  core/adaptive-skill-orchestrator: "^1.0.0"
  superpowers/systematic-debugging: "^1.0.0"
  engineering/code-review: "^1.0.0"
  superpowers/brainstorming: "^1.0.0"
  superpowers/writing-plans: "^1.0.0"
```

- [ ] **Step 2: Write the Phase 1 gate test**

Create `tests/integration/phase1-gate.test.ts`:

```typescript
import { test, expect, describe, afterAll } from 'bun:test'
import { existsSync, readdirSync, readFileSync, rmSync } from 'fs'
import { resolve } from 'path'
import { runGenerate } from '../../packages/runner/src/commands/generate'
import { runValidate } from '../../packages/runner/src/commands/validate'

const DIST_CLAUDE = resolve(process.cwd(), 'dist/claude')
const PILOT_SKILLS = [
  'core/adaptive-skill-orchestrator',
  'superpowers/systematic-debugging',
  'engineering/code-review',
  'superpowers/brainstorming',
  'superpowers/writing-plans',
]

afterAll(() => {
  if (existsSync(DIST_CLAUDE)) rmSync(DIST_CLAUDE, { recursive: true, force: true })
})

describe('Phase 1 gate: generate --target claude', () => {
  test('validate passes on all 5 pilot skills', async () => {
    // Should not throw
    for (const skill of PILOT_SKILLS) {
      await expect(runValidate({ skill })).resolves.toBeUndefined()
    }
  })

  test('generate produces artifacts for all 5 pilot skills', async () => {
    await runGenerate({ target: 'claude', force: true })
    expect(existsSync(DIST_CLAUDE)).toBe(true)
    const files = readdirSync(DIST_CLAUDE).filter((f) => f.endsWith('.md'))
    expect(files.length).toBeGreaterThanOrEqual(5)
  })

  test('each generated artifact has valid SKILL.md frontmatter', () => {
    const files = readdirSync(DIST_CLAUDE).filter((f) => f.endsWith('.md'))
    for (const file of files) {
      const content = readFileSync(resolve(DIST_CLAUDE, file), 'utf8')
      expect(content).toStartWith('---\n')
      expect(content).toContain('name:')
      expect(content).toContain('description:')
      expect(content).toContain('type: skill')
    }
  })

  test('generated artifacts include core.md content', () => {
    const codeReviewFile = resolve(DIST_CLAUDE, 'code-review.md')
    expect(existsSync(codeReviewFile)).toBe(true)
    const content = readFileSync(codeReviewFile, 'utf8')
    expect(content).toContain('## Code Review')
    expect(content).toContain('Quick Wins')
  })

  test('incremental generate skips all 5 unchanged skills', async () => {
    const logs: string[] = []
    const orig = console.log
    console.log = (...args: unknown[]) => logs.push(args.join(' '))
    await runGenerate({ target: 'claude' })
    console.log = orig
    expect(logs.some((l) => l.includes('5 unchanged'))).toBe(true)
  })
})
```

- [ ] **Step 3: Run the gate test**

```bash
bun test tests/integration/phase1-gate.test.ts
```

Expected: All 5 tests PASS

- [ ] **Step 4: Run the full test suite**

```bash
bun test
```

Expected: All tests across all files PASS

- [ ] **Step 5: Run doctor to confirm green state**

```bash
bun run packages/runner/src/cli.ts doctor
```

Expected: spec.schema.json ✅, Bun runtime ✅, dist/claude/ ✅

- [ ] **Step 6: Run `generate --target claude` on all 5 pilot skills**

```bash
bun run packages/runner/src/cli.ts generate --target claude --force
bun run packages/runner/src/cli.ts validate
```

Expected:
```
Generated 5 skill(s)
✓ All 5 skills validated successfully
```

- [ ] **Step 7: Run `install --dry-run` to preview**

```bash
bun run packages/runner/src/cli.ts install --target claude --dry-run
```

Expected:
```
[DRY RUN] Would install 5 file(s) to .claude/commands/:
  + .claude/commands/adaptive-skill-orchestrator.md
  + .claude/commands/brainstorming.md
  + .claude/commands/code-review.md
  + .claude/commands/systematic-debugging.md
  + .claude/commands/writing-plans.md
```

- [ ] **Step 8: Final commit — Phase 1 complete**

```bash
git add foundation-addon.lock.yaml tests/integration/phase1-gate.test.ts
git commit -m "feat: Phase 1 complete — 5 pilot skills, generate/validate/install --dry-run working, all tests pass"
```

---

## Self-Review

**1. Spec Coverage Check**

| Spec Requirement | Task |
|-----------------|------|
| `spec_version` field in spec.yaml | Task 2 (schema) |
| spec.schema.json validation | Task 2 |
| tool.schema.json | Task 2 |
| BaseAdapter + CLMI types | Task 3 |
| hash.ts incremental compilation | Task 4 |
| tokenizer.ts context management | Task 4 |
| sentinel.ts fenced blocks | Task 4 |
| errors.ts + exit codes | Task 5 |
| audit.ts | Task 5 |
| translate-tools.ts Claude section | Task 6 |
| ClaudeAdapter.generateArtifact | Task 6 |
| registry.ts | Task 7 |
| validate command | Task 8 |
| CLI entry (Commander.js) | Task 8 |
| generate command (parallel, incremental) | Task 9 |
| install command (backup-first, dry-run) | Task 10 |
| doctor command | Task 10 |
| providers.yaml / mcp-servers.yaml / provider-matrix.yaml / policies.yaml | Task 11 |
| .claude-plugin/plugin.json | Task 11 |
| Pilot skill: adaptive-skill-orchestrator | Task 12 |
| Pilot skill: systematic-debugging | Task 13 |
| Pilot skill: code-review | Task 14 |
| Pilot skill: brainstorming | Task 15 |
| Pilot skill: writing-plans | Task 15 |
| foundation-addon.lock.yaml | Task 16 |
| Phase 1 gate test | Task 16 |

All 26 spec requirements covered. ✅

**2. Placeholder scan:** No TBDs, no TODOs, no "implement later", no "similar to Task N". All code blocks are complete. ✅

**3. Type consistency:**
- `SkillSpec` defined in `types.ts` (Task 3), used identically in `base.ts`, `claude.ts`, `registry.ts`, `validate.ts`, `generate.ts`
- `JSONSchema` type defined in `types.ts`, used in `translate-tools.ts` and adapter contracts
- `AnthropicTool` defined in `translate-tools.ts`, returned by `translateTools()` in `claude.ts`
- `LoadedSkill` defined in `registry.ts`, consumed in `generate.ts` and `validate.ts`
- `ErrorCode` enum used as both value and type consistently throughout runner commands
- `GenerateOptions.target` typed as `string` (not union) — intentional to allow Phase 2 targets to pass through; validated at runtime ✅

---

*Plan Version 1.0 — 2026-04-11. Phase 1 only. Covers Tasks 1–16, all with complete code and TDD ordering.*
