---
name: github-repo-optimizer
description: |
  Genius-level GitHub repository optimizer that audits, hardens, and streamlines any GitHub
  repository using the `gh` CLI and GitHub API. Covers: repo health audits, branch protection,
  GitHub Actions CI/CD optimization, Dependabot configuration, security hardening, labels,
  issue/PR templates, release management, repository settings, and multi-repo management.

  EXPLICIT TRIGGER on: "optimize repo", "github best practices", "repo health", "github settings",
  "branch protection", "CI/CD", "actions", "dependabot", "repo audit", "github security",
  "secret scanning", "code scanning", "CodeQL", "CODEOWNERS", "issue templates", "PR template",
  "github labels", "release management", "changelog", "semantic versioning", "github api",
  "multi-repo", "reusable workflows", "action pinning", "OIDC", "merge settings",
  "auto-delete branches", "squash merge", "required reviews", "status checks".

  Also trigger when user asks: "is this repo set up correctly", "harden this repo",
  "what's missing from this repo", "set up CI/CD", "configure dependabot",
  "protect main branch", "enable security features".
metadata:
  author: aaron-deyoung
  version: "1.0"
  domain-category: engineering
  adjacent-skills: code-review, app-security-architect, docker-infrastructure, testing-strategy
  last-reviewed: "2026-04-10"
  review-trigger: "New GitHub features, Actions runner changes, gh CLI major version"
  capability-assumptions:
    - "gh CLI authenticated and available (gh auth status passes)"
    - "Bash tool for running gh commands"
    - "Repository exists on GitHub (public or private)"
  fallback-patterns:
    - "If gh CLI not authenticated: guide user through gh auth login"
    - "If no repo context: ask user for owner/repo or detect from git remote"
    - "If insufficient permissions: list what needs org admin vs repo admin"
  degradation-mode: "graceful"
---

## Composability Contract
- Input expects: a GitHub repository (owner/repo or current working directory with git remote)
- Output produces: audit report, gh CLI commands to fix issues, config files (dependabot.yml, workflows, templates)
- Can chain from: code-review (after review, optimize the repo), app-security-architect (harden repo security)
- Can chain into: testing-strategy (set up CI test pipeline), docker-infrastructure (containerized CI)
- Orchestrator notes: always run `gh auth status` and detect repo context before any operations

---

## Section 1 -- Core Knowledge

### The Repo Health Hierarchy (audit in this order)

1. **Security** -- Secret scanning, push protection, code scanning, branch protection, CODEOWNERS
2. **CI/CD** -- GitHub Actions workflows, status checks, caching, matrix builds, action pinning
3. **Dependency management** -- Dependabot config, update schedules, grouping, ecosystem coverage
4. **Repository settings** -- Merge strategy, auto-delete branches, topics, description, visibility
5. **Developer experience** -- Issue templates, PR template, labels, contributing guide
6. **Release management** -- Semantic versioning, changelog, GitHub Releases, tag protection

Do not reorder this hierarchy. A repo with perfect labels but no branch protection is a liability.

### Context Detection

Before any operation, establish context:

```bash
# Verify gh CLI is authenticated
gh auth status

# Detect current repo from git remote
gh repo view --json owner,name,defaultBranchRef,isPrivate,description

# Get full repo settings
gh api repos/{owner}/{repo} --jq '{
  default_branch: .default_branch,
  private: .private,
  has_issues: .has_issues,
  has_wiki: .has_wiki,
  allow_squash_merge: .allow_squash_merge,
  allow_merge_commit: .allow_merge_commit,
  allow_rebase_merge: .allow_rebase_merge,
  delete_branch_on_merge: .delete_branch_on_merge,
  allow_auto_merge: .allow_auto_merge
}'
```

---

## Section 2 -- Repository Health Audit

### The Full Audit Checklist

Run this to produce a complete health report. Each check uses `gh` commands.

#### 2.1 Essential Files

