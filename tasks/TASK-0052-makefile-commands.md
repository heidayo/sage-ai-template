# TASK-0052: makefile に doctor / repair / report コマンド追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0052 |
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0046, TASK-0049, TASK-0050 |
| 見積     | 10m |

## 責務

makefile に doctor / repair / report の 3 コマンドを追加する。

## 入力

- TASK-0046 で作成される scripts/sage-doctor.sh
- TASK-0049 で作成される scripts/sage-repair.sh
- TASK-0050 で作成される scripts/sage-report.sh

## 出力

- doctor / repair / report コマンドが追加された makefile

## File Scope（変更許可範囲）

- 変更: makefile

## 禁止事項

- 既存コマンドの変更

## 完了条件

- [ ] `make doctor` が scripts/sage-doctor.sh を正しく呼び出す
- [ ] `make repair` が scripts/sage-repair.sh を正しく呼び出す
- [ ] `make report` が scripts/sage-report.sh を正しく呼び出す

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
