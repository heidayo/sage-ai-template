# TASK-0031: Gate 5 (`sage-release-gate.yml`) に Gate 1-4 前提条件を追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0031 |
| SPEC-ID   | SPEC-0002 |
| PLAN-ID   | PLAN-0002 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0028, TASK-0029, TASK-0030 |
| 見積     | 30m |

## 責務

Gate 5（release gate）に Gate 1〜4 の成功を前提条件として追加し、いずれかが failure の場合に Gate 5 も failure にする。

## 入力

- 既存の `sage-release-gate.yml` の内容
- TASK-0028, TASK-0029, TASK-0030 で改修済みの Gate 1, 2, 4 の構造
- SPEC-0002 の AC-04

## 出力

- 変更済み `.github/workflows/sage-release-gate.yml`

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-release-gate.yml`

## 禁止事項

- 他の workflow を触らない
- Gate 5 自体の `sage-validate.sh` チェックは残す

## 完了条件

- [ ] AC-04: Gate 1-4 のいずれかが failure で Gate 5 も failure

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
