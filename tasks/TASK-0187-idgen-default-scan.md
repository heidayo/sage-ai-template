# TASK-0187: sage-id-gen.sh のデフォルト形式スキャン参照化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0187 |
| SPEC-ID   | SPEC-0027 |
| PLAN-ID   | PLAN-0027 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0186/0188/0191 と並列可。File Scope は互いに素） |
| 依存TASK  | TASK-0185 |
| 見積     | 1h |

## 責務

`scripts/sage-id-gen.sh` の連番スキャン regex（:47,52 の `${PREFIX}-[0-9]{4}`）を `sage_id_default_regex` 経由に置換する（SPEC-0027 Slice ヒント T3）。

## 入力

- SPEC-0027 FR-07、PRE-02、境界ケース1
- 生成・連番スキャンはデフォルト形式のみ対象。カスタム形式 ID は採番計算に混入させない（無視）

## 出力

- `scripts/sage-id-gen.sh` がローダー経由でデフォルト形式 regex を取得し、生成 ID・exit code は変更前と完全同一（NFR-01）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/sage-id-gen.sh`
- 削除: なし

## 禁止事項

- カスタム形式 ID の生成機能追加（スコープ外 — 受理のみサポート）
- `gen_digits` 生成桁数の変更（スコープ外）
- 他スクリプトの変更

## 完了条件

- [ ] カスタム形式 ID ファイル（`tasks/TASK-hei-a7f3-x.md`）が存在する一時環境で `bash scripts/sage-id-gen.sh task` がデフォルト形式の次連番を返す（AC-07）
- [ ] `.sage/id-patterns.json` なしの環境で生成 ID が変更前と同一（INV-01）
- [ ] `grep -rnE 'TASK-\[0-9\](\{4\}|\\\{4\\\})' scripts/sage-id-gen.sh` のヒット 0 件（AC-06 部分）

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
