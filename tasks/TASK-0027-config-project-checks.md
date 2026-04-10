# TASK-0027: `.sage/config.yaml` に `project_checks` セクション追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0027 |
| SPEC-ID   | SPEC-0002 |
| PLAN-ID   | PLAN-0002 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 15m |

## 責務

`.sage/config.yaml` に `project_checks` セクションを追加し、各 Gate が参照する lint / test / coverage コマンドを config 駆動で定義可能にする。

## 入力

- SPEC-0002 の AC-01〜AC-08（Gate Enforcement 要件）
- 既存の `.sage/config.yaml` の構造

## 出力

- 変更済み `.sage/config.yaml`（`project_checks` セクション追加済み）

## File Scope（変更許可範囲）

- 変更: `.sage/config.yaml`

## 禁止事項

- `workflows/` を触らない
- `scripts/` を触らない

## 完了条件

- [ ] `yq '.project_checks' .sage/config.yaml` が有効なYAMLを返す

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
