import {
  readFileSync, writeFileSync, readdirSync,
  existsSync, mkdirSync, copyFileSync,
} from 'fs'
import { join, resolve } from 'path'
import { auditLog } from '../audit.js'
import { ErrorCode, FoundationAddonError } from '../errors.js'

const DIST_DIR = resolve(process.cwd(), 'dist')
const BACKUP_BASE = resolve(process.cwd(), '.foundation-addon/backups')

export interface InstallOptions {
  target: string
  into?: string
  skill?: string
  dryRun?: boolean
  global?: boolean
}

export async function runInstall(options: InstallOptions): Promise<void> {
  const sourceDir = join(DIST_DIR, options.target)
  const targetDir = options.into ?? getDefaultTargetDir(options.target, options.global)

  if (!existsSync(sourceDir)) {
    throw new FoundationAddonError({
      code: ErrorCode.FilesystemError,
      message: `No generated artifacts found at ${sourceDir}`,
      fix: `Run: foundation-addon generate --target ${options.target}`,
    })
  }

  let files = readdirSync(sourceDir).filter((f) => f.endsWith('.md'))
  if (options.skill) {
    const skillFileName = options.skill.split('/')[1] + '.md'
    files = files.filter((f) => f === skillFileName)
  }

  if (files.length === 0) {
    console.log('No artifacts to install.')
    return
  }

  if (options.dryRun) {
    console.log(`\n[DRY RUN] Would install ${files.length} file(s) to ${targetDir}:`)
    files.forEach((f) => {
      const exists = existsSync(join(targetDir, f))
      console.log(`  ${exists ? '~' : '+'} ${join(targetDir, f)}`)
    })
    return
  }

  // Backup before install (DD-012)
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
  const backupDir = join(BACKUP_BASE, timestamp)
  mkdirSync(backupDir, { recursive: true })
  mkdirSync(targetDir, { recursive: true })

  files.forEach((f) => {
    const target = join(targetDir, f)
    if (existsSync(target)) copyFileSync(target, join(backupDir, f))
  })

  files.forEach((f) => {
    writeFileSync(
      join(targetDir, f),
      readFileSync(join(sourceDir, f), 'utf8'),
      'utf8'
    )
  })

  auditLog({
    action: 'install',
    timestamp: new Date().toISOString(),
    target: options.target,
    skills: files.map((f) => f.replace('.md', '')),
    success: true,
    backup_path: backupDir,
  })

  console.log(`\n✓ Installed ${files.length} skill(s) to ${targetDir}`)
  console.log(`  Backup saved: ${backupDir}`)
}

function getDefaultTargetDir(target: string, global?: boolean): string {
  if (target === 'claude') {
    return global
      ? join(process.env.HOME ?? process.env.USERPROFILE ?? '~', '.claude', 'commands')
      : join(process.cwd(), '.claude', 'commands')
  }
  throw new FoundationAddonError({
    code: ErrorCode.ConfigError,
    message: `Install path for target "${target}" is not implemented in Phase 1.`,
    fix: 'Phase 2 adds Codex, Qwen, and Gemini install paths.',
  })
}
