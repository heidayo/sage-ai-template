# TASK-0085: AGENTS.md / CLAUDE.md 双子文書 drift の埋め戻し

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0085 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-E |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 0.5h |

## 責務

CLAUDE.md ↔ AGENTS.md の「semantically aligned」を宣言どおりに復元する。現在発生している片方欠落の 3 節を対称化する:

1. `AGENTS.md` に Section 4.1 Recommended Workflow: Harness を追加 (CLAUDE.md には存在)
2. `AGENTS.md` に Section 9.1 Hooks を追加 (CLAUDE.md には存在)、Codex 経由では発火しないことを注記
3. `CLAUDE.md` に Sub-agent invocation pattern を追加 (AGENTS.md には存在)

## 入力

- CLAUDE.md Section 4.1 (L91-103): Harness 記述
- CLAUDE.md Section 9.1 (L196-209): hooks プロファイル表
- AGENTS.md Section 6 Sub-agent invocation pattern (L138-148)

## 出力

- 両文書の共通節 (4.1 / 6 Sub-agent pattern / 9.1) が対称
- 次回 TASK-0077 (drift 検知 CI) 実装後、この 3 節の非対称が FAIL 原因にならない

## File Scope（変更許可範囲）

- 作成: なし
- 変更:
  - `AGENTS.md` (Section 4.1 および 9.1 の追加のみ)
  - `CLAUDE.md` (Sub-agent invocation pattern 節の追加のみ)
- 削除: なし

## 禁止事項

- Section 9 本文の同期 (本 TASK は 9.1 の **追加** のみ、既存 Section 9 の表フォーマット統一は対象外)
- Auto-injected SAGE section の変更禁止 (これは installer が注入する部分、手編集するとドリフトが installer ドリフトに転化)
- `.claude/` / `.codex/` 側ファイルの編集禁止

## 完了条件

- [ ] `AGENTS.md` に `### 4.1 Recommended Workflow: Harness` 節が存在する
- [ ] `AGENTS.md` に `## 9.1 Hooks` 節が存在する (Codex 注記付き)
- [ ] `CLAUDE.md` に `### Sub-agent invocation pattern` 節が Section 6 内に存在する
- [ ] `diff <(grep -E "^#+" CLAUDE.md) <(grep -E "^#+" AGENTS.md)` の差分が「Claude Code ↔ Codex の名称差」「Section 9 の本文差」「Auto-injected section の記述差」に限定される
- [ ] コミットメッセージに `TASK-0085` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-E 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
