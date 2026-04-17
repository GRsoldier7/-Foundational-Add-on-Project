#!/usr/bin/env bash
# =============================================================================
# init-project.sh — Scaffold cross-platform AI configs for a new project
# =============================================================================
#
# Generates AGENTS.md, GEMINI.md, opencode.json, .claude/settings.json,
# .ai-memory/project-profile.md, and a .code-workspace file from Foundation
# AddOn templates. Detects tech stack and injects stack-specific permissions.
#
# Usage:
#   bash init-project.sh /path/to/project                     # first-time setup
#   bash init-project.sh --update /path/to/project             # re-sync existing
#   bash init-project.sh --dry-run /path/to/project            # preview changes
#   bash init-project.sh --platform claude,codex,gemini /path/to/project  # specific platforms
#   bash init-project.sh --no-mcp /path/to/project             # skip MCP prompt
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors and helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()     { echo -e "${RED}[ERROR]${NC} $*" >&2; }
section() { echo -e "\n${BOLD}${BLUE}--- $* ---${NC}"; }

# ---------------------------------------------------------------------------
# Resolve Foundation AddOn root (where this script lives)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOUNDATION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$FOUNDATION_ROOT/templates"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
DRY_RUN=false
UPDATE_MODE=false
SKIP_MCP=false
PLATFORMS="claude,codex,gemini,opencode"
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)   DRY_RUN=true; shift ;;
        --update)    UPDATE_MODE=true; shift ;;
        --no-mcp)    SKIP_MCP=true; shift ;;
        --platform)  PLATFORMS="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: bash init-project.sh [OPTIONS] /path/to/project"
            echo ""
            echo "Options:"
            echo "  --update       Re-sync existing project (preserves custom sections)"
            echo "  --dry-run      Show what would change without writing files"
            echo "  --platform X   Comma-separated: claude,codex,gemini,opencode (default: all)"
            echo "  --no-mcp       Skip MCP server setup prompt"
            echo "  --help         Show this help"
            exit 0
            ;;
        -*)          err "Unknown option: $1"; exit 1 ;;
        *)           TARGET="$1"; shift ;;
    esac
done

normalize_platforms() {
    local raw="$1"
    local normalized=""
    local IFS=','
    local entries=()
    read -r -a entries <<< "$raw"

    if [[ ${#entries[@]} -eq 0 ]]; then
        err "No platforms provided. Allowed values: claude,codex,gemini,opencode"
        exit 1
    fi

    for entry in "${entries[@]}"; do
        local platform
        platform="$(echo "$entry" | xargs)"

        case "$platform" in
            claude|codex|gemini|opencode) ;;
            "")
                err "Empty platform entry in --platform '$raw'"
                exit 1
                ;;
            *)
                err "Unknown platform '$platform'. Allowed values: claude,codex,gemini,opencode"
                exit 1
                ;;
        esac

        if [[ ",$normalized," != *",$platform,"* ]]; then
            if [[ -n "$normalized" ]]; then
                normalized="$normalized,$platform"
            else
                normalized="$platform"
            fi
        fi
    done

    if [[ -z "$normalized" ]]; then
        err "No valid platforms provided. Allowed values: claude,codex,gemini,opencode"
        exit 1
    fi

    PLATFORMS="$normalized"
}

normalize_platforms "$PLATFORMS"

if [[ -z "$TARGET" ]]; then
    err "No target project path provided."
    echo "Usage: bash init-project.sh [OPTIONS] /path/to/project"
    exit 1
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || { err "Target path does not exist: $TARGET"; exit 1; }

echo ""
echo -e "${BOLD}${BLUE}Foundation AddOn — Project Init${NC}"
echo -e "  Foundation: $FOUNDATION_ROOT"
echo -e "  Target:     $TARGET"
echo -e "  Mode:       $(if $UPDATE_MODE; then echo 'update'; else echo 'init'; fi)$(if $DRY_RUN; then echo ' (dry-run)'; fi)"
echo -e "  Platforms:  $PLATFORMS"
echo ""

# ---------------------------------------------------------------------------
# Detect tech stack
# ---------------------------------------------------------------------------
section "Detecting tech stack"

DETECTED_STACK=""
LANG_ALLOWS=""

