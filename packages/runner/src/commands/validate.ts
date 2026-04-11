import { readFileSync } from 'fs'
import { resolve, dirname } from 'path'
import Ajv from 'ajv'
import { discoverSkills, loadSkill } from '../registry.js'
import { ErrorCode, FoundationAddonError } from '../errors.js'

const SPEC_SCHEMA_PATH = resolve(
  dirname(import.meta.path),
  '../../../canonical/schema/spec.schema.json'
)

export interface ValidateOptions {
  skill?: string
  fix?: boolean
}

export async function runValidate(options: ValidateOptions): Promise<void> {
  const ajv = new Ajv({ allErrors: true })
  const specSchema = JSON.parse(readFileSync(SPEC_SCHEMA_PATH, 'utf8'))
  const validateSchema = ajv.compile(specSchema)

  const skillRefs = options.skill ? [options.skill] : discoverSkills()
  const errors: string[] = []

  for (const skillRef of skillRefs) {
    let loaded
    try {
      loaded = loadSkill(skillRef)
    } catch (e) {
      errors.push(`${skillRef}: Failed to load — ${(e as Error).message}`)
      continue
    }

    const valid = validateSchema(loaded.spec)
    if (!valid) {
      for (const err of validateSchema.errors ?? []) {
        errors.push(`${skillRef}: ${err.instancePath || '(root)'} ${err.message}`)
      }
    }

    errors.push(...lintCore(loaded.core, skillRef))
  }

  if (errors.length > 0) {
    console.error(`\n✗ Validation failed — ${errors.length} issue(s):`)
    errors.forEach((e) => console.error(`  • ${e}`))
    throw new FoundationAddonError({
      code: ErrorCode.ValidationError,
      message: `${errors.length} validation issue(s) found`,
      fix: 'Fix each issue above. Run with --fix to auto-correct minor formatting issues.',
    })
  }

  console.log(`\n✓ All ${skillRefs.length} skills validated successfully`)
}

/** Exported for testing */
export function lintCore(core: string, skillRef: string): string[] {
  const issues: string[] = []
  const wordCount = core.split(/\s+/).filter(Boolean).length

  if (/<[a-z][\w-]*>/i.test(core)) {
    issues.push(
      `${skillRef}: core.md contains XML tags — move provider-specific syntax to provider_hints.{provider}.system_prefix`
    )
  }

  if (/mcp__\w+__\w+/.test(core)) {
    issues.push(
      `${skillRef}: core.md references MCP tools directly — use generic tool names in tools/*.json instead`
    )
  }

  if (/^####/m.test(core)) {
    issues.push(
      `${skillRef}: core.md uses #### headings — maximum heading depth is ##`
    )
  }

  if (wordCount > 600) {
    issues.push(
      `${skillRef}: core.md has ${wordCount} words (limit: 600) — consider decomposing into sub-skills`
    )
  }

  return issues
}