```bash
# Check for essential files in the repo root
for file in README.md LICENSE .gitignore CODEOWNERS CONTRIBUTING.md SECURITY.md; do
  gh api "repos/{owner}/{repo}/contents/$file" --silent 2>/dev/null \
    && echo "[PASS] $file exists" \
    || echo "[FAIL] $file missing"
done
```

#### 2.2 Branch Protection Rules

```bash
# Check branch protection on default branch
gh api "repos/{owner}/{repo}/branches/main/protection" \
  --jq '{
    required_reviews: .required_pull_request_reviews.required_approving_review_count,
    dismiss_stale: .required_pull_request_reviews.dismiss_stale_reviews,
    require_code_owner_reviews: .required_pull_request_reviews.require_code_owner_reviews,
    status_checks: .required_status_checks.contexts,
    enforce_admins: .enforce_admins.enabled,
    linear_history: .required_linear_history.enabled,
    signed_commits: .required_signatures.enabled
  }'
```

#### 2.3 Security Features

```bash
# Check security features (requires admin access for some)
gh api "repos/{owner}/{repo}" --jq '{
  secret_scanning: .security_and_analysis.secret_scanning.status,
  secret_scanning_push_protection: .security_and_analysis.secret_scanning_push_protection.status,
  dependabot_alerts: .security_and_analysis.dependabot_security_updates.status
}'

# Check for code scanning alerts (CodeQL)
gh api "repos/{owner}/{repo}/code-scanning/alerts" --jq 'length' 2>/dev/null \
  && echo "[INFO] Code scanning is configured" \
  || echo "[WARN] Code scanning not configured"
```

#### 2.4 Dependabot Configuration

```bash
# Check if dependabot.yml exists
gh api "repos/{owner}/{repo}/contents/.github/dependabot.yml" --silent 2>/dev/null \
  && echo "[PASS] dependabot.yml exists" \
  || echo "[FAIL] dependabot.yml missing"
```

#### 2.5 GitHub Actions

```bash
# List workflows
gh workflow list

# Check recent workflow run success rate
gh run list --limit 20 --json status,conclusion \
  --jq 'group_by(.conclusion) | map({conclusion: .[0].conclusion, count: length})'
```

### Audit Report Format

After running all checks, produce a structured report:

| Area | Status | Finding | Fix Command |
|------|--------|---------|-------------|
| Branch protection | FAIL | No required reviews | `gh api ... -X PUT` |
| Secret scanning | PASS | Enabled | -- |
| Dependabot | FAIL | Missing config | Generate dependabot.yml |

Severity levels for audit findings:
- **CRITICAL** -- No branch protection, secrets in repo history, public repo with no security policy
- **HIGH** -- No required reviews, no CI, no dependabot, unsigned commits allowed
- **MEDIUM** -- Missing CODEOWNERS, no issue templates, stale action versions
- **LOW** -- Missing topics/description, no PR template, wiki enabled but unused

---

## Section 3 -- Branch Protection

### Recommended Protection Rules for `main`

```bash
# Set comprehensive branch protection on main
gh api "repos/{owner}/{repo}/branches/main/protection" \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["ci / test", "ci / lint"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
EOF
```

### Solo Developer Variant

For solo founders, required reviews block workflow. Use this lighter protection:

```bash
gh api "repos/{owner}/{repo}/branches/main/protection" \
  -X PUT \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["ci / test"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### Tag Protection

```bash
# Protect release tags from deletion/modification
gh api "repos/{owner}/{repo}/tag-protection" \
  -X POST \
  -f pattern='v*'
```

### Require Signed Commits

```bash
# Enable commit signature requirement
gh api "repos/{owner}/{repo}/branches/main/protection/required_signatures" \
  -X POST \
  -H "Accept: application/vnd.github.zzzax-preview+json"
```

---

## Section 4 -- GitHub Actions Optimization

### 4.1 Action Version Pinning (Security-Critical)

NEVER use `@main` or `@master` tags. ALWAYS pin to a full commit SHA:

```yaml
# BAD - mutable tag, supply chain risk
- uses: actions/checkout@v4

# GOOD - immutable SHA pin
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

Get the SHA for any action:

