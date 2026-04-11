import { test, expect, describe, afterEach } from 'bun:test'
import { existsSync, rmSync, readFileSync, readdirSync } from 'fs'
import { resolve } from 'path'
import { runGenerate } from '../../packages/runner/src/commands/generate'

const DIST_CLAUDE = resolve(process.cwd(), 'dist/claude')
const CACHE_DIR = resolve(process.cwd(), 'packages/canonical/.cache')
const FIXTURE_SKILL = 'core/test-fixture-skill'

afterEach(() => {
  if (existsSync(DIST_CLAUDE)) rmSync(DIST_CLAUDE, { recursive: true, force: true })
  if (existsSync(CACHE_DIR)) rmSync(CACHE_DIR, { recursive: true, force: true })
})

describe('runGenerate', () => {
  test('creates dist/claude/ directory', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    expect(existsSync(DIST_CLAUDE)).toBe(true)
  })

  test('generates .md artifact for fixture skill', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    const files = readdirSync(DIST_CLAUDE).filter((f) => f.endsWith('.md'))
    expect(files.length).toBeGreaterThan(0)
  })

  test('generated artifact contains SKILL.md frontmatter', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    const files = readdirSync(DIST_CLAUDE).filter((f) => f.endsWith('.md'))
    const content = readFileSync(resolve(DIST_CLAUDE, files[0]!), 'utf8')
    expect(content).toContain('---')
    expect(content).toContain('type: skill')
  })

  test('second generate skips unchanged skills (incremental)', async () => {
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL, force: true })
    const logs: string[] = []
    const orig = console.log
    console.log = ((...args: unknown[]) => {
      logs.push(args.join(' '))
    }) as typeof console.log
    await runGenerate({ target: 'claude', skill: FIXTURE_SKILL })
    console.log = orig
    expect(logs.some((l) => l.includes('unchanged'))).toBe(true)
  })

  test('rejects non-claude targets in Phase 1', async () => {
    await expect(runGenerate({ target: 'codex', force: true })).rejects.toThrow()
  })
})
