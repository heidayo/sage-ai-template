# TASK-0212: gate false positive (test-ts-enforcement.sh 開放レンジ) の恒久対応と GATE-FP-0001 記録

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0212 |
| SPEC-ID   | SPEC-0031 |
| PLAN-ID   | PLAN-0031 |
| ステータス | Review |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0210 |
| 見積     | 30m |

> **注記（遡及 TASK）**: 本 TASK は実装後に遡及承認のため作成された retroactive TASK である。Review Agent の指摘 (REV-001/002/003: TASK-0210 の File Scope 逸脱) を受け、既に実施済みの正当な変更 (コミット 9e15422 / 3db71e5) に形式承認を与えることを目的とする。

## 責務

SPEC-0031 実装中に検出された gate false positive (test-ts-enforcement.sh 開放レンジ) の恒久対応と GATE-FP-0001 記録。

## 入力

- SPEC-0031 (GATE-FP-XXXX 書式・知識管理フロー)
- TASK-0210 実装中に検出された test-ts-enforcement.sh の開放レンジ誤検知
- sage/failures.md の GATE-FP エントリフォーマット (TASK-0208 成果物)

## 出力

遡及承認対象の既存コミット:

- コミット `9e15422` — SPEC-0030 テスト `templates/hooks/tests/test-ts-enforcement.sh` の開放レンジ誤検知修正 (gate FP の恒久対応)
- コミット `3db71e5` — `sage/failures.md` への GATE-FP-0001 エントリ記録 (新テンプレートの dogfood 記録)

## File Scope（変更許可範囲）

- 変更: `templates/hooks/tests/test-ts-enforcement.sh`
- 変更: `sage/failures.md`（**追記のみ** — human-only 領域: PR レビュー・マージが human 承認行為）

## 禁止事項

- 上記 2 ファイル以外の変更
- sage/failures.md の既存エントリ・既存節の変更（追記以外の差分）
- scripts/sage-id-pattern.sh / templates/pre-commit-task-id.sh への波及（SPEC-0027 INV-03）

## 完了条件

- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS する
- [ ] `grep -qF 'GATE-FP-0001' sage/failures.md` が exit 0（GATE-FP-0001 エントリの存在）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0031-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （TASK-0210 実装セッションにて実施 — 遡及承認） |
| 開始     | 2026-07-03 |
| 完了     | 2026-07-03 |
| 結果     | Pass |
| Gate結果  | structural: ○ / functional: ○ / security: ○ |
