# SAGE Development System — AI Agent Guidance

> [!IMPORTANT]
> **これはテンプレートです。clone 直後は未レビューで信頼してはいけません。**
> このリポジトリの `.claude/settings.json`, `.mcp.json`, `templates/hooks/`, `CLAUDE.md`, `AGENTS.md` は AI agent の権限・実行・記憶に影響します。フォーク元の検証なしに全幅信頼すると、Check Point CVE-2025-59536 / NVD CVE-2026-33068 と同質の supply chain 攻撃面になり得ます。
> **This is a template. Do not trust on first clone without review** — settings, hooks, and instruction files affect AI agent behavior. See [SECURITY.md](SECURITY.md) and [sage/governance.md §9 Scope Boundary](sage/governance.md) before adoption.

## 1. Project Overview

This repository follows the **SAGE Development System** (Spec-driven, Agent-governed, Guard-railed, Evolving).

SAGE is not a tool for making AI write better code.
SAGE is a development system that makes it hard for AI to deviate — by designing specifications, roles, structure, and verification first.

Core principle: **Specifications are the single source of truth. Code is an artifact, not the truth.**

## 2. Instruction Priority

For **Claude Code sessions**, follow instructions in this order:

1. **CLAUDE.md** (this file) — highest authority for Claude Code
2. **sage/governance.md** — lifecycle, agent roles, principles
3. **docs/rules.md** — architectural constraints
4. **User instructions** — runtime directives

`AGENTS.md` is the Codex-specific counterpart. The two documents must stay semantically aligned.

### 2.1 Claude Code specificity

SAGE の `templates/hooks/` (block-dangerous-commands.sh / protect-sage-files.sh 他) は Claude Code の `PreToolUse` / `PostToolUse` 機構で実行されます。Claude Code 利用時は `.claude/settings.json` の `hooks` セクション + profile (`hooks.profile` in `.sage/config.yaml`) で有効化されます。**Codex セッションではこれらの hook は直接動作しません** — Codex 側の対応設定は [AGENTS.md §2.1 Codex specificity](AGENTS.md) を参照。

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
- [ ] Gate 2 (functional) coverage meets threshold in .sage/config.yaml (default 80%). Configure via `project_checks.test_command`
- [ ] Gate 3 (security) secret scan + dependency vuln scan passed
- [ ] Gate 4 (architecture) layer boundary + traceability check passed (FAIL on violation, not WARN)
- [ ] Gate 5 (release) Gate 1-4 prerequisite check passed (for main/production PRs)
- [ ] Review Agent has completed review (spec alignment, responsibility alignment, complexity, safety)
- [ ] Gate status: PASS(✅) / FAIL(❌) / SKIPPED(⏭️) — configure checks in `.sage/config.yaml` `project_checks`

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

### Minimum agent configuration (solo developer + Claude Code)

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
| `CLAUDE.md` | Human only |
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

Before merge, all 5 gates must pass (or be SKIPPED if unconfigured):

| Gate | Checks | Status |
|------|--------|--------|
| 1. Structural | lint, format, type check, schema validation | PASS/FAIL/SKIPPED (config-driven) |
| 2. Functional | unit test, integration test, coverage threshold | PASS/FAIL/SKIPPED (config-driven) |
| 3. Security | SAST, secret scan, dependency vulnerability scan | PASS/FAIL |
| 4. Architecture | layer boundary, forbidden dependency, traceability | PASS/FAIL (enforcement, not WARN) |
| 5. Release | migration safety, rollback readiness, Gate 1-4 prerequisite | PASS/FAIL |

Gate 1-2: configure commands in `.sage/config.yaml` `project_checks`. Unconfigured = SKIPPED.
Gate results are automatically recorded as PR comments with 3-state display (✅/❌/⏭️).

## 9.1 Claude Code Hooks

Runtime protection via `.claude/settings.json` hooks:

| Hook | Blocks | Profile |
|------|--------|---------|
| block-dangerous-commands | `--no-verify`, `--force`, `rm -rf` | standard+ |
| protect-sage-files | CLAUDE.md, sage/, .sage/config.yaml changes | standard+ |
| check-file-scope | TASK File Scope outside edits | standard(warn) / strict(block) |
| session-start | (info) RUN logs, active TASKs, failures summary | minimal+ |
| session-stop | (record) session metrics to .sage/metrics/ | minimal+ |
| mcp-allowlist-audit | drift / supply-chain pin / OAuth callback (Phase 5, audit-only) | standard+ |
| agent-inventory-validator | RUN log declared-vs-observed runtime drift (Phase 5+, validator-only) | minimal+ |
| runlog-index | SQLite FTS5 indexer for RUN log + audit events (Phase 5+, SPEC-0016) | minimal+ |

Phase 5+: MCP allowlist audit (SPEC-0015) + agent identity inventory (SPEC-0017) + RUN log SQLite-FTS (SPEC-0016) — search via `bash scripts/sage-runlog-search.sh --task-id TASK-XXXX`.

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
- On `promote/*`: Retro-SPEC must exist and be approved. Use `/sage-promote` to set up.

To promote explore code to production: `/sage-promote` or `bash scripts/sage-promote.sh vibe/<name>`

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

This file (`CLAUDE.md`) defines repository-wide development rules.

- AI agents MUST NOT modify this file unless explicitly instructed by a human
- Changes must be intentional and reviewed carefully
- This file is the highest-authority instruction source for Claude Code agents

<!-- === SAGE Development System (auto-injected) === -->
## SAGE Development System

- Before writing code on the standard lane, check `specs/` for an existing SPEC. No SPEC = no code.
- Only modify files listed in the active TASK's File Scope.
- Every commit must include a TASK-ID (enforced by pre-commit hook).
- Prototypes go on `vibe/*` branches (no SPEC needed). To promote to main: `/sage-promote` or `bash scripts/sage-promote.sh vibe/<name>`.
- Development lanes: explore (`vibe/*`, no gates) | lite (`fix/*` / `chore/*` / `docs/*`, TASK-ID + max 3 files + no contract changes + Gate 1+3) | standard (`feature/*`, full SPEC + Gate 1-4) | promotion (`promote/*`, Retro-SPEC + TASK-ID + Gate 1-4).
- `vibe/*` → `main` direct merge is prohibited. Use `promote/*` with Retro-SPEC.
- For detailed workflows: `/sage-spec`, `/sage-plan`, `/sage-review`, `/sage-evaluate`
- SPEC/PLAN completion triggers auto-scoring (100 points required before implementation).
- Governance docs in `sage/` — do not modify without human approval.
- Run `bash scripts/sage-update-check.sh` at session start (1日1回).
- CI Gates enforce quality with 3-state: PASS(✅) / FAIL(❌) / SKIPPED(⏭️). Configure in `.sage/config.yaml` `project_checks`.
- Claude Code hooks provide runtime protection: dangerous command block, SAGE file protection, File Scope check.
- Hook profile in `.sage/config.yaml` `hooks.profile`: minimal(Phase A) / standard(Phase B) / strict(Phase C+).
- Health check: `make doctor` | Repair: `make repair` | Metrics: `make report`

Auto-update rules:
- Update check failure → warning only, never block development
- `installer_url` not configured → skip silently

Project-specific rules: add your own files to `.claude/rules/` (do not edit `specs-rules.md` etc. — they are overwritten on update).

Directory: `specs/` (what) | `plans/` (how) | `tasks/` (work units) | `sage/` (governance) | `templates/hooks/` (runtime guards)
<!-- === End SAGE === -->
