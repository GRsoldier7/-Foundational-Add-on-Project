#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GENERIC="$TMPDIR/generic"
NODE="$TMPDIR/node"
PYTHON="$TMPDIR/python"
EDGE="$TMPDIR/edge \"project\" name"

mkdir -p "$GENERIC" "$NODE" "$PYTHON" "$EDGE"

cat > "$NODE/package.json" <<'JSON'
{
  "name": "foundation-smoke-node",
  "private": true
}
JSON

cat > "$PYTHON/pyproject.toml" <<'TOML'
[project]
name = "foundation-smoke-python"
version = "0.1.0"
TOML

for target in "$GENERIC" "$NODE" "$PYTHON"; do
    bash "$ROOT/scripts/init-project.sh" --no-mcp "$target" >/dev/null
done

bash "$ROOT/scripts/init-project.sh" --no-mcp "$EDGE" >/dev/null

python3 - <<'PY' "$GENERIC" "$NODE" "$PYTHON"
import json
import pathlib
import sys

for raw in sys.argv[1:]:
    target = pathlib.Path(raw)
    required = [
        target / "AGENTS.md",
        target / "GEMINI.md",
        target / "opencode.json",
        target / ".claude" / "settings.json",
        target / ".ai-memory" / "project-profile.md",
        target / ".foundation-sync.json",
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit(f"Missing generated files for {target}: {missing}")

    json.load(open(target / "opencode.json"))
    json.load(open(target / ".claude" / "settings.json"))
    json.load(open(target / ".foundation-sync.json"))

    settings = (target / ".claude" / "settings.json").read_text()
    if "@anthropic-ai/mcp-server-playwright" in settings:
        raise SystemExit(f"Legacy Playwright package leaked into {target}")
PY

python3 - <<'PY' "$GENERIC/AGENTS.md"
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
needle = "Describe your project here. This section is preserved across updates."
replacement = "Foundation smoke test custom overview."
if needle not in text:
    raise SystemExit("Expected custom section marker not found in AGENTS.md")
path.write_text(text.replace(needle, replacement, 1))
PY

python3 - <<'PY' "$GENERIC/.ai-memory/project-profile.md"
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
needle = "Define the core purpose and expected business/user outcome in 2-3 sentences."
replacement = "Foundation smoke test mission statement."
if needle not in text:
    raise SystemExit("Expected custom section marker not found in project-profile.md")
path.write_text(text.replace(needle, replacement, 1))
PY

bash "$ROOT/scripts/init-project.sh" --update --no-mcp "$GENERIC" >/dev/null
grep -q "Foundation smoke test custom overview." "$GENERIC/AGENTS.md"
grep -q "Foundation smoke test mission statement." "$GENERIC/.ai-memory/project-profile.md"

python3 - <<'PY' "$EDGE/.foundation-sync.json" "$EDGE/$(basename "$EDGE").code-workspace"
import json
import pathlib
import sys

for raw in sys.argv[1:]:
    path = pathlib.Path(raw)
    json.loads(path.read_text())
PY

if bash "$ROOT/scripts/init-project.sh" --no-mcp --platform "claude,invalid" "$GENERIC" >/dev/null 2>&1; then
    echo "Expected invalid platform value to fail"
    exit 1
fi

# ---------------------------------------------------------------------------
# Test: Go stack detection
# ---------------------------------------------------------------------------
GO="$TMPDIR/gostack"
mkdir -p "$GO"
cat > "$GO/go.mod" <<'GOMOD'
module example.com/gostack

go 1.21
GOMOD

bash "$ROOT/scripts/init-project.sh" --no-mcp "$GO" >/dev/null

python3 - <<'PY' "$GO/.claude/settings.json"
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
settings = path.read_text()
for marker in ("Bash(go build *)", "Bash(go test *)", "Bash(go run *)"):
    if marker not in settings:
        raise SystemExit(f"Go-specific permission '{marker}' not found in settings.json")
PY

# ---------------------------------------------------------------------------
# Test: Rust stack detection
# ---------------------------------------------------------------------------
RUST="$TMPDIR/ruststack"
mkdir -p "$RUST"
cat > "$RUST/Cargo.toml" <<'TOML'
[package]
name = "foundation-smoke-rust"
version = "0.1.0"
edition = "2021"
TOML

bash "$ROOT/scripts/init-project.sh" --no-mcp "$RUST" >/dev/null

python3 - <<'PY' "$RUST/.claude/settings.json"
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
settings = path.read_text()
for marker in ("Bash(cargo build *)", "Bash(cargo test *)", "Bash(cargo run *)"):
    if marker not in settings:
        raise SystemExit(f"Rust-specific permission '{marker}' not found in settings.json")
PY

# ---------------------------------------------------------------------------
# Test: --dry-run writes no files
# ---------------------------------------------------------------------------
DRYRUN="$TMPDIR/dryrun"
mkdir -p "$DRYRUN"

bash "$ROOT/scripts/init-project.sh" --no-mcp --dry-run "$DRYRUN" >/dev/null

python3 - <<'PY' "$DRYRUN"
import pathlib
import sys

target = pathlib.Path(sys.argv[1])
unexpected = [str(p) for p in target.rglob("*") if p.is_file()]
if unexpected:
    raise SystemExit(f"--dry-run wrote files but should not have: {unexpected}")
PY

# ---------------------------------------------------------------------------
# Test: --platform claude skips AGENTS.md and GEMINI.md
# ---------------------------------------------------------------------------
# AGENTS.md is only generated when platform includes "codex" or "opencode".
# GEMINI.md is only generated when platform includes "gemini".
# With --platform claude, neither condition is met, so both should be absent.
CLAUDE_ONLY="$TMPDIR/claudeonly"
mkdir -p "$CLAUDE_ONLY"

bash "$ROOT/scripts/init-project.sh" --no-mcp --platform "claude" "$CLAUDE_ONLY" >/dev/null

python3 - <<'PY' "$CLAUDE_ONLY"
import pathlib
import sys

target = pathlib.Path(sys.argv[1])

for unwanted in ("AGENTS.md", "GEMINI.md"):
    if (target / unwanted).exists():
        raise SystemExit(
            f"--platform claude should not generate {unwanted}, but it does"
        )

for required in (".claude/settings.json", ".foundation-sync.json"):
    if not (target / required).exists():
        raise SystemExit(
            f"--platform claude should generate {required}, but it is missing"
        )
PY

# ---------------------------------------------------------------------------
# Test: --update preserves custom content in CUSTOM:START blocks
# ---------------------------------------------------------------------------
UPDATE2="$TMPDIR/update2"
mkdir -p "$UPDATE2"
bash "$ROOT/scripts/init-project.sh" --no-mcp "$UPDATE2" >/dev/null

# Insert a recognisable custom value inside the project-overview CUSTOM block
python3 - <<'PY' "$UPDATE2/AGENTS.md"
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
marker_start = "<!-- CUSTOM:START project-overview -->"
marker_end = "<!-- CUSTOM:END project-overview -->"
if marker_start not in text or marker_end not in text:
    raise SystemExit("project-overview CUSTOM block not found in AGENTS.md")
custom_line = "<!-- CUSTOM: test marker -->"
replacement = f"{marker_start}\n{custom_line}\n{marker_end}"
original_block = text[text.index(marker_start):text.index(marker_end) + len(marker_end)]
path.write_text(text.replace(original_block, replacement, 1))
PY

bash "$ROOT/scripts/init-project.sh" --update --no-mcp "$UPDATE2" >/dev/null
grep -q "<!-- CUSTOM: test marker -->" "$UPDATE2/AGENTS.md"
