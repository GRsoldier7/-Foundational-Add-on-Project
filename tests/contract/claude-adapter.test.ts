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
    expect(artifact).toContain('name: "code-review"')
    expect(artifact).toContain('description: "Expert code review for correctness, security, and performance"')
    expect(artifact).toContain('type: skill')
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
    expect(artifact).toContain('name: "code-review"')
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

  test('generateArtifact safely quotes description containing colons and special chars', () => {
    const specWithSpecialChars: SkillSpec = {
      ...MOCK_SPEC,
      name: 'code-review',
      description: 'Expert review: correctness, security, & "performance"',
    }
    const artifact = adapter.generateArtifact(specWithSpecialChars, MOCK_CORE)
    // description line should be quoted and escaped
    expect(artifact).toContain('description: "Expert review: correctness, security, & \\"performance\\""')
    // frontmatter should still be valid (exactly 2 `---` lines)
    const dashLines = artifact.split('\n').filter(l => l === '---')
    expect(dashLines).toHaveLength(2)
  })

  test('generateArtifact safely escapes newlines in description', () => {
    const specWithNewline: SkillSpec = {
      ...MOCK_SPEC,
      description: 'Line one\nLine two',
    }
    const artifact = adapter.generateArtifact(specWithNewline, MOCK_CORE)
    expect(artifact).toContain('description: "Line one\\nLine two"')
    // ensure the raw newline didn't leak into the frontmatter as a real line break
    const frontmatterEnd = artifact.indexOf('---', 4)
    const frontmatter = artifact.slice(0, frontmatterEnd)
    expect(frontmatter.split('\n').length).toBeLessThanOrEqual(5)
  })
})
