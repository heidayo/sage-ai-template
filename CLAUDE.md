# SAGE Development System — AI Agent Guidance

## 1. Project Overview

This repository follows the **SAGE Development System** (Spec-driven, Agent-governed, Guard-railed, Evolving).

SAGE is not a tool for making AI write better code.
SAGE is a development system that makes it hard for AI to deviate — by designing specifications, roles, structure, and verification first.

Core principle: **Specifications are the single source of truth. Code is an artifact, not the truth.**

## 2. Instruction Priority

Follow instructions in this order:

1. **CLAUDE.md** (this file) — highest authority
2. **sage/governance.md** — lifecycle, agent roles, principles
3. **docs/rules.md** — architectural constraints
4. **User instructions** — runtime directives

If conflicts occur, follow this priority chain. CLAUDE.md always wins.

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
- [ ] Gate 4 (architecture) layer boundary + traceability check passed
- [ ] Review Agent has completed review (spec alignment, responsibility alignment, complexity, safety)

### Merge phase exit criteria
- [ ] All Gates (1-4) passed
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

Before merge, all 5 gates must pass:

| Gate | Checks |
|------|--------|
| 1. Structural | lint, format, type check, schema validation |
| 2. Functional | unit test, integration test, coverage threshold |
| 3. Security | SAST, secret scan, dependency vulnerability scan |
| 4. Architecture | layer boundary, forbidden dependency, traceability |
| 5. Release | migration safety, rollback readiness, monitoring readiness |

Gate results are automatically recorded as PR comments.

## 10. Language Rules

| Context | Language |
|---------|----------|
| User-facing documentation | Japanese |
| Code, comments, variable names | English |
| Commit messages | English |
| PR descriptions | Japanese |
| Test case names | Japanese |
| Agent reasoning (internal) | Any |

## Pre-Implementation Checklist

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
- This file is the highest-authority instruction source for all AI agents
