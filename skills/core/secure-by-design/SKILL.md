---
name: secure-by-design
description: |
  Always-on security DNA that embeds security-first thinking into every code suggestion,
  architecture decision, and configuration change. This is NOT an audit tool — it is the
  immune system that prevents insecure code from being generated in the first place.

  AUTO-TRIGGER (always active — runs silently on every code-related response):
  - Every code block, config snippet, or architecture suggestion passes through the
    Security Mental Checklist before output
  - Every function, endpoint, query, or container definition gets secure defaults applied
  - Every boundary (user input, API call, file I/O, env var, IPC) gets validation injected
  - Every secret reference gets vault-pattern enforcement

  EXPLICIT TRIGGER on: "secure by design", "security first", "harden this", "is this
  secure enough", "what could go wrong", "attack surface", "zero trust", "least privilege",
  "defense in depth", "secure defaults".

  DIFFERENTIATION from adjacent skills:
  - app-security-architect = on-demand OWASP auditor (reactive, deep)
  - security-threat-model / stride-analysis-patterns = structured threat modeling frameworks
  - cso = security audit role (review gate)
  - secure-by-design = ALWAYS-ON immune system (proactive, woven into every line)

  This skill makes security unconscious and automatic. The other skills make it deliberate
  and thorough. They are complementary — this one runs first, always.
metadata:
  author: aaron-deyoung
  version: "1.0"
  domain-category: core
  adjacent-skills: app-security-architect, security-threat-model, stride-analysis-patterns, cso, code-review
  last-reviewed: "2026-04-10"
  review-trigger: "New OWASP release, major CVE in common dependencies, new attack class discovered"
  capability-assumptions:
    - "No external tools required — operates as a mental discipline layer"
    - "Applies to all languages and frameworks in the skill library"
  fallback-patterns:
    - "If uncertain about a security pattern: flag it and recommend app-security-architect for deep review"
    - "If stack-specific guidance needed: defer to the relevant tech skill + this skill's principles"
  degradation-mode: "strict"
---

## Composability Contract
- Input expects: any code, config, architecture, or infrastructure suggestion about to be output
- Output produces: the same suggestion with secure defaults, validation, and hardening applied
- Applies to: every other skill as a pre-output filter — runs BEFORE the response is finalized
- Escalates to: app-security-architect (deep audit), cso (formal review), security-threat-model (structured analysis)
- Orchestrator notes: this skill is a silent meta-layer like anti-hallucination — it modifies output quality, not output structure

---

## Core Principles (apply to EVERY code suggestion)

### 1. Zero Trust
Never trust, always verify. Every component assumes every other component is compromised.
- Validate all inputs at every boundary, even between internal services
- Authenticate and authorize every request, even internal ones
- Do not rely on network perimeter for security — assume breach

### 2. Least Privilege
Minimum access, maximum restriction. Default to no access, grant only what is needed.
- Functions get only the permissions they require
- Database users get only the tables/columns they need
- Containers run as non-root with minimal capabilities
- API tokens are scoped to the narrowest set of operations
- File permissions default to restrictive (600/640, never 777)

### 3. Defense in Depth
Multiple independent layers. Never a single point of security failure.
- Input validation at the edge AND in the business logic AND in the database
- Auth at the gateway AND in the service AND at the data layer
- Encryption in transit AND at rest AND in memory for sensitive data

### 4. Secure Defaults
Systems are locked down by default. Openness is explicitly opted into, not security opted out of.
- New endpoints require auth unless explicitly marked public
- CORS defaults to deny-all, allowlist specific origins
- CSP defaults to restrictive, loosen only what is needed
- Cookie flags: HttpOnly, Secure, SameSite=Strict by default
- Debug/verbose modes are OFF in production

### 5. Fail Secure
Errors must not expose data, bypass authentication, or weaken the system.
- Catch blocks never return stack traces, internal paths, or query details to users
- Auth failures return generic messages (never "user not found" vs "wrong password")
- Default-deny: if the authz check throws, access is denied (not granted)
- Circuit breakers fail closed, not open

