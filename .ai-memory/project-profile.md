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
