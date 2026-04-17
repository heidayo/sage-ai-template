# TASK-0093: Local 5 Gate 代替検証 + RUN ログ蓄積

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0093 |
| SPEC-ID   | SPEC-0009 |
| PLAN-ID   | PLAN-0008-F |
| ステータス | In Progress |
| 担当Agent | Operations |
| 並列可否  | No (Track A-D の全実装 + TASK-0090..0092 が前提) |
| 依存TASK  | TASK-0070, TASK-0071, TASK-0072, TASK-0073, TASK-0074, TASK-0075, TASK-0076, TASK-0077, TASK-0078, TASK-0079, TASK-0080, TASK-0081, TASK-0082, TASK-0083, TASK-0084, TASK-0090, TASK-0091, TASK-0092 |
| 見積     | 1h |

## 責務

SPEC-0008 (enforcement gap closure) と SPEC-0009 (calculator API) を通して、SAGE が宣言どおりの 5 Gate + ドリフト検知 + RUN ログ運用を実行できる状態に到達したことを、このリポジトリ自身で実走確認する。

本セッションは feature ブランチ上で行われ、GitHub Actions の実 Gate は PR 時に走るため、ローカルで代替可能な部分のみを検証し、CI 固有項目 (Gitleaks/Trivy、setup-go による Go ビルド、release gate のワークフロー間依存) は明示的にスキップと記録する。

## 入力

- feature/spec-0008-ds-store-untrack ブランチの最新 HEAD
- Track A-F (TASK-0070..0092) の成果物
- ローカル実行環境: bash, python3, git, curl, shasum; Go 未インストール

## 出力

- 下記スクリプトが all PASS:
  - `bash scripts/sage-validate.sh` (9/9 checks)
  - `bash scripts/sage-runlog-validate.sh` (既存 3 + 本 RUN)
  - `bash scripts/sage-doc-drift.sh`
  - `bash scripts/sage-installer-reproduce.sh`
  - `bash scripts/sage-architecture-check.sh`
- `.sage/runs/RUN-0004.yaml` に本 TASK の結果を記録
- 本 TASK ファイル自身を含む

## File Scope（変更許可範囲）

- 作成:
  - `.sage/runs/RUN-0004.yaml`
  - `tasks/TASK-0093-final-verification.md` (本ファイル)
- 変更: なし
- 削除: なし

## 禁止事項

- 他 TASK の結果変更禁止 (本 TASK は検証のみ)
- SKIP 扱いの gate を PASS に偽装する禁止 (Gate 2/3/5 は明示的に skipped と記録)

## 完了条件

- [ ] `.sage/runs/RUN-0004.yaml` が sage-runlog-validate.sh を通る
- [ ] ローカル代替検証 5 系統 (sage-validate / runlog-validate / doc-drift / installer-reproduce / architecture-check) がすべて exit 0
- [ ] コミットメッセージに `TASK-0093` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-F 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | RUN-0004 |
| 開始     | 2026-04-17 |
| 完了     | 2026-04-17 |
| 結果     | pass (ローカル代替検証、CI 本番は PR 時) |
| Gate結果  | structural: pass / functional: skipped / security: skipped / architecture: pass / release: skipped |