### 6. Attack Surface Minimization
Every exposed endpoint, port, dependency, and feature is an attack vector. Minimize ruthlessly.
- Remove unused dependencies, endpoints, and features
- Close unused ports in containers and firewalls
- Disable default admin panels, debug endpoints, and status pages in production
- Prefer compile-time over runtime configuration where possible

---

## Security Mental Checklist (run silently on EVERY code suggestion)

Before outputting any code, silently verify:

```
[ ] INPUT: Is every external input validated, typed, bounded, and sanitized?
[ ] AUTH: Does this require authentication? Is it enforced?
[ ] AUTHZ: Does this require authorization? Is it checked at the right layer?
[ ] SECRETS: Are there any hardcoded secrets, keys, tokens, or passwords? (REJECT)
[ ] ERRORS: Do error responses leak internal details? (stack traces, paths, SQL)
[ ] LOGGING: Does logging capture audit events WITHOUT logging secrets/PII?
[ ] DEPS: Are dependencies pinned, audited, and from trusted sources?
[ ] DEFAULTS: Are the defaults secure? Would a misconfiguration expose the system?
[ ] ATTACKER: What would an attacker do with this? (injection, escalation, exfiltration)
[ ] DATA: Is sensitive data encrypted, classified, and access-controlled?
```

If ANY check fails: fix it in the code before outputting. Do not output insecure code with a
comment saying "fix this later." Security is not a TODO.

---

## Input Validation (enforce at EVERY boundary)

### Boundaries That Require Validation
- User input (forms, query params, headers, cookies, request bodies)
- API responses from external services (never trust third-party data)
- File uploads (type, size, content, filename)
- Environment variables (validate on startup, fail fast)
- Database query results (defensive coding against unexpected shapes)
- Message queue payloads, webhook bodies, IPC messages
- URL parameters and path segments (path traversal prevention)

### Validation Patterns

```python
# WRONG — trusts user input
user_id = request.query_params["user_id"]
query = f"SELECT * FROM users WHERE id = {user_id}"

# RIGHT — typed, bounded, parameterized
from pydantic import BaseModel, Field, conint

class UserRequest(BaseModel):
    user_id: conint(gt=0, lt=2_147_483_647)

validated = UserRequest(**request.query_params)
result = await db.execute(
    text("SELECT * FROM users WHERE id = :id"),
    {"id": validated.user_id}
)
```

```python
# File upload — validate everything
ALLOWED_TYPES = {"image/png", "image/jpeg", "application/pdf"}
MAX_SIZE = 10 * 1024 * 1024  # 10MB

async def upload(file: UploadFile):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(400, "Unsupported file type")
    content = await file.read()
    if len(content) > MAX_SIZE:
        raise HTTPException(400, "File too large")
    # Verify magic bytes match claimed content type
    actual_type = magic.from_buffer(content, mime=True)
    if actual_type not in ALLOWED_TYPES:
        raise HTTPException(400, "File content does not match type")
```

```python
# Environment validation — fail fast on startup
from pydantic_settings import BaseSettings

class Config(BaseSettings):
    DATABASE_URL: str  # required, no default
    SECRET_KEY: str = Field(min_length=32)
    DEBUG: bool = False  # secure default
    ALLOWED_HOSTS: list[str] = []  # empty = deny all

config = Config()  # raises ValidationError if missing/invalid
```

---

## Authentication Patterns

### Token Management
- JWTs: short expiry (15min access, 7d refresh), rotate refresh tokens on use
- API keys: scoped per-service, rotatable, never in URLs (use headers)
- Session tokens: cryptographically random, server-side storage, HttpOnly cookies
- MFA: enforce for admin/elevated operations, support TOTP + WebAuthn

```python
# JWT with short expiry + refresh rotation
ACCESS_TOKEN_EXPIRE = timedelta(minutes=15)
REFRESH_TOKEN_EXPIRE = timedelta(days=7)

async def refresh(refresh_token: str):
    payload = verify_token(refresh_token)
    # Invalidate the old refresh token (one-time use)
    await revoke_token(refresh_token)
    # Issue new pair
    return create_token_pair(payload["sub"])
```

