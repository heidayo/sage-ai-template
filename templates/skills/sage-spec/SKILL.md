---
name: sage-spec
description: "Create a SAGE specification document with the user"
---

# SAGE Spec Creation Workflow

## When to use
When a new feature, bug fix, or refactor needs a specification.

## Process

### 1. Generate SPEC-ID
```bash
bash scripts/sage-id-gen.sh spec
```

### 2. Create spec file
Copy `specs/_template.md` to `specs/SPEC-{ID}-{short-name}.md`

### 3. Fill sections with the user
Work through each section interactively:

- **Background/purpose**: Why does this change exist?
- **Scope (included)**: What exactly changes? (bullet list)
- **Scope (excluded)**: What is NOT changing? ("None" is never acceptable)
- **Acceptance criteria**: Minimum 3, each must be verifiable by command or test
- **Error cases**: Minimum 1
- **Security requirements**: State them, or explain why N/A

### 4. Validate exit criteria
- [ ] SPEC-ID assigned
- [ ] Background described (>=1 sentence)
- [ ] Scope listed as bullets
- [ ] Out-of-scope explicitly stated
- [ ] 3+ acceptance criteria, each command-verifiable
- [ ] 1+ error case defined
- [ ] Security requirements stated

### Minimal spec example
```markdown
# SPEC-XXXX: Fix login button not responding

## Scope
- Fix click handler on LoginButton component

## Out of scope
- Login flow redesign
- Password reset

## Acceptance criteria
1. Clicking login button submits the form
2. Error message appears on invalid credentials
3. Existing tests pass
```

## File scope for this skill
- Write: `specs/`
- Read: `plans/`, `sage/governance.md`
- Forbidden: `src/`, `tests/`, `.github/`

## After completion
Automatically run `/sage-evaluate` to score the SPEC.
The evaluate skill will loop up to 10 times, improving the SPEC until it reaches 100 points (S++).
Only after 100 points is achieved, tell the user: "Spec ready. Next: create a plan with `/sage-plan`"
