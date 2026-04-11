import { test, expect, describe, afterAll } from 'bun:test'
import { existsSync, readdirSync, readFileSync, rmSync } from 'fs'
import { resolve } from 'path'
import { runGenerate } from '../../packages/runner/src/commands/generate'
import { runValidate } from '../../packages/runner/src/commands/validate'

const DIST_CLAUDE = resolve(process.cwd(), 'dist/claude')
const CACHE_DIR = resolve(process.cwd(), 'packages/canonical/.cache')
const PILOT_SKILLS = [
  'core/adaptive-skill-orchestrator',
  'superpowers/systematic-debugging',
  'engineering/code-review',
  'superpowers/brainstorming',
  'superpowers/writing-plans',
]

afterAll(() => {
  if (existsSync(DIST_CLAUDE)) rmSync(DIST_CLAUDE, { recursive: true, force: true })
  if (existsSync(CACHE_DIR)) rmSync(CACHE_DIR, { recursive: true, force: true })
})

describe('Phase 1 Gate — generate --target claude on all 5 pilot skills', () => {
  test('validate passes on all 5 pilot skills', async () => {
    for (const skill of PILOT_SKILLS) {
      await expect(runValidate({ skill })).resolves.toBeUndefined()
    }
  })

  test('validate passes when run on all skills at once (no --skill filter)', async () => {
    await expect(runValidate({})).resolves.toBeUndefined()
  })

  test('generate produces artifacts for all 5 pilot skills', async () => {
    await runGenerate({ target: 'claude', force: true })
    expect(existsSync(DIST_CLAUDE)).toBe(true)
    const files = readdirSync(DIST_CLAUDE).filter((f) => f.endsWith('.md'))
    expect(files.length).toBe(5)
    // Verify all 5 expected filenames
    expect(files).toContain('adaptive-skill-orchestrator.md')
    expect(files).toContain('systematic-debugging.md')
    expect(files).toContain('code-review.md')
    expect(files).toContain('brainstorming.md')
    expect(files).toContain('writing-plans.md')
  })

  test('each generated artifact has valid SKILL.md frontmatter', () => {
    const files = readdirSync(DIST_CLAUDE).filter((f) => f.endsWith('.md'))
    for (const file of files) {
      const content = readFileSync(resolve(DIST_CLAUDE, file), 'utf8')
      expect(content).toStartWith('---\n')
      expect(content).toContain('name:')
      expect(content).toContain('description:')
      expect(content).toContain('type: skill')
      // frontmatter should have exactly 2 --- delimiters
      const dashLines = content.split('\n').filter(l => l === '---')
      expect(dashLines.length).toBeGreaterThanOrEqual(2)
    }
  })

  test('code-review artifact includes core.md content', () => {
    const codeReviewFile = resolve(DIST_CLAUDE, 'code-review.md')
    expect(existsSync(codeReviewFile)).toBe(true)
    const content = readFileSync(codeReviewFile, 'utf8')
    expect(content).toContain('## Code Review')
    expect(content).toContain('Quick Wins')
  })

  test('adaptive-skill-orchestrator artifact includes the system_prefix', () => {
    const file = resolve(DIST_CLAUDE, 'adaptive-skill-orchestrator.md')
    const content = readFileSync(file, 'utf8')
    expect(content).toContain('Use structured reasoning to analyze')
  })

  test('incremental generate skips all 5 unchanged skills', async () => {
    // First generate already happened in the previous test
    const logs: string[] = []
    const orig = console.log
    console.log = ((...args: unknown[]) => {
      logs.push(args.join(' '))
    }) as typeof console.log
    await runGenerate({ target: 'claude' })
    console.log = orig
    // Should log "5 unchanged" since nothing has changed since the last generate
    expect(logs.some((l) => l.includes('5 unchanged'))).toBe(true)
  })

  test('foundation-addon.lock.yaml is present and declares all 5 pilot skills', () => {
    const lockfilePath = resolve(process.cwd(), 'foundation-addon.lock.yaml')
    expect(existsSync(lockfilePath)).toBe(true)
    const content = readFileSync(lockfilePath, 'utf8')
    expect(content).toContain('spec_version: "1.0"')
    expect(content).toContain('core/adaptive-skill-orchestrator')
    expect(content).toContain('superpowers/systematic-debugging')
    expect(content).toContain('engineering/code-review')
    expect(content).toContain('superpowers/brainstorming')
    expect(content).toContain('superpowers/writing-plans')
  })
})
