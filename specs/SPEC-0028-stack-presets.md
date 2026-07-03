# SPEC-0028: project_checks スタックプリセットと導入時自動検出

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0028 |
| ステータス | Draft |
| 作成日    | 2026-07-02 |
| 更新日    | 2026-07-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0018 (supply chain hardening / SHA256SUMS), SPEC-0014 (installer modular), SPEC-0026 (installer preservation 方針), SPEC-0027 (preserve-if-exists 先行例), SPEC-0002 (CI Gate enforcement), SPEC-0008 (Go dogfooding project_checks) |
| 権限レベル | platform |

## 背景・目的

`.sage/config.yaml` の `project_checks` は SPEC-0008 dogfooding 用の Go コマンド決め打ちであり、TypeScript/pnpm monorepo 等の実プロジェクトに導入する際、lint / format / type_check / test_command / coverage_command の全コマンドを手動で差し替える必要があった。config.yaml 内に commented examples (Node / Go / Python) はあるが、「選択して適用する」仕組みがなく、初期セットアップの摩擦と設定漏れ (= 全 Gate SKIPPED のまま気付かない) の原因になっている。

本 SPEC はスタックプリセット (`templates/project-checks/` 配下の YAML 断片) を新設し、`install.sh --stack <name>` による明示選択と、マーカーファイルからの自動検出提案を提供する。既存導入先の `.sage/config.yaml` には一切触れない (preserve-if-exists、SPEC-0026/0027 と同方針) ことを要とする。

## 対象ユーザー

- sage-ai-template を Go / TypeScript(pnpm) / Node(npm) / Python プロジェクトへ新規導入するチーム
- 既存導入先 (config.yaml あり) — 挙動変化ゼロであることが前提

## スコープ（含む）

- スタックプリセット定義 `templates/project-checks/` の新設 (4 ファイル):
  - `go.yaml` / `ts-pnpm.yaml` / `node-npm.yaml` / `python.yaml`
  - 各ファイルは `.sage/config.yaml` の `project_checks:` セクションに埋め込める YAML 断片 (キー: `lint` / `format` / `type_check` / `test_command` / `coverage_command`、標準ツールチェーンのみ)
  - 全プリセットが同一キーセット・同一インデント規約を持つ (機械検証可能)
- `install.sh` に `--stack go|ts-pnpm|node-npm|python` オプション追加:
  - **新規 install 時のみ** (config.yaml が存在しない場合のみ) 該当プリセットを生成する config.yaml の `project_checks` セクションに適用する
  - 未知の値は usage を表示して exit 非0 (どのファイルも書き込まない)
  - `--dry-run` 併用時は適用予定プリセットを表示するのみで書き込まない
- 自動検出 (`--stack` 未指定の新規 install 時):
  - マーカーファイル検出: `go.mod` → go、`pnpm-workspace.yaml` または `pnpm-lock.yaml` → ts-pnpm、`package.json` (pnpm マーカーなし) → node-npm、`pyproject.toml` → python
  - 複数検出時の優先順位: **go > ts-pnpm > node-npm > python** (pnpm マーカーは package.json より特異的なため ts-pnpm が node-npm に優先)。検出結果と優先順位判断を INFO で出力し、検出結果のプリセットをデフォルト適用する
  - 検出不能時: 現行どおり SKIPPED 前提の未設定テンプレート (commented examples) を書き込み、挙動は変更前と完全同一
- generator 対応: プリセットファイルを generator (`scripts/generator/`) 経由で `install.sh` に埋め込み、`install.sh` 再生成 + SHA256SUMS 更新 (再現性維持、FAIL-0002 教訓)
- 既存導入先の保護: config.yaml が存在する場合 (更新経路)、`--stack` 指定・自動検出のいずれも `project_checks` を変更しない。`--stack` 指定時は「既存 config.yaml があるため適用しない」旨を INFO 出力
- テスト `templates/hooks/tests/test-stack-presets.sh` の追加 (`_helpers.sh` / `run-tests.sh` の既存流儀に従う。テスト実装は Test Agent 責務):
  - (1) 各プリセット (`--stack` 4 種) 適用で config.yaml の project_checks が期待コマンドを含む
  - (2) 自動検出: 単一マーカー (go.mod のみ等) → 該当プリセット適用 + INFO
  - (3) 自動検出: 複数マーカー (go.mod + package.json) → 優先順位どおり go 適用 + INFO
  - (4) 自動検出: マーカーなし → 未設定テンプレート (現行と同一内容)
  - (5) 既存 config.yaml 保持: 配置済み環境で `--stack ts-pnpm` 実行後も既存内容がバイト不変
  - (6) dry-run 非介入: `--dry-run --stack go` でファイルが 1 つも作成・変更されない
  - (7) 異常系: 未知の `--stack` 値で exit 非0 + 書き込みなし
