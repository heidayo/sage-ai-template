# TASK-0198: templates/codex-rules/ 5 ファイル新設

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0198 |
| SPEC-ID   | SPEC-0029 |
| PLAN-ID   | PLAN-0029 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（先頭 TASK、依存なし） |
| 依存TASK  | none |
| 見積     | 1h |

## 責務

`templates/rules/` の installer 配布対象 5 rules（harness-rules.md 除外）と意味的に同一な Codex 向けテンプレート 5 ファイルを `templates/codex-rules/` に新設する（SPEC-0029 T1 / FR-01 / AC-01）。

## 入力

- SPEC-0029（FR-01, NFR-03, SEC-04, INV-06）
- 起点: `templates/rules/{specs,plans,tasks,src,sage-governance}-rules.md`
- 置換方針: Claude Code 固有記述（hooks による runtime 強制、`/sage-*` slash command 等）→ Codex 文脈（guidance 遵守 + Codex Delegation Packet 参照）。Codex rules は runtime enforcement ではなく guidance であることを src-rules 相当ファイルに明記（SEC-04 / SPEC-0022 SEC-03 整合）。ルールの追加・削除は禁止（semantic 同一）

## 出力

- `templates/codex-rules/specs-rules.md`
- `templates/codex-rules/plans-rules.md`
- `templates/codex-rules/tasks-rules.md`
- `templates/codex-rules/src-rules.md`
- `templates/codex-rules/sage-governance-rules.md`

## File Scope（変更許可範囲）

- 作成: `templates/codex-rules/specs-rules.md`, `templates/codex-rules/plans-rules.md`, `templates/codex-rules/tasks-rules.md`, `templates/codex-rules/src-rules.md`, `templates/codex-rules/sage-governance-rules.md`
- 変更: なし
- 削除: なし

## 禁止事項

- `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` の編集（SPEC-0022/0023 boundary、AC-12）
- `templates/rules/` / `.claude/rules/` / `sage/` / `CLAUDE.md` / 本リポジトリの `.sage/config.yaml` の変更
- `install.sh` の手動編集
- ルール内容の実質改訂（新ルール追加・既存ルール強化）— 意味的ミラーのみ
- secret / token / API key / `.env` 例値の混入（SEC-04）
- File Scope 外の変更（AP-03）

## 完了条件

- [ ] `diff <(ls templates/rules/ | grep -v '^harness-rules.md$') <(ls templates/codex-rules/)` が exit 0（AC-01）
- [ ] 各ファイルに導入先ファイル内容の転記がない（静的テンプレートのみ、SEC-01）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0029-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に採番） |
| 開始     | - |
| 完了     | - |
| 結果     | - |
| Gate結果  | - |
