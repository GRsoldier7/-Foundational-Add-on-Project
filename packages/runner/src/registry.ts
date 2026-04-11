import { readFileSync, existsSync, readdirSync, statSync } from 'fs'
import { join, resolve, dirname } from 'path'
import yaml from 'js-yaml'
import type { SkillSpec } from '@foundation-addon/adapters'

// Resolve canonical skills directory relative to this file
const CANONICAL_SKILLS_DIR = resolve(
  dirname(import.meta.path),
  '../../canonical/skills'
)

export interface LoadedSkill {
  spec: SkillSpec
  core: string
  toolPaths: string[]
  skillDir: string
  tier: string
}

export function resolveSkillDir(tierAndName: string): string {
  const parts = tierAndName.split('/')
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    throw new Error(
      `Invalid skill reference: "${tierAndName}". Expected format: tier/skill-name`
    )
  }
  return join(CANONICAL_SKILLS_DIR, parts[0], parts[1])
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

  const toolPaths = (spec.tools ?? []).map((toolRef) =>
    join(skillDir, toolRef)
  )

  return { spec, core, toolPaths, skillDir, tier }
}

export function discoverSkills(tier?: string): string[] {
  if (!existsSync(CANONICAL_SKILLS_DIR)) return []

  const skills: string[] = []

  const tiers = tier
    ? [tier]
    : readdirSync(CANONICAL_SKILLS_DIR).filter((d) =>
        statSync(join(CANONICAL_SKILLS_DIR, d)).isDirectory()
      )

  for (const t of tiers) {
    const tierDir = join(CANONICAL_SKILLS_DIR, t)
    if (!existsSync(tierDir)) continue

    const names = readdirSync(tierDir).filter((d) =>
      statSync(join(tierDir, d)).isDirectory()
    )
    for (const name of names) {
      skills.push(`${t}/${name}`)
    }
  }

  return skills
}
