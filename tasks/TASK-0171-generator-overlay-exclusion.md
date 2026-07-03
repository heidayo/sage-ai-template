# TASK-0171: generator overlay 除外ロジックの実装（03/07 モジュール）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0171 |
| SPEC-ID   | SPEC-0025 |
| PLAN-ID   | PLAN-0025 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No（先頭タスク。TASK-0172〜0176 が依存） |
| 依存TASK  | none |
| 見積     | 3h |

## 責務

installer generator に overlay 除外判定 `is_unmanaged_path()` を単一関数として定義し、rules 生成・install-state 生成・`--verify-checksum`・メインフローの全経路で `.claude/rules/local/**` および `.codex/rules/local/**` を作成・上書き・削除・checksum 検証の対象から除外する。

## 入力

- SPEC-0025（FR-01〜03, NFR-01〜03, SEC-01〜03, INV-01〜03, PRE-01/02, POST-01, 異常系1〜3・境界ケース1）
- `scripts/generator/07-installer-main.sh`（`upsert_sage_section()`、install-state 生成部 L697 付近、`--verify-checksum` L62/L72/L433 付近）
- `scripts/generator/03-rules.sh`

## 出力

- 変更済み `scripts/generator/07-installer-main.sh`（`is_unmanaged_path()` 定義 + 参照、`unmanaged_paths:` セクション出力、verify 除外、非ディレクトリ/symlink WARN 処理）
- 変更済み `scripts/generator/03-rules.sh`（`is_unmanaged_path()` 参照による rules 生成時の overlay 不可侵）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/07-installer-main.sh`, `scripts/generator/03-rules.sh`
- 削除: なし

## 禁止事項

- File Scope 外の変更（AP-03 Silent Scope Expansion）。特に `install.sh` / `SHA256SUMS` の再生成は TASK-0172 の責務であり本 TASK では行わない
- generator + docs + tests の一括変更（AP-02 Big Bang — docs は TASK-0174/0175/0176、tests は TASK-0173 に分離済み）
- `AGENTS.md` / `docs/codex-*.md` / `sage/` 配下 / `CLAUDE.md` の編集
- 除外判定の重複実装（INV-03 違反 — 定義は単一箇所、他は参照のみ）
- `unmanaged_paths` を書き込み許可リストとして解釈する実装（SEC-02）
- managed ファイルの checksum 検証範囲の縮小（SEC-03 / INV-02）
- `local/` ディレクトリの自動作成（SPEC: ユーザーが必要時に自分で作る）
- TASK-ID なしコミット（AP-05）

## 完了条件

- [ ] `grep -q 'is_unmanaged_path' scripts/generator/07-installer-main.sh` が成功する（SPEC T1 完了条件）
- [ ] `bash templates/hooks/tests/run-tests.sh` 既存テスト全件 PASS（SPEC T1 完了条件）
- [ ] `is_unmanaged_path` の関数定義が generator 内で1箇所のみ（`grep -c 'is_unmanaged_path()' scripts/generator/*.sh` が 1）

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
