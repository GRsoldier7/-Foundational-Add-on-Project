#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"
COMMANDS_DIR="$ROOT/.claude/commands"

mkdir -p "$COMMANDS_DIR"

while IFS= read -r skill_file; do
    skill_name="$(basename "$(dirname "$skill_file")")"
    cp "$skill_file" "$COMMANDS_DIR/$skill_name.md"
done < <(find "$SKILLS_DIR" -mindepth 3 -maxdepth 3 -type f -name "SKILL.md" | sort)