if [[ -f "$TARGET/pyproject.toml" || -f "$TARGET/requirements.txt" || -f "$TARGET/setup.py" ]]; then
    DETECTED_STACK="python"
    LANG_ALLOWS='"Bash(python *)",
      "Bash(python3 *)",
      "Bash(pip install *)",
      "Bash(pip install)",
      "Bash(pip list *)",
      "Bash(pip show *)",
      "Bash(uv *)",
      "Bash(ruff *)",
      "Bash(pyright *)",
      "Bash(pytest *)",
      "Bash(black *)",
      "Bash(mypy *)",'
    ok "Detected: Python"
elif [[ -f "$TARGET/package.json" ]]; then
    DETECTED_STACK="node"
    LANG_ALLOWS='"Bash(npm test *)",
      "Bash(npm run *)",
      "Bash(npm install *)",
      "Bash(npm install)",
      "Bash(npm list *)",
      "Bash(npm outdated *)",
      "Bash(npm audit *)",
      "Bash(npx prettier *)",
      "Bash(npx eslint *)",
      "Bash(npx tsc *)",
      "Bash(node *)",'
    ok "Detected: Node.js"
elif [[ -f "$TARGET/go.mod" ]]; then
    DETECTED_STACK="go"
    LANG_ALLOWS='"Bash(go build *)",
      "Bash(go test *)",
      "Bash(go run *)",
      "Bash(go mod *)",
      "Bash(go vet *)",
      "Bash(golangci-lint *)",'
    ok "Detected: Go"
elif [[ -f "$TARGET/Cargo.toml" ]]; then
    DETECTED_STACK="rust"
    LANG_ALLOWS='"Bash(cargo build *)",
      "Bash(cargo test *)",
      "Bash(cargo run *)",
      "Bash(cargo clippy *)",
      "Bash(cargo fmt *)",
      "Bash(rustc *)",'
    ok "Detected: Rust"
else
    warn "No recognized tech stack detected. Using generic permissions."
    LANG_ALLOWS=""
fi

