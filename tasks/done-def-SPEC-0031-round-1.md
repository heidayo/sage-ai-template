# Done Definition: SPEC-0031 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0031 |
| PLAN-ID   | PLAN-0031 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（スケルトン）→ Implementation Agent（具体値） |
| 検証者     | Verify Agent |

---

## 起動条件

### サーバー起動コマンド

```bash
# サーバー不要（governance ドキュメント + bash CLI スクリプト + installer 再生成）。
# 検証は一時ディレクトリに scripts/sage-id-gen.sh + scripts/sage-id-pattern.sh +
# fixture failures.md（templates/hooks/tests/fixtures/）を配置して行う
```

### 前提条件チェック

- [ ] bash 3.2+ / POSIX ツール（grep/sed/sort/printf）が利用可能: `bash --version`（ASM-01）
- [ ] ブランチが feature/s7-gate-fp-template である: `git branch --show-current`
- [ ] 既存テストが起点で全件 PASS: `bash templates/hooks/tests/run-tests.sh`

---

## テスト対象URL

N/A（Web アプリケーションではないためスキップ。検証対象は CLI スクリプトの採番動作・ドキュメント内容・installer 整合）

---

## 受け入れ条件（このラウンドの完了条件）

### 自動検証（コマンドベース）

- [ ] `bash templates/hooks/tests/test-gate-fp-idgen.sh` が全ケース PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊, AC-12 / OPS-01）
- [ ] テストカバレッジ: N/A（bash スクリプトのため LOC coverage 非適用。代替として異常系 2・境界ケース 3 を CHECK で網羅 — SPEC 検証方針）

### 機能検証（AC 1:1 対応）

- [ ] [CHECK-001] AC-01 テンプレート存在 — `grep -qF 'GATE-FP-XXXX' sage/failures.md` が exit 0、かつ `for kw in '発生日' '誤検知した Gate' 'TASK-ID' '誤検知の根拠' '一時対応' '恒久対応' '再発回数'; do grep -qF "$kw" sage/failures.md || exit 1; done` が exit 0（FR-01）: (case: `template_fields_present`)
- [ ] [CHECK-002] AC-02 使い分け・エスカレーション — `grep -qF 'GATE-FP' sage/failures.md && grep -qE '3\s*回' sage/failures.md && grep -qF 'gate 設定の見直し' sage/failures.md` が exit 0（FR-02）: (case: `escalation_rule_present`)
- [ ] [CHECK-003] AC-03 採番（初回） — GATE-FP 0 件の fixture failures.md を配した一時リポジトリで `bash scripts/sage-id-gen.sh gate-fp` の出力が `GATE-FP-0001`（FR-03, PRE-01, POST-01）: (case: `idgen_first`)
- [ ] [CHECK-004] AC-04 採番（継続・欠番） — `GATE-FP-0001` / `GATE-FP-0003` を含む fixture で出力が `GATE-FP-0004`（最大値 + 1、欠番を詰めない。FR-03, 境界ケース1）: (case: `idgen_next`)
- [ ] [CHECK-005] AC-05 既存種別不変 — `bash scripts/sage-id-gen.sh spec|plan|task|run|fail` の各出力が変更前と同一形式・同一番号ロジック、引数なし・未知種別が従来どおり exit 1 + usage。`GATE-FP-0002` が存在しても `fail` の次番号は不変（FR-05, INV-01, INV-02, 境界ケース3）: (case: `existing_types_unchanged`)
- [ ] [CHECK-006] AC-06 異常系（failures.md 不在） — `sage/failures.md` 不在の一時ディレクトリで `bash scripts/sage-id-gen.sh gate-fp` が `GATE-FP-0001` を出力し exit 0（想定エラー1）: (case: `idgen_missing_file`)
- [ ] [CHECK-007] AC-07 異常系（未知種別の拒否維持） — `bash scripts/sage-id-gen.sh gatefp` が exit 非 0 で、usage に `gate-fp` を含む有効種別一覧を出力（想定エラー2）: (case: `unknown_type_rejected`)
- [ ] [CHECK-008] AC-08 human 承認明記 — PR 本文に「sage/ 変更の human 承認が merge 前提」の記載: `gh pr view --json body | grep -F 'human 承認'` が exit 0（PRE-02, OPS-03）: (case: `human_approval_stated`)
- [ ] [CHECK-009] AC-09 installer 再生成整合 — 再生成後 `git diff --exit-code install.sh SHA256SUMS` が exit 0（drift なし）+ `bash install.sh --verify-checksum` PASS + `grep -qF 'GATE-FP-XXXX' install.sh && grep -qF 'gate-fp' install.sh` が exit 0（FR-06, SEC-02, INV-06, POST-02）: (case: `installer_regenerated`)
- [ ] [CHECK-010] AC-10 ローダー非変更 — `git diff --name-only main | grep -E '^(scripts/sage-id-pattern\.sh|templates/pre-commit-task-id\.sh)$'` が exit 非 0（INV-04, SPEC-0027 INV-03 非波及）: (case: `loader_untouched`)
- [ ] [CHECK-011] AC-11 既存エントリ不変 — `git diff main -- sage/failures.md` の差分に追加以外の `-` 行（FAIL-0001 / FAIL-0002 エントリ行の変更）が含まれない（NFR-01, INV-05）: (case: `existing_entries_unchanged`)
- [ ] [CHECK-012] AC-12 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS（OPS-01）: (case: `all_tests_pass`)

