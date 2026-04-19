// Approximation: ~4 characters per unit (conservative estimate, plus or minus 10%)
const CHARS_PER_UNIT = 4

export function estimateTokens(text: string): number {
  return Math.ceil(text.length / CHARS_PER_UNIT)
}

export function estimatePromptTokens(
  systemPrompt: string,
  messages: { content: string }[]
): number {
  const allContent = [systemPrompt, ...messages.map((m) => m.content)].join(' ')
  return estimateTokens(allContent)
}

export type ContextWarning = 'none' | 'warn' | 'truncate'

export function checkContextUsage(
  estimatedTokens: number,
  limitTokens: number
): ContextWarning {
  const ratio = estimatedTokens / limitTokens
  if (ratio >= 0.95) return 'truncate'
  if (ratio >= 0.80) return 'warn'
  return 'none'
}
