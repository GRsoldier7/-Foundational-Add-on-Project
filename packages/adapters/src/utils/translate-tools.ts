import type { JSONSchema } from '../types.js'

export interface AnthropicTool {
  name: string
  description: string
  input_schema: Record<string, unknown>
}

export function toClaudeTool(schema: JSONSchema): AnthropicTool {
  return {
    name: schema.name,
    description: schema.description,
    input_schema: schema.parameters as Record<string, unknown>,
  }
}

export function toClaudeTools(schemas: JSONSchema[]): AnthropicTool[] {
  return schemas.map(toClaudeTool)
}
