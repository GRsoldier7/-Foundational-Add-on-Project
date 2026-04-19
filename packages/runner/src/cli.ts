#!/usr/bin/env bun
import { Command } from 'commander'
import { runGenerate } from './commands/generate.js'
import { runValidate } from './commands/validate.js'
import { runInstall } from './commands/install.js'
import { runDoctor } from './commands/doctor.js'
import { formatError } from './errors.js'
import type { FoundationAddonError } from './errors.js'

const program = new Command()

program
  .name('foundation-addon')
  .description('LLM-agnostic skill library and MCP configuration manager')
  .version('0.1.0')

program
  .command('generate')
  .description('Compile canonical skills to provider artifacts in dist/')
  .option('-t, --target <provider>', 'Target provider: claude|codex|qwen|gemini|all', 'claude')
  .option('-s, --skill <ref>', 'Specific skill (format: tier/name)')
  .option('--tier <tier>', 'Generate all skills in a tier')
  .option('--force', 'Bypass incremental compilation cache', false)
  .action(async (opts) => {
    await handle(() => runGenerate(opts))
  })

program
  .command('validate')
  .description('Validate spec.yaml files and lint core.md content')
  .option('-s, --skill <ref>', 'Validate a specific skill only')
  .option('--fix', 'Auto-correct minor formatting issues', false)
  .action(async (opts) => {
    await handle(() => runValidate(opts))
  })

program
  .command('install')
  .description('Promote dist/ artifacts to live tool directories')
  .option('-t, --target <provider>', 'Target provider', 'claude')
  .option('-i, --into <path>', 'Override default install path')
  .option('-s, --skill <ref>', 'Install a specific skill only')
  .option('--dry-run', 'Show what would change without writing', false)
  .option('--global', 'Install to global ~/.claude/commands/', false)
  .action(async (opts) => {
    await handle(() => runInstall({ ...opts, dryRun: opts.dryRun }))
  })

program
  .command('doctor')
  .description('Run environment health checks')
  .action(async () => {
    await handle(() => runDoctor())
  })

async function handle(fn: () => Promise<void>): Promise<void> {
  try {
    await fn()
  } catch (err) {
    if (err && typeof err === 'object' && 'structured' in err) {
      const e = err as InstanceType<typeof FoundationAddonError>
      console.error(formatError(e.structured, false))
      process.exit(e.structured.code)
    }
    console.error(err instanceof Error ? err.message : String(err))
    process.exit(1)
  }
}

program.parseAsync(process.argv)
