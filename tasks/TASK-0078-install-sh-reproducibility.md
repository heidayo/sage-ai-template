# TASK-0078: install.sh 再現性検証スクリプト + 前提として install.sh 再生成

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0078 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-C |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0085/0086/0088/0089 等 Sprint 1 の template 変更の後に行う必要あり) |
| 依存TASK  | TASK-0085, TASK-0086, TASK-0088, TASK-0089 (templates が先にコミットされている必要あり) |
| 見積     | 0.5h |

## 責務

1. `bash scripts/generate-installer.sh > install.sh` を実行し、Sprint 1 の templates 変更 (TASK-0085/0086/0088/0089) を install.sh に反映する
2. `scripts/sage-installer-reproduce.sh` を新規作成し、install.sh が generate-installer.sh の出力と一致することを byte-level で検証する

本 TASK は workflow 統合までは行わない (CI workflow の変更は別タスク)。

## 入力

- `install.sh` (現状 5551 行、Sprint 1 template 変更未反映)
- `scripts/generate-installer.sh` (変更なし)
- 反映すべき template 変更元:
  - `.sage/config.yaml` (TASK-0082, TASK-0088)
  - `templates/hooks/block-dangerous-commands.sh` (TASK-0086, TASK-0089)
  - `CLAUDE.md` / `AGENTS.md` (TASK-0085 — install.sh が参照する SAGE セクションがあれば同期)

## 出力

- `install.sh` 更新 (再生成結果を上書き)
- `scripts/sage-installer-reproduce.sh` 新規作成
- 検証: `diff <(bash scripts/generate-installer.sh) install.sh` が exit 0

## File Scope（変更許可範囲）

- 作成:
  - `scripts/sage-installer-reproduce.sh`
  - `tasks/TASK-0078-install-sh-reproducibility.md` (本ファイル)
- 変更:
  - `install.sh` (generate-installer.sh の出力そのまま)
- 削除: なし

## 禁止事項

- `install.sh` の手編集禁止 (差分は generate-installer.sh 経由のみ)
- `scripts/generate-installer.sh` の変更禁止
- `templates/` の変更禁止 (本 TASK は反映のみ、中身は先行 TASK の責務)
- `.github/workflows/` の変更禁止 (CI 統合は後続)

## 完了条件

- [ ] `diff <(bash scripts/generate-installer.sh) install.sh` が exit 0 を返す
- [ ] `bash scripts/sage-installer-reproduce.sh` が exit 0 を返す
- [ ] `scripts/sage-installer-reproduce.sh` 単体で意図的な差分 (例: install.sh を 1 文字変更) を検知し exit 1
- [ ] コミットメッセージに `TASK-0078` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-C 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
