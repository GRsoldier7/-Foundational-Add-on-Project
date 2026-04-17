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
