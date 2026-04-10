# TASK-0035: `.sage/config.yaml` に `hooks.profile` セクション追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0035 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 10m |

## 責務

`.sage/config.yaml` に hooks プロファイル設定セクションを追加し、各 hook の有効/無効をプロファイル単位で制御可能にする。

## 入力

- SPEC-0003 の hooks プロファイル要件（minimal / standard / strict）
- 既存の `.sage/config.yaml` の構造

## 出力

- 変更: `.sage/config.yaml`（`hooks:` および `profile:` セクションが追加された状態）

## File Scope（変更許可範囲）

- 変更: `.sage/config.yaml`

## 禁止事項

- `workflows/`, `scripts/`, `templates/` を触らない

## 完了条件

- [ ] `grep 'hooks:' .sage/config.yaml && grep 'profile:' .sage/config.yaml` が成功

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0003-round-1.md`（実装開始前に作成）

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
