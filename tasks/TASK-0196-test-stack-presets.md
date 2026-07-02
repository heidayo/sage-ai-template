# TASK-0196: test-stack-presets.sh 追加 + golden fixture 作成 + run-tests.sh 登録（Test Agent 責務）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0196 |
| SPEC-ID   | SPEC-0028 |
| PLAN-ID   | PLAN-0028 |
| ステータス | Pending |
| 担当Agent | Test（Implementation Agent とは別セッションで実行すること — AI Monolith 防止） |
| 並列可否  | No（TASK-0195 完了後） |
| 依存TASK  | TASK-0195 |
| 見積     | 3h |

## 責務

`templates/hooks/tests/test-stack-presets.sh` を新規作成し、AC-05 baseline の golden fixture を固定し、`run-tests.sh` に登録する（SPEC-0028 Slice ヒント T5）。本 TASK は **Test Agent の責務** であり、実装セッションと分離する。

## 入力

- SPEC-0028 AC-01〜08/10 と異常系（想定エラー1〜3、境界ケース1〜3）
- 既存流儀: `templates/hooks/tests/_helpers.sh` + `test-installer-preservation.sh`（一時ディレクトリ + fixture 実行）
- **golden fixture は変更前（main の install.sh）の生成する `project_checks` セクションから固定すること**（PLAN-0028 リスク5 — 変更後の実挙動から生成すると後方互換検証が自己言及になる、AP-07 対策）
- Test Agent の src/ 参照制限: installer の CLI 契約（オプション名・exit code・出力契約）のみ参照可、内部ロジック参照禁止（AP-07 対策）。期待値は SPEC の AC から導出すること

## 出力

- `templates/hooks/tests/fixtures/project-checks-default.golden` — 変更前 install.sh 生成物から固定した AC-05 baseline
- `templates/hooks/tests/test-stack-presets.sh` — ケース: `presets_exist_and_complete`(AC-01) / `explicit_stack_applied`(AC-02、4 プリセット全て) / `autodetect_single`(AC-03) / `autodetect_priority`(AC-04、境界ケース1 pnpm-lock+package.json 併存含む) / `autodetect_none_fallback`(AC-05、境界ケース2) / `existing_config_preserved`(AC-06、想定エラー2) / `unknown_stack_rejected`(AC-07、想定エラー1) / `dry_run_no_write`(AC-08、境界ケース3)
- `run-tests.sh` への登録行（自動 discovery なら変更不要）

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-stack-presets.sh`, `templates/hooks/tests/fixtures/project-checks-default.golden`
- 変更: `templates/hooks/tests/run-tests.sh`（登録行のみ）
- 削除: なし

## 禁止事項

- 本リポジトリの `.sage/config.yaml` の変更（AC-11、全 TASK 横断制約 — テストは一時ディレクトリで完結させる、ASM-03）
- 実装コード（`scripts/generator/`、`install.sh`、`templates/project-checks/`、`SHA256SUMS`）の修正（テストを通すための実装改変は §5 で禁止。FAIL は fail_feedback で Implementation Agent に返す）
- テスト期待値を実装の実挙動から逆算すること（AC から導出、AP-07）
- golden fixture を変更後の install.sh から生成すること（リスク5）

## 完了条件

- [ ] `bash templates/hooks/tests/test-stack-presets.sh` が全ケース PASS（AC-01〜08）
- [ ] AC-10: `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊）
- [ ] `autodetect_none_fallback` が `templates/hooks/tests/fixtures/project-checks-default.golden` との diff 一致を検証している（AC-05）
- [ ] `git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0（AC-11）
- [ ] コミットメッセージに TASK-0196 を含む

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0028-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
