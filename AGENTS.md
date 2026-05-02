# SAGE Development System — AI Agent Guidance

> [!IMPORTANT]
> **これはテンプレートです。clone 直後は未レビューで信頼してはいけません。**
> このリポジトリの `.codex/config.toml`, `.mcp.json`, `templates/hooks/`, `AGENTS.md`, `CLAUDE.md` は AI agent の権限・実行・記憶に影響します。Codex CLI 0.23.0 未満では `.env` の `CODEX_HOME` 経由で project-local config 経由 RCE (CVE-2025-61260) や branch name injection (BeyondTrust 報告) も成立し得ます。
> **This is a template. Do not trust on first clone without review** — Codex sandbox / approval / network is enforced by Codex itself, not by SAGE. See [SECURITY.md](SECURITY.md) and [sage/governance.md §9 Scope Boundary](sage/governance.md) before adoption.

## 1. Project Overview

This repository follows the **SAGE Development System** (Spec-driven, Agent-governed, Guard-railed, Evolving).

SAGE is not a tool for making AI write better code.
SAGE is a development system that makes it hard for AI to deviate — by designing specifications, roles, structure, and verification first.

Core principle: **Specifications are the single source of truth. Code is an artifact, not the truth.**

## 2. Instruction Priority

For **Codex sessions**, follow instructions in this order:

1. **AGENTS.md** (this file) — highest authority for Codex
2. **sage/governance.md** — lifecycle, agent roles, principles
3. **docs/rules.md** — architectural constraints
4. **User instructions** — runtime directives

`CLAUDE.md` is the Claude Code-specific counterpart. The two documents must stay semantically aligned.

### 2.1 Codex specificity

SAGE の `templates/hooks/` は Claude Code の `PreToolUse`/`PostToolUse` 機構で実行されます。**Codex セッションでは hook は直接動作しません**。Codex 側では本体機能で以下を別途構築してください:

