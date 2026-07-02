# TASK-0173: test-local-overlay.sh の追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0173 |
| SPEC-ID   | SPEC-0025 |
| PLAN-ID   | PLAN-0025 |
| ステータス | Pending |
| 担当Agent | Test |
| 並列可否  | No（TASK-0177 の再生成済み install.sh を使用） |
| 依存TASK  | TASK-0177（推移的に TASK-0172/0174/0175 を含む。テストは TASK-0177 再生成後の install.sh を対象とする） |
| 見積     | 2h |

## 責務

overlay 不可侵を検証する integration テスト `templates/hooks/tests/test-local-overlay.sh` を追加し、install / 再 install / `--dry-run` / `--verify-checksum` の全経路で overlay の内容・存在状態が不変であることを機械検証する。

## 入力

- SPEC-0025（AC-01〜04, AC-08〜10, INV-01, 異常系1〜3・境界ケース1）
- `templates/hooks/tests/_helpers.sh` と `test-installer-modularize.sh` の既存流儀（一時ディレクトリ + 生成 install.sh 実行）
- TASK-0177 で再生成済みの `install.sh`（TASK-0175 の CLAUDE.md 規約を含む — `claude_md_convention` ケース / AC-10 の前提）

## 出力

- 新規 `templates/hooks/tests/test-local-overlay.sh`（テストケース: overlay 保持 / 非作成 / install-state 宣言 / verify-checksum 非干渉 / `local_is_file` / `legacy_state` / `claude_md_convention` / 空ディレクトリ不可侵 / symlink 非追従）
- `run-tests.sh` への組み込み（既存の自動 discovery で拾われる場合は変更不要）

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-local-overlay.sh`
- 変更: `templates/hooks/tests/run-tests.sh`（テスト登録が必要な場合のみ）
- 削除: なし

## 禁止事項

- テストを通すための実装 (`scripts/generator/`, `install.sh`) の修正（AP-03 / Error Resolution Prohibitions — 実装不備は TASK-0171/0172 へ構造化フィードバックで差し戻す）
- テスト期待値の SPEC 非追跡（AP-07 — 各ケースに AC-N 参照コメントを付ける）
- 既存テストファイルの改変・削除（AC-07 非破壊）
- テスト未実行での完了報告（AP-09 Benchmark Illusion）
- File Scope 外の変更（AP-03）、複数責務の混在（AP-02）
- TASK-ID なしコミット（AP-05）

## 完了条件

- [ ] `bash templates/hooks/tests/test-local-overlay.sh` 全ケース PASS（SPEC T3 完了条件）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（AC-07）
- [ ] AC-01/02/03/04/08/09/10 の各検証コマンドに対応するテストケースが存在する（ケース名 grep で確認: `grep -E 'local_is_file|legacy_state|claude_md_convention' templates/hooks/tests/test-local-overlay.sh`）

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
