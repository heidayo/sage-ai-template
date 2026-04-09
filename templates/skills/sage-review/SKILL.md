---
name: sage-review
description: "Review code changes against SAGE spec and quality gates"
---

# SAGE Code Review Workflow

## When to use
After implementation. Must be in a SEPARATE session from implementation.

## Review checklist (in order)

### 1. Spec Alignment
- Does the code match the SPEC's acceptance criteria?
- Are there changes not covered by the SPEC? (= Silent Scope Expansion)

### 2. Scope Compliance
- Do changes stay within the TASK's File Scope?
- Flag any files modified that are not in the TASK definition

### 3. Responsibility Alignment
- Single responsibility per TASK maintained?
- Layer boundaries respected?

### 4. Complexity
- Unnecessary abstractions or over-engineering?
- Could the same result be achieved more simply?

### 5. Test Adequacy
- Normal, boundary, and error cases covered?
- Coverage above threshold (default 80% per .sage/config.yaml)?

### 6. Safety
- No hardcoded secrets or credentials
- Input validation at system boundaries
- Dependencies up to date and secure

### 7. Code Quality
コードが「動く」だけでなく「読みやすく保守しやすい」かを確認:
- **変更の意図性**: 各変更ブロックにTASK目的との対応があるか。目的を説明できない追加・変更がないか
- **既存コードとの一貫性**: 同ファイル内の既存パターンと異なる記法・命名がある場合、改善の理由が説明できるか
- **インターフェース設計**: 関数の引数設計に一貫性があるか（同種の値が引数と外部依存に分散していないか）
- **セルフレビュー遵守**: src-rules の「Code readability and maintainability」が実際に守られているか

## Quality gates to verify
| Gate | Checks |
|------|--------|
| 1. Structural | lint, format, type check |
| 2. Functional | tests pass, coverage >= threshold |
| 3. Security | secret scan, dependency vuln scan |
| 4. Architecture | layer boundary, traceability (SPEC->PLAN->TASK->commit) |
| 5. Release | migration safety, rollback readiness |

## Anti-patterns to flag
Reference: `sage/anti-patterns.md`
- Vibe Merge: PR merged without gate pass
- Big Bang Prompt: single commit >20 files without TASK-ID
- Silent Scope Expansion: changes outside File Scope
- Invisible Development: no TASK-ID in commits

## Rules
- This review MUST be in a separate session from implementation
- Never approve changes that fail quality gates
- Never approve changes outside TASK's File Scope
- Flag new anti-patterns for `sage/anti-patterns.md`

## After review
レビューで新しい品質問題パターンを発見した場合、`sage/failures.md` に症状/原因/対策/検出層の4項目で追記すること。

## File scope for this skill
- Read: all files
- Write: review comments only (no code modifications)
