---
name: sage-promote
description: "Promote a vibe/* branch to production-ready code with Retro-SPEC. Use when the user says: 本番に持っていきたい, promote, 昇格, vibe から本番へ, このコードを正式にしたい"
---

# SAGE Promotion Workflow

## When to use

- User wants to move explore (vibe/*) code to production
- User says "promote", "昇格", "本番に持っていきたい", "このコードを正式にしたい"
- User is on a `vibe/*` branch and wants to merge to main

## Process

### 1. Verify current state

Check the current branch:
```bash
git rev-parse --abbrev-ref HEAD
```

If NOT on a `vibe/*` branch, ask the user which vibe branch to promote.

### 2. Run the promotion script

```bash
bash scripts/sage-promote.sh vibe/<branch-name>
```

This will:
- Create a `promote/<feature-name>` branch
- Generate a Retro-SPEC draft in `specs/`
- Assign a TASK-ID

### 3. AI-assisted Retro-SPEC completion

After the draft is generated, **read the Retro-SPEC file** and help the user fill in TBD sections:

1. Read the generated Retro-SPEC:
   ```bash
   cat specs/RETRO-SPEC-*.md
   ```

2. Read the diff to understand changes:
   ```bash
   git diff main...HEAD --stat
   git log --oneline main..HEAD
   ```

3. For each TBD section, **propose content based on the diff and commit history**:
   - **背景・目的**: Summarize what the commits accomplished
   - **スコープ外**: Infer from what was NOT changed
   - **要件**: Extract functional requirements from the actual implementation
   - **受け入れ条件**: Propose testable criteria based on the changes
   - **異常系**: Identify error handling in the code
   - **リスク**: Assess based on change scope and complexity

4. Present the completed Retro-SPEC to the user for approval.

### 4. Gate execution

After the user approves the Retro-SPEC:

1. Run structural checks (Gate 1):
   ```bash
   # Use project_checks from .sage/config.yaml if configured
   ```

2. Run validation:
   ```bash
   bash scripts/sage-validate.sh
   ```

3. Report gate results to the user.

### 5. Completion

Summarize:
- Branch: `promote/<name>`
- SPEC-ID: assigned
- TASK-ID: assigned
- Gate results: PASS/FAIL
- Next step: Create PR from `promote/<name>` → `main`

## Important rules

- NEVER merge `vibe/*` directly to `main`. Always go through `promote/*`.
- Retro-SPEC is a **draft** — the user must approve it before proceeding.
- If the vibe branch has 50+ commits, warn that Retro-SPEC accuracy may be low.
- The AI fills in TBD sections but the human has final say.

## Lane context

This skill transitions code from the **explore lane** (no governance) to the **standard lane** (full governance). The key value is that the user gets to keep their exploration velocity while ensuring production quality.