- **Codex CLI** (`~/.codex/config.toml`): `sandbox_mode = "workspace-write"` + `approval_policy = "on-request"` を base とし、network 遮断は `[sandbox_workspace_write]` table の `network_access = false` で設定 ([Codex config reference](https://developers.openai.com/codex/config-reference))
- **Codex Cloud / web**: agent phase の internet access は環境単位で管理され既定 off ([Codex cloud internet access](https://developers.openai.com/codex/cloud/internet-access))
- `.env` 経由の `CODEX_HOME` 書き換えは Codex CLI 0.23.0+ で防止 ([CVE-2025-61260](https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/))
- branch name / PR title / issue body は untrusted input として扱う ([BeyondTrust 報告](https://www.beyondtrust.com/blog/entry/openai-codex-command-injection-vulnerability-github-token))
- 詳細は [SECURITY.md §3](SECURITY.md) と [sage/governance.md §9](sage/governance.md) を参照
- **Codex 利用者向け詳細ガイド**: [docs/codex-security.md](docs/codex-security.md) (config.toml 推奨設定 / Codex Cloud / CODEX_HOME 対策 / codex-action hardening / IR 手順)

SAGE が提供する Codex 向け価値は: SPEC/PLAN/TASK lifecycle / File Scope / anti-pattern 学習枠組み / AGENTS.md ルール — **runtime enforcement ではなく仕様駆動の構造設計**。

## 3. SAGE Lifecycle Protocol

All changes MUST follow this 7-phase lifecycle. Skipping phases is prohibited.

**Specify → Plan → Slice → Execute → Verify → Merge → Observe**

### Specify phase exit criteria
- [ ] SPEC-ID is assigned
- [ ] Background and purpose are described (at least one sentence)
- [ ] Scope (included) is listed as bullet points
- [ ] Out-of-scope is explicitly stated ("none" is not acceptable — consciously describe exclusions)
- [ ] At least 3 acceptance criteria, each verifiable by command or test
- [ ] At least 1 error case is defined
- [ ] Security requirements are stated (if "not applicable", provide reason)

### Plan phase exit criteria
- [ ] PLAN-ID is linked to a SPEC-ID
- [ ] Affected layers (controller/usecase/domain/infrastructure etc.) are listed
- [ ] Impact scope is identified by feature/module
- [ ] At least 1 risk is raised
- [ ] Required verification (unit/integration/e2e/security) is specified

### Slice phase exit criteria
- [ ] All TASKs have TASK-IDs assigned
- [ ] Each TASK has a single responsibility (does not span multiple layers or purposes)
- [ ] Dependencies are explicit (dependency graph or dependent TASK-ID list)
- [ ] Parallel feasibility is evaluated per TASK
- [ ] Each TASK has completion criteria

### Execute phase exit criteria
- [ ] TASK-ID is included in commit messages
- [ ] Changes stay within the TASK's permitted File Scope
- [ ] Gate 1 (structural: lint + format + type check) passed

### Verify phase exit criteria
- [ ] Gate 2 (functional) coverage meets threshold in .sage/config.yaml (default 80%)
- [ ] Gate 3 (security) secret scan + dependency vuln scan passed
- [ ] Gate 4 (architecture) layer boundary + traceability check passed (FAIL on violation, not WARN)
- [ ] Gate 5 (release) Gate 1-4 prerequisite check passed for main/production PRs
- [ ] Review Agent has completed review (spec alignment, responsibility alignment, complexity, safety)

### Merge phase exit criteria
- [ ] All Gates (1-5) passed or SKIPPED (Gate 5 is conditional for main/production PRs)
- [ ] All review comments resolved
- [ ] SPEC-ID, PLAN-ID, TASK-ID are in the PR body
- [ ] Run log (RUN-ID) is recorded in .sage/runs/

### Observe phase exit criteria
- [ ] Post-deploy monitoring is set up (if applicable)
- [ ] Failures are recorded in sage/failures.md
- [ ] New anti-patterns (if detected) are added to sage/anti-patterns.md

## 4. Forbidden Shortcuts

AI agents MUST NOT:

- Leave TODO/FIXME in committed code
- Use type assertions (e.g., `as unknown as T`) without explicit approval
- Bypass quality gates for merge (including force push)
- Create PRs without a SPEC-ID
- Skip tests
- Manually edit generated code
- Implement features without a spec
- Make changes outside assigned File Scope
- Perform silent scope expansion (adding unspecified changes)
- Combine multiple responsibilities in a single task

### 4.1 Recommended Workflow: Harness

For autonomous development across the full lifecycle, use the harness orchestrator:

```
/sage-harness
[requirements description]
```

This automatically chains Specify → Plan → Execute → Verify with feedback loops.
See `templates/skills/sage-harness/SKILL.md` for details.

Harness-specific forbidden shortcuts are defined in `templates/rules/harness-rules.md`.

## 5. Error Resolution Protocol

When an error occurs:

1. Record the error with TASK-ID in the run log
2. Check `sage/anti-patterns.md` for known patterns
3. If it's a new pattern, add an entry to `sage/failures.md` before committing the fix
4. If the same error occurs 3 times, escalate it to `sage/anti-patterns.md`

Do not retry blindly. Diagnose first.

### Error Context Template

When requesting error resolution, always include these 6 elements:

1. **Error log**: Complete stack trace
2. **Failing file**: File path and line number
3. **Related spec**: SPEC-ID and relevant acceptance criteria
4. **Recent changes**: git diff output
5. **Fix scope**: Files allowed to modify (everything else is off-limits)
6. **Completion criteria**: Defined by test Pass/Fail

### Error Resolution Prohibitions

| Prohibited | Required |
|-----------|----------|
| Suppress types with `any` (e.g., `as unknown as T`) | Fix the type mismatch properly |
| Modify tests to make them pass | Fix implementation to pass existing tests |
| Adjust code to absorb spec drift | Update the spec first, then fix implementation |
| Swallow errors with try/catch and no logging | Log the error, then re-throw |

## 6. Agent Constraints

### Minimum agent configuration (solo developer + Codex)

| Agent Role | Session | Notes |
|------------|---------|-------|
| Spec / Planning / TaskSlicing | Session A | Can be one session |
| Implementation | Session B | Must be separate from review |
| Review / Test | Session C | Must be separate from implementation |
| Security | CI | Automated via quality gates |

### Separation rules

- The same agent MUST NOT hold both implementation and final approval
- The same agent MUST NOT hold both implementation and security approval
- The same agent MUST NOT hold both implementation and production deployment decision

### Sub-agent invocation pattern

When using Claude Code's Agent tool for role separation:

- Pass file paths (not file contents) to sub-agents; let them Read internally
- Always include SPEC/PLAN/TASK file paths and File Scope in the prompt
- Never combine implementation and review in the same Agent tool call
- Include previous Verify feedback in re-execution prompts

See `docs/development-flow.md` "サブエージェント呼び出しパターン" for concrete examples.
See `templates/skills/sage-harness/SKILL.md` for the automated harness workflow.

## 7. File Scope Rules

| Directory | Permitted Agent |
|-----------|----------------|
| `specs/`, `plans/`, `tasks/` | Spec / Planning Agent |
| `src/` | Implementation Agent |
| `tests/` | Test Agent |
| `sage/` | Human only (or with explicit approval) |
| `.github/workflows/` | Operations Agent + human approval |
| `AGENTS.md` | Human only |
| `.sage/runs/` | Any agent (append only) |

Agents MUST NOT modify files outside their permitted scope.

## 8. Traceability Requirements

Every change must be traceable through the full chain:

```
SPEC-ID → PLAN-ID → TASK-ID → AGENT-ID → RUN-ID → MERGE-ID
```

- All PRs must include SPEC-ID, PLAN-ID, and TASK-ID in the body
- All commit messages must include TASK-ID
- All agent executions must be logged with RUN-ID in `.sage/runs/`

PRs without SPEC-ID should be rejected.

## 9. Quality Gate Checklist

Before merge, all 5 gates must pass:

| Gate | Checks |
|------|--------|
| 1. Structural | lint, format, type check, schema validation |
| 2. Functional | unit test, integration test, coverage threshold |
| 3. Security | SAST, secret scan, dependency vulnerability scan |
| 4. Architecture | layer boundary, forbidden dependency, traceability |
| 5. Release | migration safety, rollback readiness, monitoring readiness |

Gate results are automatically recorded as PR comments.

## 9.1 Hooks

Runtime protection via `.claude/settings.json` hooks. These hooks fire only
under Claude Code; Codex sessions are expected to honor the same rules via
prompt-level guidance (this document) rather than runtime interception.

| Hook | Blocks | Profile |
|------|--------|---------|
| block-dangerous-commands | `--no-verify`, `--force`, `rm -rf` | standard+ |
| protect-sage-files | AGENTS.md, sage/, .sage/config.yaml changes | standard+ |
| check-file-scope | TASK File Scope outside edits | standard(warn) / strict(block) |
| session-start | (info) RUN logs, active TASKs, failures summary | minimal+ |
| session-stop | (record) session metrics to .sage/metrics/ | minimal+ |
| mcp-allowlist-audit | drift / supply-chain pin / OAuth callback (Phase 5, audit-only) | standard+ |
| agent-inventory-validator | RUN log declared-vs-observed runtime drift (Phase 5+, validator-only) | minimal+ |

Phase 5+: MCP allowlist audit (SPEC-0015) + agent identity inventory (SPEC-0017) — declarative registry + RUN log runtime drift detection.

Profile in `.sage/config.yaml` `hooks.profile`: minimal → standard → strict → none.
Health check: `make doctor` | Repair: `make repair` | Metrics: `make report`

## 10. Language Rules

| Context | Language |
|---------|----------|
| User-facing documentation | Japanese |
| Code, comments, variable names | English |
| Commit messages | English |
| PR descriptions | Japanese |
| Test case names | Japanese |
| Agent reasoning (internal) | Any |

## Development Lanes

Lane is auto-detected from branch name. Follow the lane rules:

| Lane | Branch | SPEC needed? | TASK-ID needed? | Gates |
|------|--------|-------------|----------------|-------|
| 🟢 explore | `vibe/*` | No | No | None |
| 🟡 lite | `fix/*` `chore/*` `docs/*` | No | Yes | Gate 1+3 |
| 🔵 standard | `feature/*` others | Yes | Yes | Gate 1-4 |
| 🔴 promotion | `promote/*` | Retro-SPEC | Yes | Gate 1-4 |

**Lane-specific behavior for AI agents:**
- On `vibe/*`: Skip the Pre-Implementation Checklist. Write code freely. No SPEC or TASK-ID required.
- On `fix/*`, `chore/*`, `docs/*`: TASK-ID required in commits. SPEC not required. Max 3 files, no contract changes.
- On `feature/*` or other branches: Full SAGE lifecycle required (see checklist below).
- On `promote/*`: Retro-SPEC must exist and be approved. Use `bash scripts/sage-promote.sh vibe/<name>`.

## Pre-Implementation Checklist

**Applies to standard lane only** (`feature/*` and other non-explore/lite branches).

Before writing any code, confirm:

- [ ] A SPEC exists for this change
- [ ] A PLAN exists linking to the SPEC
- [ ] A TASK exists with clear scope and completion criteria
- [ ] File Scope is defined and understood
- [ ] No existing implementation already covers this requirement

## Anti-Pattern Quick Reference

| Anti-Pattern | Signal |
|-------------|--------|
| Vibe Merge | PR merged without quality gate pass |
| Big Bang Prompt | Single commit touching >20 files without TASK-ID |
| Silent Scope Expansion | Changes to files outside TASK File Scope |
| AI Monolith | One agent holding spec + implementation + review + test |
| Invisible Development | No RUN-ID, no TASK-ID in commits |
| Human-Only Guard | Rules exist only in documentation, not enforced by CI |

## Protected Documentation

This file (`AGENTS.md`) defines repository-wide development rules.

- AI agents MUST NOT modify this file unless explicitly instructed by a human
- Changes must be intentional and reviewed carefully
- This file is the highest-authority instruction source for Codex-based agents

<!-- === SAGE Development System (auto-injected) === -->
# SAGE Workflow

- Check `specs/` before writing code on the standard lane. No SPEC = no code.
- Create SPECs using `specs/_template.md`. Minimum: scope, out-of-scope, 3 acceptance criteria.
- Create tasks in `tasks/` with explicit File Scope (which files you may modify).
- Only modify files in the TASK's File Scope.
- Every commit must include a TASK-ID (e.g., `TASK-0001: add login endpoint`).
- Prototypes go on `vibe/*` branches (no SPEC needed). To promote to main: `bash scripts/sage-promote.sh vibe/<name>`.
- Development lanes: explore (`vibe/*`, no gates) | lite (`fix/*` / `chore/*` / `docs/*`, TASK-ID + max 3 files + no contract changes + Gate 1+3) | standard (`feature/*`, full SPEC + Gate 1-4) | promotion (`promote/*`, Retro-SPEC + TASK-ID + Gate 1-4).
- `vibe/*` → `main` direct merge is prohibited. Use `promote/*` with Retro-SPEC.
- Do not modify `sage/` without human approval.

Prohibited:
- Implementing without a SPEC
- Modifying files outside TASK's File Scope
- Leaving TODO/FIXME in committed code
- Skipping tests
- Using `--no-verify`, `--force`, `rm -rf` (blocked by hooks)

CI Gates: PASS(✅) / FAIL(❌) / SKIPPED(⏭️). Configure in `.sage/config.yaml` `project_checks`.
Hooks: block-dangerous-commands, protect-sage-files, check-file-scope, session-start, session-stop.
Health: `make doctor` | `make repair` | `make report`

Directory: `specs/` (what) | `plans/` (how) | `tasks/` (work units) | `sage/` (governance) | `templates/hooks/` (guards)
<!-- === End SAGE === -->
