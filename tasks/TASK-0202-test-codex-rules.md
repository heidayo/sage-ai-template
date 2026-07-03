# TASK-0202: test-codex-rules.sh 追加 + run-tests.sh 登録（Test Agent 責務）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0202 |
| SPEC-ID   | SPEC-0029 |
| PLAN-ID   | PLAN-0029 |
| ステータス | Pending |
| 担当Agent | **Test Agent（Implementation Agent とは別セッションで実行、AP-04 回避）** |
| 並列可否  | Yes（TASK-0203 と並列可） |
| 依存TASK  | TASK-0201 |
| 見積     | 2h |

## 責務

`.codex/rules/` 配布の integration テスト `templates/hooks/tests/test-codex-rules.sh` を追加し、run-tests.sh に登録する（SPEC-0029 T5 / AC-01〜09, AC-11）。

## 入力

- SPEC-0029 テストスコープ（(1) 配布 marker、(2) semantic pairing 1:1、(3) overlay 不可侵、(4) 再 install 冪等、(5) managed 全置換、(6) dry-run 非介入、(7) `.codex/rules/local` が通常ファイルの異常系）
- 既存流儀: `templates/hooks/tests/_helpers.sh` / `run-tests.sh` / `test-local-overlay.sh` / `test-installer-preservation.sh`
- テスト期待値は SPEC-0029 AC-01〜09 から導出すること（AP-07 回避。src/generator 内部ロジックの参照は禁止、公開挙動 = install.sh 実行結果のみ検証）

## 出力

- `templates/hooks/tests/test-codex-rules.sh`（新規、実行時間 15 秒以内 — NFR-04）
- `templates/hooks/tests/run-tests.sh`（登録行のみ。自動 discovery なら変更不要）

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-codex-rules.sh`
- 変更: `templates/hooks/tests/run-tests.sh`（登録行のみ）
- 削除: なし

## 禁止事項

- **Implementation Agent と同一セッションでの実行**（AP-04）
- テストを実装に合わせて改変して通すこと（CLAUDE.md §5 — 実装側の FAIL は fail_feedback で Implementation Agent に差し戻す）
- `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` の編集（SPEC-0022/0023 boundary、AC-12）
- `templates/rules/` / `.claude/rules/` / `sage/` / `CLAUDE.md` / 本リポジトリの `.sage/config.yaml` の変更
- `install.sh` の手動編集、`scripts/generator/` / `templates/codex-rules/` / `docs/` の変更
- File Scope 外の変更（AP-03）

## 完了条件

- [ ] `bash templates/hooks/tests/test-codex-rules.sh` が全ケース PASS（AC-01〜09 の各 case をカバー）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊、AC-11）
- [ ] 新テストの実行時間が 15 秒以内（NFR-04）

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
