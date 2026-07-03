# Done Definition: SPEC-0029 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0029 |
| PLAN-ID   | PLAN-0029 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（スケルトン）→ Implementation Agent（具体値） |
| 検証者     | Verify Agent |

---

## 起動条件

### サーバー起動コマンド

```bash
# サーバー不要（bash スクリプト群 + CLI installer）。検証は一時ディレクトリで install.sh を実行して行う
# scratch 環境の作り方は templates/hooks/tests/_helpers.sh / test-local-overlay.sh / test-installer-preservation.sh の流儀に従う
```

### 前提条件チェック

- [ ] bash 3.2+ / POSIX ツール / shasum が利用可能: `bash --version && shasum --version`（ASM-01）
- [ ] ブランチが feature/s5-codex-rules である: `git branch --show-current`
- [ ] 既存テストが起点で全件 PASS: `bash templates/hooks/tests/run-tests.sh`
- [ ] SPEC-0025 の `unmanaged_paths` 宣言（`.codex/rules/local/`）が有効: `grep -F 'rules/local' install.sh`（ASM-03）

---

## テスト対象URL

N/A（Web アプリケーションではないためスキップ。検証対象は installer CLI の挙動）

---

## 受け入れ条件（このラウンドの完了条件）

### 自動検証（コマンドベース）

- [ ] `bash templates/hooks/tests/test-codex-rules.sh` が全ケース PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊, AC-11）
- [ ] `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功（AC-10）
- [ ] テストカバレッジ: N/A（bash スクリプトのため LOC coverage 非適用。代替として下記 CHECK 全件で異常系・境界ケースを網羅 — SPEC 検証方針）

### 機能検証（AC 1:1 対応）

- [ ] [CHECK-001] AC-01 テンプレート存在・対応 — `diff <(ls templates/rules/ | grep -v '^harness-rules.md$') <(ls templates/codex-rules/)` が exit 0（配布対象 5 ファイルの 1:1 対応 / INV-06）: (case: `templates_paired`) PASS
- [ ] [CHECK-002] AC-02 配布 — 空の一時ディレクトリで `bash install.sh` 実行後、`for f in specs plans tasks src sage-governance; do test -f ".codex/rules/${f}-rules.md" && grep -q 'SAGE managed' ".codex/rules/${f}-rules.md" || exit 1; done` が exit 0、かつ注記が `.codex/rules/local/` を案内（`grep -q '.codex/rules/local'`）（POST-01）: (case: `codex_rules_installed`) PASS
- [ ] [CHECK-003] AC-03 overlay 不可侵 — `.codex/rules/local/my-rules.md` を配置した一時環境で install → 再 install 後、当該ファイルが `diff` でバイト不変かつ削除されていない（INV-01 / SPEC-0025 INV-01 継承）: (case: `overlay_untouched`) PASS
- [ ] [CHECK-004] AC-04 再 install 冪等 — install を 2 回実行し、`.codex/rules/` 全 5 ファイルが 1 回目と 2 回目で `diff -r` バイト同一（POST-02）: (case: `reinstall_idempotent`) PASS
- [ ] [CHECK-005] AC-05 managed 全置換 — `.codex/rules/specs-rules.md` に行を追記後 `bash install.sh --update` を実行すると、テンプレート内容へ復元される（追記行が消える。境界ケース1 の同挙動）: (case: `managed_replace`) PASS
- [ ] [CHECK-006] AC-06 managed_files 登録 — install 後 `grep -c '.codex/rules/' .sage/install-state.yaml` が 5 以上（unmanaged の local/ 宣言と別に managed 5 件）、かつ `bash install.sh --verify-checksum` が PASS（FR-04 / INV-04）: (case: `verify_checksum_covers`) PASS
- [ ] [CHECK-007] AC-07 異常系（dry-run 非介入） — 空の一時ディレクトリで `bash install.sh --dry-run` 実行後、`test ! -e .codex` が真、stdout に `.codex/rules` の WOULD-* 表示が含まれる（想定エラー1 / FR-05 / PRE-02）: (case: `dry_run_no_write`) PASS
- [ ] [CHECK-008] AC-08 異常系（local が通常ファイル） — `.codex/rules/local` を通常ファイルとして配置した一時環境で install を実行しても、当該ファイルがバイト不変で、managed 5 ファイルは正常配布される（想定エラー2 / FR-03 / PRE-01）: (case: `local_as_file`) PASS
- [ ] [CHECK-009] AC-09 docs — `test -f docs/codex-rules.md` かつ `grep -qF '.codex/rules/' docs/codex-rules.md && grep -qF 'AGENTS.md' docs/codex-rules.md && grep -qF '.claude/rules/' docs/codex-rules.md && grep -qF '.codex/rules/local/' docs/codex-rules.md` が exit 0、かつ `grep -qF 'docs/codex-rules.md' README.md` が exit 0（FR-06 / OPS-01）: (case: `docs_reference`) PASS
- [ ] [CHECK-010] AC-10 再現性 — `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` が 0 行、かつ `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功（想定エラー3 / FR-08 / NFR-02 / INV-04/05 / FAIL-0002 再演防止）
- [ ] [CHECK-011] AC-11 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する
- [ ] [CHECK-012] AC-12 boundary 遵守 — `git diff --name-only main | grep -E '^(AGENTS\.md|docs/codex-delegation-packet\.md|docs/codex-security\.md|templates/rules/|\.claude/rules/)'` が exit 非0、かつ `gh pr view --json body -q .body | grep -qF 'AGENTS.md 追記案' && gh pr view --json body -q .body | grep -qF 'CLAUDE.md §9.1 追記案'` が exit 0（FR-09、全 TASK 横断制約）: (case: `followup_drafts_in_pr`)

