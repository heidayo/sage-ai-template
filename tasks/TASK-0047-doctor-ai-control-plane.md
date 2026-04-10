# TASK-0047: sage-doctor.sh に AI Control Plane セキュリティチェック追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0047 |
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0046 |
| 見積     | 30m |

## 責務

sage-doctor.sh に AI Control Plane のセキュリティチェック（シークレット検出、権限チェック、hook 安全性チェック）を追加する。

## 入力

- SPEC-0004 の AI Control Plane 監査要件
- TASK-0046 で作成済みの sage-doctor.sh

## 出力

- AI Control Plane チェックが追加された scripts/sage-doctor.sh

## File Scope（変更許可範囲）

- 変更: scripts/sage-doctor.sh

## 禁止事項

- ファイル存在チェック部分を変更しない
- 整合性チェック部分を変更しない

## 完了条件

- [ ] シークレット検出チェックが実行され、検出時に WARN が出力される
- [ ] settings.json の権限チェックが実行され、不適切な権限時に FAIL が出力される
- [ ] hook スクリプトの安全性チェックが実行される

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
