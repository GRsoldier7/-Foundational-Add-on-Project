# Project Profile: Foundation AddOn Project

## Snapshot

- Project: `Foundation AddOn Project`
- Primary stack: `shell + markdown + python validation`
- Role: portable AI instruction/skill addon

## Mission

Maintain a production-grade, cross-platform AI addon that can be dropped into any workspace and
immediately provide reliable instructions, safe defaults, and repeatable workflows.

## Scope Boundaries

- In scope: portable instructions, skill catalog curation, sync scripts, template generation.
- Out of scope: host-specific machine controls or secrets management data.

## Architecture Decisions

- Keep platform-specific instruction files in templates and generate via `scripts/init-project.sh`.
- Keep skills as source of truth under `skills/`; generated command mirrors are derived artifacts.
- Preserve user custom blocks on update using `<!-- CUSTOM:START ... -->` markers.

## Operational Preferences

- Validation: `python3 scripts/validate-foundation.py`
- Smoke test: `bash scripts/test-init-project.sh`
- Shell lint: `shellcheck scripts/*.sh`

## Active Risks

- Instruction drift between root docs and templates.
- Skill growth causing context overload in master files.
- Incomplete cross-platform parity when adding new tools.

## Hardening Plan — April 2026

**Decision date:** 2026-04-19
**Status:** Track 1 in progress (Track 2 gated)

### Two-Track Architecture

**Track 1 (Active):** Harden main
- Fix command mirror drift enforcement (CI-enforced, not manual)
- Add .github/workflows/validate.yml with three status checks: validate-foundation, test-init-project, shellcheck
- Add full public-repo governance: MIT LICENSE, SECURITY.md, CONTRIBUTING.md, CODEOWNERS, PR/issue templates
- Expand smoke test coverage: Go, Rust, --dry-run, platform subsets, --update preservation
- Reconcile MCP scaffolding claims: split auto-scaffold (4 servers) vs manual-config (3 servers requiring path setup)
- Enable branch protection on main: required checks, linear history, no force-push, squash-merge default
- NotebookLM bootstrap: install ~/.claude/nlm-notebook-ids.env, wire working-memory notebook

**Track 2 (Gated):** LLM-Agnostic PR (#1)
- Do NOT merge directly; refresh onto hardened main first
- Gate review criteria: Bun/TS tests pass, canonical-core metadata represents existing skills without behavioral loss, downstream portability measurably improves

### Active Risks (April 2026)
- PR #1 is 24 commits ahead and 9 behind main — needs rebase onto hardened main before gate review
- NotebookLM bootstrap not yet installed; local .ai-memory is source of truth until verified
- Branch protection not yet active — any direct-to-main pushes possible until GitHub settings applied

### Source of Truth Hierarchy
1. `skills/` — canonical skill source (never modify .claude/commands/ by hand)
2. `.ai-memory/project-profile.md` — local durable context
3. NotebookLM working-memory notebook — mirrored backup (once bootstrap verified)
