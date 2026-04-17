#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
FIRST_PARTY_SKILLS = {
    path.parent.name: path
    for path in ROOT.glob("skills/*/*/SKILL.md")
}
COMMUNITY_SKILLS = {
    path.parent.name: path
    for path in ROOT.glob(".claude/skills/*/SKILL.md")
}
ALL_SKILLS = set(FIRST_PARTY_SKILLS) | set(COMMUNITY_SKILLS)
ERRORS: list[str] = []


def error(message: str) -> None:
    ERRORS.append(message)


def parse_adjacent_skills(text: str) -> list[str]:
    match = re.search(r"adjacent-skills:\s*([^\n]+)", text)
    if not match:
        return []

    refs = []
    for raw in re.split(r"\s*,\s*", match.group(1).strip()):
        ref = raw.strip().strip(").(")
        if re.fullmatch(r"[a-z0-9][a-z0-9-]+", ref):
            refs.append(ref)
    return refs


def check_adjacent_skill_integrity() -> None:
    for path in sorted(FIRST_PARTY_SKILLS.values()):
        text = path.read_text()
        for ref in parse_adjacent_skills(text):
            if ref not in ALL_SKILLS:
                error(f"{path.relative_to(ROOT)} references missing adjacent skill '{ref}'")


def check_registry_files() -> None:
    registry_files = [
        ROOT / "skills/core/master-orchestrator/SKILL.md",
        ROOT / "skills/core/adaptive-skill-orchestrator/SKILL.md",
        ROOT / "skills/strategy/business-genius/SKILL.md",
        ROOT / "skills/strategy/go-to-market-engine/SKILL.md",
        ROOT / "skills/strategy/pricing-strategist/SKILL.md",
    ]

    for path in registry_files:
        text = path.read_text()
        for lineno, line in enumerate(text.splitlines(), start=1):
            for ref in re.findall(r"`([a-z0-9][a-z0-9-]+)`", line):
                if ref not in ALL_SKILLS:
                    error(f"{path.relative_to(ROOT)}:{lineno} references missing skill '{ref}'")


def check_command_sync() -> None:
    commands_dir = ROOT / ".claude/commands"
    command_names = {path.stem: path for path in commands_dir.glob("*.md")}
    allowed_extra = {"using-superpowers"}

    for skill_name, skill_path in sorted(FIRST_PARTY_SKILLS.items()):
        command_path = commands_dir / f"{skill_name}.md"
        if not command_path.exists():
            error(f"Missing generated command for skill '{skill_name}'")
            continue

        if command_path.read_text() != skill_path.read_text():
            error(f"Command drift for skill '{skill_name}'")

    extra = sorted(set(command_names) - set(FIRST_PARTY_SKILLS) - allowed_extra)
    for name in extra:
        error(f"Unexpected extra command file '.claude/commands/{name}.md'")


def check_shared_settings() -> None:
    settings_path = ROOT / ".claude/settings.json"
    text = settings_path.read_text()

    try:
        json.loads(text)
    except json.JSONDecodeError as exc:
        error(f"{settings_path.relative_to(ROOT)} is not valid JSON: {exc}")
        return

    banned_snippets = [
        "/mnt/deeznas/home/",
        "/home/aaron",
        'Bash(git -C "',
        '"additionalDirectories"',
        "Bash(liquidctl *)",
        "Read(/dev/**)",
    ]
    for snippet in banned_snippets:
        if snippet in text:
            error(f"{settings_path.relative_to(ROOT)} contains machine-local or hardware-specific entry: {snippet}")


def check_repo_strings() -> None:
    readme = (ROOT / "README.md").read_text()
    if "Foundation_AddOn_Project.git" in readme:
        error("README.md still contains the dead clone URL")
    if "-Foundational-Add-on-Project.git" not in readme:
        error("README.md does not contain the canonical clone URL")

    legacy_playwright = "@anthropic-ai/" + "mcp-server-playwright"
    skip_paths = {
        ROOT / "scripts/validate-foundation.py",
        ROOT / "scripts/test-init-project.sh",
    }
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git/" in str(path):
            continue
        if "__pycache__" in path.parts:
            continue
        if path in skip_paths:
            continue
        if path.suffix in {".png", ".jpg", ".jpeg", ".gif", ".pdf", ".pyc"}:
            continue
        if path.name.startswith(".__") or path.name.startswith("._"):
            continue
        try:
            text = path.read_text(errors="ignore")
        except FileNotFoundError:
            continue
        if legacy_playwright in text:
            error(f"{path.relative_to(ROOT)} still references the legacy Playwright MCP package")


def check_gitignore() -> None:
    text = (ROOT / ".gitignore").read_text()
    for pattern in ("**/.__*", "**/._*", "*.swp", "*.swo"):
        if pattern not in text:
            error(f".gitignore is missing temporary file pattern '{pattern}'")


def check_repo_layout() -> None:
    for path in (
        ROOT / "scripts/apply-fan-fixes.sh",
        ROOT / "scripts/fix-fan-control.sh",
    ):
        if path.exists():
            error(f"Portable scripts directory still contains host-specific file {path.relative_to(ROOT)}")


def check_required_templates() -> None:
    required = (
        ROOT / "templates/AGENTS.md.tmpl",
        ROOT / "templates/GEMINI.md.tmpl",
        ROOT / "templates/opencode.json.tmpl",
        ROOT / "templates/settings.json.tmpl",
        ROOT / "templates/ai-memory/project-profile.md.tmpl",
    )
    for path in required:
        if not path.exists():
            error(f"Missing required template: {path.relative_to(ROOT)}")


def main() -> int:
    check_adjacent_skill_integrity()
    check_registry_files()
    check_command_sync()
    check_shared_settings()
    check_repo_strings()
    check_gitignore()
    check_repo_layout()
    check_required_templates()

    if ERRORS:
        print("Foundation validation failed:", file=sys.stderr)
        for item in ERRORS:
            print(f" - {item}", file=sys.stderr)
        return 1

    print("Foundation validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
