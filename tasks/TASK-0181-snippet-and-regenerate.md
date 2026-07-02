# TASK-0181: claude-md-snippet バックアップ規約追記 + install.sh 再生成 + SHA256SUMS 更新

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0181 |
| SPEC-ID   | SPEC-0026 |
| PLAN-ID   | PLAN-0026 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No（TASK-0178〜0180 の generator 変更が全て確定してから再生成する） |
| 依存TASK  | TASK-0180（直接依存。推移的に TASK-0178 / TASK-0179 の generator 変更を取り込む） |
| 見積     | 30m |

## 責務

生成入力 (`templates/claude-md-snippet.md`) にバックアップ規約を追記し、TASK-0178〜0180 の generator 変更を含めて `install.sh` を再生成して SHA256SUMS を追随させる（再生成専用タスク）。

## 入力

- SPEC-0026 FR-07 / FR-08 / NFR-02 / POST-03 / INV-05 / リスク3
- 対応 AC: AC-06 / AC-13
- FAIL-0002 の教訓 (SPEC-0025): 生成入力・generator 変更後は必ず `install.sh` 再生成 + SHA256SUMS 更新を同一 PR 内で追随させる。再生成は本タスクの TASK-ID で**別コミット**とする（generator 変更コミットと混在させない）

## 出力

- `templates/claude-md-snippet.md` に 1〜2 行追記: 「Template update backs up modified files to `.sage/backup/<timestamp>/` (3 generations). Restore: `cp .sage/backup/<ts>/<file> <file>`」
- 再生成された `install.sh`（手動編集禁止・generator 出力そのまま）
- 更新された `SHA256SUMS`（install.sh エントリ一致）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `templates/claude-md-snippet.md`, `install.sh`（再生成のみ）, `SHA256SUMS`
- 削除: なし

## 禁止事項

- `install.sh` の手動編集（generator 経由の再生成のみ許可）
- `scripts/generator/` への機能追加（generator 修正が必要なら TASK-0178〜0180 に差し戻す）
- SHA256SUMS の検証対象・強度の縮小 (INV-05)
- File Scope 外の変更 (AP-03)

## 完了条件

- [ ] `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功する
- [ ] 再生成の再現性: generator を再実行しても `install.sh` がバイト一致する (NFR-02)
- [ ] scratch 環境での clean install 後 `grep -q '.sage/backup/' CLAUDE.md` が exit 0 (AC-13)
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS

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
