# TASK-0146: AGENTS.md + agents snippet Codex-only guidance

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0146 |
| SPEC-ID   | SPEC-0022 |
| PLAN-ID   | PLAN-0022 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0145 |
| 見積     | 30m |

## 責務

Codex セッションが曖昧な依頼で実装を開始しないよう、`AGENTS.md` と `templates/agents-md-snippet.md` に短い Codex-only guidance を追加する。

## 入力

- SPEC-0022
- `docs/codex-delegation-packet.md`

## 出力

- `AGENTS.md` 既存節内の短い bullet 追加
- `templates/agents-md-snippet.md` の Codex Delegation Packet 追加

## File Scope（変更許可範囲）

- 変更: `AGENTS.md`
- 変更: `templates/agents-md-snippet.md`

## 禁止事項

- `CLAUDE.md` を変更しない
- AGENTS.md に新規 H2/H3 heading を追加しない
- SAGE lifecycle を短絡する文言を入れない

## 完了条件

- [x] `AGENTS.md` に Codex-only guidance が入っている
- [x] `templates/agents-md-snippet.md` に新規導入先向け guidance が入っている
- [x] `bash scripts/sage-doc-drift.sh` が PASS
