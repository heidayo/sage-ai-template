
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
- Codex delegation packet: follow `docs/codex-delegation-packet.md`; standard-lane tasks need Goal / Scope / Non-goals / File Scope / Acceptance Criteria / Tests before implementation.
- Codex-only boundary: do not edit Claude Code-specific files (`CLAUDE.md`, `.claude/`) unless a human explicitly assigns that scope to Codex. Record them as Claude follow-up otherwise.

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
