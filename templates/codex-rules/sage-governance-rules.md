---
description: "SAGE governance protection rules (Codex guidance)"
globs: ["sage/**", "CLAUDE.md", "AGENTS.md"]
---
# Governance Rules

Guidance for Codex sessions — follow as written; SAGE does not enforce these at runtime in Codex.

## Protected files
- `sage/` directory: human approval required for any modification
- `AGENTS.md`: human-only (AI must not modify without explicit instruction)
- `CLAUDE.md`: same as AGENTS.md

## Agent separation
- The same agent MUST NOT hold both implementation and final approval
- The same agent MUST NOT hold both implementation and security approval
- Implementation and review must be in separate sessions

## Traceability
Every change must be traceable: SPEC-ID → PLAN-ID → TASK-ID → commit
- All PRs must include SPEC-ID, PLAN-ID, TASK-ID in the body
- All commit messages must include TASK-ID
- PRs without SPEC-ID should be rejected

## Language rules
| Context | Language |
|---------|----------|
| User-facing documentation | Japanese |
| Code, comments, variable names | English |
| Commit messages | English |
| PR descriptions | Japanese |
| Test case names | Japanese |
