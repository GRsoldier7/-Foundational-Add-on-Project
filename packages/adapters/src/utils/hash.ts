import { createHash } from 'crypto'

export function sha256(content: string): string {
  return createHash('sha256').update(content, 'utf8').digest('hex')
}

/**
 * Recursively sort object keys for stable, deterministic serialization.
 * Arrays preserve order; objects get key-sorted at every depth.
 */
function canon(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canon)
  if (value && typeof value === 'object') {
    const obj = value as Record<string, unknown>
    return Object.fromEntries(
      Object.keys(obj)
        .sort()
        .map((k) => [k, canon(obj[k])])
    )
  }
  return value
}

/**
 * Canonicalize a JSON string by parsing and re-serializing with recursively sorted keys.
 * Returns input unchanged if it's not parseable JSON.
 */
function canonicalizeJson(input: string): string {
  const trimmed = input.trimStart()
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return input
  try {
    return JSON.stringify(canon(JSON.parse(input)))
  } catch {
    return input
  }
}

/**
 * Compute a content hash over a skill's source files.
 * Inputs should be the raw file contents, NOT objects. JSON-looking inputs
 * are canonicalized internally (recursive key sorting) to guarantee determinism.
 * Tool JSONs are sorted alphabetically before hashing for order-independence.
 */
export function hashSkillSources(
  coreMd: string,
  specYaml: string,
  toolJsons: string[]
): string {
  const canonicalTools = toolJsons.map(canonicalizeJson).sort()
  const canonicalSpec = canonicalizeJson(specYaml)
  const combined = [coreMd, canonicalSpec, ...canonicalTools].join('\n---\n')
  return sha256(combined)
}