### 非機能検証（該当する場合）

- [ ] NFR-01 後方互換 — failures.md の GATE-FP 節は追加のみ（CHECK-011）、変更ファイルが PLAN-0031 影響範囲表の 6 点以内: `git diff --name-only main`
- [ ] NFR-02 可搬性 — gate-fp 分岐が bash 3.2+ / POSIX のみ: `grep -E '\bjq\b|\beval\b' scripts/sage-id-gen.sh` が exit 非 0（SEC-01/INV-03 と兼用）
- [ ] NFR-03 既存導入先非破壊 — update モードで failures.md KEEP（実装レビュー: generator 07-installer-main.sh の KEEP 分岐非変更を確認）
- [ ] SEC-01 — gate-fp 採番の ERE がスクリプト内ローカル定数のみ（外部設定・ユーザー入力を評価しない。実装レビュー + CHECK-005）
- [ ] SEC-02 — `bash install.sh --verify-checksum` PASS（CHECK-009 に含む）
- [ ] SEC-03 — failures.md 追記がテンプレート文書のみで実行可能コードを含まない（実装レビュー）
- [ ] 境界ケース2 — 本文中の `GATE-FP-9999` 参照文字列もスキャン対象となる仕様の明記を確認（エントリ見出しと区別しない — 既存 fail と同型）

---

## ブラウザ検証（Playwright MCP 使用時のみ）

N/A — シェルスクリプト / governance ドキュメントのためスキップ。

---

## Pass/Fail 判定基準

| 項目 | 閾値 | 必須/オプション |
|------|------|---------------|
| test-gate-fp-idgen.sh | 全ケース PASS | 必須（1つでも失敗 = Fail） |
| run-tests.sh（既存テスト） | 全件 PASS | 必須 |
| 機能検証 CHECK-001〜012 | 全項目 Pass | 必須（CHECK-008 は PR 作成後のレビュー時点で判定） |
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
      expected: "対応する AC の期待値を具体的に記述（例: AC-04 で GATE-FP-0004 を出力）"
      actual: "実測値を具体的に記述（例: sort キー誤りで GATE-FP-0002 を出力）"
      log_snippet: "テスト出力の抜粋（最大10行）"
  fix_scope:
    - file: "scripts/sage-id-gen.sh"
      reason: "修正が必要な具体的理由（該当 TASK の File Scope 内に限る）"
  instruction: "1. [具体的な修正手順1] 2. [具体的な修正手順2]"
  retry_allowed: true   # false の場合、abort して Human にエスカレーション
  same_fail_count: 1    # 同一 CHECK-ID の連続失敗回数（3 で abort → sage/failures.md 記録）
```

### フィードバック形式のルール

- `failed_items.id` は本 Done Definition の CHECK-ID（CHECK-001〜012）と一致させること
- `category` は 4 種類のいずれか: `functional`, `structural`, `security`, `architecture`
- `log_snippet` は最大 10 行。長い場合はファイルパスで参照する
- `fix_scope` には該当 TASK（TASK-0208〜0211）の File Scope 内のファイルのみ記載する
- `instruction` は Implementation Agent が即座に実行可能な具体性で記述する
- テスト側の FAIL（CHECK-003〜007）でも、テストを実装に合わせて改変して通すことは禁止（CLAUDE.md §5）。実装修正は TASK-0209、failures.md 修正は TASK-0208、テスト修正は TASK-0210、再生成は TASK-0211 の担当 Agent に振り分ける
- 採番の誤動作（重複 ID / 誤番号 / 既存種別への影響）を検出した場合は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する（SPEC-0031 知識管理フロー、盲目的リトライ禁止）
- `same_fail_count` が 3 に達した場合は abort し、`sage/failures.md` へ TASK-ID 付きで記録する（CLAUDE.md §5）