```bash
# Resolve action tag to SHA
gh api "repos/actions/checkout/git/ref/tags/v4.1.1" --jq '.object.sha'
```

### 4.2 Caching Strategies

```yaml
# Python dependency caching
- uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b # v5.3.0
  with:
    python-version: '3.12'
    cache: 'pip'

# Node dependency caching
- uses: actions/setup-node@1d0ff469b7ec7b3cb9d8673fde0c81c44821de2a # v4.2.0
  with:
    node-version: '20'
    cache: 'npm'

# Custom cache for expensive operations
- uses: actions/cache@6849a6489940f00c2f30c0fb92c6274307ccb58a # v4.1.2
  with:
    path: |
      ~/.cache/pre-commit
      .mypy_cache
    key: ${{ runner.os }}-precommit-${{ hashFiles('.pre-commit-config.yaml') }}
```

### 4.3 Matrix Builds

```yaml
strategy:
  fail-fast: false
  matrix:
    python-version: ['3.11', '3.12', '3.13']
    os: [ubuntu-latest, macos-latest]
    exclude:
      - os: macos-latest
        python-version: '3.11'
```

### 4.4 Reusable Workflows

```yaml
# .github/workflows/reusable-test.yml
name: Reusable Test Pipeline
on:
  workflow_call:
    inputs:
      python-version:
        required: true
        type: string
    secrets:
      CODECOV_TOKEN:
        required: false

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b
        with:
          python-version: ${{ inputs.python-version }}
          cache: 'pip'
      - run: pip install -r requirements.txt
      - run: pytest --cov
```

Caller workflow:

```yaml
jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      python-version: '3.12'
    secrets: inherit
```

### 4.5 OIDC for Cloud Deployments (No Long-Lived Secrets)

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: google-github-actions/auth@62cf5bd3e4211a0a0b51f2c6d6a37129d828611d # v2.1.3
    with:
      workload_identity_provider: 'projects/PROJECT_NUM/locations/global/workloadIdentityPools/POOL/providers/PROVIDER'
      service_account: 'deploy@project.iam.gserviceaccount.com'
```

### 4.6 Starter CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b
        with:
          python-version: '3.12'
          cache: 'pip'
      - run: pip install ruff
      - run: ruff check .
      - run: ruff format --check .

  test:
    runs-on: ubuntu-latest
    needs: [lint]
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b
        with:
          python-version: '3.12'
          cache: 'pip'
      - run: pip install -r requirements.txt
      - run: pytest --cov --cov-report=xml
```

---

## Section 5 -- Dependabot Configuration

### Ecosystem Detection and Config Generation

Detect all ecosystems in the repo and generate a comprehensive `dependabot.yml`:

```bash
# Detect ecosystems by checking for manifest files
declare -A ecosystems
[ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] && ecosystems[pip]=1
[ -f "package.json" ] && ecosystems[npm]=1
[ -f "Gemfile" ] && ecosystems[bundler]=1
[ -f "go.mod" ] && ecosystems[gomod]=1
[ -f "Cargo.toml" ] && ecosystems[cargo]=1
[ -f "docker-compose.yml" ] || [ -f "Dockerfile" ] && ecosystems[docker]=1
[ -d ".github/workflows" ] && ecosystems[github-actions]=1
[ -f "terraform" ] && ecosystems[terraform]=1
```

### Recommended dependabot.yml

```yaml
# .github/dependabot.yml
version: 2
updates:
  # Python dependencies
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    reviewers:
      - "your-username"
    groups:
      python-minor:
        update-types:
          - "minor"
          - "patch"
    open-pull-requests-limit: 10

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    groups:
      actions-all:
        patterns:
          - "*"

  # Docker base images
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  # npm (if applicable)
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    groups:
      npm-minor:
        update-types:
          - "minor"
          - "patch"
      npm-dev:
        dependency-type: "development"
```

### Grouping Strategy

Group updates to reduce PR noise:
- **Minor + patch** together (low risk, one review)
- **Dev dependencies** separately (never affect production)
- **Major versions** individually (breaking changes need isolated review)
- **GitHub Actions** all together (usually safe)

---

