# TASK-0188: pre-commit-task-id.sh の設定優先 + fallback 内包化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0188 |
| SPEC-ID   | SPEC-0027 |
| PLAN-ID   | PLAN-0027 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0186/0187/0191 と並列可。File Scope は互いに素） |
| 依存TASK  | TASK-0185 |
| 見積     | 1.5h |

## 責務

`templates/pre-commit-task-id.sh`（:56）を、`.sage/id-patterns.json` が読解可能な場合は `task.accept` を優先し、そうでなければ内包 fallback regex で単体動作するよう変更する（SPEC-0027 Slice ヒント T4）。

## 入力

- SPEC-0027 FR-06、INV-03（内包 fallback はローダーの fallback と同一値）、境界ケース2
- hook は導入先スタンドアロン配布物 — `scripts/sage-id-pattern.sh` が存在しない環境でも単体動作すること

## 出力

- 更新された `templates/pre-commit-task-id.sh`（テンプレートのみ。install.sh への再埋め込みは TASK-0189 の責務）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `templates/pre-commit-task-id.sh`
- 削除: なし

## 禁止事項

- `install.sh` / `SHA256SUMS` / `scripts/generator/` の変更（TASK-0189 の責務・単独コミット、FAIL-0002）
- 内包 fallback とローダー fallback の値の乖離（INV-03 違反）
- `eval` の使用（SEC-01）

## 完了条件

- [ ] ローダー・設定ファイルともに存在しない一時環境 fixture で hook が単体動作し、`TASK-0001` 受理 / `NOTASK` 拒否が変更前と同一（FR-06/INV-01）
- [ ] カスタム accept 設定ありの fixture で `TASK-hei-a7f3` を含む commit message が hook を通過する（AC-03）
- [ ] `TASK-[0-9]{4}` のハードコードが内包 fallback 定義行のみに存在する（AC-06 部分）

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
