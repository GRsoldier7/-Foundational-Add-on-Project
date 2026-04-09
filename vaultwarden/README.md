# Vaultwarden Self-Hosted Vault — Setup Guide

A production-grade Bitwarden-compatible password manager running on your homelab. This stack handles credentials for both personal use AND development secrets (API keys, tokens, connection strings) with proper isolation.

## Architecture

```
┌──────────────────────────────────────────────────┐
│  Your Devices (Mac, phone, browsers)             │
│  ↓ HTTPS                                         │
└──────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│  Caddy Reverse Proxy (port 443)                  │
│  - Auto HTTPS (internal CA or Let's Encrypt)     │
│  - HTTP/3, security headers, rate limiting       │
└──────────────────────────────────────────────────┘
                    │ internal docker network
                    ▼
┌──────────────────────────────────────────────────┐
│  Vaultwarden (no public ports)                   │
│  - SQLite database (encrypted)                   │
│  - Argon2 admin token, rate limiting             │
│  - WebSocket for live sync                       │
└──────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│  Persistent Docker Volumes                       │
│  - vw-data (vault contents)                      │
│  - caddy-data (TLS certs)                        │
└──────────────────────────────────────────────────┘
```

## Prerequisites

- Docker + Docker Compose
- A hostname for your vault — pick one:
  - **LAN-only:** `vault.lan` (add to your local DNS or `/etc/hosts`)
  - **Tailscale:** `vault.tailnet-name.ts.net` (auto-resolved)
  - **Public:** `vault.yourdomain.com` (DNS A record pointing at your IP)
- `openssl` and `age` (for backup encryption): `brew install age`

## First-Time Setup

### 1. Generate the admin token (Argon2-hashed)

```bash
# Generate a strong random token
openssl rand -base64 48
# Copy the output

# Hash it with Argon2 (paste the token when prompted)
docker run --rm -it vaultwarden/server:1.32.5-alpine /vaultwarden hash
# Copy the $argon2id$... output
```

### 2. Configure environment

```bash
cp .env.example .env
$EDITOR .env  # Fill in VW_DOMAIN, VW_DOMAIN_HOST, VW_ADMIN_TOKEN
```

### 3. Choose your deployment mode

Edit `Caddyfile` and pick one:
- **MODE 1 (recommended):** LAN-only with Caddy's internal CA — no internet exposure
- **MODE 2:** Public domain with Let's Encrypt — only if you need access without VPN

For LAN-only mode, you'll install Caddy's local CA root certificate on your devices once. Caddy will tell you the path after first start.

### 4. Start the stack

```bash
docker compose up -d
docker compose logs -f vaultwarden  # Watch for "Rocket has launched"
```

### 5. Create your first user

1. Open `https://vault.lan` (or your chosen domain) in a browser
2. Click **Create Account**
3. Use a STRONG master passphrase — 4+ random words, 20+ characters
4. Enable 2FA immediately (Settings → Security → Two-step Login)

### 6. Lock down signups

```bash
# Edit .env
VW_SIGNUPS_ALLOWED=false

# Restart
docker compose up -d
```

### 7. Migrate from LastPass

1. **In LastPass:** Account Options → Advanced → Export → Save CSV
2. **In Vaultwarden web UI:** Tools → Import Data → File format: `LastPass (csv)` → Upload
3. **Verify** all items imported correctly
4. **Securely delete** the CSV: `srm lastpass-export.csv` (or `rm` then `diskutil secureErase`)

### 8. Install clients

| Client | Where to get it |
|---|---|
| Browser extension | Chrome/Firefox/Edge web stores — search "Bitwarden" |
| macOS app | App Store — "Bitwarden" |
| iOS/Android | App stores — "Bitwarden" |
| CLI | `brew install bitwarden-cli` |

For all clients: in settings, change the **Server URL** to point at your Vaultwarden instance (e.g. `https://vault.lan`).

### 9. Set up CLI access (for MCP and scripts)

```bash
# Configure CLI to use your server
bw config server https://vault.lan

# Login (you'll need your master password)
bw login your-email@example.com

# Unlock and export session key
export BW_SESSION="$(bw unlock --raw)"

# Test
bw list items --search "github" | jq
```

The `BW_SESSION` is a session key — not your master password. It expires when you `bw lock` or close your shell.

## Backups

The `scripts/backup.sh` script creates encrypted backups using `age`. Set it up:

```bash
# 1. Generate an age keypair (do this ONCE, store the private key safely!)
mkdir -p ~/.age
age-keygen -o ~/.age/vaultwarden-backup.key

# 2. Extract the public key
grep 'public key' ~/.age/vaultwarden-backup.key | awk '{print $NF}' > ~/.age/vaultwarden-backup.pub

# 3. Run a manual backup
./scripts/backup.sh

# 4. Schedule daily via cron
crontab -e
# Add this line:
0 3 * * * /full/path/to/scripts/backup.sh >> /var/log/vaultwarden-backup.log 2>&1
```

**CRITICAL:** Store `~/.age/vaultwarden-backup.key` somewhere safe and OFFLINE. If you lose this key, your encrypted backups are useless. Print it on paper, store in a safe deposit box.

### Restore from backup

```bash
age -d -i ~/.age/vaultwarden-backup.key backup.tar.gz.age | tar -xzf - -C /tmp/restore
docker compose down
docker run --rm -v vaultwarden_vw-data:/data -v /tmp/restore:/restore alpine \
  sh -c "cp -av /restore/. /data/"
docker compose up -d
```

## Updating

```bash
docker compose pull
docker compose up -d
```

Always read the [Vaultwarden release notes](https://github.com/dani-garcia/vaultwarden/releases) before updating to check for breaking changes.

## Security Hardening Checklist

- [x] Argon2-hashed admin token (not plain)
- [x] Signups disabled after first user
- [x] HTTPS enforced (no HTTP fallback)
- [x] Rate limiting on login + admin (built-in)
- [x] Containers run as non-root user
- [x] No new privileges security flag
- [x] Caddy drops all capabilities except NET_BIND_SERVICE
- [x] Strong CSP, HSTS, X-Frame-Options headers
- [x] WebSocket served via reverse proxy (not exposed directly)
- [x] Pinned image versions (reproducible builds)
- [x] Persistent volumes with backup script
- [ ] **YOU:** Strong master password (4+ random words, 20+ chars)
- [ ] **YOU:** 2FA enabled on every account
- [ ] **YOU:** Backups tested via restore drill
- [ ] **YOU:** Updates applied monthly
- [ ] **YOU:** Vault organization separated (see VAULT_ORGANIZATION.md)

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Browser cert error | LAN mode, CA not trusted | Install Caddy's root CA on your device (logs show path) |
| Cannot reach `vault.lan` | DNS not configured | Add `192.168.x.x vault.lan` to `/etc/hosts` |
| WebSocket disconnects | Proxy misconfigured | Verify Caddyfile `/notifications/hub` route |
| Admin panel locked out | Wrong token format | Re-hash with `vaultwarden hash`, ensure `$argon2id$` prefix |
| `bw login` 401 | CLI pointed at wrong server | `bw config server https://vault.lan && bw logout && bw login` |

## See Also

- [VAULT_ORGANIZATION.md](VAULT_ORGANIZATION.md) — How to organize personal vs dev secrets
- [../mcp-config/recommended-servers.json](../mcp-config/recommended-servers.json) — Bitwarden MCP server config
