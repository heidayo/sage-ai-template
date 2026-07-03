# Done Definition: SPEC-0030 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0030 |
| PLAN-ID   | PLAN-0030 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（スケルトン）→ Implementation Agent（具体値） |
| 検証者     | Verify Agent |

---

## 起動条件

### サーバー起動コマンド

```bash
# サーバー不要（bash スクリプト + テンプレート断片 + docs）。検証は一時ディレクトリに
# mock tsc fixture（templates/hooks/tests/fixtures/mock-tsc-*.sh）を配置し、
# SAGE_TSC_COMMAND / --tsc-command で注入して行う（Node / tsc 実物非依存、NFR-03）
```

### 前提条件チェック

- [ ] bash 3.2+ / POSIX ツール（grep/sed/wc）が利用可能: `bash --version`（ASM-01）
- [ ] ブランチが feature/s6-ts-enforcement である: `git branch --show-current`
- [ ] 既存テストが起点で全件 PASS: `bash templates/hooks/tests/run-tests.sh`

---

## テスト対象URL

N/A（Web アプリケーションではないためスキップ。検証対象は CLI スクリプトの挙動とファイル成果物）

---

## 受け入れ条件（このラウンドの完了条件）

### 自動検証（コマンドベース）

- [ ] `bash templates/hooks/tests/test-ts-enforcement.sh` が全ケース PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊, AC-10）
- [ ] テストカバレッジ: N/A（bash スクリプトのため LOC coverage 非適用。代替として異常系・境界ケース全件を下記 CHECK で網羅 — SPEC 検証方針）

### 機能検証（AC 1:1 対応）

- [ ] [CHECK-001] AC-01 ラチェット基本動作 — mock tsc（固定 3 エラー）を `SAGE_TSC_COMMAND` 注入し `bash scripts/sage-tsc-ratchet.sh --init` 後、`grep -F '"errors": 3' .tsc-baseline.json` が exit 0、続く検査モードが exit 0（FR-01/02, POST-02）: (case: `init_and_check_equal`)
- [ ] [CHECK-002] AC-02 増加検出 — baseline 3 + 5 エラー版 mock で検査モード → exit 1、出力に現在数 5・baseline 3・増分 2（FR-01, INV-02, POST-01）: (case: `increase_detected`)
- [ ] [CHECK-003] AC-03 減少 + 正規更新経路 — baseline 3 + 1 エラー版 mock で検査モード → exit 0 + update 推奨 INFO。`--update` 後 `grep -F '"errors": 1' .tsc-baseline.json` が exit 0（FR-02, POST-02/03）: (case: `decrease_and_update`)
- [ ] [CHECK-004] AC-04 異常系（不正 baseline） — `{"errors": -1}` / `{"errors": "abc"}` / `not-json` の各不正値で検査モード → いずれも exit 1、stderr に理由、baseline ファイルがバイト不変（FR-04, INV-01, PRE-02, 想定エラー1）: (case: `invalid_baseline_rejected`)
- [ ] [CHECK-005] AC-05 異常系（baseline 不在） — baseline なしで検査モード → exit 1、stderr の `--init` 案内が `grep -F -- '--init'` で exit 0（FR-05, 想定エラー2）: (case: `missing_baseline_guided`)
- [ ] [CHECK-006] AC-06 tsc 注入の優先順位 — `--tsc-command` 引数のみで動作 + `SAGE_TSC_COMMAND` 併存時に環境変数優先（FR-03, PRE-03）: (case: `tsc_injection_priority`)
- [ ] [CHECK-007] AC-07 ESLint 断片形式 — `for f in eslint-flat.mjs eslint-flat-transitional.mjs eslintrc-fragment.json; do test -f "templates/ts-enforcement/$f" || exit 1; done` が exit 0、`grep -F 'ban-ts-comment' templates/ts-enforcement/eslint-flat.mjs` / `grep -F 'no-explicit-any' templates/ts-enforcement/eslint-flat-transitional.mjs` が exit 0 で transitional 版が warn 指定（FR-06）: (case: `eslint_fragments_present`)
- [ ] [CHECK-008] AC-08 jq/eval 非依存 — `grep -E '\bjq\b|\beval\b' scripts/sage-tsc-ratchet.sh` が exit 非0（NFR-02, INV-03, SEC-01）: (case: `no_jq_no_eval`)
- [ ] [CHECK-009] AC-09 installer 非変更 — `git diff --name-only main | grep -E '^(install\.sh|SHA256SUMS|scripts/generator/)'` が exit 非0（INV-05, SEC-04、全 TASK 横断制約）: (case: `installer_untouched`)
- [ ] [CHECK-010] AC-10 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS（OPS-02）: (case: `all_tests_pass`)
- [ ] [CHECK-011] AC-11 ドキュメント — `grep -qF 'sage-tsc-ratchet' docs/ts-enforcement.md && grep -qF 'ts-enforcement' docs/stack-presets.md && grep -qF 'ts-enforcement' README.md` が exit 0、かつ `grep -qF 'tsconfig' docs/ts-enforcement.md` が exit 0、かつ `grep -qE '昇格|graduation' docs/ts-enforcement.md` が exit 0（FR-07/08, OPS-01）: (case: `docs_reference`)
- [ ] [CHECK-012] AC-12 ts-pnpm プリセット不変 — `git diff main -- templates/project-checks/ts-pnpm.yaml` が空（5 キーのコマンド値含め不変、INV-06, リスク5）: (case: `preset_values_unchanged`)

