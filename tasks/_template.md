# TASK-XXXX: [タイトル]

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-XXXX |
| SPEC-ID   | SPEC-XXXX（必須） |
| PLAN-ID   | PLAN-XXXX（必須） |
| ステータス | Pending / In Progress / Review / Done |
| 担当Agent | Implementation / Test / Security / Review |
| 並列可否  | Yes / No |
| 依存TASK  | TASK-YYYY / none |
| 見積     | [時間] |

## 責務

このタスクが担う単一責務。1文で記述。

## 入力

必要な仕様や前提条件。

## 出力

期待される成果物（ファイルパス、テスト結果等）。

## File Scope（変更許可範囲）

- 作成: [パス]
- 変更: [パス]
- 削除: [パス]

## 禁止事項

触ってはいけない範囲・やってはいけないこと。

## 完了条件

コマンドベースで検証可能な条件を1件以上。

- [ ] `make test` が全件パスする
- [ ] [具体的な完了判定]

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-XXXX-round-N.md`（実装開始前に作成）

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
