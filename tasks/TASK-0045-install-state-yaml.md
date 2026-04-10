# TASK-0045: install.sh / generate-installer.sh に install-state.yaml 生成ロジック追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0045 |
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 45m |

## 責務

generate-installer.sh にインストール状態を記録する install-state.yaml 生成ロジックを追加する。

## 入力

- SPEC-0004 のインストールライフサイクル要件
- 既存の scripts/generate-installer.sh の構造

## 出力

- 変更済み scripts/generate-installer.sh
- install.sh 実行後に生成される .sage/install-state.yaml

## File Scope（変更許可範囲）

- 変更: scripts/generate-installer.sh

## 禁止事項

- 既存の install ステップのロジック変更
- generate-installer.sh 以外のスクリプト変更

## 完了条件

- [ ] install.sh 実行後に .sage/install-state.yaml が生成される
- [ ] yq で version フィールドが読み取れる
- [ ] yq で files フィールドが読み取れる

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
