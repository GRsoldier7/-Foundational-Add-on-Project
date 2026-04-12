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

interface GenResult {
  skillRef: string
  skillName: string
  hash: string
  artifact: string
  skipped: boolean
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

  const outDir = join(DIST_DIR, 'claude')
  mkdirSync(outDir, { recursive: true })

  // Phase 1: compute hashes and generate artifacts in parallel (pure, no shared state mutation)
  // Fix I1: collect results, apply to cache sequentially AFTER Promise.all resolves
  const results: GenResult[] = await Promise.all(
    skillRefs.map(async (skillRef): Promise<GenResult> => {
      const loaded = loadSkill(skillRef)
      const toolContents = loaded.toolPaths.map((p) => readFileSync(p, 'utf8'))
      const currentHash = hashSkillSources(
        loaded.core,
        JSON.stringify(loaded.spec),
        toolContents
      )

      if (!options.force && cache[skillRef] === currentHash) {
        return {
          skillRef,
          skillName: loaded.spec.name,
          hash: currentHash,
          artifact: '',
          skipped: true,
        }
      }

      const artifact = adapter.generateArtifact(loaded.spec, loaded.core)
      return {
        skillRef,
        skillName: loaded.spec.name,
        hash: currentHash,
        artifact,
        skipped: false,
      }
    })
  )

  // Phase 2: apply results sequentially (no race conditions)
  // Fix I2: newCache only contains entries for skills we actually processed,
  // preventing stale entries for deleted skills from lingering forever.
  const newCache: Record<string, string> = {}
  let skipped = 0
  let generated = 0

  for (const result of results) {
    newCache[result.skillRef] = result.hash
    if (result.skipped) {
      skipped++
    } else {
      const outFile = join(outDir, `${result.skillName}.md`)
      writeFileSync(outFile, result.artifact, 'utf8')
      generated++
    }
  }

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
