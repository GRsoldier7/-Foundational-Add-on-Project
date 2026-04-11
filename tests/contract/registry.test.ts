import { test, expect, describe, beforeAll } from 'bun:test'
import { writeFileSync, mkdirSync, existsSync } from 'fs'
import { join, resolve } from 'path'
import { discoverSkills, loadSkill } from '../../packages/runner/src/registry'

// Create a minimal fixture skill in the canonical layer
const FIXTURE_DIR = resolve(
  import.meta.dir,
  '../../packages/canonical/skills/core/test-fixture-skill'
)

beforeAll(() => {
  mkdirSync(FIXTURE_DIR, { recursive: true })
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
  test('loadSkill returns spec, core, toolPaths, and tier', () => {
    const loaded = loadSkill('core/test-fixture-skill')
    expect(loaded.spec.name).toBe('test-fixture-skill')
    expect(loaded.core).toContain('Test Fixture')
    expect(loaded.toolPaths).toEqual([])
    expect(loaded.tier).toBe('core')
  })

  test('loadSkill throws on missing skill', () => {
    expect(() => loadSkill('core/nonexistent-skill')).toThrow()
  })

  test('loadSkill throws on malformed ref', () => {
    expect(() => loadSkill('invalid-ref-no-slash')).toThrow(/tier\/skill-name/)
  })

  test('discoverSkills finds fixture skill in core tier', () => {
    const skills = discoverSkills('core')
    expect(skills).toContain('core/test-fixture-skill')
  })

  test('discoverSkills with no tier returns skills across all tiers', () => {
    const skills = discoverSkills()
    expect(skills.length).toBeGreaterThan(0)
    expect(skills).toContain('core/test-fixture-skill')
  })
})
