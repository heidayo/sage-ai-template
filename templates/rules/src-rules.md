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

## Before starting
実装開始前に `sage/failures.md` を確認し、過去に同様のパターンで失敗していないか確認すること。

## Code readability and maintainability

コードは正しく動くだけでなく、他の開発者（人間・AI問わず）が読んで理解・保守できることを重視する。コミット前に以下を確認すること:

### Intentional changes only
- 変更ブロックごとにTASK目的との対応を説明できるか。説明できない追加・変更は削除する
- 変更対象外の行に差分が出ていないか（trailing whitespace、行末改行の変更等）

### Consistency with existing code
- 同ファイル・同モジュール内に同等の処理パターンがある場合、既存のパターン・命名・記法に合わせる
- 既存パターンと異なる書き方をする場合は、改善の理由を説明できること（既存が悪い場合は改善してよい）

### Readable intent
- 非自明な制御フロー（early return、条件分岐、例外処理）の意図がコードだけで伝わらない場合、コメントで補足する
- 関数のインターフェース設計に一貫性を持たせる（条件分岐に使う値の一部だけを引数にして残りを外部依存にしない）

### No speculative code
- 「念のため」や「将来使うかもしれない」コードを追加しない
- 追加するコードは全て、現在のTASKの完了に必要な理由を説明できること

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