## Section 6 -- Security Hardening

### Enable All Security Features

```bash
OWNER="owner"
REPO="repo"

# Enable secret scanning
gh api "repos/$OWNER/$REPO" -X PATCH \
  --input - <<'EOF'
{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
EOF

# Enable Dependabot security updates
gh api "repos/$OWNER/$REPO/automated-security-fixes" -X PUT

# Enable private vulnerability reporting
gh api "repos/$OWNER/$REPO/private-vulnerability-reporting" -X PUT
```

### CodeQL Code Scanning Setup

```yaml
# .github/workflows/codeql.yml
name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'  # Weekly Monday 6am UTC

permissions:
  security-events: write
  contents: read

jobs:
  analyze:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        language: ['python', 'javascript']
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: github/codeql-action/init@b611370bb5703a7efb587f9d136a52ea24c5c38c # v3.25.0
        with:
          languages: ${{ matrix.language }}
      - uses: github/codeql-action/autobuild@b611370bb5703a7efb587f9d136a52ea24c5c38c
      - uses: github/codeql-action/analyze@b611370bb5703a7efb587f9d136a52ea24c5c38c
```

### SECURITY.md Template

```markdown
# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest  | Yes       |

## Reporting a Vulnerability

Please report security vulnerabilities via GitHub's
[private vulnerability reporting](../../security/advisories/new).

Do NOT open a public issue for security vulnerabilities.

Expected response time: 48 hours for acknowledgment, 7 days for a fix plan.
```

### CODEOWNERS

```bash
# .github/CODEOWNERS
# Default owner for everything
* @your-username

# Security-sensitive paths require explicit review
.github/workflows/ @your-username
.github/dependabot.yml @your-username
Dockerfile @your-username
docker-compose*.yml @your-username
```

---

## Section 7 -- Labels and Templates

### Standard Label Set

```bash
# Delete default labels and create a structured set
REPO="owner/repo"

# Remove defaults
for label in bug duplicate enhancement "good first issue" "help wanted" invalid question wontfix; do
  gh label delete "$label" --repo "$REPO" --yes 2>/dev/null
done

# Create structured labels
gh label create "type: bug"         --color "d73a4a" --description "Something isn't working"                 --repo "$REPO"
gh label create "type: feature"     --color "0075ca" --description "New feature or request"                  --repo "$REPO"
gh label create "type: chore"       --color "e4e669" --description "Maintenance, refactoring, dependencies"  --repo "$REPO"
gh label create "type: docs"        --color "0075ca" --description "Documentation improvements"              --repo "$REPO"
gh label create "type: security"    --color "b60205" --description "Security issue or improvement"           --repo "$REPO"

gh label create "priority: critical" --color "b60205" --description "Must fix immediately"                   --repo "$REPO"
gh label create "priority: high"     --color "d93f0b" --description "Fix in current sprint"                  --repo "$REPO"
gh label create "priority: medium"   --color "fbca04" --description "Fix in next sprint"                     --repo "$REPO"
gh label create "priority: low"      --color "0e8a16" --description "Fix when convenient"                    --repo "$REPO"

gh label create "status: triage"       --color "c5def5" --description "Needs triage"                         --repo "$REPO"
gh label create "status: in-progress"  --color "c5def5" --description "Actively being worked on"             --repo "$REPO"
gh label create "status: blocked"      --color "c5def5" --description "Blocked by external dependency"       --repo "$REPO"
gh label create "status: needs-review" --color "c5def5" --description "Ready for review"                     --repo "$REPO"
```

### Issue Templates

#### Bug Report (.github/ISSUE_TEMPLATE/bug_report.yml)

```yaml
name: Bug Report
description: Report a bug or unexpected behavior
labels: ["type: bug", "status: triage"]
body:
  - type: textarea
    id: description
    attributes:
      label: Bug Description
      description: Clear description of the bug
    validations:
      required: true
  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      description: Minimal steps to reproduce the behavior
      value: |
        1.
        2.
        3.
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
      description: What you expected to happen
    validations:
      required: true
  - type: textarea
    id: actual
    attributes:
      label: Actual Behavior
      description: What actually happened
    validations:
      required: true
  - type: textarea
    id: environment
    attributes:
      label: Environment
      description: OS, browser, version, etc.
      render: shell
```

