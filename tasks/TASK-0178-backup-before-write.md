# TASK-0178: generator: backup_before_write() + 世代ローテーション

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0178 |
| SPEC-ID   | SPEC-0026 |
| PLAN-ID   | PLAN-0026 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（起点タスク。後続 TASK-0179〜0182 は直列、TASK-0183 のみ本タスク完了後に並列可） |
| 依存TASK  | none |
| 見積     | 2h |

## 責務

installer generator に、書き込み前バックアップの単一関数 `backup_before_write()` と `.sage/backup/` 世代ローテーション (直近3世代) を実装する。

## 入力

- SPEC-0026 FR-01 / FR-02 / SEC-01 / SEC-03 / NFR-01 / NFR-03、想定エラー2〜4、境界ケース1、INV-02 / INV-03 / INV-04、PRE-01、POST-01
- 対応 AC: AC-02 / AC-03 / AC-09 / AC-11 / AC-12
- 変更箇所: `scripts/generator/07-installer-main.sh` のファイル書き込みループ (全書き込み経路に `backup_before_write()` を挿入)
- SPEC-0025 の `is_unmanaged_path()` と整合: overlay 配下は書き込み対象外なのでバックアップ対象外

## 出力

- `scripts/generator/07-installer-main.sh` に以下が実装されている:
  - `backup_before_write()`: 「既存 + 内容差分あり」の場合のみ `.sage/backup/<UTC YYYYMMDD-HHMMSS>/<相対パス>` へコピー。UPDATE 0件なら世代ディレクトリを作らない。保存先パスを stdout に出力 (内容はダンプしない)
  - 世代ローテーション: 4世代目作成時に最古世代を削除 (削除対象は `^[0-9]{8}-[0-9]{6}(-[0-9]+)?$` マッチのディレクトリのみ)、削除世代を stdout に出力。`-N` suffix も1世代としてカウント
  - timestamp 衝突時は `-N` suffix で保存 (既存世代を上書きしない)
  - `.sage/backup` 書き込み不可時はファイル更新せずエラー出力 + 非0 exit (fail-safe)
  - `--dry-run` 時はバックアップを作成しない

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/07-installer-main.sh`
- 削除: なし

## 禁止事項

- `install.sh` / `SHA256SUMS` の再生成（TASK-0181 の責務。再生成専用 TASK-ID で別コミットにするため本タスクでは行わない）
- upsert マーカー処理 (TASK-0179)・`--diff` (TASK-0180)・テスト (TASK-0182)・docs (TASK-0183) への着手
- `sage/`・AGENTS.md・`docs/codex-*.md`・overlay 機構 (`is_unmanaged_path()` の挙動変更) への変更
- File Scope 外の変更 (AP-03)

## 完了条件

- [ ] `grep -q 'backup_before_write' scripts/generator/07-installer-main.sh` が exit 0
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊）
- [ ] バックアップ判定・実行が単一関数に集約され、全書き込み経路が経由している (INV-04、Review で確認)

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
