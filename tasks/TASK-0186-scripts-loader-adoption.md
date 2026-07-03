# TASK-0186: trace-check / validate / report の受理判定ローダー参照化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0186 |
| SPEC-ID   | SPEC-0027 |
| PLAN-ID   | PLAN-0027 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0187/0188/0191 と並列可。File Scope は互いに素） |
| 依存TASK  | TASK-0185 |
| 見積     | 2h |

## 責務

`scripts/sage-trace-check.sh` / `scripts/sage-validate.sh` / `scripts/sage-report.sh` の ID 受理判定 regex を `sage_id_accept_regex` 参照に置換する（SPEC-0027 Slice ヒント T2。3 ファイルは同種変更のため単一責務「受理判定の参照化」として直列 1 タスク）。

## 入力

- SPEC-0027 FR-05、INV-03、POST-02
- ハードコード位置: `sage-trace-check.sh:19`、`sage-validate.sh:195`、`sage-report.sh:123-125`（BRE 混在）
- 注意: `sage-report.sh` の `git log --grep`（BRE）は合成 ERE 非対応。`--format` 出力を `grep -E` でフィルタする方式へ変更（SPEC 実装メモ、最重要事故ポイント）
- 集計・表示目的の抽出 regex（`sage-report.sh:146,148` 等）は置換対象外（スコープ外）

## 出力

- 3 スクリプトの受理判定がすべて `scripts/sage-id-pattern.sh` 経由になり、受理判定用ハードコード regex が残存しないこと
- 設定ファイルなしで既存挙動（受理/拒否/exit code）が完全同一（NFR-01/INV-01）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/sage-trace-check.sh`, `scripts/sage-validate.sh`, `scripts/sage-report.sh`
- 削除: なし

## 禁止事項

- `scripts/sage-id-gen.sh` / `templates/pre-commit-task-id.sh` の変更（TASK-0187/0188 の責務）
- 集計・表示目的の抽出 regex の変更（スコープ外）
- CLI 引数・exit code 規約の変更（契約不変）

## 完了条件

- [ ] `.sage/id-patterns.json` なしの一時環境で 3 スクリプト単体実行の出力・exit code が変更前と同一（INV-01）
- [ ] カスタム accept（`TASK-[a-z]+-[0-9a-f]{4}`）設定 fixture で `TASK-hei-a7f3` を含む commit が trace-check / validate で受理される（POST-02）
- [ ] `grep -rnE 'TASK-\[0-9\](\{4\}|\\\{4\\\})' scripts/sage-trace-check.sh scripts/sage-report.sh scripts/sage-validate.sh` のヒット 0 件（AC-06 部分）

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
