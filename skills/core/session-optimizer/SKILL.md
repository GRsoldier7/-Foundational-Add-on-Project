---
name: session-optimizer
description: |
  Session architecture and context window management. Activates at session start for
  complex projects and when context approaches 40%.

  EXPLICIT TRIGGER: "optimize session", "context management", "compact", "session strategy",
  "long session", "running out of context", "token usage", "hooks", "permissions",
  "session architecture", "power user", "worktree", "multi-session", "handoff".

  Also trigger when work will clearly exceed one context window or user seems frustrated.
metadata:
  author: aaron-deyoung
  version: "1.1"
  domain-category: core
  adjacent-skills: parallel-execution-strategist, anti-hallucination, context-guardian, efficiency-engine
  last-reviewed: "2026-04-10"
  review-trigger: "New Claude Code features, context window changes"
  capability-assumptions:
    - "Claude Code CLI with standard tool suite"
    - "Settings, CLAUDE.md, and hook system"
  fallback-patterns:
    - "Not Claude Code: general LLM session management principles"
    - "No hook access: prompt and workflow patterns only"
  degradation-mode: "graceful"
---

## Composability Contract

- Input: session planning, efficiency concern, or context management need
- Output: session architecture, settings config, or workflow optimization
- Chains into: parallel-execution-strategist (parallel work within session)
- At 60%+: **defers to context-guardian** for all compaction and verification decisions

---

## Session Patterns

| Pattern | Use Case | Key Rule |
| ------- | -------- | -------- |
| **A: Single-Focus** | Bug fix, feature, review | Compact at ~50%. One context window. |
| **B: Multi-Phase** | Design + implement + test | Phase gates. Compact between phases. Track with tasks. |
| **C: Multi-Session** | Large feature, migration | Persist ALL decisions to files. Write handoff doc at session end. |
| **D: Exploration** | Bug investigation, research | Start broad, compact when direction emerges, switch to A/B. |

---

## Context Budget

| Fill | Status | Action |
| ---- | ------ | ------ |
| 0-30% | Green | Full speed |
| 30-50% | Yellow | Selective file reads, use line ranges |
| 50-70% | Orange | Compact proactively, save state to files |
| 70-85% | Red | Compact or new session with handoff |
| 85%+ | Critical | Finish current task, write handoff, new session |

At 60%+, context-guardian takes over with AMBER/RED protocols. This skill defers.

### Reading Efficiently

- Grep before Read -- find line numbers first, read only what you need
- Use `limit`/`offset` on Read -- never read 2000 lines for one function
- Don't re-read files already in context
- Use Agent for broad searches (separate context)
- Glob for structure, not directory reads

### Writing Efficiently

- Edit over Write (sends only diff)
- Batch related changes to same file
- Reference by path+line, don't echo large content

---

## Compaction Strategy

**Preserve:** task state, key decisions + reasoning, modified file paths, errors + solutions, user preferences, uncommitted work status.

**Drop:** full file contents on disk, dead-end explorations, verbose tool outputs, repeated patterns.

**Before compacting:** save in-progress work to files, update task list, note any context only in conversation, write state to CLAUDE.md or temp file if mid-implementation.

---

## CLAUDE.md as Session Memory

**Belongs:** architecture decisions, coding conventions, build/test/deploy commands, gotchas, key file paths.

**Does not belong:** temporary state, full docs (use docs/), personal prefs (use ~/.claude), anything >200 lines.

Update actively when you learn something a future session needs.

---

## Hook Patterns

### Auto-Format After Writes

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "jq -r '.tool_response.filePath // .tool_input.file_path' | { read -r f; prettier --write \"$f\"; } 2>/dev/null || true"
    }]
  }]
}
```

### Pre-Compaction Context Saver

```json
{
  "PreCompact": [{
    "hooks": [{
      "type": "command",
      "command": "echo '{\"systemMessage\": \"Remember to save any in-progress state to files before compaction.\"}'"
    }]
  }]
}
```

---

## Permission Optimization

**Safe to auto-allow:** `git:*`, `npm:*`, `pip:*`, `pytest:*`, `wc:*`, `mkdir:*`

**Keep gated:** `rm -rf`, `git push --force`, `git reset --hard`, deployment commands, production DB access, file deletions outside project.

Project-wide: `.claude/settings.json` (committed). Personal: `.claude/settings.local.json` (gitignored).

---

## Anti-Patterns

| Anti-Pattern | Fix |
| ------------ | --- |
| Reading entire large files "just to check" | Grep first, read specific lines |
| Re-reading files already in context | Reference what you know |
| "Explore the codebase" without direction | Give specific search targets |
| Not compacting until context limit | Proactively compact at 50-60% |
| Over-specifying trivial tasks | Match prompt length to task complexity |
| Starting cold on multi-day projects | Read CLAUDE.md and handoff doc first |

---

## Self-Evaluation (before complex sessions)

- [ ] Clear session goal, or exploration?
- [ ] Right permissions for this project?
- [ ] CLAUDE.md current?
- [ ] Need multi-session planning?
- [ ] Tasks to parallelize with background agents?
- [ ] Right session pattern (A/B/C/D)?