### 非機能検証（該当する場合）

- [ ] NFR-01 後方互換 — 自作 `.codex/AGENTS.md` / `.codex/LOCAL.md` / `.codex/rules/local/` を配置した一時環境で `install.sh --update` 後も当該ファイルがバイト不変、追加は managed 5 ファイル + docs のみ（INV-02、CHECK-003/008 と同型検証）
- [ ] NFR-02 再現性 — generator 再実行で install.sh がバイト一致（CHECK-010）
- [ ] NFR-03 semantic pairing — 内容のバイト同一は要求しない。ファイル集合の 1:1 対応（CHECK-001）+ レビューで文言 drift を確認
- [ ] NFR-04 実行時間 — 新テスト `test-codex-rules.sh` が 15 秒以内
- [ ] SEC-01 — `.codex/rules/` へ書き込まれる内容が install.sh 埋め込みの静的テンプレート文字列のみ（導入先ファイル内容の非転記、実装レビュー + CHECK-002）
- [ ] SEC-02 — 書き込みパスが固定文字列 5 パスのみ（パストラバーサル不能、実装レビュー）
- [ ] SEC-03 — `unmanaged_paths` 宣言 + `is_unmanaged_path` ガードの両方で不可侵担保、SPEC-0025 INV-01 / SPEC-0018 検証フローの非縮小（CHECK-003/006 + diff レビュー）
- [ ] SEC-04 — 新規テンプレート / docs に secret 非含有（gitleaks PASS）、guidance（非 runtime enforcement）の明記を確認
- [ ] OPS-02 — `.codex/rules/` 配布後も `make doctor` が PASS

---

## ブラウザ検証（Playwright MCP 使用時のみ）

N/A — シェルスクリプト/CLI のためスキップ。

---

## Pass/Fail 判定基準

| 項目 | 閾値 | 必須/オプション |
|------|------|---------------|
| test-codex-rules.sh | 全ケース PASS | 必須（1つでも失敗 = Fail） |
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
      expected: "対応する AC の期待値を具体的に記述（例: AC-03 overlay ファイルがバイト不変）"
      actual: "実測値を具体的に記述（例: 再 install 後に .codex/rules/local/my-rules.md が全置換された）"
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
- `fix_scope` には該当 TASK（TASK-0198〜0203）の File Scope 内のファイルのみ記載する
- `instruction` は Implementation Agent が即座に実行可能な具体性で記述する
- generator 由来の FAIL（CHECK-002〜008/010 等）の fix は generator 側を修正し install.sh を再生成すること（手動編集禁止、再生成は TASK-0201 の単独コミット規約に従う）
- overlay 破壊（CHECK-003 相当）を検出した場合は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する（SPEC-0029 知識管理フロー）
- `same_fail_count` が 3 に達した場合は abort し、`sage/failures.md` へ TASK-ID 付きで記録する（CLAUDE.md §5）