#### Feature Request (.github/ISSUE_TEMPLATE/feature_request.yml)

```yaml
name: Feature Request
description: Suggest a new feature or improvement
labels: ["type: feature", "status: triage"]
body:
  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: What problem does this solve?
    validations:
      required: true
  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
      description: How should this work?
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      description: What other approaches did you consider?
  - type: dropdown
    id: priority
    attributes:
      label: Priority
      options:
        - Nice to have
        - Important
        - Critical
```

### PR Template (.github/pull_request_template.md)

```markdown
## Summary
<!-- What does this PR do? Why? -->

## Changes
- [ ] Change 1
- [ ] Change 2

## Testing
- [ ] Tests added/updated
- [ ] Manual testing done

## Checklist
- [ ] Code follows project conventions
- [ ] No secrets or credentials committed
- [ ] Documentation updated (if applicable)
```

---

## Section 8 -- Repository Settings

### Optimal Settings via API

```bash
OWNER="owner"
REPO="repo"

# Configure merge settings and housekeeping
gh api "repos/$OWNER/$REPO" -X PATCH \
  --input - <<'EOF'
{
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": true,
  "squash_merge_commit_title": "PR_TITLE",
  "squash_merge_commit_message": "PR_BODY",
  "delete_branch_on_merge": true,
  "allow_auto_merge": true,
  "allow_update_branch": true,
  "has_wiki": false,
  "has_projects": false
}
EOF

# Set repository topics for discoverability
gh repo edit "$OWNER/$REPO" --add-topic "python" --add-topic "fastapi" --add-topic "postgresql"

# Set description
gh repo edit "$OWNER/$REPO" --description "Brief, accurate description of what this repo does"
```

### Decision Framework: Merge Strategy

| Strategy | When to Use | Tradeoff |
|----------|------------|----------|
| **Squash merge** (default) | Most repos. Clean linear history, one commit per PR. | Loses granular commit history within PR. |
| **Rebase merge** | When individual commits within a PR are meaningful and well-crafted. | Requires disciplined commit hygiene. |
| **Merge commit** | Almost never. Only if branch history is critical for audit. | Pollutes main with merge noise. |

Recommendation: Enable squash + rebase, disable merge commit.

---

## Section 9 -- Release Management

### Semantic Versioning with gh CLI

```bash
# Create a release with auto-generated notes
gh release create v1.2.0 \
  --title "v1.2.0" \
  --generate-notes \
  --latest

# Create a pre-release
gh release create v2.0.0-rc.1 \
  --title "v2.0.0 Release Candidate 1" \
  --prerelease \
  --generate-notes

# List recent releases
gh release list --limit 5
```

### Release Drafter Workflow

```yaml
# .github/workflows/release-drafter.yml
name: Release Drafter
on:
  push:
    branches: [main]
  pull_request:
    types: [opened, reopened, synchronize]

permissions:
  contents: read
  pull-requests: write

jobs:
  update-release-draft:
    runs-on: ubuntu-latest
    steps:
      - uses: release-drafter/release-drafter@3ef166993f4ac63e9748fabe0c20cea75fcc7544 # v6.0.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Release Drafter Config (.github/release-drafter.yml)

```yaml
name-template: 'v$RESOLVED_VERSION'
tag-template: 'v$RESOLVED_VERSION'
categories:
  - title: 'Features'
    labels:
      - 'type: feature'
  - title: 'Bug Fixes'
    labels:
      - 'type: bug'
  - title: 'Maintenance'
    labels:
      - 'type: chore'
      - 'type: docs'
  - title: 'Security'
    labels:
      - 'type: security'
change-template: '- $TITLE @$AUTHOR (#$NUMBER)'
version-resolver:
  major:
    labels:
      - 'semver: major'
  minor:
    labels:
      - 'semver: minor'
      - 'type: feature'
  patch:
    labels:
      - 'semver: patch'
      - 'type: bug'
      - 'type: chore'
  default: patch
