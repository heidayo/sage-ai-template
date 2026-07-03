# TASK-0184: generator: 導入先生成 .gitignore への .sage/backup/ エントリ追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0184 |
| SPEC-ID   | SPEC-0026 |
| PLAN-ID   | PLAN-0026 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（T1=TASK-0178 完了後、TASK-0183 と並列可。TASK-0179〜0182 とは 07-installer-main.sh / SHA256SUMS を共有するため直列推奨） |
| 依存TASK  | TASK-0178 |
| 見積     | 1h |

## 責務

installer generator の `setup_gitignore` に `.sage/backup/` エントリを追加する (FR-09)。新規生成・既存 `.gitignore` への追記の両経路で冪等（既存エントリがあれば追記しない）。

## 入力

- SPEC-0026 FR-09 / AC-14（追補 T7）
- 変更箇所: `scripts/generator/07-installer-main.sh` の `setup_gitignore`
  - 新規生成時: `.sage/backup/` エントリを含める
  - 既存 `.gitignore` 追記時: `grep -qF '.sage/backup/'` で存在確認し、無い場合のみ追記（冪等）
- テストケース `gitignore_backup_entry` を `templates/hooks/tests/test-installer-preservation.sh` に追加（CHECK-017 対応）
- 再生成 (`install.sh` / `SHA256SUMS`) は **本タスク内で同一 TASK-ID として追随させる**（FAIL-0002 教訓: 生成入力の変更と再生成を同一 PR / 同一 TASK で機械検証可能にする）

## 出力

- `scripts/generator/07-installer-main.sh`: `setup_gitignore` が `.sage/backup/` エントリを新規・追記の両経路で冪等に出力する
- `install.sh`: generator から再生成済み（手動編集禁止）
- `SHA256SUMS`: install.sh エントリ更新済み、`shasum -a 256 -c` PASS
- `templates/hooks/tests/test-installer-preservation.sh`: case `gitignore_backup_entry` 追加

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/07-installer-main.sh`, `install.sh`（再生成のみ・手動編集禁止）, `SHA256SUMS`, `templates/hooks/tests/test-installer-preservation.sh`（case `gitignore_backup_entry` 追加のみ）

## 禁止事項

- `install.sh` の手動編集（generator からの再生成のみ許可）
- backup / upsert / `--diff` ロジック（TASK-0178〜0181 の成果物）への変更
- 既存テストケースの変更（case 追加のみ）
- `sage/`・CLAUDE.md・AGENTS.md・`docs/codex-*.md` への変更
- File Scope 外の変更 (AP-03)

## 完了条件

- [ ] clean install 後 `grep -qF '.sage/backup/' .gitignore` が exit 0
- [ ] 再 install（2回目実行）で `.gitignore` の `.sage/backup/` 行が重複しない（行数不変）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（case `gitignore_backup_entry` 含む、既存テスト非破壊）
- [ ] `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が PASS（再生成追随の機械検証）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0026-round-1.md`（CHECK-017）

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
