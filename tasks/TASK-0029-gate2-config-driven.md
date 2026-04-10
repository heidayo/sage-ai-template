# TASK-0029: Gate 2 (`sage-functional-gate.yml`) を config 駆動に改修

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0029 |
| SPEC-ID   | SPEC-0002 |
| PLAN-ID   | PLAN-0002 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (but parallel with TASK-0028) |
| 依存TASK  | TASK-0027 |
| 見積     | 30m |

## 責務

Gate 2（functional gate）を `.sage/config.yaml` の `project_checks` を参照する config 駆動方式に改修し、echo プレースホルダーを削除して実コマンド置換する。

## 入力

- TASK-0027 で追加された `project_checks` セクションの構造
- 既存の `sage-functional-gate.yml` の内容
- SPEC-0002 の AC-01, AC-02, AC-07, AC-08

## 出力

- 変更済み `.github/workflows/sage-functional-gate.yml`

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-functional-gate.yml`

## 禁止事項

- 他の workflow を触らない
- echo プレースホルダーを残さない（削除して置換）

## 完了条件

- [ ] AC-01: config 未設定時に SKIPPED 表示
- [ ] AC-02: テスト失敗時に failure
- [ ] AC-07: config 不在で SKIP
- [ ] AC-08: YAML 不正で failure

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