### 非機能検証（該当する場合）

- [ ] NFR-01 後方互換 — 変更ファイルが新規追加 + docs 参照追記のみ: `git diff --name-only main` が PLAN-0030 影響範囲表の 10 ファイル以内に収まる
- [ ] NFR-02 可搬性 — `sage-tsc-ratchet.sh` が jq / node / python 非依存（CHECK-008 + 実装レビュー）
- [ ] NFR-03 テスト独立性 — test-ts-enforcement.sh が Node.js / tsc 実物なしで PASS（mock fixture のみ）
- [ ] SEC-01 — tsc コマンドは `sh -c` 単一経路・eval 不使用（CHECK-008 + 実装レビュー）、docs に外部入力を渡さない旨の明記（`grep` 確認）
- [ ] SEC-02 — baseline 書き込みが静的スキーマ + 数値 + タイムスタンプのみ（tsc 出力の非転記、実装レビュー + CHECK-001/003）
- [ ] SEC-03 — baseline 読み取り値の非負整数検証後のみ数値比較（CHECK-004 + 実装レビュー）
- [ ] SEC-04 — installer / SHA256SUMS / provenance 検証フロー非介入（CHECK-009）
- [ ] 境界ケース1 — tsc エラー 0 件で baseline 0 が正常動作し、0 からの増加も検出される（テストケース化）
- [ ] 境界ケース2 — tsc 実行失敗（パターン 0 件 + 非0 exit）→ exit 1 + 出力透過（エラー 0 件と誤認しない、テストケース化）
- [ ] 想定エラー3 — `--init` を既存 baseline で実行 → exit 1 + `--update` 案内、baseline 非変更（テストケース化）

---

## ブラウザ検証（Playwright MCP 使用時のみ）

N/A — シェルスクリプト/CLI のためスキップ。

---

## Pass/Fail 判定基準

| 項目 | 閾値 | 必須/オプション |
|------|------|---------------|
| test-ts-enforcement.sh | 全ケース PASS | 必須（1つでも失敗 = Fail） |
| run-tests.sh（既存テスト） | 全件 PASS | 必須 |
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
      expected: "対応する AC の期待値を具体的に記述（例: AC-02 増加検出で exit 1 + 現在数/baseline/増分出力）"
      actual: "実測値を具体的に記述（例: 増加時に exit 0 を返し増分が出力されない）"
      log_snippet: "テスト出力の抜粋（最大10行）"
  fix_scope:
    - file: "scripts/sage-tsc-ratchet.sh"
      reason: "修正が必要な具体的理由（該当 TASK の File Scope 内に限る）"
  instruction: "1. [具体的な修正手順1] 2. [具体的な修正手順2]"
  retry_allowed: true   # false の場合、abort して Human にエスカレーション
  same_fail_count: 1    # 同一 CHECK-ID の連続失敗回数（3 で abort → sage/failures.md 記録）
```

### フィードバック形式のルール

- `failed_items.id` は本 Done Definition の CHECK-ID（CHECK-001〜012）と一致させること
- `category` は 4 種類のいずれか: `functional`, `structural`, `security`, `architecture`
- `log_snippet` は最大 10 行。長い場合はファイルパスで参照する
- `fix_scope` には該当 TASK（TASK-0204〜0207）の File Scope 内のファイルのみ記載する
- `instruction` は Implementation Agent が即座に実行可能な具体性で記述する
- テスト側の FAIL（CHECK-001〜008）でも、テストを実装に合わせて改変して通すことは禁止（CLAUDE.md §5）。実装修正は TASK-0204/0205、テスト修正は TASK-0207 の担当 Agent に振り分ける
- ラチェット誤判定（誤カウント / 不正 exit code / baseline 破壊）を検出した場合は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する（SPEC-0030 知識管理フロー、OPS-03）
- `same_fail_count` が 3 に達した場合は abort し、`sage/failures.md` へ TASK-ID 付きで記録する（CLAUDE.md §5）
