# TASK-0091: project_checks を Go 向け実コマンドに設定

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0091 |
| SPEC-ID   | SPEC-0009 |
| PLAN-ID   | PLAN-0008-F |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0090 sample app 必須) |
| 依存TASK  | TASK-0090 |
| 見積     | 0.3h |

sage-managed: true

## 責務

TASK-0090 で配置した Go 電卓サンプルを CI から実際に Lint/Test/Coverage できるよう、`.sage/config.yaml` の `project_checks` セクションを Go 向けコマンドで有効化する。

## 入力

- `src/calculator/` と `tests/calculator/` (TASK-0090 済)
- `go.mod` (TASK-0090 済)
- `.sage/config.yaml` の `project_checks` (現状すべてコメントアウト)

## 出力

- `project_checks`:
  - `lint: "go vet ./..."` (golangci-lint が前提できないため go vet で代替)
  - `format: "test -z \"$(gofmt -l .)\""` (差分出力無しを確認)
  - `type_check: "go build ./..."` (コンパイル通過で型チェック相当)
  - `test_command: "go test ./... -coverprofile=coverage.out"`
  - `coverage_command: "go tool cover -func=coverage.out | tail -1 | awk '{print $NF}'"`

## File Scope（変更許可範囲）

- 作成:
  - `tasks/TASK-0091-project-checks-go-config.md` (本ファイル)
- 変更:
  - `.sage/config.yaml` (`project_checks` セクションのみ)
- 削除: なし

## 禁止事項

- 外部 linter (golangci-lint 等) の導入禁止 (Go 標準ツールのみ)
- 他 config セクションの変更禁止
- `src/` `tests/` の変更禁止

## 完了条件

- [ ] `.sage/config.yaml` の `project_checks` で 5 コマンドが有効化されている
- [ ] `bash -c "$(yq -r '.project_checks.test_command' .sage/config.yaml)"` が shell 的に解釈可能なコマンド文字列
- [ ] コミットメッセージに `TASK-0091` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-F 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
