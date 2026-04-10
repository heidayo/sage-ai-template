# TASK-0046: scripts/sage-doctor.sh 実装（ファイル存在＋整合性チェック）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0046 |
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0045 |
| 見積     | 45m |

## 責務

sage-doctor.sh を新規作成し、ファイル存在チェックと SHA256 整合性チェックを実装する。

## 入力

- SPEC-0004 の doctor 要件
- TASK-0045 で生成される install-state.yaml

## 出力

- 作成済み scripts/sage-doctor.sh

## File Scope（変更許可範囲）

- 作成: scripts/sage-doctor.sh

## 禁止事項

- 他スクリプトの変更

## 完了条件

- [ ] `make doctor` でファイル存在チェックが実行される
- [ ] `make doctor` で SHA256 整合性チェックが実行される
- [ ] 正常時に exit 0 かつ "ALL CHECKS PASSED" が出力される

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
