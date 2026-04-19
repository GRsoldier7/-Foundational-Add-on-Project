# Security Policy

## Supported Versions

Only the latest commit on `main` is supported. No backports or patches are
provided for older commits or tagged releases.

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report security issues by emailing:

**Claude@aarondy3777.33mail.com**

Include as much detail as possible:

- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- Any suggested mitigations (optional)

## Response Timeline

| Milestone | Target |
|-----------|--------|
| Acknowledgement | Within 7 days of receipt |
| Fix or mitigation provided | Within 30 days of acknowledgement |

If a vulnerability cannot be resolved within 30 days, an interim mitigation or
workaround will be communicated before the deadline.

## Scope

This project is a portable AI workspace addon (skills, command mirrors, init
scripts). The primary attack surface is script execution and file writes
performed by `scripts/*.sh` and `scripts/*.py`. File path traversal, arbitrary
command injection in generated configs, and credential leakage are the most
relevant risk categories.

## Out of Scope

- Theoretical issues with no practical exploit path
- Issues in third-party tools (shellcheck, Python, etc.) rather than this project
