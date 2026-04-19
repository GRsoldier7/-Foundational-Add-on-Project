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
