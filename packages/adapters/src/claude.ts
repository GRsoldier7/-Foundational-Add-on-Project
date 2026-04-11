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

  formatPrompt(_spec: SkillSpec, _core: string, _messages: CLMIMessage[]): unknown {
    throw new Error('Runtime invoke not implemented until Phase 2. Use generate + install for build-time workflows.')
  }

  parseResponse(_raw: unknown): NormalizedResponse {
    throw new Error('Runtime invoke not implemented until Phase 2. Use generate + install for build-time workflows.')
  }
}
