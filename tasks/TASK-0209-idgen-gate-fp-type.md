# TASK-0209: sage-id-gen.sh への gate-fp 種別追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0209 |
| SPEC-ID   | SPEC-0031 |
| PLAN-ID   | PLAN-0031 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0208 と並列可） |
| 依存TASK  | none |
| 見積     | 45m |

## 責務

`scripts/sage-id-gen.sh` に `gate-fp` 種別を追加し、`sage/failures.md` スキャンによる `GATE-FP-XXXX` 採番を実装する（既存 5 種別は完全不変）。

## 入力

- SPEC-0031 FR-03〜05 / SEC-01 / NFR-02、設計判断2（SPEC-0027 ローダー非経由）
- 実装指針（SPEC 実装メモ転記）:
  - 既存 `case "$TYPE"` に `gate-fp)` を追加。`DIR="sage"` / `PREFIX="GATE-FP"`、`DEFAULT_RE` はローダーの `sage_id_default_regex` を**呼ばず**ローカル定数 `DEFAULT_RE='GATE-FP-[0-9]{4}'` を直接代入（設計判断2 のコメントを添える）
  - スキャンは `fail` 種別と同じ failures.md grep 方式。ファイル不在は LAST_NUM=0（`GATE-FP-0001` を返す）
  - **sort キー注意**: `GATE-FP-0001` は `-` 区切りで 3 フィールドのため、既存 `fail` の `sort -t'-' -k2 -n` を共通化せず、gate-fp 専用のソートキー（`sort -t'-' -k3 -n` 相当）を使う
  - usage 文言に `gate-fp` を追加。「GATE-FP は記録専用 ID であり、SPEC-0027 ローダー・コミット規約 (commit-msg hook / trace check) の受理対象外」をスクリプト内コメントに明記

## 出力

- `scripts/sage-id-gen.sh`: gate-fp 分岐 + usage 追記 + コメント

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/sage-id-gen.sh`（gate-fp 分岐 + usage 追記のみ）
- 削除: なし

## 禁止事項

- `scripts/sage-id-pattern.sh` / `templates/pre-commit-task-id.sh` の変更（SPEC-0027 INV-03, AC-10）
- `.sage/id-patterns.json` の gate-fp 対応（SEC-01 — 外部設定をパターンとして評価しない）
- 既存 5 種別（spec/plan/task/run/fail）の入出力・番号ロジック・エラーメッセージ形式の変更（FR-05, INV-01）
- jq / eval の使用（NFR-02）
- install.sh / SHA256SUMS の再生成（TASK-0211 の責務）
- `scripts/generator/` の変更（必要と判明した場合は Spec Agent へ差し戻し）

## 完了条件

（手動で fixture failures.md を一時ディレクトリに置いて確認。自動テスト化は TASK-0210）

- [ ] AC-03: GATE-FP 0 件の fixture で `bash scripts/sage-id-gen.sh gate-fp` が `GATE-FP-0001` を出力 (case: `idgen_first`)
- [ ] AC-04: `GATE-FP-0001` / `GATE-FP-0003` を含む fixture で出力が `GATE-FP-0004`（欠番を詰めない） (case: `idgen_next`)
- [ ] AC-05: `bash scripts/sage-id-gen.sh spec|plan|task|run|fail` の出力が変更前と同一、引数なし・未知種別が従来どおり exit 1 + usage (case: `existing_types_unchanged`)
- [ ] AC-06: `sage/failures.md` 不在の一時ディレクトリで `GATE-FP-0001` + exit 0 (case: `idgen_missing_file`)
- [ ] AC-07: `bash scripts/sage-id-gen.sh gatefp`（typo）が exit 非 0 で、usage に `gate-fp` を含む有効種別一覧を出力 (case: `unknown_type_rejected`)
- [ ] `grep -E '\bjq\b|\beval\b' scripts/sage-id-gen.sh` の gate-fp 分岐にヒットなし（NFR-02 / SEC-01）
- [ ] コミットメッセージに TASK-0209 を含む

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0031-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
