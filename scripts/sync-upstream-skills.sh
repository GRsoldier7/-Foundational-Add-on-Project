#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/config/upstream-skill-manifest.txt"

usage() {
    echo "Usage: bash scripts/sync-upstream-skills.sh /path/to/My_AI_Skills"
}

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

if [[ ! -d "$1" ]]; then
    echo "Upstream source path does not exist: $1" >&2
    exit 1
fi

SOURCE="$(cd "$1" && pwd)"

if [[ "$SOURCE" == "$ROOT" ]]; then
    echo "Refusing to sync from the current repo into itself." >&2
    exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
    echo "Missing manifest file: $MANIFEST" >&2
    exit 1
fi

while IFS= read -r relpath; do
    [[ -z "$relpath" || "$relpath" =~ ^# ]] && continue

    src="$SOURCE/$relpath"
    dst="$ROOT/$relpath"

    if [[ ! -e "$src" ]]; then
        echo "Missing upstream path: $relpath" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    cp -R "$src" "$dst"
done < "$MANIFEST"

bash "$ROOT/scripts/sync-claude-commands.sh"
