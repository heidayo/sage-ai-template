
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
- Claude collaboration brief: reference `docs/claude-collaboration-brief.md` for engagement patterns; well-scoped tasks may be delegated to Codex via packet.
- Claude-only boundary: do not edit Codex-specific files (`AGENTS.md`, `docs/codex-*.md`) unless human explicitly assigns. Record as Codex follow-up otherwise.
- Properties section is required for new SPECs (system/platform). See `sage/governance.md` §11.
- Review uses 3-gate FP filter (Dead Code / Trust Boundary / Scope Check).

Auto-update rules:
- Update check failure → warning only, never block development
- `installer_url` not configured → skip silently

Project-specific rules: put your own files in `.claude/rules/local/` — the installer never creates, overwrites, or deletes this directory (SPEC-0025 local overlay). Read `.claude/rules/local/*.md` as project-specific rules with the same precedence as managed rules. Do not edit managed rules (`specs-rules.md` etc.) — they are replaced entirely on update.

Template update backs up modified files to `.sage/backup/<timestamp>/` (3 generations). Restore: `cp .sage/backup/<ts>/<file> <file>`. Preview changes first with `bash install.sh --diff` (SPEC-0026).

Directory: `specs/` (what) | `plans/` (how) | `tasks/` (work units) | `sage/` (governance) | `templates/hooks/` (runtime guards)
<!-- === End SAGE === -->
