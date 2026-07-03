---
description: "SAGE rules for task definitions (Codex guidance)"
globs: ["tasks/**"]
---
# Task Rules

Guidance for Codex sessions — follow as written; SAGE does not enforce these at runtime in Codex.

When creating or editing files in tasks/:

## Required fields
- TASK-ID: assigned via `bash scripts/sage-id-gen.sh task`
- Single responsibility: one task does one thing (no spanning layers or purposes)
- File Scope: explicit list of files allowed to modify
- Dependencies: list dependent TASK-IDs or state "none"
- Completion criteria: defined by test pass/fail

## Exit criteria checklist
- [ ] TASK-ID assigned
- [ ] Single responsibility maintained
- [ ] File Scope explicitly listed
- [ ] Dependencies stated
- [ ] Parallel feasibility evaluated
- [ ] Completion criteria defined

## Prohibited
- Combining multiple responsibilities in one task
- Omitting File Scope (every task must state which files it may touch)

## Template
Use `tasks/_template.md` as the base.
