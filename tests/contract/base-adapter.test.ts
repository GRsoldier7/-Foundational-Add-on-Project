import { test, expect, describe } from 'bun:test'
import { BaseAdapter } from '../../packages/adapters/src/base'
import type { SkillSpec, CLMIMessage, NormalizedResponse, JSONSchema } from '../../packages/adapters/src/types'

// Concrete stub to verify the abstract contract
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
    const spec: SkillSpec = {
      spec_version: '1.0', name: 'test', version: '1.0.0',
      description: 'Test skill for verification',
      tier: 'core', capabilities: ['test'], trust_tier: 'T1', author: 'test',
    }
    const result = adapter.generateArtifact(spec, 'core content')
    expect(result).toBe('test:core content')
  })
})