# ---------------------------------------------------------------------------
# Get Foundation AddOn git hash
# ---------------------------------------------------------------------------
FOUNDATION_HASH=$(git -C "$FOUNDATION_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
SYNC_TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# ---------------------------------------------------------------------------
# Helper: preserve custom sections on update
# ---------------------------------------------------------------------------
preserve_custom_sections() {
    local existing_file="$1"
    local new_content="$2"

    if [[ ! -f "$existing_file" ]]; then
        echo "$new_content"
        return
    fi

    local result="$new_content"
    # Extract custom sections from existing file and inject into new content
    while IFS= read -r marker; do
        local section_name
        section_name=$(echo "$marker" | sed -n 's/.*CUSTOM:START \(.*\) -->.*/\1/p')
        if [[ -n "$section_name" ]]; then
            # Extract the custom content between START and END markers
            local custom_content
            custom_content=$(sed -n "/<!-- CUSTOM:START ${section_name} -->/,/<!-- CUSTOM:END ${section_name} -->/p" "$existing_file")
            if [[ -n "$custom_content" ]]; then
                # Replace the section in new content with the preserved version
                local placeholder_start="<!-- CUSTOM:START ${section_name} -->"
                local placeholder_end="<!-- CUSTOM:END ${section_name} -->"
                # Use awk for multi-line replacement
                result=$(echo "$result" | awk -v start="$placeholder_start" -v end="$placeholder_end" -v replacement="$custom_content" '
                    $0 ~ start { in_section=1; print replacement; next }
                    $0 ~ end { in_section=0; next }
                    !in_section { print }
                ')
            fi
        fi
    done < <(grep -n "CUSTOM:START" "$existing_file" 2>/dev/null || true)

    echo "$result"
}

# ---------------------------------------------------------------------------
# Helper: write or preview a file
# ---------------------------------------------------------------------------
write_file() {
    local filepath="$1"
    local content="$2"
    local desc="$3"

    if $DRY_RUN; then
        if [[ -f "$filepath" ]]; then
            info "[DRY-RUN] Would update: $filepath ($desc)"
        else
            info "[DRY-RUN] Would create: $filepath ($desc)"
        fi
        return
    fi

    mkdir -p "$(dirname "$filepath")"
    printf '%s\n' "$content" > "$filepath"
    if [[ -f "$filepath" ]]; then
        ok "Written: $filepath ($desc)"
    fi
}

# ---------------------------------------------------------------------------
# Helper: compute file checksum
# ---------------------------------------------------------------------------
file_checksum() {
    sha256sum "$1" 2>/dev/null | cut -d' ' -f1 || echo "none"
}

json_escape() {
    local raw="$1"
    raw="${raw//\\/\\\\}"
    raw="${raw//\"/\\\"}"
    raw="${raw//$'\n'/\\n}"
    raw="${raw//$'\r'/\\r}"
    raw="${raw//$'\t'/\\t}"
    printf '%s' "$raw"
}

# ---------------------------------------------------------------------------
# Determine project name
# ---------------------------------------------------------------------------
PROJECT_NAME=$(basename "$TARGET")

# ---------------------------------------------------------------------------
# Generate: AGENTS.md (for Codex / Opencode)
# ---------------------------------------------------------------------------
if echo "$PLATFORMS" | grep -qE "codex|opencode"; then
    section "Generating AGENTS.md"

    AGENTS_CONTENT=$(cat "$TEMPLATES_DIR/AGENTS.md.tmpl")
    AGENTS_CONTENT="${AGENTS_CONTENT//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
    AGENTS_CONTENT="${AGENTS_CONTENT//\{\{TECH_STACK\}\}/${DETECTED_STACK:-generic}}"
    AGENTS_CONTENT="${AGENTS_CONTENT//\{\{CONVENTIONS\}\}/See project-specific conventions.}"
    AGENTS_CONTENT="${AGENTS_CONTENT//\{\{FOUNDATION_PATH\}\}/$FOUNDATION_ROOT}"
    AGENTS_CONTENT="${AGENTS_CONTENT//\{\{SYNC_TIMESTAMP\}\}/$SYNC_TIMESTAMP}"
    AGENTS_CONTENT="${AGENTS_CONTENT//\{\{FOUNDATION_HASH\}\}/$FOUNDATION_HASH}"

    if $UPDATE_MODE; then
        AGENTS_CONTENT=$(preserve_custom_sections "$TARGET/AGENTS.md" "$AGENTS_CONTENT")
    fi

    write_file "$TARGET/AGENTS.md" "$AGENTS_CONTENT" "Codex/Opencode instructions"
fi

# ---------------------------------------------------------------------------
# Generate: GEMINI.md
# ---------------------------------------------------------------------------
if echo "$PLATFORMS" | grep -q "gemini"; then
    section "Generating GEMINI.md"

    GEMINI_CONTENT=$(cat "$TEMPLATES_DIR/GEMINI.md.tmpl")
    GEMINI_CONTENT="${GEMINI_CONTENT//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
    GEMINI_CONTENT="${GEMINI_CONTENT//\{\{TECH_STACK\}\}/${DETECTED_STACK:-generic}}"
    GEMINI_CONTENT="${GEMINI_CONTENT//\{\{CONVENTIONS\}\}/See project-specific conventions.}"
    GEMINI_CONTENT="${GEMINI_CONTENT//\{\{FOUNDATION_PATH\}\}/$FOUNDATION_ROOT}"
    GEMINI_CONTENT="${GEMINI_CONTENT//\{\{SYNC_TIMESTAMP\}\}/$SYNC_TIMESTAMP}"
    GEMINI_CONTENT="${GEMINI_CONTENT//\{\{FOUNDATION_HASH\}\}/$FOUNDATION_HASH}"

    if $UPDATE_MODE; then
        GEMINI_CONTENT=$(preserve_custom_sections "$TARGET/GEMINI.md" "$GEMINI_CONTENT")
    fi

    write_file "$TARGET/GEMINI.md" "$GEMINI_CONTENT" "Gemini CLI instructions"
fi

# ---------------------------------------------------------------------------
# Generate: .claude/settings.json (permissions)
# ---------------------------------------------------------------------------
if echo "$PLATFORMS" | grep -q "claude"; then
    section "Generating .claude/settings.json"

    SETTINGS_CONTENT=$(cat "$TEMPLATES_DIR/settings.json.tmpl")
    SETTINGS_CONTENT="${SETTINGS_CONTENT//\{\{FOUNDATION_HASH\}\}/$FOUNDATION_HASH}"
    SETTINGS_CONTENT="${SETTINGS_CONTENT//\{\{SYNC_TIMESTAMP\}\}/$SYNC_TIMESTAMP}"

    # Inject language-specific allows
    if [[ -n "$LANG_ALLOWS" ]]; then
        SETTINGS_CONTENT="${SETTINGS_CONTENT//\{\{LANG_ALLOWS\}\}/$LANG_ALLOWS}"
    else
        SETTINGS_CONTENT="${SETTINGS_CONTENT//\{\{LANG_ALLOWS\}\}/}"
    fi

    # MCP allows (default set)
    MCP_ALLOWS='"mcp__filesystem",
      "mcp__git",
      "mcp__memory",
      "mcp__fetch",
      "mcp__sequential-thinking",
      "mcp__context7",
      "mcp__playwright"'
    SETTINGS_CONTENT="${SETTINGS_CONTENT//\{\{MCP_ALLOWS\}\}/$MCP_ALLOWS}"

    # Custom allows placeholder — empty by default
    SETTINGS_CONTENT="${SETTINGS_CONTENT//\{\{CUSTOM_ALLOWS\}\}/}"

    # Only write if it doesn't exist or in update mode
    if [[ ! -f "$TARGET/.claude/settings.json" ]] || $UPDATE_MODE; then
        write_file "$TARGET/.claude/settings.json" "$SETTINGS_CONTENT" "Three-tier permissions"
    else
        ok "Skipping .claude/settings.json (already exists, use --update to overwrite)"
    fi
fi

# ---------------------------------------------------------------------------
# Generate: .ai-memory/project-profile.md
# ---------------------------------------------------------------------------
section "Generating .ai-memory bootstrap"

PROFILE_CONTENT=$(cat "$TEMPLATES_DIR/ai-memory/project-profile.md.tmpl")
PROFILE_CONTENT="${PROFILE_CONTENT//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
PROFILE_CONTENT="${PROFILE_CONTENT//\{\{TECH_STACK\}\}/${DETECTED_STACK:-generic}}"
PROFILE_CONTENT="${PROFILE_CONTENT//\{\{FOUNDATION_PATH\}\}/$FOUNDATION_ROOT}"
PROFILE_CONTENT="${PROFILE_CONTENT//\{\{SYNC_TIMESTAMP\}\}/$SYNC_TIMESTAMP}"
PROFILE_CONTENT="${PROFILE_CONTENT//\{\{FOUNDATION_HASH\}\}/$FOUNDATION_HASH}"

if $UPDATE_MODE; then
    PROFILE_CONTENT=$(preserve_custom_sections "$TARGET/.ai-memory/project-profile.md" "$PROFILE_CONTENT")
fi

if [[ ! -f "$TARGET/.ai-memory/project-profile.md" ]] || $UPDATE_MODE; then
    write_file "$TARGET/.ai-memory/project-profile.md" "$PROFILE_CONTENT" "AI memory bootstrap profile"
else
    ok "Skipping .ai-memory/project-profile.md (already exists, use --update to overwrite)"
fi

# ---------------------------------------------------------------------------
# Generate: opencode.json
# ---------------------------------------------------------------------------
if echo "$PLATFORMS" | grep -q "opencode"; then
    section "Generating opencode.json"

    OC_CONTENT=$(cat "$TEMPLATES_DIR/opencode.json.tmpl")
    OC_CONTENT="${OC_CONTENT//\{\{FOUNDATION_HASH\}\}/$FOUNDATION_HASH}"
    OC_CONTENT="${OC_CONTENT//\{\{PRIMARY_PROVIDER\}\}/anthropic}"
    OC_CONTENT="${OC_CONTENT//\{\{PRIMARY_MODEL\}\}/claude-sonnet-4-6}"

    write_file "$TARGET/opencode.json" "$OC_CONTENT" "Opencode model routing"
fi

# ---------------------------------------------------------------------------
# Generate: .code-workspace
# ---------------------------------------------------------------------------
if echo "$PLATFORMS" | grep -q "claude"; then
    section "Generating workspace file"

    WS_CONTENT=$(cat "$TEMPLATES_DIR/workspace.code-workspace.tmpl")
    WS_CONTENT="${WS_CONTENT//\{\{PROJECT_NAME\}\}/$(json_escape "$PROJECT_NAME")}"
    WS_CONTENT="${WS_CONTENT//\{\{PROJECT_PATH\}\}/.}"
    WS_CONTENT="${WS_CONTENT//\{\{FOUNDATION_PATH\}\}/$(json_escape "$FOUNDATION_ROOT")}"

    WS_FILE="$TARGET/${PROJECT_NAME}.code-workspace"
    if [[ ! -f "$WS_FILE" ]]; then
        write_file "$WS_FILE" "$WS_CONTENT" "VS Code workspace"
    else
        ok "Workspace file already exists: $WS_FILE"
    fi
fi

# ---------------------------------------------------------------------------
# Generate: .foundation-sync.json (version tracking)
# ---------------------------------------------------------------------------
section "Writing sync manifest"

CHECKSUMS="{"
for f in AGENTS.md GEMINI.md opencode.json .claude/settings.json .ai-memory/project-profile.md; do
    if [[ -f "$TARGET/$f" ]]; then
        cs=$(file_checksum "$TARGET/$f")
        CHECKSUMS="$CHECKSUMS\"$f\":\"$cs\","
    fi
done
CHECKSUMS="${CHECKSUMS%,}}"

SYNC_MANIFEST=$(cat <<SYNCEOF
{
  "foundation_addon": {
    "path": "$(json_escape "$FOUNDATION_ROOT")",
    "commit": "$(json_escape "$FOUNDATION_HASH")",
    "last_sync": "$(json_escape "$SYNC_TIMESTAMP")"
  },
  "project": {
    "name": "$(json_escape "$PROJECT_NAME")",
    "tech_stack": "$(json_escape "${DETECTED_STACK:-generic}")",
    "platforms": "$(json_escape "$PLATFORMS")"
  },
  "generated_files": $CHECKSUMS,
  "custom_sections_preserved": true
}
SYNCEOF
)

write_file "$TARGET/.foundation-sync.json" "$SYNC_MANIFEST" "Sync tracking manifest"

# ---------------------------------------------------------------------------
# MCP server prompt (optional)
# ---------------------------------------------------------------------------
if ! $SKIP_MCP && ! $DRY_RUN && [[ ! -f "$TARGET/.mcp.json" ]]; then
    section "MCP Server Setup"
    echo ""
    echo "The Foundation AddOn recommends these MCP servers (Tier 1, zero API keys):"
    echo "  1. Context7    — live library docs"
    echo "  2. Filesystem  — sandboxed file ops"
    echo "  3. Git         — native git operations"
    echo "  4. Playwright  — browser automation"
    echo "  5. Memory      — persistent knowledge graph"
    echo "  6. Fetch       — URL to markdown"
    echo "  7. Sequential Thinking — structured problem-solving"
    echo ""
    read -rp "Generate .mcp.json with Tier 1 servers? [Y/n] " MCP_RESPONSE
    if [[ "${MCP_RESPONSE:-Y}" =~ ^[Yy] ]]; then
        MCP_JSON=$(cat <<'MCPJSON'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
MCPJSON
)
        write_file "$TARGET/.mcp.json" "$MCP_JSON" "MCP server config"
        warn "Add .mcp.json to your .gitignore (may contain credentials later)"
    else
        info "Skipping MCP setup. Create .mcp.json manually when ready."
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
section "Summary"
echo ""
if $DRY_RUN; then
    info "Dry run complete. No files were written."
    info "Re-run without --dry-run to apply changes."
else
    ok "Project initialized for: $PLATFORMS"
    echo ""
    echo "  Generated files:"
    for f in AGENTS.md GEMINI.md opencode.json .claude/settings.json .ai-memory/project-profile.md .foundation-sync.json .mcp.json "${PROJECT_NAME}.code-workspace"; do
        [[ -f "$TARGET/$f" ]] && echo "    $TARGET/$f"
    done
    echo ""
    echo "  Next steps:"
    echo "    1. Open ${PROJECT_NAME}.code-workspace in VS Code"
    echo "    2. Review .ai-memory/project-profile.md and fill custom sections"
    echo "    3. Start a Claude Code session"
    echo "    4. Try: /health or /brainstorming"
    echo ""
    echo "  To update later:"
    echo "    bash $0 --update $TARGET"
    echo "    Or in Claude Code: /project-sync"
fi
echo ""