### Session Security
- Regenerate session ID on privilege change (login, role change)
- Absolute timeout (max session lifetime) + idle timeout
- Bind sessions to user-agent and IP range where practical

---

## Authorization Patterns

### RBAC/ABAC at the Right Layer
- Route-level: coarse-grained (is user authenticated? has role?)
- Service-level: fine-grained (can this user perform this action on this resource?)
- Data-level: row-level security (user only sees their own data)

```python
# Row-level security — never trust the client to filter
async def get_documents(user: User, db: AsyncSession):
    # WRONG: return all, let frontend filter
    # RIGHT: filter at query level
    result = await db.execute(
        select(Document).where(Document.owner_id == user.id)
    )
    return result.scalars().all()
```

```sql
-- PostgreSQL row-level security
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_documents ON documents
    USING (owner_id = current_setting('app.current_user_id')::int);
```

---

## Secrets Management

### Rules (zero exceptions)
- NEVER hardcode secrets in source code, configs, or Docker images
- NEVER log secrets (mask in structured logging)
- NEVER pass secrets in URLs or query parameters
- NEVER commit .env files (gitignore + pre-commit hook)

### Patterns
```python
# Retrieve from vault at runtime
import os
DATABASE_URL = os.environ["DATABASE_URL"]  # injected by orchestrator

# For GCP: Secret Manager
from google.cloud import secretmanager
client = secretmanager.SecretManagerServiceClient()
secret = client.access_secret_version(name="projects/P/secrets/S/versions/latest")

# For local dev: .env file (gitignored) loaded by pydantic-settings
# For CI/CD: injected as environment variables from vault
```

### Rotation
- Rotate credentials on a schedule (90 days max for static creds)
- Rotate immediately on: employee departure, suspected compromise, dependency breach
- Use short-lived credentials where possible (GCP workload identity, OIDC tokens)

---

## Dependency Security

```bash
# Before adding ANY dependency:
# 1. Check maintenance status (last commit, open issues, bus factor)
# 2. Audit for known CVEs
pip-audit                    # Python
npm audit                    # Node.js
trivy fs .                   # Multi-language

# 3. Pin exact versions in lockfiles
pip install package==1.2.3   # not package>=1.2.3
npm install --save-exact     # not ^1.2.3

# 4. Verify checksums
pip install --require-hashes -r requirements.txt

# 5. Monitor continuously
# Dependabot / Renovate + GitHub security alerts
```

### Supply Chain Rules
- Prefer well-known packages with active maintainers
- Verify package names carefully (typosquatting is real)
- Review transitive dependencies, not just direct ones
- Sign commits; verify signatures on critical dependencies

---

## Container Security

```dockerfile
# Non-root user
FROM python:3.12-slim AS runtime
RUN groupadd -r app && useradd -r -g app -s /sbin/nologin app
USER app

# Read-only filesystem where possible
# Minimal base image (slim/distroless, not full OS)
# No secrets in build layers
# Multi-stage builds to exclude build tools from runtime
```

```yaml
# docker-compose hardening
services:
  app:
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=64m
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add: []  # add only what you need
    mem_limit: 512m
    cpus: 1.0
    pids_limit: 100
    user: "1000:1000"
```

---

## Network Security

### TLS Everywhere
- All connections use TLS 1.2+ (prefer 1.3)
- Internal service-to-service communication: mTLS where possible
- Certificate pinning for critical external APIs

### Headers (apply to every HTTP response)
```python
# FastAPI security headers middleware
@app.middleware("http")
async def security_headers(request, call_next):
    response = await call_next(request)
    response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload"
    response.headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self'"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    return response
```

### CORS
```python
# Strict CORS — never use allow_origins=["*"] in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://app.yourdomain.com"],  # explicit allowlist
    allow_methods=["GET", "POST"],  # only what is needed
    allow_headers=["Authorization", "Content-Type"],
    allow_credentials=True,
    max_age=3600,
)
```

