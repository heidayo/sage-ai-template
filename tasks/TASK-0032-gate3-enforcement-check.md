# TASK-0032: Gate 3 (`sage-security-gate.yml`) の enforcement 確認

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0032 |
| SPEC-ID   | SPEC-0002 |
| PLAN-ID   | PLAN-0002 |
| ステータス | Pending |
| 担当Agent | Review |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 15m |

## 責務

Gate 3（security gate）の enforcement 設定が正しいことを確認し、必要な場合のみ修正する。

## 入力

- 既存の `sage-security-gate.yml` の内容
- Gitleaks / Trivy の設定状況

## 出力

- 変更済み `.github/workflows/sage-security-gate.yml`（必要な場合のみ）
- 確認結果レポート

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-security-gate.yml`（必要な場合のみ）

## 禁止事項

- enforcement が既に正しい場合は変更しない

## 完了条件

- [ ] Gitleaks が `continue-on-error: false` であることを確認
- [ ] Trivy の動作確認

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
