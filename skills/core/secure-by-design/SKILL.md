---
name: secure-by-design
description: |
  Always-on security immune system. Embeds secure defaults into every code suggestion,
  config snippet, and architecture decision BEFORE output. Not an audit tool — a pre-output
  filter that prevents insecure code from being generated.

  AUTO-TRIGGER: silently on every response containing code, config, Dockerfile, SQL,
  infrastructure-as-code, or architecture decisions.
  DOES NOT TRIGGER on: pure business/strategy, conversational, content creation,
  or planning responses with no code artifacts.

  EXPLICIT TRIGGER: "secure by design", "harden this", "what could go wrong",
  "attack surface", "secure defaults".

  BOUNDARY: This is the lightweight always-on layer (the 80%). For deep analysis,
  escalate to app-security-architect | cso | security-threat-model.
metadata:
  author: aaron-deyoung
  version: "2.0"
  domain-category: core
  adjacent-skills: app-security-architect, security-threat-model, stride-analysis-patterns, cso, code-review
  last-reviewed: "2026-04-10"
  review-trigger: "New OWASP release, major CVE, new attack class"
  capability-assumptions:
    - "No external tools — mental discipline layer"
    - "All languages and frameworks"
  fallback-patterns:
    - "Uncertain about a pattern → flag it, recommend app-security-architect"
  degradation-mode: "strict"
---

## Composability Contract
- **Role:** Silent pre-output filter on every code-producing response
- **Input:** Any code, config, or architecture about to be output
- **Output:** Same artifact with secure defaults, validation, and hardening applied
- **Escalates to:** app-security-architect (deep OWASP), cso (formal audit), security-threat-model (structured analysis)
- **Does NOT duplicate:** Detailed auth flows, STRIDE enumeration, dependency audit tooling, container hardening checklists — those live in adjacent skills

---

## Security Mental Checklist (run silently before outputting code)

```
[ ] INPUT    — Every external input: validated, typed, bounded, sanitized?
[ ] AUTH     — Authentication enforced where required?
[ ] AUTHZ    — Authorization checked at the right layer?
[ ] SECRETS  — Zero hardcoded secrets/keys/tokens? All from vault/env?
[ ] ERRORS   — Error responses leak nothing internal? (no stack traces, paths, SQL)
[ ] LOGGING  — Audit events captured, secrets/PII never logged?
[ ] DEFAULTS — Secure defaults? (deny-all CORS, debug off, restrictive permissions)
[ ] ATTACKER — "What would an attacker do with this?" (injection, escalation, exfil)
```

If ANY check fails: fix it in the code. Never output insecure code with a TODO.

---

## Secure Defaults (apply automatically)

| Domain | Default | Never |
|--------|---------|-------|
| Endpoints | Require auth unless explicitly marked public | Open by default |
| CORS | Deny-all, explicit origin allowlist | `allow_origins=["*"]` in production |
| Cookies | `HttpOnly`, `Secure`, `SameSite=Strict` | Missing flags |
| CSP | `default-src 'self'` | No CSP header |
| File permissions | 600/640 | 777 |
| Containers | Non-root, `cap_drop: ALL`, read-only rootfs | `--privileged`, root user |
| Debug mode | OFF in production | `DEBUG=True` deployed |
| Dependencies | Pinned exact versions | Unpinned ranges |
| TLS | 1.2+ required (prefer 1.3) | Plaintext internal traffic |
| Tokens | Short-lived (15min access, 7d refresh) | Long-lived static tokens |

---

## Input Validation Rules

Validate at EVERY boundary: user input, API responses, file uploads, env vars, message queues, URL path segments.

```python
# WRONG — trusts user input, SQL injection
user_id = request.query_params["user_id"]
query = f"SELECT * FROM users WHERE id = {user_id}"

# RIGHT — typed, bounded, parameterized
from pydantic import BaseModel, conint

class UserRequest(BaseModel):
    user_id: conint(gt=0, lt=2_147_483_647)

validated = UserRequest(**request.query_params)
result = await db.execute(
    text("SELECT * FROM users WHERE id = :id"),
    {"id": validated.user_id}
)
```

Key rules:
- Use parameterized queries for ALL database access — no string interpolation
- Validate file uploads: type allowlist, size limit, magic byte verification
- Validate env vars at startup with typed config (fail fast, not fail late)
- Filter query results server-side — never trust the client to filter (row-level security)

---

## Secrets Rules (zero exceptions)

- NEVER hardcode secrets in source, configs, Dockerfiles, or git history
- NEVER log secrets (mask in structured logging)
- NEVER pass secrets in URLs or query parameters
- NEVER commit .env files — gitignore + pre-commit hook
- Retrieve at runtime from vault/env, use short-lived credentials where possible
- Rotate on schedule (90d max) and immediately on compromise/departure

---

## Error Handling

- Return generic messages to users — never "user not found" vs "wrong password"
- Log detailed errors server-side to error tracker, not to response body
- Default-deny on authz errors: if the check throws, access is denied
- Catch blocks must log and alert — never swallow silently

---

## Anti-Patterns (reject on sight)

| Pattern | Fix |
|---------|-----|
| `eval()`/`exec()` on user input | Structured parsers, operation allowlist |
| `shell=True` in subprocess | `subprocess.run(["cmd", "arg"], shell=False)` |
| SQL string interpolation | Parameterized queries / ORM |
| `verify=False` on HTTP requests | Fix the certificate chain |
| Catching exceptions silently | Log, alert, fail secure |
| Secrets in git history | Vault + pre-commit hooks + `git-secrets` |

---

## Escalation Rules

| Signal | Route To |
|--------|----------|
| Complex auth/authz architecture | `app-security-architect` |
| New system or major feature | `security-threat-model` |
| Multiple threat categories | `stride-analysis-patterns` |
| Pre-ship security gate | `cso` |
| Suspicious code in review | `code-review` with security flag |

---

## Self-Evaluation (silent, before every code output)

- [ ] Every input boundary has typed validation
- [ ] Zero hardcoded secrets
- [ ] Error handling leaks nothing internal
- [ ] Auth/authz present where required
- [ ] Defaults are secure (deny-all, minimal access, debug off)
- [ ] Attacker question asked: "What could go wrong?"

If any check fails: fix it. Do not output with a TODO.
