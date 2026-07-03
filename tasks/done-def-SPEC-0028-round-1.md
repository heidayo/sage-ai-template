# Done Definition: SPEC-0028 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0028 |
| PLAN-ID   | PLAN-0028 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（スケルトン）→ Implementation Agent（具体値） |
| 検証者     | Verify Agent |

---

## 起動条件

### サーバー起動コマンド

```bash
# サーバー不要（bash スクリプト群 + CLI installer）。検証は一時ディレクトリにマーカー fixture を配置して行う
# scratch 環境の作り方は templates/hooks/tests/_helpers.sh / test-installer-preservation.sh の流儀に従う
```

### 前提条件チェック

- [ ] bash 3.2+ / POSIX ツール / shasum が利用可能: `bash --version && shasum --version`（ASM-01）
- [ ] ブランチが feature/s4-stack-presets である: `git branch --show-current`
- [ ] 既存テストが起点で全件 PASS: `bash templates/hooks/tests/run-tests.sh`

---

## テスト対象URL

N/A（Web アプリケーションではないためスキップ。検証対象は installer CLI の挙動）

---

## 受け入れ条件（このラウンドの完了条件）

### 自動検証（コマンドベース）

- [ ] `bash templates/hooks/tests/test-stack-presets.sh` が全ケース PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊, AC-10）
- [ ] `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功（AC-09）
- [ ] テストカバレッジ: N/A（bash スクリプトのため LOC coverage 非適用。代替として下記 CHECK 全件で異常系・境界ケースを網羅 — SPEC 検証方針）

### 機能検証（AC 1:1 対応）

- [ ] [CHECK-001] AC-01 プリセット存在・形式 — `for f in go ts-pnpm node-npm python; do for k in lint format type_check test_command coverage_command; do grep -qE "^ *${k}:" "templates/project-checks/${f}.yaml" || exit 1; done; done` が exit 0: (case: `presets_exist_and_complete`) PASS
- [ ] [CHECK-002] AC-02 明示適用 — 空の一時ディレクトリで `bash install.sh --stack ts-pnpm` 実行後、`grep -F 'pnpm' .sage/config.yaml` が exit 0 かつ `grep -F 'go vet' .sage/config.yaml` が exit 非0（4 プリセット全てで同型検証）: (case: `explicit_stack_applied`) PASS
- [ ] [CHECK-003] AC-03 自動検出（単一） — `go.mod` のみ存在する一時ディレクトリで `--stack` なし install 後、config.yaml の project_checks に `go vet ./...` が含まれ、stdout に検出 INFO（`grep -F 'go.mod'`）が含まれる: (case: `autodetect_single`) PASS
- [ ] [CHECK-004] AC-04 自動検出（複数・優先順位） — `go.mod` + `package.json` 併存の一時ディレクトリで install 後、go プリセットが適用され、INFO に複数検出と採用理由が含まれる（境界ケース1: pnpm-lock.yaml + package.json 併存 → ts-pnpm 採用も同ケースで検証）: (case: `autodetect_priority`) PASS
- [ ] [CHECK-005] AC-05 検出不能 fallback — マーカーなし一時ディレクトリで install 後、config.yaml の `project_checks` セクションが `templates/hooks/tests/fixtures/project-checks-default.golden`（**変更前** install.sh の生成物から固定した fixture）と diff 一致（境界ケース2）: (case: `autodetect_none_fallback`) PASS
- [ ] [CHECK-006] AC-06 既存 config 保持 — カスタム project_checks 入り `.sage/config.yaml` 配置済み一時環境で `bash install.sh --stack python` 実行後、`diff` で config.yaml がバイト不変、かつ stdout にスキップ INFO が含まれる（想定エラー2 / INV-01）: (case: `existing_config_preserved`) PASS
- [ ] [CHECK-007] AC-07 異常系（未知スタック） — `bash install.sh --stack rust` が exit 非0、stderr に usage を含み、一時ディレクトリにファイルが 1 つも作成されない（`find . -type f | wc -l` が 0、想定エラー1 / SEC-01）: (case: `unknown_stack_rejected`) PASS
- [ ] [CHECK-008] AC-08 異常系（dry-run 非介入） — `bash install.sh --dry-run --stack go` 実行後、一時ディレクトリにファイルが 1 つも作成されず、stdout に適用予定プリセットの表示が含まれる（境界ケース3 / PRE-03）: (case: `dry_run_no_write`) PASS
- [ ] [CHECK-009] AC-09 再現性 — generator 再生成後 `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功する（NFR-02 / INV-05、想定エラー3 の検出経路）
- [ ] [CHECK-010] AC-10 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する
- [ ] [CHECK-011] AC-11 本リポジトリ非変更 — `git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0（全 TASK 横断制約 / ASM-03）
- [ ] [CHECK-012] AC-12 ドキュメント — `grep -rqF 'templates/project-checks' docs/stack-presets.md README.md` が exit 0、かつ `grep -qF -- '--stack' docs/stack-presets.md` が exit 0: (case: `docs_reference`) PASS

### 非機能検証（該当する場合）

- [ ] NFR-01 後方互換 — `--stack` 未指定かつマーカー非検出の install の生成物・exit code が変更前と完全同一（CHECK-005 golden diff + CHECK-010 で担保）
- [ ] NFR-02 再現性 — generator 再実行で install.sh がバイト一致（CHECK-009）
- [ ] NFR-03 性能 — 自動検出の追加コストがマーカー存在チェック（定数回の `[ -f ]`）のみである（実装レビューで確認、内容読み取り・再帰探索なし — PRE-02/ASM-01）
- [ ] SEC-01 — `--stack` 値の許可リスト完全一致分岐のみで、パス連結・コマンド評価経路が存在しない（`--stack ../evil` が CHECK-007 同型で拒否される）
- [ ] SEC-02 — config.yaml へ書き込まれる project_checks が install.sh 埋め込みの静的文字列のみ（導入先ファイル内容の非転記、実装レビュー + CHECK-002）
- [ ] SEC-03 — `--verify-checksum` / provenance 検証フローの対象・強度が縮小されていない（CHECK-009 + diff レビュー）
- [ ] OPS-02 — プリセット適用後の config.yaml で `make doctor` が PASS

---

## ブラウザ検証（Playwright MCP 使用時のみ）

N/A — シェルスクリプト/CLI のためスキップ。

---

## Pass/Fail 判定基準

| 項目 | 閾値 | 必須/オプション |
|------|------|---------------|
| test-stack-presets.sh | 全ケース PASS | 必須（1つでも失敗 = Fail） |
| run-tests.sh（既存テスト） | 全件 PASS | 必須 |
| SHA256SUMS 検証 | PASS | 必須 |
| 機能検証 CHECK-001〜012 | 全項目 Pass | 必須 |
| 非機能検証 | 全項目 Pass | 必須 |
| ブラウザ検証 | — | N/A |

---

## Fail 時の構造化フィードバック形式

Verify Agent が Fail 判定した場合、以下の YAML 構造で Implementation Agent にフィードバックする。

```yaml
fail_feedback:
  round: 1
  iteration: M
  verdict: FAIL
  failed_items:
    - id: "CHECK-XXX"          # 上記 CHECK-001〜012 のいずれか
      category: "functional"   # functional | structural | security | architecture
      expected: "対応する AC の期待値を具体的に記述（例: AC-06 config.yaml バイト不変）"
      actual: "実測値を具体的に記述（例: project_checks セクションが python プリセットで上書きされた）"
      log_snippet: "テスト出力の抜粋（最大10行）"
  fix_scope:
    - file: "scripts/generator/07-installer-main.sh"
      reason: "修正が必要な具体的理由（該当 TASK の File Scope 内に限る）"
  instruction: "1. [具体的な修正手順1] 2. [具体的な修正手順2]"
  retry_allowed: true   # false の場合、abort して Human にエスカレーション
  same_fail_count: 1    # 同一 CHECK-ID の連続失敗回数（3 で abort → sage/failures.md 記録）
```

### フィードバック形式のルール

- `failed_items.id` は本 Done Definition の CHECK-ID（CHECK-001〜012）と一致させること
- `category` は 4 種類のいずれか: `functional`, `structural`, `security`, `architecture`
- `log_snippet` は最大 10 行。長い場合はファイルパスで参照する
- `fix_scope` には該当 TASK（TASK-0192〜0197）の File Scope 内のファイルのみ記載する
- `instruction` は Implementation Agent が即座に実行可能な具体性で記述する
- generator 由来の FAIL（CHECK-009 等）の fix は generator 側を修正し install.sh を再生成すること（手動編集禁止）
- `same_fail_count` が 3 に達した場合は abort し、`sage/failures.md` へ TASK-ID 付きで記録する（CLAUDE.md §5）
