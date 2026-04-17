# SPEC-0009: Calculator HTTP API (SAGE Dogfooding Sample)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0009 |
| ステータス | Implemented |
| 作成日    | 2026-04-17 |
| 更新日    | 2026-04-17 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0008 (enforcement gap closure — 本 SPEC の検証に必要な機能が提供される) |
| 権限レベル | feature |

## 背景・目的

SAGE テンプレート自身に対する最大の批判の一つは「全 SPEC が自己メタ改善で、実アプリ適用実績がゼロ」という点だった (外部レビュー 2026-04)。テンプレートが示す 5 Gate / File Scope / traceability / RUN ログ等のガードレールが実際のアプリ開発で機能することを証明するため、最小の Go HTTP API を「このテンプレで作ったアプリ」として切り出す。機能要件よりもサンプルとしての明瞭さを優先する。

## 対象ユーザー

- SAGE テンプレートを評価する maintainer / 利用者
- Gate 2 カバレッジ閾値 / Gate 4 レイヤ境界 / Gate 1 lint 等、SPEC-0008 で実装した機能を動作確認する CI

## スコープ（含む）

- 加減乗除の純粋計算関数 (`src/calculator/calc.go`)
- `/calc?op=X&a=N&b=M` エンドポイント (`src/calculator/server.go`)
- ユニットテスト + HTTP 統合テスト (`tests/calculator/*_test.go`)
- Go 標準ライブラリのみ使用 (`net/http`, `testing`, `httptest`, `strconv`, `encoding/json`)
- エラーパス (0 除算 = 422、不正パラメータ = 400、未知 op = 400) の網羅
- カバレッジ 80% 以上を達成する程度のテスト密度
- `.sage/config.yaml` の `project_checks` で Go コマンドを有効化し、Gate 1/2 が実走する状態

## スコープ外（明示的に除外）

- 認証 / レート制限 / 永続化 / データベース接続 (サンプルなので意図的に省く)
- golangci-lint / gocyclo / gosec 等の外部 lint ツール (標準 toolchain のみで template をシンプルに保つ)
- Python / Node 並列実装 (別 SPEC で扱う余地を残す)
- OpenAPI / gRPC (HTTP JSON のみ)
- Docker / CI build image の整備 (GitHub Actions 標準 runner に依存)

## 要件

### 機能要件

- [FR-01] Add/Sub/Mul/Div の 4 関数を公開 API として持つ
- [FR-02] Div は 0 除算で `ErrDivByZero` エラーを返す
- [FR-03] `Apply(op, a, b)` で op 文字列から対応関数へディスパッチする
- [FR-04] `Apply` は未知 op でエラーを返す
- [FR-05] `/calc` エンドポイントは JSON `{result,error}` 形式を返す
- [FR-06] 0 除算時は HTTP 422 + error 文字列
- [FR-07] 不正なクエリパラメータで HTTP 400 + error 文字列

### 非機能要件

- [NFR-01] テストカバレッジ ≥ 80% (SPEC-0008 TASK-0070 の閾値を実証)
- [NFR-02] 外部依存ゼロ (`go.mod` に require なし)
- [NFR-03] `go vet ./...` が 0 issue
- [NFR-04] `gofmt -l .` が差分なし

### セキュリティ要件

- [SEC-01] 該当なし (pure compute, no I/O beyond HTTP echo)。ただし CI の Gate 3 (Gitleaks / Trivy) は通過すること

### 運用要件

- [OPS-01] GitHub Actions の setup-go で Go 1.22+ を install
- [OPS-02] `.sage/config.yaml` の `project_checks` が本 SPEC 成立後は有効状態

## 受け入れ条件（Acceptance Criteria）

- [x] AC-01: `go test ./... -coverprofile=coverage.out` が全テスト PASS
- [x] AC-02: `go tool cover -func=coverage.out | tail -1` が 80.0% 以上
- [x] AC-03: `go vet ./...` が 0 issue
- [x] AC-04: `gofmt -l .` 出力が空
- [x] AC-05: `src/calculator/` と `tests/calculator/` 以外に変更がない (File Scope 準拠)
- [x] AC-06: `/calc?op=div&a=1&b=0` が HTTP 422 を返す
- [x] AC-07: `/calc?op=unknown&a=1&b=2` が HTTP 400 を返す

## 異常系

- 0 除算: `ErrDivByZero` 明示エラー、server では 422
- 未知 op: エラー文字列を含む 400
- 非数値パラメータ (`a=foo`): 400
- 欠落パラメータ (`a` 無し): 非数値パラメータと同じ扱い (400)

## 契約

- API: `GET /calc?op={add|sub|mul|div}&a=<float>&b=<float>` → JSON `{result: number}` または `{error: string}`
- DB: なし
- イベント: なし

## リスク

- リスク 1: GitHub Actions runner に Go が未インストール → 軽減策: workflow で `actions/setup-go@v5` + `go-version-file: go.mod`
- リスク 2: `coverage.out` ファイルがテスト失敗時に生成されないと coverage_command がエラー → 軽減策: test が成功した後に coverage を読む前提、FAIL時は coverage SKIPPED として扱う workflow

## 実装メモ（Implementation Agent向け）

- File Scope:
  - Implementation Agent: `src/calculator/` のみ
  - Test Agent: `tests/calculator/` のみ
  - Tests は external test package (`package calculator_test`) で書き、ブラックボックス検査にする
- import パス: `github.com/heidayo/sage-ai-template/src/calculator`

## 関連ID

- PLAN-ID: PLAN-0008-F
- TASK-ID: TASK-0090 (実装), TASK-0091 (project_checks config), TASK-0092 (本 SPEC 作成), TASK-0093 (5 Gate 実走)
