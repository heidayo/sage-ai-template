# TASK-0048: sage-doctor.sh に failures.md 候補出力 + doctor-history.jsonl 記録追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0048 |
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0047 |
| 見積     | 20m |

## 責務

sage-doctor.sh に WARN/FAIL 時の failures.md 候補出力と doctor-history.jsonl への記録追記を追加する。

## 入力

- SPEC-0004 の障害記録・履歴要件
- TASK-0047 までに実装済みの sage-doctor.sh

## 出力

- failures.md 候補出力機能と doctor-history.jsonl 記録機能が追加された scripts/sage-doctor.sh

## File Scope（変更許可範囲）

- 変更: scripts/sage-doctor.sh

## 禁止事項

- 既存チェックロジック（ファイル存在、整合性、AI Control Plane）の変更

## 完了条件

- [ ] WARN/FAIL 時に stderr に failures.md 候補テキストが出力される
- [ ] .sage/metrics/doctor-history.jsonl に実行記録が追記される

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
