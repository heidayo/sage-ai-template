# TASK-0033: 全 Gate の PRコメントに PASS/FAIL/SKIPPED 3状態表示を統一

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0033 |
| SPEC-ID   | SPEC-0002 |
| PLAN-ID   | PLAN-0002 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0028, TASK-0029, TASK-0030 |
| 見積     | 20m |

## 責務

全 Gate の PR コメントに PASS / FAIL / SKIPPED の3状態表示を統一フォーマットで出力する。

## 入力

- TASK-0028, TASK-0029, TASK-0030 で改修済みの各 Gate workflow
- 既存の各 Gate workflow の PR コメント出力部分

## 出力

- 変更済み `.github/workflows/sage-structural-gate.yml`
- 変更済み `.github/workflows/sage-functional-gate.yml`
- 変更済み `.github/workflows/sage-architecture-gate.yml`
- 変更済み `.github/workflows/sage-release-gate.yml`
- 変更済み `.github/workflows/sage-security-gate.yml`

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-structural-gate.yml`
- 変更: `.github/workflows/sage-functional-gate.yml`
- 変更: `.github/workflows/sage-architecture-gate.yml`
- 変更: `.github/workflows/sage-release-gate.yml`
- 変更: `.github/workflows/sage-security-gate.yml`

## 禁止事項

- ゲートのロジック自体を変更しない（表示のみ）

## 完了条件

- [ ] 各 workflow の PR コメントに PASS / FAIL / SKIPPED の3状態が表示される
- [ ] PASS は表示される
- [ ] FAIL は表示される
- [ ] SKIPPED は表示される

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
