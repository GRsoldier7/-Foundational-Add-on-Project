# Vault Organization — Personal vs Dev Separation

The single most important architectural decision when using a vault for both personal credentials AND development secrets is **isolation**. This document describes the recommended structure.

## Why Separate?

| Risk | Mitigation |
|---|---|
| Prompt injection in a file tells Claude to "show all vault items" | Dev vault has only dev secrets — no banking, no personal accounts |
| MCP server compromised | Blast radius limited to dev credentials |
| Accidental sharing of vault export | Personal life not exposed |
| Team member needs access to dev secrets | Share dev org only — personal stays untouched |

## Recommended Structure

### Option A: Two Separate Accounts (Strongest Isolation)

Create **two distinct Bitwarden accounts** on your Vaultwarden instance:

```
1. you@personal.email — Personal Account
   ├── Banking
   ├── Social media
   ├── Email
   ├── Shopping
   ├── Insurance
   └── Family sharing

2. you+dev@yourdomain.com — Dev Account
   ├── Folder: GCP / Production
   ├── Folder: GCP / Staging
   ├── Folder: AWS / Production
   ├── Folder: APIs / Stripe
   ├── Folder: APIs / OpenAI
   ├── Folder: APIs / Anthropic
   ├── Folder: Databases / Postgres
   ├── Folder: GitHub / PATs
   └── Folder: Client Projects / [client name]
```

- The MCP server only authenticates as the **dev account**
- The browser extension uses your **personal account** for daily browsing
- The two are completely isolated — different master passwords, different sessions

### Option B: One Account, Two Organizations (Easier Management)

If two accounts feels like too much, use Bitwarden Organizations within a single account:

```
your-account@email.com
├── My Vault (personal)
│   ├── Banking, social, etc.
│
├── Org: Personal-Sensitive
│   └── (unused — not connected to MCP)
│
└── Org: Development
    ├── Collection: GCP
    ├── Collection: APIs
    └── Collection: Databases
```

- Configure the MCP server with a **scoped API key** that only has access to the Development organization
- Personal items stay in "My Vault" and are inaccessible to the MCP

**Tradeoff:** One master password protects both. If that's compromised, both are exposed. Option A is stronger.

## Folder/Collection Structure (Best Practice)

Whichever option you pick, organize dev secrets by **environment + service**:

```
GCP/
├── Production/
│   ├── service-account-prod.json     [Secure Note]
│   ├── DATABASE_URL                  [Login: custom field]
│   └── REDIS_URL                     [Login: custom field]
├── Staging/
│   └── ...
└── Local/
    └── ...

APIs/
├── Anthropic/
│   ├── ANTHROPIC_API_KEY             [Login: password field]
│   └── notes                         [Secure Note]
├── OpenAI/
│   └── OPENAI_API_KEY
├── Stripe/
│   ├── STRIPE_SECRET_KEY             [Login]
│   ├── STRIPE_PUBLISHABLE_KEY        [Login]
│   └── STRIPE_WEBHOOK_SECRET         [Login]

GitHub/
├── PATs/
│   ├── personal-classic              [Login]
│   ├── fine-grained-foundation       [Login]
│   └── deploy-key-prod               [Secure Note]
```

## Item Types — When to Use What

| Type | Best for | Example |
|---|---|---|
| **Login** | Service credentials with username + password + URL | GitHub login, AWS console |
| **Secure Note** | API keys, tokens, multi-line config, JSON files | Service account JSON, GPG key |
| **Card** | Payment cards (encrypted, autofills checkout forms) | Stripe billing card |
| **Identity** | Personal info for forms | Address for shipping |

For API keys specifically, two valid patterns:

**Pattern A — Login item with password field:**
- Name: `OpenAI API Key — Production`
- Username: `your-account@email.com` (helps identify which account)
- Password: `sk-...` (the actual key)
- URL: `https://platform.openai.com`
- Custom fields: `org-id`, `created-at`, `last-rotated`

**Pattern B — Secure Note with custom fields:**
- Name: `OpenAI Production`
- Notes: "Used by foundation-project. Rotate quarterly."
- Custom fields:
  - `OPENAI_API_KEY` (hidden) = sk-...
  - `OPENAI_ORG_ID` (text) = org-...
  - `created` (text) = 2026-04-08

Pattern B is cleaner for env-var-style secrets that don't have a "username". Use it for most API keys.

## Naming Conventions

Be consistent — your future self (and Claude) will thank you:

```
Format: [SERVICE] [ENVIRONMENT] [DESCRIPTOR]

Good:
  GCP Production Service Account
  Stripe Live Webhook Secret
  GitHub PAT Foundation Project
  PostgreSQL Production Connection String

Bad:
  api key
  test
  new key 2
  prod stuff
```

Why this matters: when Claude searches the vault via MCP (`bw list items --search "stripe"`), consistent naming returns predictable results.

## Tagging with Custom Fields

Add metadata fields to every secret for tracking:

| Field | Purpose | Example |
|---|---|---|
| `created` | When you stored it | `2026-04-08` |
| `rotated` | Last rotation date | `2026-01-15` |
| `expires` | When it must be rotated | `2026-07-15` |
| `project` | What it's used for | `foundation-addon` |
| `environment` | prod/staging/dev | `production` |
| `owner` | Who manages it | `aaron` |

Run a monthly query: `bw list items | jq '.[] | select(.fields[] | select(.name=="expires" and .value < "2026-05-01"))'` to find soon-to-expire secrets.

## Rotation Schedule (Best Practice)

| Secret type | Rotation cadence |
|---|---|
| Production database passwords | 90 days |
| Production API keys | 180 days |
| Personal/dev API keys | Annually |
| GitHub PATs | Use fine-grained, set 90-day expiry |
| Service account keys | 90 days, automate via Terraform if possible |
| OAuth refresh tokens | When compromised only |

## What NOT to Store

Some things should never be in a password manager:
- **Recovery codes for the password manager itself** — store offline (paper, safe)
- **The age private key for vault backups** — store offline (paper, safe deposit box)
- **PII subject to compliance** (HIPAA, PCI) — use a compliance-certified tool
- **Anything that needs to be rotated automatically** — use the cloud provider's secret manager (GCP Secret Manager, AWS Secrets Manager) with the password manager just storing the access reference

## Sharing Patterns

If you need to share dev secrets with a contractor or AI agent later:

1. Create a **temporary collection** in the Development org
2. Move ONLY the needed items to that collection
3. Invite the user/agent with read-only access to that collection
4. Set a calendar reminder to revoke access on a specific date
5. Rotate any shared secrets after access is revoked

Never share your master password. Never share your personal vault. Use organizations and collections for everything that needs to be shared.
