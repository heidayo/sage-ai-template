# TASK-0200: docs/codex-rules.md 新設 + README 参照追記

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0200 |
| SPEC-ID   | SPEC-0029 |
| PLAN-ID   | PLAN-0029 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0199 と並列可 — File Scope は互いに素。generator 側 docs 配布経路は TASK-0199 が担当） |
| 依存TASK  | TASK-0198 |
| 見積     | 1h |

## 責務

Codex rules の優先順位・読み込み手順を公式文書化する `docs/codex-rules.md`（日本語）を新設し、README から参照する（SPEC-0029 T3 / FR-06 / OPS-01 / AC-09）。

## 入力

- SPEC-0029（FR-06, SEC-04, OPS-01, ASM-02）
- 必須 4 節: (a) 優先順位規約「`.codex/rules/` > ルート `AGENTS.md`」（矛盾時は `.codex/rules/` 側に従い paired-update で解消）、(b) Codex config（AGENTS.md 参照機構）前提の読み込み手順（参照追記の実施は Codex follow-up と明記）、(c) `.claude/rules/` との対応表（5 ファイル 1:1、SHARED / CLI-specific 区分）、(d) `.codex/rules/local/` overlay の使い方（SPEC-0025 参照）
- doc 冒頭に「本文書は SPEC-0029 で新設。以後の本文修正は Codex 側 task（SPEC-0023 boundary）」を明記
- 既存導入先向け移行案内（プロジェクト固有ルールは `.codex/rules/local/` へ — 境界ケース1）と guidance（非 runtime enforcement）の明記（SEC-04）

## 出力

- `docs/codex-rules.md`（新規）
- `README.md`（`docs/codex-rules.md` への参照追記のみ）

## File Scope（変更許可範囲）

- 作成: `docs/codex-rules.md`
- 変更: `README.md`（参照追記のみ）
- 削除: なし

## 禁止事項

- `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` の編集（SPEC-0022/0023 boundary、AC-12）
- `templates/rules/` / `.claude/rules/` / `sage/` / `CLAUDE.md` / 本リポジトリの `.sage/config.yaml` の変更
- `install.sh` の手動編集、`scripts/generator/` の変更（generator 側は TASK-0199 の File Scope）
- secret / token / API key / `.env` 例値の混入（SEC-04）
- README への参照追記を超える変更（AP-03）

## 完了条件

- [ ] `test -f docs/codex-rules.md && grep -qF '.codex/rules/' docs/codex-rules.md && grep -qF 'AGENTS.md' docs/codex-rules.md && grep -qF '.claude/rules/' docs/codex-rules.md && grep -qF '.codex/rules/local/' docs/codex-rules.md` が exit 0（AC-09 前半）
- [ ] `grep -qF 'docs/codex-rules.md' README.md` が exit 0（AC-09 後半）
- [ ] doc 冒頭に SPEC-0029 新設・以後 Codex 側 task の帰属記載がある

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
