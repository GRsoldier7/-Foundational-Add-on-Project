import { test, expect, describe } from 'bun:test'
import { ErrorCode, FoundationAddonError, formatError } from '../../packages/runner/src/errors'

describe('ErrorCode', () => {
  test('Success is 0', () => expect(ErrorCode.Success).toBe(0))
  test('ValidationError is 1', () => expect(ErrorCode.ValidationError).toBe(1))
  test('AdapterError is 2', () => expect(ErrorCode.AdapterError).toBe(2))
  test('FilesystemError is 3', () => expect(ErrorCode.FilesystemError).toBe(3))
  test('ConfigError is 4', () => expect(ErrorCode.ConfigError).toBe(4))
  test('TrustViolation is 5', () => expect(ErrorCode.TrustViolation).toBe(5))
  test('CompositionError is 6', () => expect(ErrorCode.CompositionError).toBe(6))
  test('ContextOverflow is 7', () => expect(ErrorCode.ContextOverflow).toBe(7))
})

describe('FoundationAddonError', () => {
  test('wraps structured error', () => {
    const err = new FoundationAddonError({
      code: ErrorCode.ValidationError,
      message: 'spec is invalid',
      skill: 'code-review',
      fix: 'Check your spec.yaml',
    })
    expect(err.structured.code).toBe(1)
    expect(err.message).toBe('spec is invalid')
    expect(err.structured.skill).toBe('code-review')
  })
})

describe('formatError', () => {
  test('plain text includes all fields', () => {
    const formatted = formatError(
      { code: ErrorCode.ValidationError, message: 'bad spec', skill: 'my-skill', fix: 'fix it' },
      false
    )
    expect(formatted).toContain('ValidationError')
    expect(formatted).toContain('bad spec')
    expect(formatted).toContain('my-skill')
    expect(formatted).toContain('fix it')
  })

  test('json mode returns parseable JSON with error key', () => {
    const formatted = formatError(
      { code: ErrorCode.ConfigError, message: 'missing key' },
      true
    )
    const parsed = JSON.parse(formatted)
    expect(parsed.error.code).toBe(4)
    expect(parsed.error.message).toBe('missing key')
  })
})
