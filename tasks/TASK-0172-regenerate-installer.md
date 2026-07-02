# TASK-0172: install.sh 再生成 + SHA256SUMS 更新

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0172 |
| SPEC-ID   | SPEC-0025 |
| PLAN-ID   | PLAN-0025 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No（TASK-0171 完了後、TASK-0173 の前提） |
| 依存TASK  | TASK-0171 |
| 見積     | 30m |

## 責務

TASK-0171 の generator 変更を反映した `install.sh` を再生成し、`SHA256SUMS` を更新して再現性（バイト一致）を維持する。

## 入力

- SPEC-0025（FR-06, NFR-02, POST-02, AC-06）
- TASK-0171 完了済みの `scripts/generator/` 一式
- 既存の再生成手順（`scripts/generate-installer.sh` 相当）

## 出力

- 再生成された `install.sh`
- 更新された `SHA256SUMS`

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `install.sh`, `SHA256SUMS`
- 削除: なし

## 禁止事項

- `install.sh` の手動編集（generated code の手動編集禁止 — 必ず generator から再生成する）
- generator (`scripts/generator/`) の追加変更（AP-03 — 不備があれば TASK-0171 に差し戻す）
- SHA256SUMS の install.sh 以外のエントリの改変（SEC-03: 既存検証フローの弱体化禁止）
- File Scope 外の変更（AP-03）、複数責務の混在（AP-02）
- TASK-ID なしコミット（AP-05）

## 完了条件

- [ ] `shasum -a 256 -c SHA256SUMS` が PASS する（SPEC T2 完了条件 / AC-06）
- [ ] 再生成を2回実行して `install.sh` がバイト一致する（NFR-02 再現性: `diff <(bash 再生成1回目) <(2回目)` 相当で差分なし）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0025-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | - |
| 完了     | - |
| 結果     | - |
| Gate結果  | - |
