# TASK-0037: `templates/hooks/protect-sage-files.sh` 実装

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0037 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0035 |
| 見積     | 30m |

## 責務

SAGE 管理ファイル（CLAUDE.md, sage/*, .sage/config.yaml, .claude/settings.json）への編集を検出し、sage-managed TASK でない場合にブロックする PreToolUse hook スクリプトを実装する。

## 入力

- stdin: JSON（tool_name, tool_input）
- 保護対象: `CLAUDE.md`, `sage/*`, `.sage/config.yaml`, `.claude/settings.json`
- TASK 判定: `tasks/` 内の .md ファイルで `sage-managed: true` を含むアクティブ TASK があれば exit 0
- プロファイル要件: standard+

## 出力

- 作成: `templates/hooks/protect-sage-files.sh`

## File Scope（変更許可範囲）

- 作成: `templates/hooks/protect-sage-files.sh`

## 禁止事項

- 他の hook スクリプトを触らない

## 完了条件

- [ ] AC-03: CLAUDE.md 編集で exit 2 が返る
- [ ] AC-03: sage-managed TASK 時は exit 0 が返る

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
