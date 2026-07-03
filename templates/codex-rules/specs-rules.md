---
description: "SAGE rules for creating and editing specifications (Codex guidance)"
globs: ["specs/**"]
---
# Spec Rules

Guidance for Codex sessions — follow as written; SAGE does not enforce these at runtime in Codex.

When creating or editing files in specs/:

## Required fields (all mandatory)
- SPEC-ID: assigned via `bash scripts/sage-id-gen.sh spec`
- Background/purpose: at least one sentence explaining why
- Scope (included): bullet list of what changes
- Scope (excluded): explicit exclusions. "None" is never acceptable
- Acceptance criteria: minimum 3, each verifiable by command or test
- Error cases: minimum 1 defined
- Security requirements: stated, or reason why N/A

## Exit criteria checklist
- [ ] SPEC-ID assigned
- [ ] Background described
- [ ] Scope listed as bullets
- [ ] Out-of-scope explicitly stated
- [ ] 3+ acceptance criteria, each command-verifiable
- [ ] 1+ error case
- [ ] Security requirements stated

## Prohibited
- Approving a spec with "TBD" or "TODO" in required fields
- Skipping the out-of-scope section
- Acceptance criteria that cannot be verified by command or test

## Template
Use `specs/_template.md` as the base for all new specs.
