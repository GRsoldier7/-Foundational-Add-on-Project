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
