# TASK-0034: SPEC-0002 の全 AC 検証

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0034 |
| SPEC-ID   | SPEC-0002 |
| PLAN-ID   | PLAN-0002 |
| ステータス | Pending |
| 担当Agent | Test |
| 並列可否  | No |
| 依存TASK  | TASK-0033 |
| 見積     | 30m |

## 責務

SPEC-0002 の全 AC（AC-01〜AC-08）が正しく実装されていることを検証する。

## 入力

- SPEC-0002 の AC-01〜AC-08 定義
- TASK-0027〜TASK-0033 の実装成果物

## 出力

- 検証結果レポート（全 AC の Pass/Fail 判定）

## File Scope（変更許可範囲）

- 変更なし（ReadOnly）

## 禁止事項

- コードを修正しない

## 完了条件

- [ ] AC-01: config 未設定時に SKIPPED 表示 — 検証済み
- [ ] AC-02: テスト失敗時に failure — 検証済み
- [ ] AC-03: トレーサビリティ違反で failure — 検証済み
- [ ] AC-04: Gate 1-4 failure で Gate 5 も failure — 検証済み
- [ ] AC-05: security gate enforcement — 検証済み
- [ ] AC-06: `make validate` 回帰なし — 検証済み
- [ ] AC-07: config 不在で SKIP — 検証済み
- [ ] AC-08: YAML 不正で failure — 検証済み

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0002-round-1.md`（実装開始前に作成）

Done Definition は SPEC 単位・ラウンド単位で作成する。
テンプレート: `templates/done-definition-template.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
