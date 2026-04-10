# TASK-0041: `.claude/settings.json` に5つの hook 定義を追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0041 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0036, TASK-0037, TASK-0038, TASK-0039, TASK-0040 |
| 見積     | 15m |

## 責務

`.claude/settings.json` に 5 つの hook 定義（PreToolUse x3, SessionStart x1, Stop x1）を追加する。

## 入力

- TASK-0036〜TASK-0040 で作成された 5 つの hook スクリプトのパス
- SPEC-0003 AC-01 の要件

## 出力

- 変更: `.claude/settings.json`（5 件の hook 定義が追加された状態）

## File Scope（変更許可範囲）

- 変更: `.claude/settings.json`

## 禁止事項

- hook スクリプト自体を変更しない

## 完了条件

- [ ] AC-01: `.claude/settings.json` に 5 件の hook 定義が存在する
- [ ] PreToolUse x3, SessionStart x1, Stop x1 の構成になっている

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
