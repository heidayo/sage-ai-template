# TASK-0183: docs: 復元手順 + マーカー方式対比表

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0183 |
| SPEC-ID   | SPEC-0026 |
| PLAN-ID   | PLAN-0026 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0178 完了後、TASK-0179〜0182 と並列可。File Scope が generator/tests 系と互いに素） |
| 依存TASK  | TASK-0178（バックアップ仕様＝パス形式・世代数の確定後に記述するため） |
| 見積     | 1h |

## 責務

`.sage/backup/` からの手動復元手順と、マーカー方式の「防御される / 防御されないケース」対比表を日本語ドキュメントとして追加する。

## 入力

- SPEC-0026 スコープ「ドキュメント」/ OPS-02 / リスク4 / 境界ケース2 / ロールバック手順
- 対応 AC: AC-10
- 言語ルール: ユーザー向けドキュメントは日本語

## 出力

- `docs/installer-preservation.md`（新規）:
  - 手動復元手順: `cp .sage/backup/<最新timestamp>/<ファイル> <ファイル>`（`--restore` 相当の cp 手順案内）
  - マーカー方式対比表（「防御されないケース」の語を含む）: マーカー正常 / 片方欠損（更新されない・WARN）/ 両方欠損（append される — 消失はしないが重複し得る）/ 旧フォーマット / マーカー内手動編集 の各ケース
- `README.md`: `.sage/backup/` 復元手順への言及または `docs/installer-preservation.md` への導線

## File Scope（変更許可範囲）

- 作成: `docs/installer-preservation.md`
- 変更: `README.md`
- 削除: なし

## 禁止事項

- generator / install.sh / SHA256SUMS / templates / tests への変更（他 TASK の責務。並列実行のため File Scope を互いに素に保つ）
- AGENTS.md / `docs/codex-*.md` の編集（CLAUDE.md §2.1 boundary — 必要なら Codex follow-up として記録）
- `sage/` 配下の変更
- File Scope 外の変更 (AP-03)

## 完了条件

- [ ] `grep -rq '\.sage/backup/' README.md docs/` が exit 0（復元手順）
- [ ] `grep -rq '防御されないケース' docs/` が exit 0（対比表）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（非破壊確認）

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
