
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

Auto-update rules:
- Update check failure → warning only, never block development
- `installer_url` not configured → skip silently

Project-specific rules: add your own files to `.claude/rules/` (do not edit `specs-rules.md` etc. — they are overwritten on update).

Directory: `specs/` (what) | `plans/` (how) | `tasks/` (work units) | `sage/` (governance)
<!-- === End SAGE === -->
