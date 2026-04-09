---
name: sage-plan
description: "Create a SAGE implementation plan and task breakdown"
---

# SAGE Plan & Task Creation Workflow

## When to use
After a SPEC is approved. Creates a PLAN and breaks it into TASKs.

## Process

### Phase 1: Create Plan
1. Generate PLAN-ID: `bash scripts/sage-id-gen.sh plan`
2. Copy `plans/_template.md` to `plans/PLAN-{ID}.md`
3. Link to the source SPEC-ID
4. Identify affected architectural layers (controller/usecase/domain/infrastructure etc.)
5. Assess impact scope by feature/module
6. Raise at least 1 risk
7. Specify verification methods (unit/integration/e2e/security)

### Phase 2: Slice into Tasks
1. Generate TASK-IDs: `bash scripts/sage-id-gen.sh task` (one per task)
2. Each TASK must have:
   - Single responsibility (does not span layers or purposes)
   - Explicit File Scope (list of files allowed to modify)
   - Dependencies (list dependent TASK-IDs or "none")
   - Completion criteria (test pass/fail)
3. Evaluate parallel feasibility per task
4. Draw dependency graph if tasks > 3

### Plan exit criteria
- [ ] PLAN-ID linked to SPEC-ID
- [ ] Affected layers listed
- [ ] Impact scope identified
- [ ] 1+ risk raised
- [ ] Verification methods specified

### Slice exit criteria
- [ ] All TASKs have TASK-IDs
- [ ] Single responsibility per TASK
- [ ] File Scope explicitly listed per TASK
- [ ] Dependencies stated
- [ ] Parallel feasibility evaluated
- [ ] Completion criteria per TASK

## File scope for this skill
- Write: `plans/`, `tasks/`
- Read: `specs/`
- Forbidden: `src/`, `tests/`, `sage/`

## After completion
Automatically run `/sage-evaluate` to score the PLAN and TASKs.
The evaluate skill will loop up to 10 times, improving the documents until they reach 100 points (S++).
Only after 100 points is achieved, tell the user: "Plan and tasks ready. Implementation can begin on separate sessions."
