# TASK-0175: CLAUDE.md テンプレートへの local overlay 読み込み規約追記（01-templates.sh）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0175 |
| SPEC-ID   | SPEC-0025 |
| PLAN-ID   | PLAN-0025 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0174 / TASK-0176 と並列可） |
| 依存TASK  | TASK-0171, TASK-0172 |
| 見積     | 1h |

## 責務

CLAUDE.md テンプレート（SAGE managed セクション、`scripts/generator/01-templates.sh` 内）に overlay ディレクトリの存在と読み込み規約（「`.claude/rules/local/*.md` はプロジェクト固有ルールとして managed rules と同順位で参照する」）を generator 経由で追記する。

## 入力

- SPEC-0025（FR-05, AC-10, ASM-02）
- `scripts/generator/01-templates.sh`（CLAUDE.md managed セクション生成部）
- `upsert_sage_section()` の既存マーカー方式（`scripts/generator/07-installer-main.sh`）— managed セクション内への追記であることの確認

## 出力

- 変更済み `scripts/generator/01-templates.sh`（SAGE managed セクションに overlay 読み込み規約を出力）

※ `install.sh` 再生成 + `SHA256SUMS` 更新は TASK-0177 に直列化（本 TASK では行わない）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/01-templates.sh`
- 削除: なし

## 禁止事項

- このリポジトリ自身の `CLAUDE.md` の直接編集（CLAUDE.md は Human-only — 変更は generator テンプレート経由のみ）
- overlay 読み込みの runtime enforcement（hook 追加等）の実装（SPEC スコープ外）
- `install.sh` / `SHA256SUMS` の編集（再生成は TASK-0177 の責務）
- `AGENTS.md` / `docs/codex-*.md` / `sage/` 配下の編集
- 他 TASK 責務（rules 注記 = TASK-0174、README = TASK-0176）の取り込み（AP-02 Big Bang）
- File Scope 外の変更（AP-03 Silent Scope Expansion）
- TASK-ID なしコミット（AP-05）

## 完了条件

- [ ] `scripts/generator/01-templates.sh` の CLAUDE.md managed セクション出力に `rules/local/` 読み込み規約が含まれる（`grep -q 'rules/local/' scripts/generator/01-templates.sh`。clean install での AC-10 検証は TASK-0177 再生成後、TASK-0173 の `claude_md_convention` ケースで機械検証）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（非破壊）

※ `shasum -a 256 -c SHA256SUMS`（AC-06）の PASS は TASK-0177 の完了条件

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0025-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | - |
| 完了     | - |
| 結果     | - |
| Gate結果  | - |
