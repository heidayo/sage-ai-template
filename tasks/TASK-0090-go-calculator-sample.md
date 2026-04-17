# TASK-0090: Go 電卓 HTTP API の src/tests 配置 (dogfooding)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0090 |
| SPEC-ID   | SPEC-0009 |
| PLAN-ID   | PLAN-0008-F |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 2h |

## 責務

SAGE テンプレート自身がテンプレ通りに運用できる実証 (dogfooding) のため、最小の Go 電卓 HTTP API をサンプルアプリとして `src/calculator/` と `tests/calculator/` に配置する。標準ライブラリのみ使用。カバレッジ 80% 以上。

## 入力

- `src/` `tests/` が現状 `.gitkeep` のみで空
- SAGE File Scope Rules: `src/` = Implementation Agent、`tests/` = Test Agent
- Go convention: tests are beside source (`*_test.go` in the same dir)

## 出力

- `go.mod` (repo root): module `github.com/heidayo/sage-ai-template`, go 1.22
- `src/calculator/calc.go`: 加減乗除 4 関数 (package calculator)
- `src/calculator/server.go`: `net/http` ベースの最小サーバ (package calculator)
- `tests/calculator/calc_test.go`: 関数単位のテスト (package calculator_test)
- `tests/calculator/server_test.go`: `httptest` ベースの HTTP テスト (package calculator_test)

tests/ を外部パッケージ (`package calculator_test`) として扱うことで SAGE の `src/` と `tests/` File Scope 分離を Go 的にも成立させる。

## File Scope（変更許可範囲）

- 作成:
  - `go.mod` (repo root)
  - `src/calculator/calc.go`
  - `src/calculator/server.go`
  - `tests/calculator/calc_test.go`
  - `tests/calculator/server_test.go`
  - `tasks/TASK-0090-go-calculator-sample.md` (本ファイル)
- 変更:
  - `src/.gitkeep` 削除 (dir に実ファイルが入るため不要)
  - `tests/.gitkeep` 削除 (同上)
- 削除:
  - `src/.gitkeep`
  - `tests/.gitkeep`

## 禁止事項

- Go 外部依存 (net/http/httptest/testing 以外) の追加禁止
- `go.sum` の手書き (必要なら `go mod tidy` で生成)
- SPEC-0008 の他 TASK への波及編集禁止

## 完了条件

- [ ] `go build ./...` がエラーなくビルドできる (環境に Go 1.22+ があれば)
- [ ] `go test ./... -coverprofile=coverage.out` が全テスト PASS、coverage >= 0.80
- [ ] `go vet ./...` が 0 issue
- [ ] `gofmt -l .` が差分なし
- [ ] コミットメッセージに `TASK-0090` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-F 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
