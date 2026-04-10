# TASK-0038: `templates/hooks/check-file-scope.sh` 実装

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0038 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0035 |
| 見積     | 30m |

## 責務

アクティブ TASK の File Scope を読み取り、スコープ外のファイル変更を検出して警告またはブロックする PreToolUse hook スクリプトを実装する。

## 入力

- stdin: JSON（tool_name, tool_input）
- TASK 判定: `tasks/` 内でステータス「実行中」の TASK から File Scope を読み取る
- プロファイル要件: standard（warn） / strict（block）

## 出力

- 作成: `templates/hooks/check-file-scope.sh`

## File Scope（変更許可範囲）

- 作成: `templates/hooks/check-file-scope.sh`

## 禁止事項

- 他の hook スクリプトを触らない

## 完了条件

- [ ] TASK 未検出時 "No active TASK found" で exit 0 が返る
- [ ] スコープ外のファイル変更時に warning が出力される（exit 0）
- [ ] strict モードでスコープ外のファイル変更時に exit 2 が返る

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
