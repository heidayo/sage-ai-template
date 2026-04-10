# TASK-0051: scripts/sage-validate.sh に [7/8] AI Control Plane チェック追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0051 |
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0047 |
| 見積     | 20m |

## 責務

sage-validate.sh に AI Control Plane セクションのチェックを追加する。

## 入力

- SPEC-0004 の validate 拡張要件
- TASK-0047 で実装された AI Control Plane チェックロジック
- 既存の scripts/sage-validate.sh の構造

## 出力

- AI Control Plane チェックが追加された scripts/sage-validate.sh

## File Scope（変更許可範囲）

- 変更: scripts/sage-validate.sh

## 禁止事項

- 既存 [1/6]〜[6/6] のロジック変更しない（番号変更のみ許可）

## 完了条件

- [ ] `make validate` の出力に AI Control Plane セクションが含まれる
- [ ] 既存チェックを含め ALL PASSED が維持される

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