- docs (日本語): `docs/stack-presets.md` (新規) — プリセット一覧・各プリセットのコマンド内容・`--stack` / 自動検出の選択手順・優先順位・適用後のカスタマイズ方法 (config.yaml 直接編集)。README からの参照追記

## スコープ外（明示的に除外）

- TS enforcement プリセット (tsc エラー数ラチェット等) — S6 として別 SPEC
- 多言語 monorepo 向けの複数 `project_checks` ブロック (現行スキーマは単一ブロックのみ)
- 既存導入先への migration (`--stack` による既存 config.yaml の書き換え・マージ機能は提供しない)
- プリセットコマンドの実行検証 (導入先のツールチェーン存在確認・コマンド実行は行わない — 導入先環境依存)
- 本リポジトリ自身の `.sage/config.yaml` の変更 — Go dogfooding のまま維持
- 対話的なプリセット選択 UI (プロンプト入力) — 非対話 (CI) 実行を壊すため自動検出 + INFO のみ
- Rust / Java / Ruby 等の追加プリセット — 需要が確認されたら別 SPEC
- `--verify-checksum` / provenance / cosign 経路の変更 (SPEC-0018/0019 の検証フローには不介入)
- `AGENTS.md` / `docs/codex-*.md` の編集 (Codex-specific boundary)
- `sage/` 配下 governance 文書の改訂 (Human-only)
- CLAUDE.md §9.1 への機能追記 (Human-only) — マージ後に Human が「stack presets (SPEC-0028) — install.sh --stack go|ts-pnpm|node-npm|python + 自動検出、詳細: docs/stack-presets.md」を追記する follow-up として分離。PR 本文に追記案を記載する

## 要件

### 機能要件
- [FR-01] `templates/project-checks/{go,ts-pnpm,node-npm,python}.yaml` が存在し、各々 `lint` / `format` / `type_check` / `test_command` / `coverage_command` の 5 キーを持つ YAML 断片である
- [FR-02] `install.sh --stack <name>` は新規 install 時 (config.yaml 不在時)、生成する `.sage/config.yaml` の `project_checks` セクションを該当プリセットの内容で置き換える
- [FR-03] `--stack` に未知の値が渡された場合、usage を stderr に表示し exit 非0 で終了する。いかなるファイルも書き込まない
- [FR-04] `--stack` 未指定の新規 install 時、インストール先 (カレントディレクトリ) のマーカーファイルからスタックを検出し、検出結果を INFO で出力した上でデフォルト適用する。複数検出時は優先順位 go > ts-pnpm > node-npm > python に従い、検出した全マーカーと採用理由を INFO 出力する
- [FR-05] マーカー検出不能時は現行の未設定テンプレート (commented examples) を書き込み、出力・exit code とも変更前と同一である
- [FR-06] `.sage/config.yaml` が既に存在する場合、`--stack` 指定・自動検出のいずれも config.yaml を変更しない (preserve-if-exists)。`--stack` 明示時はスキップ理由を INFO 出力する
- [FR-07] `--dry-run` 併用時、適用予定プリセット (または検出結果) を表示するのみで、ファイルの作成・変更を一切行わない
- [FR-08] プリセットは generator 経由で `install.sh` に埋め込まれ、generator 変更後の `install.sh` は再生成され SHA256SUMS と一致する

### 非機能要件
- [NFR-01] 後方互換: `--stack` 未指定かつマーカー検出不能な環境での install の入出力 (生成ファイル内容・exit code) は変更前と完全同一
- [NFR-02] 再現性: 同一 generator 入力から生成される `install.sh` はバイト一致し、SHA256SUMS 検証を壊さない
- [NFR-03] 自動検出の追加コストはマーカーファイル存在チェック (定数回の `[ -f ]`) のみで、install 体感を悪化させない

