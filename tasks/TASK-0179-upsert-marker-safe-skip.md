# TASK-0179: generator: upsert マーカー片方欠損の安全側スキップ

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0179 |
| SPEC-ID   | SPEC-0026 |
| PLAN-ID   | PLAN-0026 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No（TASK-0178 と `07-installer-main.sh` を共有するため直列） |
| 依存TASK  | TASK-0178 |
| 見積     | 1h |

## 責務

`upsert_sage_section()` に、開始/終了マーカーの片方のみ存在する場合の安全側スキップ (変更なし + WARN + installer 継続) を実装する。

## 入力

- SPEC-0026 FR-05 / 想定エラー1 / 境界ケース2 / INV-01 / PRE-03 / リスク4
- 対応 AC: AC-01 / AC-08
- 変更箇所: `scripts/generator/07-installer-main.sh` の `upsert_sage_section()`

## 出力

- `upsert_sage_section()` が編集前にマーカー整合を判定:
  - 両方存在: 従来どおりマーカー内のみ置換（マーカー外不変, INV-01）
  - 片方のみ: 対象ファイルを変更せず (append もしない) WARN を stderr に出力 (手動修復手順 = docs へのポインタを含む)、installer 全体は exit 0 で継続
  - 両方不在: 既存の末尾 append 挙動を維持（既存行は不変）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/07-installer-main.sh`
- 削除: なし

## 禁止事項

- `install.sh` / `SHA256SUMS` の再生成（TASK-0181 の責務・別コミット）
- バックアップ関数 (TASK-0178 成果) の挙動変更、`--diff` (TASK-0180) への着手
- File Scope 外の変更 (AP-03)、`sage/`・AGENTS.md・`docs/codex-*.md` への変更

## 完了条件

- [ ] 欠損 fixture（終了マーカーのみ削除した CLAUDE.md）に対する生成 `install.sh` 実行が exit 0 かつ WARN を出力し、当該ファイル内容が不変であること（scratch 環境で `bash install.sh; echo $?` + `grep -c 'WARN' stderr` + `diff` で確認）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊）

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
