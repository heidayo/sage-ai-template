# TASK-0036: `templates/hooks/block-dangerous-commands.sh` 実装

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0036 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0035 |
| 見積     | 30m |

## 責務

危険なコマンド（`--no-verify`, `--force`（git push コンテキスト）, `rm -rf /`, `rm -rf ~`, `rm -rf .`）を検出してブロックする PreToolUse hook スクリプトを実装する。

## 入力

- stdin: JSON `{"tool_name":"Bash","tool_input":{"command":"..."}}`
- SPEC-0003 AC-02, AC-07 の要件
- 検出パターン: `--no-verify`, `--force`（git push コンテキスト）, `rm -rf /`, `rm -rf ~`, `rm -rf .`
- jq 不在時は grep フォールバック
- パースエラー時 exit 0
- プロファイル要件: standard+

## 出力

- 作成: `templates/hooks/block-dangerous-commands.sh`

## File Scope（変更許可範囲）

- 作成: `templates/hooks/block-dangerous-commands.sh`

## 禁止事項

- 他の hook スクリプトを触らない
- `settings.json` を触らない
- `config.yaml` を触らない

## 完了条件

- [ ] AC-02: `--no-verify` を含むコマンドで exit 2 が返る
- [ ] AC-07: 空入力で exit 0 が返る
- [ ] jq 不在時に grep フォールバックで正常動作する
- [ ] パースエラー時に exit 0 が返る

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
