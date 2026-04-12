import { join, resolve } from 'path'
import { appendFileSync, mkdirSync } from 'fs'

const ADDON_DIR = resolve(process.cwd(), '.foundation-addon')
const AUDIT_FILE = join(ADDON_DIR, 'audit.jsonl')

export interface AuditEntry {
  action: 'generate' | 'install' | 'uninstall' | 'validate' | 'invoke' | 'rollback'
  timestamp: string
  target?: string
  skills?: string[]
  provider?: string
  backup_path?: string
  success: boolean
  error_code?: number
}

export function auditLog(entry: AuditEntry): void {
  try {
    mkdirSync(ADDON_DIR, { recursive: true })
    appendFileSync(AUDIT_FILE, JSON.stringify(entry) + '\n', 'utf8')
  } catch {
    // Audit log failure is non-fatal — never block the main operation
  }
}
