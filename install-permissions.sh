#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

# Re-sync only Claude permissions/config scaffolding.
bash "$ROOT/scripts/init-project.sh" --platform claude --update --no-mcp "$TARGET"
