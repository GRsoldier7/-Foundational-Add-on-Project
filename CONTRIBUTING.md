# Contributing

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/GRsoldier7/-Foundational-Add-on-Project.git
   cd -Foundational-Add-on-Project
   ```

2. Install [shellcheck](https://github.com/koalaman/shellcheck#installing):
   ```bash
   # macOS
   brew install shellcheck
   # Ubuntu/Debian
   sudo apt-get install shellcheck
   ```

3. Verify the baseline passes before making any changes:
   ```bash
   python3 scripts/validate-foundation.py
   bash scripts/test-init-project.sh
   shellcheck scripts/*.sh
   ```

All three commands must exit cleanly before you start work.

## Making Changes

- Always branch from `main`:
  ```bash
  git checkout main && git pull
  git checkout -b feat/my-change
  ```
- Use [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages:
  - `feat:` — new skill, command, or capability
  - `fix:` — bug fix
  - `ci:` — CI/CD workflow changes
  - `chore:` — maintenance, dependency updates
  - `docs:` — documentation only
- **Never commit directly to `main`.**

## PR Checklist

Before opening a pull request, confirm:

- [ ] `python3 scripts/validate-foundation.py` passes
- [ ] `bash scripts/test-init-project.sh` passes
- [ ] `shellcheck scripts/*.sh` passes
- [ ] If you edited a skill, command mirrors were regenerated:
      `bash scripts/sync-claude-commands.sh`
- [ ] No files under `.claude/commands/` were modified by hand
- [ ] Docs updated if behavior changed

All three CI checks must pass for a PR to be merged.

## Skill Authorship

- Skills live in `skills/` — this is the source of truth.
- Command mirrors in `.claude/commands/` are **auto-generated**. Do not edit them
  directly; they will be overwritten.
- After editing or adding a skill, regenerate mirrors:
  ```bash
  bash scripts/sync-claude-commands.sh
  ```
- Template files in `templates/` are exercised by `scripts/test-init-project.sh`.
  Update tests if you add a new template.

## Code of Conduct

Be respectful and constructive. Critique ideas, not people. Harassment or
dismissive behavior of any kind is not welcome.
