# スタックプリセット（SPEC-0028）

`.sage/config.yaml` の `project_checks` は、CI Gate 1（lint / format / type check）と Gate 2（test / coverage）で実行するコマンドを定義します。未設定のままだと該当 Gate は SKIPPED になります。スタックプリセットは、新規導入時にこの `project_checks` を主要スタックの標準コマンドで初期化する仕組みです。

プリセットの実体は `templates/project-checks/` 配下の YAML 断片（4 ファイル）で、generator により `install.sh` に静的文字列として埋め込まれます（導入先のファイル内容が config.yaml に転記されることはありません）。

## プリセット一覧

| プリセット | 対象スタック | 前提ツール |
|-----------|-------------|-----------|
| `go` | Go | Go 標準ツールチェーン（`go vet` / `gofmt` / `go build` / `go test` / `go tool cover`） |
| `ts-pnpm` | TypeScript + pnpm | pnpm, prettier, tsc, nyc（`pnpm run lint` / `pnpm test` は package.json の scripts 定義が前提） |
| `node-npm` | Node.js + npm | npm, prettier, tsc, nyc（`npm run lint` / `npm test` は package.json の scripts 定義が前提） |
| `python` | Python | ruff, black, mypy, pytest（pytest-cov）, coverage |

### 各プリセットのコマンド内容

#### go（`templates/project-checks/go.yaml`）

```yaml
  lint: "go vet ./..."
  format: 'test -z "$(gofmt -l .)"'
  type_check: "go build ./..."
  test_command: "go test ./... -coverprofile=coverage.out"
  coverage_command: "go tool cover -func=coverage.out | tail -1 | awk '{print $NF}'"
```

#### ts-pnpm（`templates/project-checks/ts-pnpm.yaml`）

```yaml
  lint: "pnpm run lint"
  format: "pnpm exec prettier --check ."
  type_check: "pnpm exec tsc --noEmit"
  test_command: "pnpm test"
  coverage_command: "pnpm exec nyc report --reporter=text-summary | grep Lines | awk '{print $3}'"
```

#### node-npm（`templates/project-checks/node-npm.yaml`）

```yaml
  lint: "npm run lint"
  format: "npx prettier --check ."
  type_check: "npx tsc --noEmit"
  test_command: "npm test"
  coverage_command: "npx nyc report --reporter=text-summary | grep Lines | awk '{print $3}'"
```

#### python（`templates/project-checks/python.yaml`）

```yaml
  lint: "ruff check ."
  format: "black --check ."
  type_check: "mypy ."
  test_command: "pytest --cov=src --cov-report=term-missing"
  coverage_command: "coverage report --format=total"
```

## 使い方

### 明示選択（`--stack`）

新規導入時に `--stack` でプリセットを指定します:

```bash
bash install.sh --stack ts-pnpm
```

- 許可値は `go` / `ts-pnpm` / `node-npm` / `python` の 4 つのみ。未知の値は usage を表示して exit 非0 となり、ファイルは一切書き込まれません。
- `--dry-run --stack <name>` は適用予定プリセットを表示するだけで、何も書き込みません。

### 自動検出（`--stack` 未指定時）

`--stack` を指定せずに新規 install すると、カレントディレクトリ直下のマーカーファイルからスタックを検出し、INFO 出力の上でデフォルト適用します:

| マーカーファイル | 検出されるプリセット |
|-----------------|-------------------|
| `go.mod` | `go` |
| `pnpm-workspace.yaml` または `pnpm-lock.yaml` | `ts-pnpm` |
| `package.json`（pnpm マーカーなし） | `node-npm` |
| `pyproject.toml` | `python` |

- **複数検出時の優先順位: go > ts-pnpm > node-npm > python**（pnpm マーカーは package.json より特異的なため ts-pnpm が node-npm に優先）。検出した全マーカーと採用理由が INFO 出力されます。
- 検出はファイルの**存在チェックのみ**で、内容は読み取りません。サブディレクトリは探索しません。
- マーカーが 1 つも見つからない場合は、従来どおりの未設定テンプレート（commented examples、全 Gate SKIPPED 前提）が書き込まれます。

### 誤検出時の上書き

意図しないスタックが検出された場合（例: ツール置き場の `go.mod` を拾った）は、`--stack` で明示指定して上書きしてください:

```bash
bash install.sh --stack python   # 自動検出結果を無視して python を適用
```

## 既存導入先の扱い（preserve-if-exists）

`.sage/config.yaml` が既に存在する場合、`--stack` 指定・自動検出のいずれも **config.yaml を一切変更しません**（SPEC-0026/0027 と同方針）。`--stack` を明示した場合は「既存 config.yaml があるため適用しない」旨の INFO が出力され、install 自体は正常に続行します。

既存導入先でプリセット相当の設定にしたい場合は、`templates/project-checks/<name>.yaml` の内容を参考に `.sage/config.yaml` の `project_checks` セクションを手動で編集してください。

## 適用後のカスタマイズ

プリセットは初期値にすぎません。適用後は `.sage/config.yaml` の `project_checks` セクションを直接編集して、プロジェクトの実コマンドに合わせて調整してください:

```yaml
project_checks:
  lint: "pnpm run lint"
  # 例: coverage を vitest に変更
  test_command: "pnpm vitest run --coverage"
  coverage_command: "..."
```

- `coverage_command` の出力にはパース可能な数値（0-1 または 0-100）が含まれる必要があります（`scripts/sage-coverage-parse.sh` が最初の数値を抽出します）。
- プリセットのコマンドが実際に動くか（ツールチェーン導入済みか）の検証は installer では行いません。不足があれば Gate 実行時に FAIL / SKIPPED として顕在化します。
- 適用後の健全性確認: `make doctor`

## 関連

- SPEC: `specs/SPEC-0028-stack-presets.md`
- プリセット実体: `templates/project-checks/`
- Gate 設定全般: `.sage/config.yaml` の `project_checks` / `quality_gates`
