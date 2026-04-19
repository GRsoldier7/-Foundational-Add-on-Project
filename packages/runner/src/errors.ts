export enum ErrorCode {
  Success = 0,
  ValidationError = 1,
  AdapterError = 2,
  FilesystemError = 3,
  ConfigError = 4,
  TrustViolation = 5,
  CompositionError = 6,
  ContextOverflow = 7,
}

export interface StructuredError {
  code: ErrorCode
  message: string
  skill?: string
  provider?: string
  field?: string
  fix?: string
}

export class FoundationAddonError extends Error {
  constructor(public readonly structured: StructuredError) {
    super(structured.message)
    this.name = 'FoundationAddonError'
  }
}

export function formatError(err: StructuredError, json: boolean): string {
  if (json) return JSON.stringify({ error: err })

  const lines = [`Error [${ErrorCode[err.code]}]: ${err.message}`]
  if (err.skill) lines.push(`  Skill:    ${err.skill}`)
  if (err.provider) lines.push(`  Provider: ${err.provider}`)
  if (err.field) lines.push(`  Field:    ${err.field}`)
  if (err.fix) lines.push(`  Fix:      ${err.fix}`)
  return lines.join('\n')
}