template: |
  ## Changes

  $CHANGES

  **Full Changelog**: https://github.com/$OWNER/$REPOSITORY/compare/$PREVIOUS_TAG...v$RESOLVED_VERSION
```

---

## Section 10 -- GitHub API Patterns

### Bulk Operations

```bash
# Close all stale issues older than 90 days
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    issues(first: 50, states: OPEN, orderBy: {field: UPDATED_AT, direction: ASC}) {
      nodes {
        id
        number
        title
        updatedAt
      }
    }
  }
}' --jq '.data.repository.issues.nodes[] | select(.updatedAt < "'$(date -v-90d +%Y-%m-%dT%H:%M:%SZ)'") | .number' \
| while read -r num; do
    gh issue close "$num" --repo "OWNER/REPO" --comment "Closing as stale (no activity for 90 days). Reopen if still relevant."
  done
```

### Repository Statistics

```bash
# Get contributor stats
gh api "repos/{owner}/{repo}/stats/contributors" \
  --jq '.[] | {author: .author.login, total_commits: .total, weeks: (.weeks | length)}'

# Get traffic data (requires push access)
gh api "repos/{owner}/{repo}/traffic/views" --jq '{views: .count, uniques: .uniques}'
gh api "repos/{owner}/{repo}/traffic/clones" --jq '{clones: .count, uniques: .uniques}'

# Get language breakdown
gh api "repos/{owner}/{repo}/languages"
```

### GraphQL for Complex Queries

```bash
# Get all repos in an org with their protection rules
gh api graphql -f query='
{
  organization(login: "ORG") {
    repositories(first: 100, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        name
        defaultBranchRef {
          name
          branchProtectionRule {
            requiresApprovingReviews
            requiredApprovingReviewCount
            requiresStatusChecks
            requiredStatusCheckContexts
          }
        }
      }
    }
  }
}'
```

---

## Section 11 -- Multi-Repo Management

### Apply Settings Across Multiple Repos

```bash
# Define repos to manage
REPOS=(
  "owner/repo-1"
  "owner/repo-2"
  "owner/repo-3"
)

# Apply branch protection to all repos
for repo in "${REPOS[@]}"; do
  echo "Configuring $repo..."
  gh api "repos/$repo/branches/main/protection" \
    -X PUT \
    --input protection-rules.json \
    && echo "  [OK] Branch protection set" \
    || echo "  [FAIL] Branch protection failed"
done

