# TASK-0043: `install.sh` に hook 展開 + settings.json 登録ロジック追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0043 |
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0042 |
| 見積     | 30m |

## 責務

`install.sh` に hook ファイル展開と `.claude/settings.json` への hook 定義登録ロジックを追加する。

## 入力

- TASK-0042 で更新された `scripts/generate-installer.sh` からの再生成対象
- 既存のインストールステップ [1/8]〜[8/8] の構造

## 出力

- 変更: `install.sh`（hook 展開 + settings.json 登録ロジックが追加された状態）

## File Scope（変更許可範囲）

- 変更: `install.sh`

## 禁止事項

- 既存のインストールステップ [1/8]〜[8/8] のロジックを変更しない

## 完了条件

- [ ] `install.sh` 実行後に `templates/hooks/` に 5 ファイルが展開される
- [ ] `install.sh` 実行後に `.claude/settings.json` に hook 定義が登録される

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0003-round-1.md`（実装開始前に作成）

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
