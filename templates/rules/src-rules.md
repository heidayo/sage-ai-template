---
description: "SAGE rules for source code implementation"
globs: ["src/**", "app/**", "lib/**", "components/**", "packages/**"]
---
# Implementation Rules

When writing or modifying source code:

## Before coding
- Confirm a SPEC and TASK exist for this change
- Check the TASK's File Scope — only modify listed files
- Include TASK-ID in every commit message (e.g., `TASK-0001: add endpoint`)

## Forbidden shortcuts
- TODO/FIXME in committed code
- Type assertions (`as unknown as T`) without explicit approval
- Bypassing quality gates (including force push)
- Changes outside assigned File Scope
- Silent scope expansion (adding unspecified changes)

## Error resolution protocol
When an error occurs:
1. Record the error with TASK-ID in the run log
2. Check `sage/anti-patterns.md` for known patterns
3. If new pattern, add to `sage/failures.md` before fixing
4. If same error occurs 3 times, escalate to `sage/anti-patterns.md`

Error context (always include these 6 elements):
1. Error log: complete stack trace
2. Failing file: path and line number
3. Related spec: SPEC-ID and relevant acceptance criteria
4. Recent changes: git diff output
5. Fix scope: files allowed to modify
6. Completion criteria: test pass/fail

## Error resolution prohibitions
| Prohibited | Required |
|-----------|----------|
| Suppress types with `any` | Fix the type mismatch properly |
| Modify tests to make them pass | Fix implementation to pass existing tests |
| Adjust code to absorb spec drift | Update spec first, then fix implementation |
| Swallow errors with try/catch | Log the error, then re-throw |
