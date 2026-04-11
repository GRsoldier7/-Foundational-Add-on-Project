---
name: notebooklm
description: |
  Complete programmatic access to Google NotebookLM via the notebooklm-py CLI.
  Creates notebooks, adds sources (URLs, YouTube, PDFs, audio, video, images), generates
  all artifact types (podcast, video, quiz, flashcards, slide deck, infographic, mind map,
  report), downloads results, and supports web research and chat.

  EXPLICIT TRIGGER on: "/notebooklm", "create a podcast about", "audio overview", "generate
  a quiz from", "summarize these URLs", "NotebookLM", "add to notebooklm", "flashcards for
  studying", "turn this into a podcast", "create flashcards", "generate a slide deck",
  "make an infographic", "create a mind map", "install notebooklm", "add notebooklm to cowork",
  "briefing doc", "study guide from", "deep dive podcast".

  Also activates on: "create a podcast about X", "I want to study this material", "can you
  summarize these documents into something I can listen to", "make this into audio content".
compatibility: Requires notebooklm-py CLI installed; Google account authenticated; Python 3.10+
metadata:
  author: aaron-deyoung
  version: "2.1"
  domain-category: core
  adjacent-skills: wrapup, knowledge-management, obsidian-automation-architect
  last-reviewed: "2026-04-04"
  review-trigger: "notebooklm-py version bump, Google NotebookLM UI changes that break auth, new artifact type added"
allowed-tools: Bash
---

## Composability Contract
- Input expects: topic, URLs, files, or research query to process
- Output produces: notebooks, sources, generated artifacts (audio, quiz, slides, etc.)
- Hands off to: wrapup (session summaries), knowledge-management (vault organization)
- Receives from: any skill needing to transform content into audio/visual/study material

---

## Core Principles

1. **Auth is fragile** — Google cookies expire 7-30 days. Always `notebooklm auth check` first.
2. **Context required** — Every command except `list`/`create` needs `notebooklm use <id>`.
3. **Sources must be READY** — Wait with `source wait <id>` before generating.
4. **Generation is async** — Audio 10-20 min, video 15-45 min. Use `artifact wait`.
5. **No parallel generation** — Google rate-limits per notebook. Sequential only.
6. **Linux path** — activate venv: `source ~/.notebooklm-venv/bin/activate`

---

## Environment Setup

### First-Time Install
```bash
python3 -m venv ~/.notebooklm-venv
source ~/.notebooklm-venv/bin/activate
pip install "notebooklm-py[browser]" && playwright install chromium
```

### Authentication — IMPORTANT: Playwright is BROKEN on macOS

Google blocks sign-in from Playwright-controlled browsers ("Couldn't sign you in — This browser or app may not be secure"). **Do NOT use the Playwright nlm_login.py approach.** Use `browser_cookie3` instead, which reads from the existing Chrome session via macOS Keychain.

**Install once:**
```bash
~/.notebooklm-venv/bin/pip install browser_cookie3
```

**Re-auth script** (run whenever `notebooklm auth check` fails — cookies expire 7-30 days):
```python
# scripts/notebooklm-auth.py — reads Chrome cookies via macOS Keychain
import json
from pathlib import Path

try:
    import browser_cookie3
except ImportError:
    print("Run: ~/.notebooklm-venv/bin/pip install browser_cookie3")
    raise

STORAGE_FILE = Path.home() / ".notebooklm" / "storage_state.json"
STORAGE_FILE.parent.mkdir(exist_ok=True)

print("Reading Chrome cookies (may prompt for Keychain access)...")
jar = browser_cookie3.chrome(domain_name=".google.com")

cookies = []
for c in jar:
    cookies.append({
        "name": c.name, "value": c.value, "domain": c.domain,
        "path": c.path if c.path else "/",
        "expires": int(c.expires) if c.expires else -1,
        "httpOnly": bool(c.has_nonstandard_attr("HttpOnly")),
        "secure": bool(c.secure), "sameSite": "Lax",
    })

google_cookies = [c for c in cookies if "google" in c["domain"]]
sid = [c for c in google_cookies if c["name"] == "SID"]
print(f"Google cookies: {len(google_cookies)}, SID: {len(sid)}")

STORAGE_FILE.write_text(json.dumps({"cookies": google_cookies, "origins": []}, indent=2))
print(f"Saved to {STORAGE_FILE}")
```

**Run with venv Python:**
```bash
source ~/.notebooklm-venv/bin/activate
~/.notebooklm-venv/bin/python3 scripts/notebooklm-auth.py
notebooklm auth check   # should show SID cookie ✓
```

**Requirements:** Chrome must have Google signed in. Script saved at `scripts/notebooklm-auth.py` in ObsidianHomeOrchestrator repo.

**NEVER** use `notebooklm login` directly — requires interactive terminal. **NEVER** use the old Playwright script — Google blocks it.

---

## Decision Framework

| Goal | Command |
|------|---------|
| Check auth | `notebooklm auth check` |
| List notebooks | `notebooklm list` |
| Create notebook | `notebooklm create "Title"` |
| Set context | `notebooklm use <id>` |
| Add URL source | `notebooklm source add "https://..."` |
| Add file source | `notebooklm source add ./file.pdf` |
| Add inline text | `notebooklm source add "text content" --type text --title "Name"` |
| Research topic | `notebooklm source add-research "query" --mode deep --no-wait` |
| Chat with sources | `notebooklm ask "question"` |
| Generate podcast | `notebooklm generate audio "instructions"` |
| Generate quiz | `notebooklm generate quiz --difficulty medium` |
| Generate slides | `notebooklm generate slide-deck --format detailed` |
| Download artifact | `notebooklm download audio ./out.mp3` |

---

## Standard Workflows

### Session Wrapup to AI Brain (primary use case)
```bash
source ~/.notebooklm-venv/bin/activate
notebooklm auth check
notebooklm use <brain_notebook_id>
notebooklm source add "/tmp/session-summary-YYYY-MM-DD.md"
```

### Research-to-Podcast
```bash
notebooklm auth check
notebooklm create "Research: [topic]"
notebooklm use <id>
notebooklm source add "https://..."
notebooklm source wait <source_id>
notebooklm generate audio "Focus on key decisions"
notebooklm artifact wait <artifact_id>
notebooklm download audio ./podcast.mp3
```

---

## Edge Cases

| Case | Symptom | Fix |
|------|---------|-----|
| Auth expired | SID cookie missing | Re-run `scripts/notebooklm-auth.py` (browser_cookie3 method) |
| Source stuck PROCESSING | >10 min | Delete and re-add; DRM PDFs fail silently |
| Generation 429 | Rate limit error | Wait 10-20 min; never retry within 2 min |
| CLI not found | `command not found` | `source ~/.notebooklm-venv/bin/activate` |

---

## Anti-Patterns

1. **Using the Playwright login script** — Google blocks it on macOS with "This browser may not be secure". Use `browser_cookie3` / `scripts/notebooklm-auth.py` instead.
2. **Running `notebooklm login` directly** — requires interactive terminal input unavailable in Claude Code.
3. **Generating before sources are READY** — silently produces incomplete output.
4. **Parallel generations** — both fail with 429. Always sequential.
5. **Asking user to run commands** — skill should be fully automated. User only needs Chrome signed in to Google.

---

## Quality Gates

- [ ] `notebooklm auth check` passes with SID cookie before any workflow
- [ ] Notebook context set before source/generate commands
- [ ] All sources confirmed READY before generating
- [ ] Artifact confirmed COMPLETED before downloading
- [ ] Auth flow was fully automated — user only signed in to Google
