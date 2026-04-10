# TASK-0044: SPEC-0003 の全 AC 検証

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0044 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Test |
| 並列可否  | No |
| 依存TASK  | TASK-0043 |
| 見積     | 30m |

## 責務

SPEC-0003 の全 AC（AC-01〜AC-08）を検証コマンドで網羅的に検証する。

## 入力

- SPEC-0003 の AC-01〜AC-08 定義
- TASK-0035〜TASK-0043 の全成果物

## 出力

- 検証結果レポート（変更なし、ReadOnly）

## File Scope（変更許可範囲）

- 変更なし（ReadOnly）

## 禁止事項

- コードを修正しない

## 完了条件

- [ ] AC-01〜AC-08 すべてが検証済み
- [ ] 検証コマンド: `echo JSON | bash hook` で exit code 確認
- [ ] `jq` で `settings.json` の hook 定義確認
- [ ] `sessions.jsonl` の JSON 行確認

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
