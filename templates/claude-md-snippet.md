
<!-- === SAGE Development System (auto-injected) === -->

## SAGE Workflow (Auto-enforced)

This project follows the SAGE Development System. These rules apply automatically to every session.

### Before writing ANY code

1. Check `specs/` for an existing SPEC that covers the requested change
2. If no SPEC exists, create one with the user before writing code
   - Use `specs/_template.md` as the base
   - Assign a SPEC-ID (next sequential number in `specs/`)
   - Minimum required: scope, out-of-scope, 3 acceptance criteria
3. If a SPEC exists but no TASK exists, create tasks in `tasks/`
4. Only modify files listed in the TASK's File Scope

**"Just do it quickly" is not an exception.** Always confirm the spec first.

### Commit rules

- Every commit message MUST include a TASK-ID (e.g., `TASK-0001: add login endpoint`)
- Commits without TASK-ID will be rejected by pre-commit hook

### What you MUST NOT do

- Implement features without a SPEC
- Modify files outside your TASK's File Scope
- Leave TODO/FIXME in committed code
- Skip tests
- Hold both implementation and review in the same session

### Quick reference

| I want to...              | First step                              |
|---------------------------|-----------------------------------------|
| Add a new feature         | Create a SPEC in `specs/`               |
| Fix a bug                 | Find or create a SPEC, then fix         |
| Refactor code             | Create a SPEC with scope boundaries     |
| "Just a small change"     | Still needs a SPEC (can be minimal)     |
| Experiment / prototype    | Use a `vibe/*` branch (no SPEC needed)  |

### SPEC minimal example

If the change is small, the SPEC can be short:

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

### Directory structure

```
specs/      → Specifications (what to build)
plans/      → Plans (how to build)
tasks/      → Tasks (individual work units with File Scope)
sage/       → Governance docs (do not modify without approval)
.sage/      → Config and run logs
```

<!-- === End SAGE === -->
