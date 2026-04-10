# TASK-0040: `templates/hooks/session-stop.sh` 実装

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0040 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0035 |
| 見積     | 20m |

## 責務

セッション終了時に変更ファイル情報を `.sage/metrics/sessions.jsonl` に JSON 行として追記する Stop hook スクリプトを実装する。

## 入力

- git diff で検出された変更ファイル一覧
- JSON schema: `{"timestamp":"ISO8601","files_changed":N,"files":["path1","path2"]}`
- `.sage/metrics/` 不在時は自動作成
- プロファイル要件: minimal+

## 出力

- 作成: `templates/hooks/session-stop.sh`
- 追記: `.sage/metrics/sessions.jsonl`

## File Scope（変更許可範囲）

- 作成: `templates/hooks/session-stop.sh`
- 変更: `.sage/metrics/sessions.jsonl`（追記）

## 禁止事項

- 他の hook スクリプトを触らない

## 完了条件

- [ ] AC-05: `sessions.jsonl` に JSON 行 1 行が追加される
- [ ] `.sage/metrics/` 不在時に自動作成される

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
