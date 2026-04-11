import { test, expect, describe } from 'bun:test'
import { sha256, hashSkillSources } from '../../packages/adapters/src/utils/hash'
import { estimateTokens, checkContextUsage } from '../../packages/adapters/src/utils/ctx-window'
import { insertOrReplace, removeBlock, listBlocks, startTag, endTag } from '../../packages/adapters/src/utils/sentinel'

describe('hash', () => {
  test('sha256 returns 64-char hex string', () => {
    const result = sha256('hello world')
    expect(result).toHaveLength(64)
    expect(result).toMatch(/^[0-9a-f]+$/)
  })

  test('same input produces same hash', () => {
    expect(sha256('test')).toBe(sha256('test'))
  })

  test('different input produces different hash', () => {
    expect(sha256('test1')).not.toBe(sha256('test2'))
  })

  test('hashSkillSources combines all inputs', () => {
    const h1 = hashSkillSources('core', 'spec', ['tool1'])
    const h2 = hashSkillSources('core', 'spec', ['tool2'])
    expect(h1).not.toBe(h2)
  })
})

describe('tokenizer', () => {
  test('estimateTokens approximates by character count', () => {
    const tokens = estimateTokens('hello world')
    expect(tokens).toBeGreaterThan(0)
    expect(typeof tokens).toBe('number')
  })

  test('checkContextUsage returns "none" below 80%', () => {
    expect(checkContextUsage(700, 1000)).toBe('none')
  })

  test('checkContextUsage returns "warn" at 85%', () => {
    expect(checkContextUsage(850, 1000)).toBe('warn')
  })

  test('checkContextUsage returns "truncate" at 96%', () => {
    expect(checkContextUsage(960, 1000)).toBe('truncate')
  })
})

describe('sentinel', () => {
  test('insertOrReplace appends new block to empty file', () => {
    const result = insertOrReplace('', 'my-skill', 'skill content')
    expect(result).toContain(startTag('my-skill'))
    expect(result).toContain('skill content')
    expect(result).toContain(endTag('my-skill'))
  })

  test('insertOrReplace replaces existing block content', () => {
    const original = insertOrReplace('', 'my-skill', 'old content')
    const updated = insertOrReplace(original, 'my-skill', 'new content')
    expect(updated).toContain('new content')
    expect(updated).not.toContain('old content')
  })

  test('insertOrReplace preserves content outside sentinels', () => {
    const existing = 'User content here\n'
    const result = insertOrReplace(existing, 'my-skill', 'skill content')
    expect(result).toContain('User content here')
    expect(result).toContain('skill content')
  })

  test('removeBlock removes sentinel block and its content', () => {
    const withBlock = insertOrReplace('before\n', 'my-skill', 'skill content')
    const removed = removeBlock(withBlock, 'my-skill')
    expect(removed).not.toContain('skill content')
    expect(removed).not.toContain(startTag('my-skill'))
    expect(removed).toContain('before')
  })

  test('removeBlock is a no-op when block not present', () => {
    const content = 'no blocks here'
    expect(removeBlock(content, 'missing-skill')).toBe(content)
  })

  test('listBlocks returns all skill names in file', () => {
    let content = ''
    content = insertOrReplace(content, 'skill-a', 'content a')
    content = insertOrReplace(content, 'skill-b', 'content b')
    const blocks = listBlocks(content)
    expect(blocks).toContain('skill-a')
    expect(blocks).toContain('skill-b')
    expect(blocks).toHaveLength(2)
  })
})
