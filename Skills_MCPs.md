### 1. Executive Recommendation
Based on the provided sources, the most robust and scalable pattern is the **"Canonical Core + Thin Adapter" architecture**. Do not build monolithic, provider-specific skills. Instead, adopt a hybrid approach: maintain a single, provider-agnostic source of truth for each skill (using Markdown and YAML), and use an execution/generation engine to render these skills into the specific payloads or artifacts required by platforms like Claude, Codex, or Gemini. 

While the sources offer slight variations—runtime adapter scripts versus a build-time generator—I decisively recommend combining them into an **Internal SDK/Runner**. This means your core repository acts as a centralized library of canonical instructions and JSON schemas. When invoked, a thin provider adapter translates the universal contract into the native API payload (e.g., Anthropic XML or OpenAI function calls) or generates required workspace files (e.g., `AGENTS.md`, `.claude/skills/SKILL.md`). This approach guarantees zero duplication of business logic while preserving native tool compatibility.

### 2. Target Architecture
The ideal provider-agnostic LLM skill architecture uses a strict separation of concerns, divided into three layers:

*   **Model/Provider Abstraction (The Contract):** Define a "Common LLM Interface" (CLMI) that uses a normalized internal message format (`role`, `content`, `tool_calls`). This ensures your orchestration code interacts with a unified API, completely insulated from provider volatility.
*   **Prompt and Skill Orchestration:** Store the skill intent, logic, and examples in a plain-text markdown file (`core.md`) using a templating engine (like Jinja2) for variable injection. The runner injects context and routes the payload to the appropriate adapter.
*   **Tool/Function Calling:** Define all tools strictly as standard JSON Schema files. Never hardcode provider-specific tool syntax (like OpenAI's `{ "type": "function" }`) in your core files. The adapter layer is responsible for translating the JSON schema into the provider's native tool format.
*   **Evaluation/Testing:** Implement three layers: contract compliance tests (verifying payload serialization), behavioral consistency tests (running inputs against all models and comparing to "golden traces"), and performance benchmarking.
*   **Configuration/Environment Management:** Use global configurations (`providers.yml`, `skills.yaml`) to dictate active models, rate limits, and environment variables. 
*   **Memory/State Handling & Observability:** The sources suggest maintaining execution context outside the core skill via a normalized message history, but deep state management architectures are a recognized gap in the source texts (detailed in Section 9).

### 3. Repository and Project Structure
I recommend building this as an **internal SDK/CLI package** (e.g., a monorepo package) that other projects can import or invoke. This allows the core logic to be centrally versioned while artifacts are generated seamlessly into consuming projects.

**Proposed Structure:**
```text
/skills-core-repo
├── skills/
│   ├── code-review/
│   │   ├── core.md         # Provider-neutral instructions/templates
│   │   ├── spec.yaml       # Manifest: name, inputs, capabilities, hints
│   │   └── tools/          # JSON Schema tool definitions
├── adapters/
│   ├── base.py             # Adapter interface (format_prompt, parse)
│   ├── claude.py           # Anthropic-specific formatting/parsing
│   └── chatgpt.py          # OpenAI-specific formatting/parsing
├── lib/                    # Shared, provider-neutral utility scripts
├── tests/                  # Golden traces and contract tests
├── config/                 # providers.yml, skills-registry.yaml
└── cli/                    # The runner/generator engine
```
**Why this option?** An internal SDK allows you to run `skill-runner generate --target vscode` to instantly populate a consuming project's workspace with the required `.claude/skills` symlinks or `AGENTS.md` files without duplicating the source code.

### 4. VS Code Workspace Strategy
To leverage this shared LLM core across multiple related projects in VS Code:
*   **Workspace Integration:** Do not copy skill files into each project. Instead, run the build/generation step from your CLI to emit provider-ready artifacts (`AGENTS.md` for Codex, `GEMINI.md` for Gemini, or `SKILL.md` for Claude) directly into the local project's `.claude/` or `.gemini/` hidden directories. Symlinks can also be used during local development to ensure auto-loading without duplication.
*   **Local Development & Debugging:** Use a "validation script" or dry-run feature in the CLI to send a minimal prompt to the adapter to ensure a 200 OK response from the provider before full execution.
*   **Versioning:** Treat the core skills repo as a versioned dependency. Use a configuration file in each VS Code project (e.g., `skill-overrides.yaml`) to pin specific skill versions (e.g., `code-review: 1.2.0`) so upstream updates do not silently break active project workflows.

### 5. Implementation Roadmap
Execute this build sequentially to minimize rework:

*   **Phase 1: Foundation (What to build first) [Weeks 1-2]:** Define your standardized `spec.yaml` schema, the canonical `core.md` format, and the Common LLM Interface (CLMI). Build exactly *one* thin adapter (e.g., Claude) to act as a reference.
*   **Phase 2: Pilot Refactoring [Weeks 3-4]:** Pick 2-3 high-leverage, complex skills. Extract their logic into the core format and build a second adapter (e.g., OpenAI). Prove that both adapters yield functionally identical results from the same core file.
*   **Phase 3: Automated Bulk Migration [Weeks 5-8]:** Write a migration script that parses old monolithic skills, splits them into `core.md` and `spec.yaml`, and moves provider-specific syntax into the adapter layer.
*   **Phase 4: Governance & CI/CD (What to defer until basics work) [Weeks 9+]:** Implement tiered trust verification (T1-T4), capability-based permissions, and GitHub Actions to run the full provider matrix test suite on every commit.
*   **What to avoid entirely:** Do not attempt to abstract provider-specific features that cannot be unified (e.g., Anthropic's computer use). Isolate these in an explicitly labeled `skills/legacy/` or `skills/claude-only/` directory.

### 6. Anti-Duplication and Anti-Rework Guidance
Duplication thrives when developers mix "what a skill does" with "how a tool loads it".
*   **Rule 1: Zero Provider Syntax in Core.** Never embed XML tags (`<thinking>`) or API-specific JSON inside `core.md`. Use generic markdown headings and let the adapter inject provider-specific delimiters.
*   **Rule 2: Automated JSON Schemas.** Never manually write tool schemas in your prompts. Store them as `.json` files and let adapters translate them into `functionDeclarations` (Gemini) or `tools` (Claude).
*   **Rule 3: Use Provider Hints.** If a skill requires a slight model quirk, do not fork the skill. Use a `provider_hints` block in the `spec.yaml` (e.g., `claude: { system: "Use <thinking> tags" }`) that the adapter can optionally apply.

### 7. Future-Proofing
*   **Abstraction vs. Native Features:** Abstract the message format and the tool definitions, but *do not over-abstract*. If a provider offers a massive performance boost via a proprietary feature, allow the adapter to access it via `provider_hints` so you don't lose the "magic".
*   **Technical Debt Sources:** The biggest future technical debt will come from "Monolithic Prompting" (cramming logic, routing, and formatting into one file) and "Ignoring Error Handling". Enforce a strict error response format (`errorCode`, `errorMessage`) at the adapter level so orchestration code never has to parse varied vendor errors.

### 8. Decision Framework
When adding a new capability, use this scoring rubric to determine its placement:
1.  **Can it be expressed in natural language + JSON schema?** Yes (Score 2), No (Score 0).
2.  **Does it require unique formatting tweaks?** No (Score 2), Yes but optional (Score 1), Yes and mandatory (Score 0).
3.  **Does it rely on a unique provider capability?** No (Score 2), Yes (Score 0).

*   **Score 5-6:** Unify. Build it purely in the `core.md` + `spec.yaml`.
*   **Score 3-4:** Shim. Keep the logic shared but write a thin condition in the provider adapter to handle the quirk.
*   **Score 0-2:** Isolate. It belongs as a tool-specific implementation in a separate directory; do not force unification.

### 9. Risks, Assumptions, and Gaps
*   **Risk:** "Interface compatibility is not portability." Identical prompts may yield wildly varying reasoning capabilities across models.
*   **Assumption:** It is assumed that the shared core runner has sufficient filesystem access to generate and symlink files locally for VS Code workspace integrations.
*   **Gap - State/Memory Management:** The sources heavily focus on prompt logic, metadata, and tool abstraction. However, there is a distinct gap regarding how complex *state, memory, or multi-turn conversational history* should be unified beyond simply declaring a "normalized message format". The sources note Gemini's memory model and Claude's `{CLAUDE_SESSION_ID}`, but fail to define a robust caching or state-management architecture. You will need to design an external database or robust session-state adapter independent of this specific source text.

### 10. Final Output

#### Recommended Architecture Summary
A "Canonical Core + Thin Adapter" system. Skills are defined in plain Markdown and YAML (`core.md`, `spec.yaml`) with tools in JSON Schema. An internal SDK/CLI parses this universal standard and routes it through provider-specific Python/JS adapters to standardize LLM API calls or generate workspace artifacts.

#### Proposed Workspace Structure
```text
/enterprise-workspace (Monorepo)
├── /packages/llm-skill-core    # The portable shared architecture (see Section 3)
├── /apps/web-frontend          # Implements via CLI: `skill-runner generate`
└── /apps/backend-api           # Integrates via SDK: `adapter.complete(core_prompt)`
```

#### 30/60/90-Day Implementation Plan
*   **30 Days:** Establish `spec.yaml` schemas, build the `BaseAdapter` interface, and refactor 1 pilot skill (e.g., Code Review) for Claude and OpenAI.
*   **60 Days:** Automate the migration of the top 20% of existing skills. Integrate the internal SDK into your primary VS Code projects using symlinks and generated `AGENTS.md` artifacts.
*   **90 Days:** Enforce tiered security testing (T1-T4), batch migrate the long-tail of remaining skills, and add CI/CD regression tests ("golden traces") to prevent model drift.

#### Top 10 Design Principles
1.  **Separate "what" from "how":** Core logic is universal; execution is provider-specific.
2.  **No provider syntax in core files:** Exclude proprietary XML/JSON from `core.md`.
3.  **JSON Schema for all tools:** Let adapters translate generic schema to native tool definitions.
4.  **Enforce a strict CLMI contract:** Standardize all inputs and API responses internally.
5.  **Use provider hints for model "magic":** Don't over-abstract; utilize `provider_hints` to access unique features safely.
6.  **Progressive disclosure:** Keep metadata light in `spec.yaml`; load context files only on demand.
7.  **Generate, don't duplicate:** Compile artifacts for VS Code/CLI tools via a build step.
8.  **Automate testing:** Test contract compliance, semantic consistency, and performance in CI.
9.  **Apply least privilege:** Enforce a capability-based permission model for all skills.
10. **Version everything:** Semantic versioning must apply to both skills and the core runner.