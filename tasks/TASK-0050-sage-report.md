# TASK-0050: scripts/sage-report.sh 実装

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0050 |
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0048 |
| 見積     | 30m |

## 責務

sage-report.sh を新規作成し、doctor-history.jsonl からセッション数・FAIL 数を集計してヘルスステータスを判定する。

## 入力

- SPEC-0004 の report 要件
- TASK-0048 で記録される .sage/metrics/doctor-history.jsonl のフォーマット

## 出力

- 作成済み scripts/sage-report.sh

## File Scope（変更許可範囲）

- 作成: scripts/sage-report.sh

## 禁止事項

- 他スクリプトの変更

## 完了条件

- [ ] SESSIONS 数と FAIL 数が集計される
- [ ] HEALTHY / WARN / INSUFFICIENT DATA の判定が正しく行われる
- [ ] 14 日間 FAIL 0 件の場合に "READY FOR STRICT" と出力される

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0004-round-1.md`

Done Definition は SPEC 単位・ラウンド単位で作成する。
テンプレート: `templates/done-definition-template.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | RUN-XXXX（実行時に自動採番） |
| 開始     | YYYY-MM-DD HH:MM |
| 完了     | YYYY-MM-DD HH:MM |
| 結果     | Pass / Fail |
| Gate結果  | structural: ○ / functional: ○ / security: ○ |
