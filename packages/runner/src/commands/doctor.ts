import { existsSync } from 'fs'
import { resolve, dirname } from 'path'
import { FoundationAddonError, ErrorCode } from '../errors.js'

interface Check {
  name: string
  status: '✅' | '⚠️' | '❌'
  detail: string
}

export async function runDoctor(): Promise<void> {
  const checks: Check[] = []

  // Bun runtime version
  const bunVer = (process.versions as Record<string, string>).bun
  checks.push({
    name: 'Bun runtime',
    status: bunVer ? '✅' : '❌',
    detail: bunVer ? `v${bunVer}` : 'Not running under Bun — install from bun.sh',
  })

  // spec.schema.json
  const schemaPath = resolve(
    dirname(import.meta.path),
    '../../../canonical/schema/spec.schema.json'
  )
  checks.push({
    name: 'spec.schema.json',
    status: existsSync(schemaPath) ? '✅' : '❌',
    detail: existsSync(schemaPath) ? 'Found' : `Missing: ${schemaPath}`,
  })

  // providers.yaml
  const providersPath = resolve(
    dirname(import.meta.path),
    '../../../config/providers.yaml'
  )
  checks.push({
    name: 'providers.yaml',
    status: existsSync(providersPath) ? '✅' : '⚠️',
    detail: existsSync(providersPath)
      ? 'Found'
      : `Not found at ${providersPath} — create per spec Section 7 (Task 11)`,
  })

  // API keys (never log values)
  const providerKeys = [
    { env: 'ANTHROPIC_API_KEY', label: 'Claude (ANTHROPIC_API_KEY)' },
    { env: 'OPENAI_API_KEY', label: 'Codex (OPENAI_API_KEY)' },
  ]
  for (const { env, label } of providerKeys) {
    checks.push({
      name: `API key: ${label}`,
      status: process.env[env] ? '✅' : '⚠️',
      detail: process.env[env]
        ? 'Present (value hidden)'
        : `${env} not set in environment`,
    })
  }

  // dist/claude/ populated
  const distDir = resolve(process.cwd(), 'dist/claude')
  checks.push({
    name: 'dist/claude/',
    status: existsSync(distDir) ? '✅' : '⚠️',
    detail: existsSync(distDir)
      ? 'Populated'
      : 'Empty — run: foundation-addon generate --target claude',
  })

  // .claude-plugin/plugin.json
  const pluginPath = resolve(process.cwd(), '.claude-plugin/plugin.json')
  checks.push({
    name: '.claude-plugin/plugin.json',
    status: existsSync(pluginPath) ? '✅' : '⚠️',
    detail: existsSync(pluginPath) ? 'Found' : 'Missing — create in Task 11',
  })

  // Print report
  console.log('\n  Foundation AddOn — Doctor Report')
  console.log('  ' + '─'.repeat(44))
  checks.forEach((c) => console.log(`  ${c.status}  ${c.name}: ${c.detail}`))

  const failures = checks.filter((c) => c.status === '❌').length
  const warnings = checks.filter((c) => c.status === '⚠️').length
  console.log(`\n  ${checks.length} checks — ${failures} failure(s), ${warnings} warning(s)\n`)

  if (failures > 0) {
    throw new FoundationAddonError({
      code: ErrorCode.ConfigError,
      message: `Doctor found ${failures} critical failure(s)`,
      fix: 'Review the ❌ items above and fix them before running other commands.',
    })
  }
}
