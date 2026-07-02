# TASK-0190: test-id-patterns.sh 追加 + run-tests.sh 登録（Test Agent 責務）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0190 |
| SPEC-ID   | SPEC-0027 |
| PLAN-ID   | PLAN-0027 |
| ステータス | Pending |
| 担当Agent | Test（Implementation Agent とは別セッションで実行すること — AI Monolith 防止） |
| 並列可否  | No（TASK-0189 完了後） |
| 依存TASK  | TASK-0189 |
| 見積     | 2h |

## 責務

`templates/hooks/tests/test-id-patterns.sh` を新規作成し `run-tests.sh` に登録する（SPEC-0027 Slice ヒント T6）。本 TASK は **Test Agent の責務** であり、実装セッションと分離する。

## 入力

- SPEC-0027 AC-01〜07/09/11 と異常系（想定エラー1〜3、境界ケース1〜2）
- 既存流儀: `templates/hooks/tests/_helpers.sh` + `test-local-overlay.sh`（一時ディレクトリ + fixture 実行）
- Test Agent の src/ 参照制限: ローダー関数のシグネチャ（関数名・引数・出力契約）のみ参照可、内部ロジック参照禁止（AP-07 対策）。期待値は SPEC の AC から導出すること

## 出力

- `templates/hooks/tests/test-id-patterns.sh` — ケース: `fallback_no_config`(AC-01) / `default_accepted`(AC-02) / `custom_accepted`(AC-03) / `invalid_json_fallback`(AC-04) / `empty_accept_fallback`(AC-05) / `no_stray_hardcode`(AC-06) / `idgen_ignores_custom`(AC-07) / `docs_and_config_reference`(AC-10, done-def CHECK-010/012) / `installer_preserves_config`(AC-12, installer 再実行時の `.sage/id-patterns.json` 保持, done-def CHECK-015) / `hook_standalone_fallback`(AC-11, hook 単体 fallback, done-def CHECK-016) + 表記揺れ fixture（リスク2）+ 種別欠落 fallback（想定エラー3）
- `run-tests.sh` への登録行（自動 discovery なら変更不要）

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-id-patterns.sh`
- 変更: `templates/hooks/tests/run-tests.sh`（登録行のみ）
- 削除: なし

## 禁止事項

- 実装コード（`scripts/`、`templates/pre-commit-task-id.sh`）の修正（テストを通すための実装改変は §5 で禁止。FAIL は fail_feedback で Implementation Agent に返す）
- テスト期待値を実装の実挙動から逆算すること（AC から導出、AP-07）

## 完了条件

- [ ] `bash templates/hooks/tests/test-id-patterns.sh` が全ケース PASS（AC-01〜07/09/10/11/12）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊、AC-09）
- [ ] `no_stray_hardcode` ケースが AC-06 の grep 検証（許容行数・位置の機械検証）を実装している

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0027-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
