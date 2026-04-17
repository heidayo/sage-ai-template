# TASK-0086: .DS_Store の untrack と再追加ブロック

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0086 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-E |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (他 Track PR のノイズ防止のため最先行単独マージ) |
| 依存TASK  | none |
| 見積     | 0.5h |

## 責務

`.gitignore` に記載済みだが tracked のままになっている `.DS_Store` を untrack し、`git add -f .DS_Store` による再追加を hook でブロックする。

## 入力

- 現状: `.DS_Store` が repository root に tracked 状態で存在 (`git ls-files | grep DS_Store` が `.DS_Store` を返す)
- `.gitignore` には `.DS_Store` が既に記載されている (L15 付近)
- block-dangerous-commands.sh の PreToolUse Bash hook は既に稼働中

## 出力

- `.DS_Store` が tracked から除外された状態 (ファイル自体は local に残る)
- `git add -f .DS_Store` が hook で block される動作
- git log に TASK-0086 を含むコミットが追加される

## File Scope（変更許可範囲）

- 作成: なし
- 変更:
  - `templates/hooks/block-dangerous-commands.sh` (`.DS_Store` force-add パターン追加のみ)
- 削除:
  - `.DS_Store` (git index から `git rm --cached`、local file は残す)

## 禁止事項

- `.claude/hooks/` 直接編集禁止 (`templates/hooks/` をソースオブトゥルースとするが、install.sh 再生成までは .claude/ 側との drift が一時的に発生。TASK-0078 (install.sh 再現性 CI) で検知されるため、本 TASK 単独では install.sh 再生成までは行わない)
- `.gitignore` 変更禁止 (既に `.DS_Store` が記載済み、追加変更不要)
- 他 Track の変更混入禁止 (本 TASK は `.DS_Store` 単独対応のみ、File Scope 外の変更は silent scope expansion)

## 完了条件

- [ ] `git ls-files | grep -c DS_Store` が 0
- [ ] local の `.DS_Store` ファイルは残っていても git 管理下に入らない (`git status` で tracked として現れない)
- [ ] `templates/hooks/block-dangerous-commands.sh` に `git add -f .DS_Store` (および `.DS_Store` に関する force-add の一般形) を検出するパターンが追加されている
- [ ] PreToolUse hook の standalone テスト: `echo '{"tool_name":"Bash","tool_input":{"command":"git add -f .DS_Store"}}' | bash templates/hooks/block-dangerous-commands.sh` の exit code が 2
- [ ] 通常のコマンド (`ls`, `git status` 等) は block されない (誤検知なし)
- [ ] コミットメッセージに `TASK-0086` を含む

## Done Definition（ラウンド単位）

参照: (初回のため done-def ファイルは本 TASK では作成せず、PLAN-0008-E 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
