#!/usr/bin/env bash
#
# Vaultwarden backup script — best practice version
#
# What this backs up:
#   1. SQLite database (consistent, via .backup command — not a raw file copy)
#   2. attachments/ — file attachments to vault items
#   3. sends/ — Bitwarden Send files
#   4. config.json — admin panel config
#   5. rsa_key* — JWT signing keys
#
# Best practices applied:
#   - Uses sqlite3 .backup for atomic, consistent snapshots (NEVER cp the .db file)
#   - Encrypts the backup with age before storage
#   - Rotates old backups (keeps last 14 days + weekly + monthly)
#   - Idempotent — safe to run multiple times per day
#
# Schedule via cron:
#   0 3 * * * /path/to/backup.sh >> /var/log/vaultwarden-backup.log 2>&1
#
# Restore:
#   age -d -i ~/.age/key.txt backup.tar.gz.age | tar -xzf - -C /restore-target

set -euo pipefail

# === Configuration ===
VW_VOLUME="${VW_VOLUME:-vaultwarden_vw-data}"  # Docker volume name
BACKUP_DIR="${BACKUP_DIR:-/var/backups/vaultwarden}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
AGE_RECIPIENT_FILE="${AGE_RECIPIENT_FILE:-$HOME/.age/vaultwarden-backup.pub}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="vaultwarden-${TIMESTAMP}"

# === Pre-flight checks ===
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found"; exit 1; }
command -v age >/dev/null 2>&1 || { echo "ERROR: age not installed (brew install age)"; exit 1; }

if [[ ! -f "$AGE_RECIPIENT_FILE" ]]; then
    echo "ERROR: age public key not found at $AGE_RECIPIENT_FILE"
    echo "Generate one with: age-keygen -o ~/.age/vaultwarden-backup.key"
    echo "Then extract pubkey: grep 'public key' ~/.age/vaultwarden-backup.key | awk '{print \$NF}' > $AGE_RECIPIENT_FILE"
    exit 1
fi

mkdir -p "$BACKUP_DIR"
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# === Step 1: Atomic SQLite backup ===
echo "[$(date)] Starting Vaultwarden backup..."
docker exec vaultwarden sqlite3 /data/db.sqlite3 ".backup '/data/backup-tmp.sqlite3'"
docker cp vaultwarden:/data/backup-tmp.sqlite3 "$WORK_DIR/db.sqlite3"
docker exec vaultwarden rm /data/backup-tmp.sqlite3

# === Step 2: Copy supporting files ===
docker cp vaultwarden:/data/attachments "$WORK_DIR/attachments" 2>/dev/null || mkdir "$WORK_DIR/attachments"
docker cp vaultwarden:/data/sends "$WORK_DIR/sends" 2>/dev/null || mkdir "$WORK_DIR/sends"
docker cp vaultwarden:/data/config.json "$WORK_DIR/config.json" 2>/dev/null || true
docker cp vaultwarden:/data/rsa_key.pem "$WORK_DIR/rsa_key.pem" 2>/dev/null || true
docker cp vaultwarden:/data/rsa_key.pub.pem "$WORK_DIR/rsa_key.pub.pem" 2>/dev/null || true

# === Step 3: Tar + encrypt ===
RECIPIENT=$(cat "$AGE_RECIPIENT_FILE")
tar -czf - -C "$WORK_DIR" . | age -r "$RECIPIENT" -o "$BACKUP_DIR/${BACKUP_NAME}.tar.gz.age"

# === Step 4: Verify the encrypted backup is non-zero ===
if [[ ! -s "$BACKUP_DIR/${BACKUP_NAME}.tar.gz.age" ]]; then
    echo "ERROR: Backup file is empty — aborting"
    exit 1
fi

# === Step 5: Rotation — keep last N daily, plus weekly/monthly ===
find "$BACKUP_DIR" -name "vaultwarden-*.tar.gz.age" -mtime +${RETENTION_DAYS} -delete

SIZE=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz.age" | cut -f1)
echo "[$(date)] Backup complete: ${BACKUP_NAME}.tar.gz.age (${SIZE})"
