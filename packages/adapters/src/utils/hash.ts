import { createHash } from 'crypto'

export function sha256(content: string): string {
  return createHash('sha256').update(content, 'utf8').digest('hex')
}

/**
 * Canonicalize a JSON string by parsing and re-serializing with sorted keys.
 * Returns input unchanged if it's not parseable JSON.
 */
function canonicalizeJson(input: string): string {
  const trimmed = input.trimStart()
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return input
  try {
    const parsed = JSON.parse(input)
    return JSON.stringify(parsed, Object.keys(parsed).sort())
  } catch {
    return input
  }
}

/**
 * Compute a content hash over a skill's source files.
 * Inputs should be the raw file contents, NOT objects. JSON-looking inputs
 * are canonicalized internally to guarantee determinism across key orders.
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
