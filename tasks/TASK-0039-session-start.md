# TASK-0039: `templates/hooks/session-start.sh` 実装

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0039 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0035 |
| 見積     | 30m |

## 責務

セッション開始時に最新 RUN ログ・保留 TASK・failures.md 要約を stdout に出力する SessionStart hook スクリプトを実装する。

## 入力

- `.sage/runs/` の最新 3 件の RUN ログの status, task_id, error_log 先頭行
- `tasks/` 内の in-progress / blocked の TASK 一覧
- `sage/failures.md` の最新 5 件
- プロファイル要件: minimal+

## 出力

- 作成: `templates/hooks/session-start.sh`

## File Scope（変更許可範囲）

- 作成: `templates/hooks/session-start.sh`

## 禁止事項

- 他の hook スクリプトを触らない
- `.sage/runs/` を変更しない（ReadOnly）

## 完了条件

- [ ] AC-04: exit 0 が返る
- [ ] AC-04: `.sage/runs/` が空でも正常動作する
- [ ] stdout に最新 RUN ログ・保留 TASK・failures.md 要約が出力される

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
