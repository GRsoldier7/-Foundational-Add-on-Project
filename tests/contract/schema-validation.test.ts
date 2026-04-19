import { test, expect, describe } from 'bun:test'
import Ajv from 'ajv'
import { readFileSync } from 'fs'
import { join } from 'path'

const SCHEMA_DIR = join(import.meta.dir, '../../packages/canonical/schema')

function loadSchema(name: string) {
  return JSON.parse(readFileSync(join(SCHEMA_DIR, name), 'utf8'))
}

describe('spec.schema.json', () => {
  test('validates a minimal valid spec', () => {
    const ajv = new Ajv()
    const schema = loadSchema('spec.schema.json')
    const validate = ajv.compile(schema)

    const validSpec = {
      spec_version: '1.0',
      name: 'code-review',
      version: '1.0.0',
      description: 'Expert code review for correctness and security',
      tier: 'engineering',
      capabilities: ['code_analysis'],
      trust_tier: 'T2',
      author: 'foundation-addon',
    }

    expect(validate(validSpec)).toBe(true)
  })

  test('rejects spec missing required field "author"', () => {
    const ajv = new Ajv()
    const schema = loadSchema('spec.schema.json')
    const validate = ajv.compile(schema)

    const invalidSpec = {
      spec_version: '1.0',
      name: 'code-review',
      version: '1.0.0',
      description: 'Expert code review',
      tier: 'engineering',
      capabilities: ['code_analysis'],
      trust_tier: 'T2',
    }

    expect(validate(invalidSpec)).toBe(false)
  })

  test('rejects invalid trust_tier value', () => {
    const ajv = new Ajv()
    const schema = loadSchema('spec.schema.json')
    const validate = ajv.compile(schema)

    const invalidSpec = {
      spec_version: '1.0',
      name: 'code-review',
      version: '1.0.0',
      description: 'Expert code review',
      tier: 'engineering',
      capabilities: ['code_analysis'],
      trust_tier: 'T5',
      author: 'foundation-addon',
    }

    expect(validate(invalidSpec)).toBe(false)
  })

  test('rejects invalid tier value', () => {
    const ajv = new Ajv()
    const schema = loadSchema('spec.schema.json')
    const validate = ajv.compile(schema)

    const invalidSpec = {
      spec_version: '1.0',
      name: 'code-review',
      version: '1.0.0',
      description: 'Expert code review',
      tier: 'invalid-tier',
      capabilities: ['code_analysis'],
      trust_tier: 'T2',
      author: 'foundation-addon',
    }

    expect(validate(invalidSpec)).toBe(false)
  })
})
