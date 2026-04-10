# TASK-0049: scripts/sage-repair.sh 実装

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0049 |
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes (with TASK-0047) |
| 依存TASK  | TASK-0046 |
| 見積     | 45m |

## 責務

sage-repair.sh を新規作成し、doctor で検出された欠損ファイルの復元機能を実装する。

## 入力

- SPEC-0004 の repair 要件
- TASK-0046 で作成済みの sage-doctor.sh の出力形式

## 出力

- 作成済み scripts/sage-repair.sh

## File Scope（変更許可範囲）

- 作成: scripts/sage-repair.sh

## 禁止事項

- scripts/sage-doctor.sh の変更

## 完了条件

- [ ] `--dry-run` オプション実行時にファイル変更が発生しない
- [ ] 通常実行で欠損ファイルが復元される
- [ ] `--yes` オプションで確認プロンプトがスキップされる

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
