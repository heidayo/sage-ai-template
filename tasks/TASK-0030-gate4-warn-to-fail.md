# TASK-0030: Gate 4 (`sage-architecture-gate.yml`) を WARN → FAIL に変更

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0030 |
| SPEC-ID   | SPEC-0002 |
| PLAN-ID   | PLAN-0002 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 15m |

## 責務

Gate 4（architecture gate）のトレーサビリティ違反を WARN から FAIL に変更し、errors > 0 で exit 1 するようにする。

## 入力

- 既存の `sage-architecture-gate.yml` の内容
- SPEC-0002 の AC-03

## 出力

- 変更済み `.github/workflows/sage-architecture-gate.yml`

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-architecture-gate.yml`

## 禁止事項

- 他の workflow を触らない

## 完了条件

- [ ] AC-03: トレーサビリティ違反で failure
- [ ] errors > 0 で exit 1

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0002-round-1.md`（実装開始前に作成）

Done Definition は SPEC 単位・ラウンド単位で作成する。
テンプレート: `templates/done-definition-template.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
