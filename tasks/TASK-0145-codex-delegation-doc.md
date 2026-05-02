# TASK-0145: Codex Delegation Packet doc

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0145 |
| SPEC-ID   | SPEC-0022 |
| PLAN-ID   | PLAN-0022 |
| ステータス | Done |
| 担当Agent | Spec / Planning |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 45m |

## 責務

Codex に渡す委任入力の標準形を `docs/codex-delegation-packet.md` として定義する。

## 入力

- SPEC-0022
- Notion research summary: Codex = delegation / Claude Code = collaboration
- OpenAI Codex AGENTS.md / App / Cloud official docs

## 出力

- `docs/codex-delegation-packet.md`

## File Scope（変更許可範囲）

- 作成: `docs/codex-delegation-packet.md`
- 変更: なし
- 削除: なし

## 禁止事項

- `CLAUDE.md` を変更しない
- Claude Code 固有の Plan Mode / hooks / memory 設計を本タスクで扱わない
- モデル価格やベンチマーク値を固定値として運用ルール化しない

## 完了条件

- [x] doc が Goal / Scope / Non-goals / Constraints / Acceptance Criteria / Tests / File Scope / Human Review を含む
- [x] Codex が実装前に不足情報を検出する基準が明記されている
- [x] セキュリティ review 欄がある
