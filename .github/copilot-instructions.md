# Foundation AddOn Copilot Instructions

## Project Type

Portable AI instruction and skill addon repository.

## Expectations

- Keep edits aligned across `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, and templates.
- Prefer modifying source skill files in `skills/` and regenerate dependent mirrors.
- Preserve update-safe custom sections in templates.

## Safety

- Never read or print secret files.
- Avoid destructive operations unless explicitly requested.

## Verification

Run before finalizing:
- `python3 scripts/validate-foundation.py`
- `bash scripts/test-init-project.sh`
