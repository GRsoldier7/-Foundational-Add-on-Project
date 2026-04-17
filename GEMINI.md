# Foundation AddOn Project

## Project Intent

This repository provides portable AI workflow infrastructure:
- skill library under `skills/`
- platform templates under `templates/`
- initialization and sync scripts under `scripts/`

## Execution Standard

1. Confirm requirements with repo evidence before editing.
2. Make the smallest correct change and keep boundaries clean.
3. Run validation commands before claiming success.
4. Update docs/templates when behavior changes.
5. Do not touch secrets or run destructive operations without explicit approval.

## File Map

- `CLAUDE.md` — concise Claude-specific rules for this repo.
- `AGENTS.md` — Codex/OpenAI baseline operating instructions.
- `.claude/commands/` — generated mirrors from `skills/`.
- `.ai-memory/project-profile.md` — durable context for future sessions.
- `scripts/init-project.sh` — main bootstrap generator.

## Required Verification

- `python3 scripts/validate-foundation.py`
- `bash scripts/test-init-project.sh`
- `shellcheck scripts/*.sh`

If only a subset of files changed, run targeted checks first and still run full validation
before completion unless blocked by environment constraints.

## Safety Rules

- No secret reads from `.env`, `*token*`, `*password*`, private key files.
- No force pushes or history rewrites.
- No destructive shell commands outside explicit user request.

## Preferred Workflow

1. Audit current state (`git status`, targeted file reads).
2. Patch files with explicit, minimal diffs.
3. Re-run checks.
4. Summarize: what changed, why, and verification evidence.
