# TASK-0028: Gate 1 (`sage-structural-gate.yml`) を config 駆動に改修

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0028 |
| SPEC-ID   | SPEC-0002 |
| PLAN-ID   | PLAN-0002 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0027 |
| 見積     | 30m |

## 責務

Gate 1（structural gate）を `.sage/config.yaml` の `project_checks` を参照する config 駆動方式に改修し、未設定時は SKIPPED ログを出力するようにする。

## 入力

- TASK-0027 で追加された `project_checks` セクションの構造
- 既存の `sage-structural-gate.yml` の内容

## 出力

- 変更済み `.github/workflows/sage-structural-gate.yml`

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-structural-gate.yml`

## 禁止事項

- 他の workflow を触らない
- `config.yaml` を触らない
- コメントアウトされた言語別テンプレートは残す

## 完了条件

- [ ] yq で `project_checks.lint` を読み取り、未設定時は SKIPPED ログ出力
- [ ] config 駆動でコマンドが実行されること

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
