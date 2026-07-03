# TASK-0207: test-ts-enforcement.sh + mock tsc fixtures（Test Agent 責務）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0207 |
| SPEC-ID   | SPEC-0030 |
| PLAN-ID   | PLAN-0030 |
| ステータス | Pending |
| 担当Agent | **Test（Implementation とは別セッションで実行すること — AP-04 / AP-07 回避）** |
| 並列可否  | Yes（TASK-0206 と並列可 — File Scope 互いに素） |
| 依存TASK  | TASK-0204, TASK-0205 |
| 見積     | 2h |

## 責務

`sage-tsc-ratchet.sh` と ESLint 断片の integration テスト（mock tsc fixture 使用、Node / tsc 実物非依存）を追加する。

## 入力

- SPEC-0030 AC-01〜08・検証方針・異常系（想定エラー1〜3、境界ケース1〜3）・NFR-03
- 既存流儀: `templates/hooks/tests/_helpers.sh` / `run-tests.sh` / `test-stack-presets.sh` / `test-installer-preservation.sh`
- テスト期待値は SPEC の AC から導出すること（実装の内部ロジック参照禁止 — シグネチャ / CLI 契約のみ参照可、AP-07 回避）

## 出力

- `templates/hooks/tests/fixtures/mock-tsc-*.sh` — `printf` で `error TS2345: ...` 行を N 件出力する bash スクリプト（例: 0 / 1 / 3 / 5 エラー版）
- `templates/hooks/tests/test-ts-enforcement.sh` — 一時ディレクトリで mock を `SAGE_TSC_COMMAND` / `--tsc-command` 注入して検証:
  - (case: `init_and_check_equal`) AC-01: `--init` で `"errors": 3` 作成 + 検査モード exit 0
  - (case: `increase_detected`) AC-02: 5 エラー版で exit 1 + 現在数 5 / baseline 3 / 増分 2 出力
  - (case: `decrease_and_update`) AC-03: 1 エラー版で exit 0 + update 推奨 INFO、`--update` 後 `"errors": 1`
  - (case: `invalid_baseline_rejected`) AC-04: 不正 baseline 3 種 → exit 1 + stderr 理由 + バイト不変
  - (case: `missing_baseline_guided`) AC-05: baseline 不在 → exit 1 + `--init` 案内
  - (case: `tsc_injection_priority`) AC-06: `--tsc-command` 単独動作 + 環境変数優先
  - (case: `eslint_fragments_present`) AC-07: 3 ファイル存在 + 期待 severity
  - (case: `no_jq_no_eval`) AC-08: jq / eval 非使用 grep
  - 境界ケース1（エラー 0 件 baseline）・想定エラー3（`--init` 既存時 exit 1 + `--update` 案内）・境界ケース2（tsc 実行失敗の区別）も網羅
- `templates/hooks/tests/run-tests.sh` — 登録行のみ（自動 discovery なら変更不要）

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-ts-enforcement.sh`, `templates/hooks/tests/fixtures/mock-tsc-*.sh`
- 変更: `templates/hooks/tests/run-tests.sh`（登録行のみ、必要時）
- 削除: なし

## 禁止事項

- `scripts/sage-tsc-ratchet.sh` / `templates/ts-enforcement/` の変更（実装修正は Implementation Agent へフィードバック — テストを実装に合わせて改変して通すことは禁止、CLAUDE.md §5）
- Node.js / tsc 実物への依存（NFR-03 — mock は printf のみの bash スクリプト）
- `install.sh` / `SHA256SUMS` / `scripts/generator/` / `templates/project-checks/ts-pnpm.yaml` への変更（AC-09 / AC-12）
- 既存テストファイルの改変（登録行追加を除く）

## 完了条件

- [ ] `bash templates/hooks/tests/test-ts-enforcement.sh` が全ケース PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（新テスト含む・既存テスト非破壊、AC-10）
- [ ] 各テストケースに対応 AC-N 参照コメントが存在する（AP-07 検出シグナル回避）

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
