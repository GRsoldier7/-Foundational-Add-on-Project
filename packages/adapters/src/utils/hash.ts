import { createHash } from 'crypto'

export function sha256(content: string): string {
  return createHash('sha256').update(content, 'utf8').digest('hex')
}

export function hashSkillSources(
  coreMd: string,
  specYaml: string,
  toolJsons: string[]
): string {
  const combined = [coreMd, specYaml, ...toolJsons.sort()].join('\n---\n')
  return sha256(combined)
}