# Enable security features on all repos
for repo in "${REPOS[@]}"; do
  gh api "repos/$repo" -X PATCH \
    --input - <<'EOF'
{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
EOF
done
```

### Sync Labels Across Repos

```bash
# Export labels from a template repo
gh label list --repo "owner/template-repo" --json name,color,description > labels.json

# Apply to all target repos
for repo in "${REPOS[@]}"; do
  echo "Syncing labels to $repo..."
  jq -c '.[]' labels.json | while read -r label; do
    name=$(echo "$label" | jq -r '.name')
    color=$(echo "$label" | jq -r '.color')
    desc=$(echo "$label" | jq -r '.description')
    gh label create "$name" --color "$color" --description "$desc" --repo "$repo" --force
  done
done
```

### Audit All Repos at Once

```bash
# Quick audit of all your repos
gh repo list --json name,owner,defaultBranchRef,isPrivate,hasIssuesEnabled \
  --limit 100 \
  --jq '.[] | [.owner.login + "/" + .name, .defaultBranchRef.name, if .isPrivate then "private" else "public" end] | @tsv'
```

---

## Section 12 -- Standard Workflow

1. **Detect context.** Run `gh auth status` and `gh repo view` to establish the repo.
2. **Run the full audit.** Check all six areas in the hierarchy (Section 2).
3. **Produce the audit report.** Structured table with findings, severity, and fix commands.
4. **Prioritize by severity.** Address CRITICAL and HIGH first. Group fixes logically.
5. **Apply fixes.** Run `gh api` commands for settings. Generate config files for workflows/dependabot.
6. **Verify.** Re-run the audit after fixes to confirm all issues resolved.
7. **Document.** List what was changed and why. Create a summary for the repo owner.

---

## Section 13 -- Anti-Patterns

**Anti-Pattern 1: Branch Protection Without CI**
Requiring status checks that don't exist. This blocks all merges and forces disabling protection.
Fix: Set up the CI workflow FIRST, then add the status check names to branch protection.

**Anti-Pattern 2: Over-Permissive Action Permissions**
Using `permissions: write-all` or not setting permissions at all (defaults to write).
Fix: Always use least-privilege `permissions` block. Start with `contents: read` and add only what's needed.

**Anti-Pattern 3: Dependabot Without Grouping**
Ungrouped dependabot creates a PR for every single dependency update. 50+ PRs per week.
Fix: Always group minor/patch updates. Major versions stay individual for proper review.

**Anti-Pattern 4: Long-Lived Secrets in Actions**
Storing cloud provider credentials as repository secrets with no expiration.
Fix: Use OIDC workload identity federation wherever supported (GCP, AWS, Azure all support it).

**Anti-Pattern 5: Ignoring the GitHub Security Tab**
Having Dependabot alerts and code scanning alerts pile up without review.
Fix: Schedule a weekly 15-minute triage of the Security tab. Close false positives, fix real issues.

---

## Section 14 -- Edge Cases

**Edge Case 1: Organization vs Personal Repos**
Some API endpoints require org admin permissions. Branch protection rulesets (the newer API) are org-level.
Mitigation: Detect org vs personal with `gh api repos/{owner}/{repo} --jq '.owner.type'` and adjust commands accordingly.

**Edge Case 2: GitHub Free vs Pro/Team/Enterprise**
Some features (CODEOWNERS enforcement, required reviewers >1, branch protection for private repos on Free) require a paid plan.
Mitigation: Check plan with `gh api repos/{owner}/{repo} --jq '.owner.type'` and note which recommendations require a paid tier.

**Edge Case 3: Monorepo with Multiple Ecosystems**
Dependabot needs separate entries for each directory containing a manifest file.
Mitigation: Scan subdirectories for manifest files and generate dependabot entries per directory.

**Edge Case 4: Existing Branch Protection via Rulesets**
Newer repos may use repository rulesets instead of the legacy branch protection API.
Mitigation: Check both `gh api repos/{owner}/{repo}/branches/main/protection` and `gh api repos/{owner}/{repo}/rulesets` and report which system is in use.

---

## Section 15 -- Quality Gates

- [ ] `gh auth status` confirmed before any API calls
- [ ] Repository owner/name correctly detected from context
- [ ] All six audit areas checked (security, CI/CD, dependencies, settings, DX, releases)
- [ ] Audit findings classified by severity (CRITICAL/HIGH/MEDIUM/LOW)
- [ ] Branch protection appropriate for team size (solo vs team variants offered)
- [ ] All action versions pinned to full SHA, not mutable tags
- [ ] Dependabot config covers all detected ecosystems with grouping
- [ ] Security features enabled: secret scanning, push protection, code scanning
- [ ] Fixes verified by re-running relevant audit checks after applying
- [ ] No destructive operations run without explicit user confirmation

---

## Section 16 -- Failure Modes and Fallbacks

**Failure: gh CLI not authenticated**
Detection: `gh auth status` returns error.
Fallback: Guide user through `gh auth login`. Provide commands as text until auth is established.

**Failure: Insufficient permissions**
Detection: 403 from `gh api` calls.
Fallback: Identify which operations need admin access. Provide the commands for the user to run manually or escalate with their org admin.

**Failure: API rate limiting**
Detection: 429 response or `X-RateLimit-Remaining: 0` header.
Fallback: Check `gh api rate_limit` and report when limits reset. Batch remaining operations.

**Failure: Repo uses rulesets instead of branch protection**
Detection: Legacy protection API returns 404 but rulesets API returns data.
Fallback: Switch to rulesets API (`gh api repos/{owner}/{repo}/rulesets`) for all protection operations.
