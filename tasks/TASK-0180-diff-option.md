# TASK-0180: generator: --diff オプション

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0180 |
| SPEC-ID   | SPEC-0026 |
| PLAN-ID   | PLAN-0026 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No（`07-installer-main.sh` の UPDATE 判定ロジックを共有するため直列） |
| 依存TASK  | TASK-0179（直接依存。推移的に TASK-0178 — UPDATE 判定/バックアップ基盤を利用） |
| 見積     | 1.5h |

## 責務

`install.sh --diff` オプション (UPDATE 対象の unified diff 表示のみ、書き込みなし) を generator に実装する。

## 入力

- SPEC-0026 FR-03 / FR-04 / NFR-01 / SEC-02 / PRE-02 / POST-02 / CLI 契約
- 対応 AC: AC-04 / AC-04b
- 変更箇所: `scripts/generator/07-installer-main.sh` — 引数パーサ (L480 付近)、usage (L488 付近)、書き込みフェーズ前の分岐

## 出力

- `install.sh --diff` が:
  - UPDATE 対象ファイルごとに unified diff (`diff -u` 相当、`---` / `+++` 行を含む) を表示し、いかなるファイルも作成・変更・削除せず exit 0
  - CLAUDE.md / AGENTS.md は upsert 後の想定内容との差分を表示し、マーカー外の行が差分に含まれる場合も隠さず表示 (保全違反の可視化)
  - バックアップも作成しない (書き込みなしのため)
- 既存 `--dry-run` / `--verify-checksum` / `--remote` / provenance の出力・挙動は不変

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/07-installer-main.sh`
- 削除: なし

## 禁止事項

- `install.sh` / `SHA256SUMS` の再生成（TASK-0181 の責務・別コミット）
- 既存 `--dry-run` の出力・挙動の変更（非破壊, NFR-01）
- SHA256SUMS / `--verify-checksum` / provenance 検証範囲の縮小 (SEC-02, INV-05)
- File Scope 外の変更 (AP-03)

## 完了条件

- [ ] scratch 環境で生成 `install.sh --diff` の出力に `^+++ ` 行が含まれること (`bash install.sh --diff | grep -q '^+++ '`)
- [ ] `--diff` 実行前後で全ファイルの checksum が不変であること（実行前後の `find . -type f | sort | xargs shasum -a 256` 比較）
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
