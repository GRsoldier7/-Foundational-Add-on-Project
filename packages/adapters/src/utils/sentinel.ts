const START_PREFIX = '<!-- foundation-addon:start:'
const END_PREFIX = '<!-- foundation-addon:end:'
const SENTINEL_SUFFIX = ' -->'

export function startTag(skillName: string): string {
  return `${START_PREFIX}${skillName}${SENTINEL_SUFFIX}`
}

export function endTag(skillName: string): string {
  return `${END_PREFIX}${skillName}${SENTINEL_SUFFIX}`
}

export function insertOrReplace(
  existingContent: string,
  skillName: string,
  newBlock: string
): string {
  const start = startTag(skillName)
  const end = endTag(skillName)
  const block = `${start}\n${newBlock}\n${end}`

  const startIdx = existingContent.indexOf(start)
  if (startIdx === -1) {
    const sep = existingContent.length > 0 && !existingContent.endsWith('\n') ? '\n' : ''
    return `${existingContent}${sep}\n${block}\n`
  }

  const endIdx = existingContent.indexOf(end, startIdx)
  if (endIdx === -1) {
    throw new Error(
      `Corrupted sentinel: found start tag but no end tag for skill "${skillName}"`
    )
  }

  return (
    existingContent.slice(0, startIdx) +
    block +
    existingContent.slice(endIdx + end.length)
  )
}

export function removeBlock(existingContent: string, skillName: string): string {
  const start = startTag(skillName)
  const end = endTag(skillName)

  const startIdx = existingContent.indexOf(start)
  if (startIdx === -1) return existingContent

  const endIdx = existingContent.indexOf(end, startIdx)
  if (endIdx === -1) {
    throw new Error(
      `Corrupted sentinel: found start tag but no end tag for skill "${skillName}"`
    )
  }

  let before = existingContent.slice(0, startIdx)
  const after = existingContent.slice(endIdx + end.length)

  if (before.endsWith('\n\n')) before = before.slice(0, -1)

  return before + after
}

export function listBlocks(content: string): string[] {
  const blocks: string[] = []
  const pattern = /<!-- foundation-addon:start:([^>]+) -->/g
  let match
  while ((match = pattern.exec(content)) !== null) {
    blocks.push(match[1])
  }
  return blocks
}
