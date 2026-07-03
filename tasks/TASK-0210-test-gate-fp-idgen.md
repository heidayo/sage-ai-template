# TASK-0210: test-gate-fp-idgen.sh と fixtures の追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0210 |
| SPEC-ID   | SPEC-0031 |
| PLAN-ID   | PLAN-0031 |
| ステータス | Pending |
| 担当Agent | **Test**（Implementation Agent と別セッションで実行 — AP-04 AI Monolith 回避） |
| 並列可否  | No |
| 依存TASK  | TASK-0209 |
| 見積     | 1h |

## 責務

`sage-id-gen.sh gate-fp` の採番動作（AC-03〜07）を fixture ベースの integration テストとして実装し、既存テストスイートに組み込む。

## 入力

- SPEC-0031 AC-03〜07 / AC-12、検証方針節
- 既存流儀: `templates/hooks/tests/test-id-patterns.sh`（一時ディレクトリに `scripts/sage-id-gen.sh` + `scripts/sage-id-pattern.sh` + fixture を配置する方式）、`templates/hooks/tests/_helpers.sh`、`templates/hooks/tests/run-tests.sh`
- fixture: GATE-FP 0 件版 / 複数件（`GATE-FP-0001` + `GATE-FP-0003`、欠番あり）版の failures.md を `templates/hooks/tests/fixtures/` 配下に置く

## 出力

- `templates/hooks/tests/test-gate-fp-idgen.sh`（新規）
- `templates/hooks/tests/fixtures/` 配下の fixture failures.md（新規 2 種）
- `templates/hooks/tests/run-tests.sh` 登録行（自動 discovery なら変更不要）

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-gate-fp-idgen.sh`、`templates/hooks/tests/fixtures/` 配下の fixture failures.md
- 変更: `templates/hooks/tests/run-tests.sh`（登録行のみ）
- 削除: なし

## 禁止事項

- `scripts/sage-id-gen.sh` 本体の修正（実装不具合を発見したら fail_feedback で TASK-0209 担当へ差し戻す — テストを実装に合わせて改変して通すことは禁止, CLAUDE.md §5）
- 既存テストファイル・既存 fixture の変更
- `sage/failures.md` 実物の変更（テストは fixture コピーのみ使用）
- install.sh / SHA256SUMS の再生成（TASK-0211 の責務）

## 完了条件

- [ ] `bash templates/hooks/tests/test-gate-fp-idgen.sh` が全ケース PASS（case: `idgen_first` / `idgen_next` / `existing_types_unchanged` / `idgen_missing_file` / `unknown_type_rejected` — AC-03〜07 と 1:1）
- [ ] AC-12: `bash templates/hooks/tests/run-tests.sh` が既存テスト含め全件 PASS (case: `all_tests_pass`)
- [ ] コミットメッセージに TASK-0210 を含む

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0031-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
