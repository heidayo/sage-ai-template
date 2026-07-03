# TASK-0182: test-installer-preservation.sh 追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0182 |
| SPEC-ID   | SPEC-0026 |
| PLAN-ID   | PLAN-0026 |
| ステータス | Pending |
| 担当Agent | Test |
| 並列可否  | No（再生成済み install.sh を検証対象とするため TASK-0181 完了後） |
| 依存TASK  | TASK-0181（直接依存。推移的に TASK-0178〜0180 の全機能を検証対象とする） |
| 見積     | 2h |

## 責務

installer カスタマイズ保全のリグレッションテスト `templates/hooks/tests/test-installer-preservation.sh` を追加する。

## 入力

- SPEC-0026 検証方針 / 受け入れ条件 AC-01〜05 (AC-04b 含む) / AC-08 / AC-09 / AC-11 / AC-12 / AC-13、境界ケース1〜2
- 既存流儀: `templates/hooks/tests/_helpers.sh` + `test-local-overlay.sh` / `test-installer-modularize.sh`（一時ディレクトリ + 生成 `install.sh` 実行）
- テスト期待値は SPEC の AC から導出し、各ケースに AC-N 参照を付ける (AP-07 対策)。実装内部ロジックへの参照は禁止（シグネチャ/CLI 契約のみ）

## 出力

- `templates/hooks/tests/test-installer-preservation.sh`（新規）— 以下のケースを含む:
  - `marker_outside_preserved` (AC-01)
  - `backup_created` (AC-02)
  - `backup_rotation` (AC-03)
  - `diff_no_write` (AC-04)
  - `diff_shows_outside_marker` (AC-04b)
  - `idempotent_reinstall` (AC-05, 境界ケース1)
  - `marker_half_broken_safe` (AC-08)
  - `backup_unwritable_aborts` (AC-09)
  - `rotation_skips_foreign_entries` (AC-11)
  - `timestamp_collision_no_overwrite` (AC-12)
  - `claude_md_backup_convention` (AC-13)
  - `marker_both_missing_append` (境界ケース2)
  - `.sage/backup/` が gitignore 対象であることの検証（SPEC スコープ「含む」）
- `templates/hooks/tests/run-tests.sh` への登録行（自動 discovery の場合は変更不要）

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-installer-preservation.sh`
- 変更: `templates/hooks/tests/run-tests.sh`（登録行のみ）
- 削除: なし

## 禁止事項

- 実装 (`scripts/generator/` / `install.sh` / `SHA256SUMS`) の変更 — テスト失敗時は fail_feedback で Implementation に差し戻す
- テストを実装挙動に合わせて改変して通すこと（§5 禁止事項）
- 既存テストファイルの変更（run-tests.sh の登録行を除く）
- File Scope 外の変更 (AP-03)

## 完了条件

- [ ] `bash templates/hooks/tests/test-installer-preservation.sh` が全ケース PASS する
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS する（新テスト包含 + 既存テスト非破壊, AC-07）
- [ ] 全ケース名が SPEC の case 名と 1:1 対応し、AC-N 参照コメントを持つ

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0026-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
