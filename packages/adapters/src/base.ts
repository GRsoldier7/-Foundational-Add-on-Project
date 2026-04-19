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
