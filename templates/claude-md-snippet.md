
<!-- === SAGE Development System (auto-injected) === -->
## SAGE Development System

- Before writing ANY code, check `specs/` for an existing SPEC. No SPEC = no code.
- Only modify files listed in the active TASK's File Scope.
- Every commit must include a TASK-ID (enforced by pre-commit hook).
- Prototypes go on `vibe/*` branches (no SPEC needed).
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
