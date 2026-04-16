---
name: project-sync
description: |
  Auto-update cross-platform AI configs (AGENTS.md, opencode.json, settings.json) from the
  Foundation AddOn source of truth. Detects stale sync, shows a diff summary, regenerates
  configs while preserving user-customized sections, and updates the sync manifest. Use when
  starting work on a project that hasn't been synced recently, or after the Foundation AddOn
  gains new skills/permissions.
metadata:
  author: aaron-deyoung
  version: "1.0"
  domain-category: core
  adjacent-skills: portable-ai-instructions, adaptive-skill-orchestrator
  last-reviewed: "2026-04-16"
  review-trigger: "New platforms added, AGENTS.md spec changes, init-project.sh changes"
  capability-assumptions:
    - "Bash tool available for running init-project.sh"
    - "Foundation AddOn accessible at path stored in .foundation-sync.json"
  fallback-patterns:
    - "If .foundation-sync.json missing: treat as first-time init, run init-project.sh"
    - "If Foundation AddOn path unreachable: warn user, provide manual steps"
  degradation-mode: "graceful"
---

# Project Sync

Keep your project's cross-platform AI configs in sync with the Foundation AddOn.

## When to Use

- Starting a session on a project you haven't touched in a while
- After pulling new changes to the Foundation AddOn
- When you notice skills or permissions are missing
- Automatically: the session-start hook warns if sync is >30 days stale

## How It Works

```
.foundation-sync.json (in your project)
    ├── foundation_addon.commit  →  compare with current HEAD
    ├── foundation_addon.path    →  locate the Foundation AddOn
    ├── generated_files          →  checksums of last-generated files
    └── custom_sections_preserved → marker for safe update
```

## Process

### Step 1: Check Sync Status

Read `.foundation-sync.json` from the current project root. If it doesn't exist, this is a first-time setup — run `init-project.sh` instead.

```bash
cat .foundation-sync.json
```

Compare the stored `foundation_addon.commit` with the Foundation AddOn's current HEAD:

```bash
git -C "<foundation-path>" rev-parse --short HEAD
```

If they match, the project is up to date. Report this and stop.

### Step 2: Identify Changes

If the hashes differ, show what changed in the Foundation AddOn since last sync:

```bash
git -C "<foundation-path>" log --oneline <stored-hash>..HEAD
```

Summarize for the user: new skills added, permissions updated, templates changed.

### Step 3: Preview the Update

Run init-project.sh in dry-run mode to show what would change:

```bash
bash "<foundation-path>/scripts/init-project.sh" --update --dry-run .
```

Present the preview to the user. Ask for confirmation before proceeding.

### Step 4: Apply the Update

Run init-project.sh in update mode:

```bash
bash "<foundation-path>/scripts/init-project.sh" --update .
```

This regenerates AGENTS.md, opencode.json, and .claude/settings.json while preserving
any sections the user has customized (wrapped in `<!-- CUSTOM:START -->` / `<!-- CUSTOM:END -->`
markers).

### Step 5: Verify

Read the updated `.foundation-sync.json` to confirm the new commit hash is stored.
Spot-check one generated file to confirm it reflects current Foundation AddOn content.

### Step 6: Optionally Commit

Ask the user if they want to commit the updated configs:

```bash
git add AGENTS.md opencode.json .claude/settings.json .foundation-sync.json
git commit -m "chore: sync cross-platform configs from Foundation AddOn (<new-hash>)"
```

## Cross-Platform Usage

**In Claude Code:** Invoke as `/project-sync`. The skill runs the full process above.

**In Codex / Opencode:** Run the init script directly from your terminal:
```bash
bash "/path/to/Foundation_AddOn_Project/scripts/init-project.sh" --update .
```

## Stale Detection

The Foundation AddOn can optionally check sync age on session start via a hook.
If `.foundation-sync.json` exists and `last_sync` is >30 days old, it prints:

> "Foundation AddOn sync is X days stale. Run /project-sync to update."

This is advisory, not blocking.
