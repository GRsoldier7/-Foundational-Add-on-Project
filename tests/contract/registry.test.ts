import { test, expect, describe } from 'bun:test'
import { discoverSkills, loadSkill } from '../../packages/runner/src/registry'

describe('registry', () => {
  test('loadSkill returns spec, core, toolPaths, and tier', () => {
    const loaded = loadSkill('core/adaptive-skill-orchestrator')
    expect(loaded.spec.name).toBe('adaptive-skill-orchestrator')
    expect(loaded.core).toContain('Adaptive Skill Orchestrator')
    expect(loaded.toolPaths).toEqual([])
    expect(loaded.tier).toBe('core')
  })

  test('loadSkill throws on missing skill', () => {
    expect(() => loadSkill('core/nonexistent-skill')).toThrow()
  })

  test('loadSkill throws on malformed ref', () => {
    expect(() => loadSkill('invalid-ref-no-slash')).toThrow(/tier\/skill-name/)
  })

  test('discoverSkills finds pilot skill in core tier', () => {
    const skills = discoverSkills('core')
    expect(skills).toContain('core/adaptive-skill-orchestrator')
  })

  test('discoverSkills with no tier returns skills across all tiers', () => {
    const skills = discoverSkills()
    expect(skills.length).toBeGreaterThan(0)
    expect(skills).toContain('core/adaptive-skill-orchestrator')
  })

  test('resolveSkillDir rejects path traversal in tier', () => {
    expect(() => loadSkill('../../../etc/passwd/foo')).toThrow(/Invalid skill reference/)
  })

  test('resolveSkillDir rejects dots in name (no parent-dir escape)', () => {
    // 'core/..' would parse as two parts and could escape without regex
    expect(() => loadSkill('core/..')).toThrow(/Invalid skill reference/)
  })

  test('resolveSkillDir rejects single-name with no tier', () => {
    expect(() => loadSkill('nonesuch')).toThrow(/tier\/skill-name/)
  })

  test('resolveSkillDir rejects slug with slashes', () => {
    expect(() => loadSkill('core/sub/dir')).toThrow(/Invalid skill reference/)
  })
})
