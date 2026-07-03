---
description: "SAGE rules for creating implementation plans (Codex guidance)"
globs: ["plans/**"]
---
# Plan Rules

Guidance for Codex sessions — follow as written; SAGE does not enforce these at runtime in Codex.

When creating or editing files in plans/:

## Required fields
- PLAN-ID: linked to a SPEC-ID
- Affected layers: list all (controller/usecase/domain/infrastructure etc.)
- Impact scope: identified by feature/module
- Risks: at least 1 raised
- Verification: specify required methods (unit/integration/e2e/security)

## Exit criteria checklist
- [ ] PLAN-ID linked to SPEC-ID
- [ ] Affected layers listed
- [ ] Impact scope identified
- [ ] 1+ risk raised
- [ ] Verification methods specified

## Prohibited
- Creating a plan without an approved SPEC
- Starting implementation without an approved plan

## Template
Use `plans/_template.md` as the base.
