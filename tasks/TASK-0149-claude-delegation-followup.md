# TASK-0149: Claude-side delegation alignment follow-up

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0149 |
| SPEC-ID   | SPEC-0022 |
| PLAN-ID   | PLAN-0022 |
| ステータス | Pending |
| 担当Agent | Claude Code |
| 並列可否  | Yes |
| 依存TASK  | TASK-0145, TASK-0146 |
| 見積     | 45m |

## 責務

Codex 側で追加した delegation packet doctrine に対し、Claude Code 側で必要な意味的整合性を別タスクとして確認・反映する。

## 入力

- `docs/codex-delegation-packet.md`
- `AGENTS.md`
- `templates/agents-md-snippet.md`
- Claude Review finding: AGENTS / CLAUDE semantic alignment follow-up

## 出力

- Claude 側で必要と判断した follow-up PR または SPEC
- `CLAUDE.md` / `templates/claude-md-snippet.md` / `.claude/` の更新案（必要な場合のみ）

## File Scope（変更許可範囲）

- 本 Codex PR では作成のみ: `tasks/TASK-0149-claude-delegation-followup.md`
- Claude 側 follow-up では、Claude Code が別 SPEC/TASK で File Scope を再定義する

## 禁止事項

- 本 Codex PR で `CLAUDE.md` / `templates/claude-md-snippet.md` / `.claude/` を編集しない
- Codex 側の delegation packet を Claude 固有 hooks / slash commands の設計に暗黙拡張しない

## 完了条件

- [ ] Claude Code 側で、`AGENTS.md` と `CLAUDE.md` の意味的整合性を確認する
- [ ] 必要なら Claude 側 SPEC/TASK を作成する
- [ ] Claude 固有ファイルを更新する場合は、別 PR または明示された Claude 側 task で扱う
