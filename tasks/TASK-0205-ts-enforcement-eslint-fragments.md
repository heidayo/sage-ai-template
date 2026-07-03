# TASK-0205: templates/ts-enforcement/ ESLint 設定断片 3 ファイル新設

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0205 |
| SPEC-ID   | SPEC-0030 |
| PLAN-ID   | PLAN-0030 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0204 と並列可 — File Scope 互いに素） |
| 依存TASK  | none |
| 見積     | 1h |

## 責務

型抑制コメント・`any` を error 化する ESLint 設定断片 3 ファイルを `templates/ts-enforcement/` に新設する（適用手順コメント付き）。

## 入力

- SPEC-0030 スコープ第 2 項・FR-06・リスク4・実装メモ（ESLint 断片の形）

## 出力

- `templates/ts-enforcement/eslint-flat.mjs` — flat config 用、`export default` の配列要素 1 つ（spread 取り込み形）。`@typescript-eslint/ban-ts-comment`=error（`ts-ignore` / `ts-nocheck` 禁止、`"ts-expect-error": "allow-with-description"`）、`@typescript-eslint/no-explicit-any`=error
- `templates/ts-enforcement/eslint-flat-transitional.mjs` — 同上だが `no-explicit-any` のみ warn（レガシー移行用）
- `templates/ts-enforcement/eslintrc-fragment.json` — legacy `.eslintrc` 用 `rules` オブジェクト断片（error バリアント。transitional への差し替え手順はコメント/README 案内）
- 各ファイル冒頭に適用手順コメント + 前提バージョン（@typescript-eslint v6+）を記載

## File Scope（変更許可範囲）

- 作成: `templates/ts-enforcement/eslint-flat.mjs`, `templates/ts-enforcement/eslint-flat-transitional.mjs`, `templates/ts-enforcement/eslintrc-fragment.json`
- 変更: なし
- 削除: なし

## 禁止事項

- `templates/project-checks/ts-pnpm.yaml` への変更（generator 埋め込み対象、AC-12 / リスク5）
- `install.sh` / `SHA256SUMS` / `scripts/generator/` への変更（AC-09）
- installer への配布組込み（scope-out — 導入は docs 記載のファイルコピー手順）
- テスト実装（TASK-0207 の Test Agent 責務）

## 完了条件

- [ ] `for f in eslint-flat.mjs eslint-flat-transitional.mjs eslintrc-fragment.json; do test -f "templates/ts-enforcement/$f" || exit 1; done` が exit 0（AC-07）
- [ ] `grep -F 'ban-ts-comment' templates/ts-enforcement/eslint-flat.mjs` が exit 0（AC-07）
- [ ] `grep -F 'no-explicit-any' templates/ts-enforcement/eslint-flat-transitional.mjs` が exit 0 で warn 指定（AC-07）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊、AC-10）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0030-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
