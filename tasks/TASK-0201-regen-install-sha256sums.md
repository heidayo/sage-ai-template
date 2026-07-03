# TASK-0201: install.sh 再生成 + SHA256SUMS 更新（専用 TASK・単独コミット）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0201 |
| SPEC-ID   | SPEC-0029 |
| PLAN-ID   | PLAN-0029 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No（TASK-0199 / TASK-0200 の合流点） |
| 依存TASK  | TASK-0199, TASK-0200 |
| 見積     | 30m |

## 責務

generator から `install.sh` を再生成し、`SHA256SUMS` を追随更新する。**このタスクは専用・単独コミットとする**（SPEC-0029 T4 / FR-08 / AC-10 / FAIL-0002 教訓）。

## 入力

- SPEC-0029（FR-08, NFR-02, INV-04, INV-05）
- TASK-0199（generator 変更）/ TASK-0200（docs 実体）の完了済み成果物
- 再生成: `bash scripts/generate-installer.sh`

## 出力

- `install.sh`（再生成物 — 手動編集禁止）
- `SHA256SUMS`（install.sh エントリ更新）
- 単独コミット（このタスクの変更のみを含む 1 コミット）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `install.sh`（再生成のみ）, `SHA256SUMS`
- 削除: なし

## 禁止事項

- **`install.sh` の手動編集**（generator 経由の再生成のみ、INV-05）
- 他タスクの変更（generator / templates / docs / tests）を同一コミットに混在させること（FAIL-0002）
- `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` の編集（SPEC-0022/0023 boundary、AC-12）
- `templates/rules/` / `.claude/rules/` / `sage/` / `CLAUDE.md` / 本リポジトリの `.sage/config.yaml` の変更
- SPEC-0018/0025 検証フローの対象・強度の縮小（managed_files は追加のみ、SEC-03 / INV-04）
- File Scope 外の変更（AP-03）

## 完了条件

- [ ] `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` が 0 行（AC-10）
- [ ] `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功する（AC-10）
- [ ] `git show --name-only HEAD` の変更ファイルが `install.sh` と `SHA256SUMS` のみ（単独コミット）

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
