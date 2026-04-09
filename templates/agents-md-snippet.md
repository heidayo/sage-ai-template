
<!-- === SAGE Development System (auto-injected) === -->

# SAGE Workflow

This project follows the SAGE Development System.

## Before writing ANY code

1. Check `specs/` for an existing SPEC that covers the requested change
2. If no SPEC exists, ask the user to define scope and acceptance criteria, then create a SPEC in `specs/`
3. Create tasks in `tasks/` with explicit File Scope (which files you are allowed to modify)
4. Only modify files listed in the TASK's File Scope

## Commit rules

- Every commit message MUST include a TASK-ID (e.g., `TASK-0001: add login endpoint`)

## Prohibited

- Implementing features without a SPEC
- Modifying files outside TASK's File Scope
- Leaving TODO/FIXME in committed code
- Skipping tests

## Quick reference

| I want to...              | First step                              |
|---------------------------|-----------------------------------------|
| Add a new feature         | Create a SPEC in `specs/`               |
| Fix a bug                 | Find or create a SPEC, then fix         |
| Refactor code             | Create a SPEC with scope boundaries     |
| Experiment / prototype    | Use a `vibe/*` branch (no SPEC needed)  |

## Directory structure

```
specs/      → Specifications (what to build)
plans/      → Plans (how to build)
tasks/      → Tasks (individual work units with File Scope)
sage/       → Governance docs (do not modify without approval)
```

<!-- === End SAGE === -->
