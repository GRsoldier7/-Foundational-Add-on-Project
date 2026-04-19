import { readFileSync, existsSync, readdirSync, statSync } from 'fs'
import { join, resolve, dirname, sep } from 'path'
import yaml from 'js-yaml'
import type { SkillSpec } from '@foundation-addon/adapters'

// Resolve canonical skills directory relative to this file
const CANONICAL_SKILLS_DIR = resolve(
  dirname(import.meta.path),
  '../../canonical/skills'
)

// Strict slug pattern: lowercase letters, digits, hyphens. Must start with a letter.
const SLUG_RE = /^[a-z][a-z0-9-]*$/
// Tool path must be tools/<slug>.json with no path traversal
const TOOL_PATH_RE = /^tools\/[a-z][a-z0-9-]*\.json$/

export interface LoadedSkill {
  spec: SkillSpec
  core: string
  toolPaths: string[]
  skillDir: string
  tier: string
}

export function resolveSkillDir(tierAndName: string): string {
  const parts = tierAndName.split('/')
  if (parts.length !== 2) {
    throw new Error(
      `Invalid skill reference: "${tierAndName}". Expected format: tier/skill-name`
    )
  }
  const [tier, name] = parts
  if (!tier || !name || !SLUG_RE.test(tier) || !SLUG_RE.test(name)) {
    throw new Error(
      `Invalid skill reference: "${tierAndName}". tier and name must match /^[a-z][a-z0-9-]*$/ (no path traversal)`
    )
  }
  const dir = resolve(CANONICAL_SKILLS_DIR, tier, name)
  // Defense in depth: confirm the resolved path is still inside CANONICAL_SKILLS_DIR
  if (!dir.startsWith(CANONICAL_SKILLS_DIR + sep) && dir !== CANONICAL_SKILLS_DIR) {
    throw new Error(`Skill reference escapes canonical dir: ${tierAndName}`)
  }
  return dir
}

export function loadSkill(tierAndName: string): LoadedSkill {
  const skillDir = resolveSkillDir(tierAndName)
  const tier = tierAndName.split('/')[0]!

  const specPath = join(skillDir, 'spec.yaml')
  const corePath = join(skillDir, 'core.md')

  if (!existsSync(specPath)) {
    throw new Error(`spec.yaml not found: ${specPath}`)
  }
  if (!existsSync(corePath)) {
    throw new Error(`core.md not found: ${corePath}`)
  }

  const spec = yaml.load(readFileSync(specPath, 'utf8')) as SkillSpec
  const core = readFileSync(corePath, 'utf8')

  // Fix C2: Validate tool paths against TOOL_PATH_RE before joining.
  // This prevents '../../../etc/passwd' style escapes even if a hand-edited spec.yaml
  // slips past Ajv validation or is loaded in a context where Ajv hasn't run yet.
  const toolRefs = spec.tools ?? []
  const toolPaths = toolRefs.map((toolRef) => {
    if (!TOOL_PATH_RE.test(toolRef)) {
      throw new Error(
        `Invalid tool reference in ${tierAndName}: "${toolRef}". Must match ${TOOL_PATH_RE}`
      )
    }
    const resolved = resolve(skillDir, toolRef)
    if (!resolved.startsWith(skillDir + sep)) {
      throw new Error(
        `Tool path escapes skill directory: ${toolRef} -> ${resolved}`
      )
    }
    return resolved
  })

  return { spec, core, toolPaths, skillDir, tier }
}

export function discoverSkills(tier?: string): string[] {
  if (!existsSync(CANONICAL_SKILLS_DIR)) return []

  const skills: string[] = []

  const tiers = tier
    ? [tier]
    : readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
        .filter((d) => d.isDirectory())
        .map((d) => d.name)

  for (const t of tiers) {
    if (!SLUG_RE.test(t)) continue // Skip anything that doesn't look like a valid tier
    const tierDir = join(CANONICAL_SKILLS_DIR, t)
    if (!existsSync(tierDir)) continue

    const names = readdirSync(tierDir, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name)
      .filter((n) => SLUG_RE.test(n))

    for (const name of names) {
      skills.push(`${t}/${name}`)
    }
  }

  return skills
}