### セキュリティ要件
- [SEC-01] `--stack` の引数値はファイルパス・シェルコマンドとして評価しない。許可リスト (go/ts-pnpm/node-npm/python) との完全一致比較のみで分岐し、パストラバーサル (`--stack ../evil`) を不能にする
- [SEC-02] プリセット内容は install.sh に埋め込み済みの静的文字列のみを使用し、インストール先のファイル内容 (package.json 等) を config.yaml に転記しない (マーカーは存在チェックのみ — 導入先ファイルからのコンテンツ注入を遮断)
- [SEC-03] プリセット適用は SHA256SUMS / provenance / `--verify-checksum` の検証対象・強度を縮小しない (SPEC-0018 フロー非破壊)

### 運用要件
- [OPS-01] `docs/stack-presets.md` にプリセット一覧・選択手順・優先順位・カスタマイズ方法を記載する
- [OPS-02] `make doctor` 既存チェックがプリセット適用後の config.yaml でも PASS する
- [OPS-03] 定量合格基準: リリース後2週間、`sage/failures.md` にプリセット誤適用 (意図しないスタックの適用 / 既存 config.yaml の書き換え) 起因の失敗記録が0件、かつ少なくとも1導入先で `--stack` または自動検出によるセットアップ完了 (Gate 1-2 が SKIPPED 以外で実行) を確認できた場合に安定 (Observe 完了) とみなす。誤適用報告1件で issue 起票、同種3件で `sage/anti-patterns.md` へ昇格検討

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: プリセット存在・形式 — `for f in go ts-pnpm node-npm python; do for k in lint format type_check test_command coverage_command; do grep -qE "^ *${k}:" "templates/project-checks/${f}.yaml" || exit 1; done; done` が exit 0 (case: `presets_exist_and_complete`)
- [ ] AC-02: 明示適用 — 空の一時ディレクトリで `bash install.sh --stack ts-pnpm` 実行後、`grep -F 'pnpm' .sage/config.yaml` が exit 0 かつ `grep -F 'go vet' .sage/config.yaml` が exit 非0 (case: `explicit_stack_applied`、4 プリセット全てで同型検証)
- [ ] AC-03: 自動検出 (単一) — `go.mod` のみ存在する一時ディレクトリで `--stack` なし install 後、config.yaml の project_checks に `go vet ./...` が含まれ、stdout に検出 INFO (`grep -F 'go.mod'`) が含まれる (case: `autodetect_single`)
- [ ] AC-04: 自動検出 (複数・優先順位) — `go.mod` + `package.json` が併存する一時ディレクトリで install 後、go プリセットが適用され、INFO に複数検出と採用理由が含まれる (case: `autodetect_priority`)
- [ ] AC-05: 検出不能 fallback — マーカーなし一時ディレクトリで install 後、config.yaml の `project_checks` セクションが `templates/hooks/tests/fixtures/project-checks-default.golden` (現行生成物から Test TASK で固定した fixture) と diff 一致する (case: `autodetect_none_fallback`)
- [ ] AC-06: 既存 config 保持 — カスタム project_checks 入り `.sage/config.yaml` 配置済み一時環境で `bash install.sh --stack python` 実行後、`diff` で config.yaml がバイト不変、かつ stdout にスキップ INFO が含まれる (case: `existing_config_preserved`)
- [ ] AC-07: 異常系 (未知スタック) — `bash install.sh --stack rust` が exit 非0、stderr に usage を含み、一時ディレクトリにファイルが 1 つも作成されない (`find . -type f | wc -l` が 0) (case: `unknown_stack_rejected`)
- [ ] AC-08: 異常系 (dry-run 非介入) — `bash install.sh --dry-run --stack go` 実行後、一時ディレクトリにファイルが 1 つも作成されず、stdout に適用予定プリセットの表示が含まれる (case: `dry_run_no_write`)
- [ ] AC-09: 再現性 — generator 再生成後 `shasum -a 256 -c SHA256SUMS` (install.sh エントリ) が成功する
- [ ] AC-10: 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する
- [ ] AC-11: 本リポジトリ非変更 — 本 SPEC の PR diff に本リポジトリの `.sage/config.yaml` が含まれない (`git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0)
- [ ] AC-12: ドキュメント — `grep -rqF 'templates/project-checks' docs/stack-presets.md README.md` が exit 0、かつ `grep -qF -- '--stack' docs/stack-presets.md` が exit 0 (case: `docs_reference`)

### 検証方針

- `templates/hooks/tests/test-stack-presets.sh` は integration テストとして、一時ディレクトリにマーカー fixture を配置して install.sh を実行し AC-01〜08 の各ケースを検証する (test-installer-preservation.sh の流儀を踏襲)。テスト実装は Test Agent 責務 (Implementation Agent と分離)。AC-05 の baseline として、変更前 install.sh の生成する `project_checks` セクションを `templates/hooks/tests/fixtures/project-checks-default.golden` に固定する fixture 作成を Test TASK に含める
- テスト種別: bash integration テストのみ。unit テストは対象がシェルスクリプトのため非適用
- カバレッジ閾値は N/A — bash スクリプトであり Gate 2 の LOC ベース coverage 計測の適用対象外。代替として異常系 (想定エラー1〜3・境界ケース1〜3) を全てテストケース化し網羅性を担保する

## 異常系

- 想定エラー1: 未知の `--stack` 値 — usage 表示 + exit 非0、書き込みゼロ (FR-03, AC-07)
- 想定エラー2: 既存 config.yaml がある環境で `--stack` を明示指定 — 適用せずスキップ INFO を出力し、install 自体は正常続行 (FR-06, AC-06)
- 想定エラー3: プリセット埋め込みの破損 (generator 再生成漏れで install.sh 内プリセットが欠落) — AC-09 の SHA256SUMS 検証と AC-01 の形式検証で検出し FAIL
- 境界ケース1: pnpm-lock.yaml と package.json の併存 — ts-pnpm を採用 (pnpm マーカーが特異的、FR-04)
- 境界ケース2: マーカーが 1 つも存在しない — 現行同一の未設定テンプレート、INFO も現行同等 (FR-05, AC-05)
- 境界ケース3: `--dry-run --stack <name>` — 表示のみで非介入 (FR-07, AC-08)

## 契約

- API: なし
- DB: なし
- イベント: なし
- CLI 契約: `install.sh --stack go|ts-pnpm|node-npm|python` を追加。既存オプション (`--dry-run` / `--verify-checksum` / `--remote` 等) の意味・exit code 規約は不変。`--stack` 未指定時の挙動は「自動検出 + 検出不能時は現行同一」
- ファイル契約: `templates/project-checks/<name>.yaml` — `project_checks` セクション用 YAML 断片 (5 キー固定: lint/format/type_check/test_command/coverage_command)。`.sage/config.yaml` は preserve-if-exists (存在時は installer が一切変更しない、SPEC-0026/0027 と同方針)

## リスク

- リスク1: 自動検出の誤判定 (例: ツール置き場に置かれた go.mod) で意図しないプリセットが適用される → 軽減策: 検出結果と根拠マーカーを INFO で明示し、docs に `--stack` での上書き手順と適用後のカスタマイズ方法を記載。適用は新規 install 時のみで既存設定は壊さない
- リスク2: generator 再埋め込み漏れでテンプレート側と install.sh 内プリセットが乖離する (FAIL-0002 再演) → 軽減策: generator 変更 → install.sh 再生成 → SHA256SUMS 更新を専用 TASK・単独コミットとし AC-09 で機械検証
- リスク3: プリセットコマンドが導入先のツールバージョンで動かない (例: pnpm 未導入なのに ts-pnpm 検出) → 軽減策: 実行検証はスコープ外と明示し、Gate 実行時に自然に FAIL/SKIPPED で顕在化する。docs にプリセットの前提ツールを記載
- リスク4: config.yaml 生成経路 (`write_file_if_new` + TMPL_CONFIG) へのセクション置換実装が、project_checks 以外の行に差分を出す → 軽減策: 置換は `project_checks:` セクション境界のみを対象とし、AC-05 (非検出時のバイト同一) で機械検証

### 知識管理 (failures.md 連携フロー)

- 実装中・リリース後にプリセット誤適用・既存 config 書き換え・検出誤判定を検出した場合、Implementation Agent は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する。同種の失敗が3回発生した場合は `sage/anti-patterns.md` へ昇格する (CLAUDE.md §5 Error Resolution Protocol 準拠、盲目的リトライ禁止)
- エラー報告時は §5 の6要素 (エラーログ / 失敗ファイル+行 / SPEC-0028 の該当 AC / git diff / 修正スコープ / 完了条件) を必ず含める

### ロールバック手順

- 本 SPEC のリリースに問題が発生した場合、直前リリースの `install.sh` + SHA256SUMS (GitHub Releases) に差し戻して再実行する。`--stack` は新規オプションのため、未使用なら旧 install.sh で完全に旧挙動へ戻る
- 導入先で誤適用が発生した場合の暫定回避: `.sage/config.yaml` の `project_checks` セクションを手動で修正 (または commented examples 状態に戻す)。installer は既存 config.yaml に触れないため再実行で悪化しない

## 実装メモ（Implementation Agent向け）

- **File Scope (Implementation Agent が変更可能なファイル)**:
  - `templates/project-checks/go.yaml` (新規)
  - `templates/project-checks/ts-pnpm.yaml` (新規)
  - `templates/project-checks/node-npm.yaml` (新規)
  - `templates/project-checks/python.yaml` (新規)
  - `scripts/generator/01-templates.sh` (プリセット埋め込み — 配置は 02 と実装時に判断、いずれか)
  - `scripts/generator/02-config.sh` (TMPL_CONFIG の project_checks セクション置換ロジック)
  - `scripts/generator/07-installer-main.sh` (`--stack` オプション解析・自動検出・INFO 出力・dry-run 分岐)
  - `install.sh` (再生成のみ・手動編集禁止)
  - `SHA256SUMS`
  - `templates/hooks/tests/test-stack-presets.sh` (新規 — **Test Agent 責務**)
  - `templates/hooks/tests/run-tests.sh` (登録行のみ、自動 discovery なら不要 — Test Agent 責務)
  - `README.md` (参照追記のみ)
  - `docs/stack-presets.md` (新規)

  上記以外の変更は禁止 (AP-03)。本リポジトリの `.sage/config.yaml` / `AGENTS.md` / `docs/codex-*.md` / `sage/` は特に不可。
- 現行の config.yaml 生成経路: `scripts/generator/02-config.sh` が本リポジトリの `.sage/config.yaml` から TMPL_CONFIG を生成し、`scripts/generator/07-installer-main.sh:732` の `write_file_if_new ".sage/config.yaml" "$TMPL_CONFIG"` で新規時のみ書き込む。プリセット適用はこの write 直前のセクション置換として実装するのが最小介入 (write_file_if_new の preserve 挙動は既にある — 更新経路の保護は現行機構で満たされることをテストで確認)
- オプション解析は `install.sh` 既存の引数ループ (`--dry-run` / `--verify-checksum` 周辺、生成元は 07-installer-main.sh) に追随。`--stack` は値を取るため `case` の shift 処理に注意
- プリセットのコマンド内容は config.yaml の既存 commented examples (Node/Go/Python) と SPEC-0008 の Go 実績値をベースにし、標準ツールチェーンのみ (golangci-lint 等の追加ツール前提を置かない)
- **FAIL-0002 の教訓**: generator 変更後は必ず `install.sh` を再生成して SHA256SUMS を追随させること。再生成 + SHA256SUMS 更新は専用 TASK・単独コミットとする。再生成漏れは AC-09 で FAIL する
- テストは `templates/hooks/tests/_helpers.sh` + `test-installer-preservation.sh` の流儀 (一時ディレクトリ + fixture 実行) を踏襲。テスト作成は Test Agent が別セッションで担当 (AP-04 回避)
- コミット規約: 全コミットに TASK-ID を含める (commit-msg hook で強制、AP-05)。PR 本文に SPEC-0028 / PLAN-ID / TASK-ID を記載
- 禁止事項: `--stack` 値のパス連結によるプリセット読み込み (SEC-01 — 許可リスト分岐で静的文字列を選ぶ)、導入先ファイル内容の config.yaml への転記 (SEC-02)、install.sh の手動編集、テスト未実行での受け入れ (AP-09)、テストを実装に合わせて改変して通すこと (§5 禁止事項)
- Slice 向け分割ヒント:

| TASK | 内容 | 対応 AC | コマンド検証可能な完了条件 | 依存 / 並列可否 |
|------|------|---------|--------------------------|----------------|
| T1 | プリセット 4 ファイル (`templates/project-checks/`) 新設 | AC-01 | AC-01 の grep ループが exit 0 | 依存なし |
| T2 | generator: プリセット埋め込み + project_checks セクション置換関数 | AC-02 (部分) | generator 単体実行で TMPL_CONFIG 置換結果が期待値 | T1 に依存 |
| T3 | generator: `--stack` 解析 + 自動検出 + INFO + dry-run 分岐 (07-installer-main.sh) | AC-02/03/04/05/06/07/08 (実装) | 一時ディレクトリでの手動 install 検証が各 AC 相当を満たす | T2 に依存 |
| T4 | install.sh 再生成 + SHA256SUMS 更新 (**専用 TASK・単独コミット** = FAIL-0002) | AC-09 | `shasum -a 256 -c SHA256SUMS` PASS | T3 後 |
| T5 | test-stack-presets.sh 追加 + run-tests.sh 登録 + AC-05 baseline fixture (`templates/hooks/tests/fixtures/project-checks-default.golden`) 作成 (**Test Agent 責務・別セッション**) | AC-01〜08/10 | `bash templates/hooks/tests/test-stack-presets.sh` 全ケース PASS + run-tests.sh 全件 PASS | T4 後 |
| T6 | docs (`docs/stack-presets.md` 新規 + README 参照追記) | AC-12 | AC-12 の grep 検証 PASS | T1 後に並列可 |

  実行順: T1 → T2 → T3 → T4 → T5。T6 は T1 完了後に並列可。各 TASK は単一責務を維持する。AC-11 (本リポジトリ config.yaml 非変更) は全 TASK 横断の制約として PR レビューで確認。

## Properties

権限レベル platform + Security 要件あり → 5 件以上。

### Invariants
- [INV-01] (Gate 2) `.sage/config.yaml` が既に存在する導入先では、installer のいかなる実行経路 (`--stack` 有無・自動検出・更新) でも config.yaml は 1 バイトも変更されない (preserve-if-exists の要)
- [INV-02] (Gate 2) `--stack` 未指定かつマーカー非検出の新規 install の生成物は、本 SPEC 適用前と完全同一である (後方互換)
- [INV-03] (Gate 3) `--stack` の引数値は許可リスト完全一致でのみ分岐され、ファイルパス・コマンドとして評価される経路が存在しない
- [INV-04] (Gate 3) config.yaml へ書き込まれる project_checks の値は install.sh 埋め込みの静的プリセット文字列のみであり、導入先ファイルの内容は転記されない
- [INV-05] (Gate 3) 再生成された `install.sh` は SHA256SUMS と一致し、SPEC-0018 の検証フロー (--verify-checksum / provenance) の対象・強度を縮小しない
- [INV-06] (Gate 4) プリセット定義の実体は `templates/project-checks/` の 4 ファイルのみであり、install.sh 内の埋め込みは generator による派生物である (二重管理による drift 禁止)

### Pre-conditions
- [PRE-01] (Gate 2) プリセット適用は「config.yaml 不在」の判定成立時のみ実行される (判定は書き込み直前に行う)
- [PRE-02] (Gate 2) 自動検出はマーカーファイルの存在チェックのみを行い、ファイル内容の読み取り・パースは行わない
- [PRE-03] (Gate 2) `--dry-run` 判定はプリセット適用を含む全書き込みに先行して評価される

### Post-conditions
- [POST-01] (Gate 2) プリセット適用後の config.yaml は `project_checks` セクション以外が未適用時の生成物と同一である (置換の局所性)
- [POST-02] (Gate 2) 自動検出が発動した場合、stdout に検出マーカー・採用プリセット・優先順位判断を含む INFO が必ず出力される (Invisible Development 回避)
- [POST-03] (Gate 3) generator 実行後の `install.sh` はバイト再現性を持ち、SHA256SUMS 検証が成功する

### Assumptions
- [ASM-01] (Gate 横断) 導入先は bash 3.2+ / POSIX ツールが利用可能 (既存 install.sh と同一前提)。マーカーファイルはインストール実行ディレクトリ直下のみを見る (サブディレクトリ再帰探索はしない)
- [ASM-02] (Gate 横断) プリセットコマンドが実際に動くか (ツールチェーン導入済みか) は導入先の運用責任。不適合時は Gate 実行で FAIL/SKIPPED として顕在化する
- [ASM-03] (Gate 横断) 本リポジトリ自身の `.sage/config.yaml` は Go dogfooding 設定のまま維持され、本 SPEC の実装・テストはそれに依存しない (テストは一時ディレクトリで完結)

## 関連ID

- PLAN-ID: [PLAN-0028](../plans/PLAN-0028-stack-presets.md)
- TASK-ID: TASK-0192 (T1 プリセット 4 ファイル) / TASK-0193 (T2 generator 埋め込み+置換) / TASK-0194 (T3 --stack 解析+自動検出) / TASK-0195 (T4 install.sh 再生成+SHA256SUMS) / TASK-0196 (T5 テスト+golden fixture, Test Agent) / TASK-0197 (T6 docs)
- Done Definition: [tasks/done-def-SPEC-0028-round-1.md](../tasks/done-def-SPEC-0028-round-1.md)
