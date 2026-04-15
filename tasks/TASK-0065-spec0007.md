# TASK-0065: src-rules同期（テンプレート＋ランタイム）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0065 |
| SPEC-ID   | SPEC-0007 |
| PLAN-ID   | PLAN-0007 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0064 |
| 見積     | 15m |

## 責務

src-rules同期（テンプレート＋ランタイム）

## 入力

- SPEC: specs/SPEC-0007-ai-code-risk-mitigation.md
- PLAN: plans/PLAN-0007-ai-code-risk-mitigation.md

## 出力

変更対象ファイルの更新。

## File Scope（変更許可範囲）

- 変更: templates/rules/src-rules.md
- 変更: .claude/rules/src-rules.md

## 禁止事項

- File Scope外のファイル変更
- 既存ゲートの動作変更（TASK-0068: opt-inのみ許可）

## 完了条件

- [x] 変更ファイルがFile Scope内に収まっている
- [x] make validate が PASS

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | - |
| 開始     | 2026-04-15 |
| 完了     | 2026-04-15 |
| 結果     | Pass |
| Gate結果  | structural: ○ / security: ○ |
