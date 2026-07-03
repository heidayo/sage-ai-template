# TASK-0203: PR 本文への follow-up 追記案起草（AGENTS.md / CLAUDE.md §9.1）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0203 |
| SPEC-ID   | SPEC-0029 |
| PLAN-ID   | PLAN-0029 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0202 と並列可） |
| 依存TASK  | TASK-0201 |
| 見積     | 30m |

## 責務

PR 本文に「AGENTS.md 追記案（Codex follow-up）」と「CLAUDE.md §9.1 追記案（Human follow-up）」を起草・記載する（SPEC-0029 T6 / FR-09 / AC-12 部分）。対象ファイル本体は一切編集しない。

## 入力

- SPEC-0029（FR-09, AC-12, リスク4/5, 関連ID の follow-up 記述）
- AGENTS.md 追記案: `.codex/rules/` 参照の追加位置・文言（ルート `AGENTS.md` または `.codex/AGENTS.md` からの参照手順、`docs/codex-rules.md` の読み込み規約と整合）— Codex 側 task として起票する差分提案テキスト
- CLAUDE.md §9.1 追記案: 「Codex rules layer (SPEC-0029) — installer が `.codex/rules/` を配布、詳細: docs/codex-rules.md」相当（Human がマージ後に追記）
- PR 本文には SPEC-0029 / PLAN-0029 / TASK-0198〜0203 も記載（traceability）

## 出力

- PR 本文（GitHub PR body）のみ。リポジトリ内ファイルの変更なし

## File Scope（変更許可範囲）

- 作成: なし
- 変更: なし（PR body のみ）
- 削除: なし

## 禁止事項

- **`AGENTS.md` / `CLAUDE.md` 本体への追記**（追記案は PR 本文のみ、FR-09 / Human-only / Codex boundary）
- `docs/codex-delegation-packet.md` / `docs/codex-security.md` の編集（SPEC-0022/0023 boundary、AC-12）
- `templates/rules/` / `.claude/rules/` / `sage/` / 本リポジトリの `.sage/config.yaml` の変更
- `install.sh` の手動編集
- リポジトリ内ファイルへの一切の変更（AP-03）

## 完了条件

- [ ] `gh pr view --json body -q .body | grep -qF 'AGENTS.md 追記案' && gh pr view --json body -q .body | grep -qF 'CLAUDE.md §9.1 追記案'` が exit 0（AC-12 部分, case: followup_drafts_in_pr）
- [ ] `git diff --name-only main | grep -E '^(AGENTS\.md|docs/codex-delegation-packet\.md|docs/codex-security\.md|templates/rules/|\.claude/rules/)'` が exit 非0（AC-12 boundary）
- [ ] PR 本文に SPEC-0029 / PLAN-0029 / TASK-ID が記載されている

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