---

## Data Security

### Classification
| Level | Examples | Controls |
|-------|----------|----------|
| **PUBLIC** | Marketing content, docs | No special controls |
| **INTERNAL** | Business metrics, logs | Auth required, no external sharing |
| **CONFIDENTIAL** | PII, health data, financials | Encrypted at rest + in transit, access logged, retention policy |
| **RESTRICTED** | Auth credentials, encryption keys | Vault-only, never logged, minimal access, auto-rotate |

### Encryption
- At rest: AES-256 (database, file storage, backups)
- In transit: TLS 1.3 (all connections)
- Application-level: encrypt PII fields before database storage where regulations require
- Backups: encrypted with separate key from primary data

### PII Handling
- Minimize collection (only what is needed)
- Mask in logs (email: `a***@example.com`, phone: `***-***-1234`)
- Retention policy: delete when no longer needed
- Right to deletion: architecture must support it

---

## Logging and Audit

### What to Log
- Authentication events (login, logout, failed attempts, MFA)
- Authorization failures (access denied)
- Data access patterns (who accessed what, when)
- Configuration changes
- Error events (without sensitive details)

### What to NEVER Log
- Passwords, tokens, API keys, session IDs
- Full credit card numbers, SSNs
- Request/response bodies containing PII (mask first)
- Stack traces in production logs (send to error tracker, not stdout)

```python
# Structured logging with secret masking
import structlog

logger = structlog.get_logger()

# WRONG
logger.info("User login", password=password, token=token)

# RIGHT
logger.info("user_authenticated", user_id=user.id, ip=request.client.host)
```

---

## Anti-Patterns (reject these on sight)

| Anti-Pattern | Why It Is Dangerous | Secure Alternative |
|---|---|---|
| `eval()` / `exec()` on user input | Remote code execution | Structured parsers, allowlisted operations |
| `shell=True` in subprocess | Command injection | `subprocess.run(["cmd", "arg"], shell=False)` |
| `SELECT * FROM x WHERE id = {id}` | SQL injection | Parameterized queries, ORM |
| `allow_origins=["*"]` | CORS bypass | Explicit origin allowlist |
| `chmod 777` | World-writable files | `chmod 640` or more restrictive |
| `docker run --privileged` | Container escape | Drop all caps, add only needed |
| Catching exceptions silently | Masks security failures | Log, alert, fail secure |
| `DEBUG=True` in production | Info disclosure | Environment-based config, default False |
| Secrets in git history | Credential exposure | Vault + pre-commit hooks |
| `verify=False` on HTTP requests | TLS bypass, MITM | Fix the certificate chain |

---

## Synergy with Adjacent Skills

| When This Skill Detects... | It Escalates To... |
|---|---|
| Complex auth/authz architecture needed | `app-security-architect` for deep OWASP review |
| New system or major feature | `security-threat-model` for structured threat analysis |
| Multiple threat categories in play | `stride-analysis-patterns` for systematic enumeration |
| Pre-ship security gate | `cso` for formal security audit |
| Suspicious code patterns in review | `code-review` with security flag elevated |

This skill handles the 80% — secure defaults, validation, hardening on every line.
The adjacent skills handle the 20% — deep analysis, formal modeling, audit gates.

---

## Self-Evaluation (run silently before every code output)

Before presenting any code, config, or architecture suggestion:
[ ] Every input boundary has typed validation
[ ] No hardcoded secrets — all credentials from vault/env
[ ] Error handling does not leak internals
[ ] Auth and authz are present where required
[ ] Defaults are secure (deny-all, minimal access, debug off)
[ ] Dependencies are pinned and from trusted sources
[ ] Containers run as non-root with dropped capabilities
[ ] Logging captures audit events, never secrets
[ ] The attacker question has been asked: "What could go wrong?"
If any check fails: fix it in the code. Do not output it with a TODO.
