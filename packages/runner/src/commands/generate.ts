import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs'
import { join, resolve, dirname } from 'path'
import { ClaudeAdapter, hashSkillSources } from '@foundation-addon/adapters'
import { discoverSkills, loadSkill } from '../registry.js'
import { auditLog } from '../audit.js'
import { ErrorCode, FoundationAddonError } from '../errors.js'

const DIST_DIR = resolve(process.cwd(), 'dist')
const CACHE_FILE = resolve(
  dirname(import.meta.path),
  '../../../canonical/.cache/hashes.json'
)

function loadHashCache(): Record<string, string> {
  if (!existsSync(CACHE_FILE)) return {}
  try {
    return JSON.parse(readFileSync(CACHE_FILE, 'utf8'))
  } catch {
    return {}
  }
}

function saveHashCache(cache: Record<string, string>): void {
  mkdirSync(dirname(CACHE_FILE), { recursive: true })
  writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 2), 'utf8')
}

export interface GenerateOptions {
  target: string
  skill?: string
  tier?: string
  force?: boolean
}

export async function runGenerate(options: GenerateOptions): Promise<void> {
  if (options.target !== 'claude') {
    throw new FoundationAddonError({
      code: ErrorCode.AdapterError,
      message: `Target "${options.target}" is not supported in Phase 1.`,
      fix: 'Use --target claude. Multi-provider support arrives in Phase 2.',
    })
  }

  const adapter = new ClaudeAdapter()
  const skillRefs = options.skill
    ? [options.skill]
    : discoverSkills(options.tier)

  const cache = options.force ? {} : loadHashCache()
  const newCache: Record<string, string> = { ...cache }

  const outDir = join(DIST_DIR, 'claude')
  mkdirSync(outDir, { recursive: true })

  let skipped = 0
  let generated = 0

  // Parallel generation across all skills (DD-014)
  await Promise.all(
    skillRefs.map(async (skillRef) => {
      const loaded = loadSkill(skillRef)
      const toolContents = loaded.toolPaths.map((p) => readFileSync(p, 'utf8'))
      const currentHash = hashSkillSources(
        loaded.core,
        JSON.stringify(loaded.spec),
        toolContents
      )

      if (!options.force && cache[skillRef] === currentHash) {
        skipped++
        return
      }

      const artifact = adapter.generateArtifact(loaded.spec, loaded.core)
      const outFile = join(outDir, `${loaded.spec.name}.md`)
      writeFileSync(outFile, artifact, 'utf8')
      newCache[skillRef] = currentHash
      generated++
    })
  )

  saveHashCache(newCache)

  auditLog({
    action: 'generate',
    timestamp: new Date().toISOString(),
    target: 'claude',
    skills: skillRefs,
    success: true,
  })

  console.log(
    `Generated ${generated} skill(s)` +
      (skipped > 0 ? ` (${skipped} unchanged, skipped)` : '')
  )
}
