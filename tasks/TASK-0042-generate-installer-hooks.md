# TASK-0042: `scripts/generate-installer.sh` に hook テンプレート埋め込み追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0042 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0036, TASK-0037, TASK-0038, TASK-0039, TASK-0040 |
| 見積     | 20m |

## 責務

`scripts/generate-installer.sh` に 5 つの hook テンプレートの heredoc 埋め込みを追加する。

## 入力

- TASK-0036〜TASK-0040 で作成された 5 つの hook スクリプト
- `embed_file` 関数（行 18-33）を再利用

## 出力

- 変更: `scripts/generate-installer.sh`（5 つの hook テンプレートが heredoc として出力に含まれる）

## File Scope（変更許可範囲）

- 変更: `scripts/generate-installer.sh`

## 禁止事項

- 既存の `embed_file` 呼び出しを変更しない（追加のみ）

## 完了条件

- [ ] `generate-installer.sh` 実行時に 5 つの hook テンプレートが heredoc として出力に含まれる

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
