# Done Definition: SPEC-0025 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0025 |
| PLAN-ID   | PLAN-0025 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（スケルトン）→ Implementation Agent（具体値） |
| 検証者     | Verify Agent |

---

## 起動条件

### サーバー起動コマンド

```bash
# アプリケーションサーバーなし（installer / bash テストのみ）。
# テスト実行コマンド:
bash templates/hooks/tests/test-local-overlay.sh
bash templates/hooks/tests/run-tests.sh
```

### 前提条件チェック

- [ ] bash 3.2+ が利用可能: `bash --version`（ASM-01）
- [ ] shasum または sha256sum が利用可能: `command -v shasum || command -v sha256sum`（ASM-01）
- [ ] TASK-0177 完了後の再生成済み `install.sh`（T4/T5 反映済み）が存在する: `test -f install.sh`

---

## テスト対象URL

N/A — Web アプリケーションではなく installer のため URL 検証なし。integration テスト（一時ディレクトリ + 生成 install.sh 実行）で代替する。

---

## 受け入れ条件（このラウンドの完了条件）

### 自動検証（コマンドベース）

- [ ] `bash templates/hooks/tests/test-local-overlay.sh` が全ケース PASS する
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS する（既存テスト非破壊）
- [ ] `shasum -a 256 -c SHA256SUMS` が PASS する（install.sh エントリ）
- [ ] テストカバレッジ N/A — bash スクリプトのため LOC coverage 対象外。異常系（想定エラー1〜3・境界ケース1）の全テストケース化で代替（SPEC 検証方針）

### 機能検証

- [ ] [CHECK-001] AC-01 overlay 保持 — install 済み一時ディレクトリに `.claude/rules/local/my-rule.md` を配置後 `bash install.sh` 再実行でファイル内容不変: 検証コマンド `bash templates/hooks/tests/test-local-overlay.sh`（overlay 保持ケース PASS）
- [ ] [CHECK-002] AC-02 非作成 — clean install 後 `test ! -e .claude/rules/local -a ! -e .codex/rules/local` が真: 検証コマンド `bash templates/hooks/tests/test-local-overlay.sh`（非作成ケース PASS）
- [ ] [CHECK-003] AC-03 install-state 宣言 — install 後: 検証コマンド `grep -A3 'unmanaged_paths' .sage/install-state.yaml | grep -q '.claude/rules/local/'`（一時ディレクトリ内で実行）
- [ ] [CHECK-004] AC-04 verify-checksum 非干渉 — overlay ファイル追加・変更状態で: 検証コマンド `bash install.sh --verify-checksum` が PASS
- [ ] [CHECK-005] AC-05 参照規約注記 — clean install 後: 検証コマンド `test "$(grep -l 'rules/local/' .claude/rules/*.md | wc -l)" -eq "$(ls .claude/rules/*.md | wc -l)"`（managed rules 全件に注記。`local/` 配下ファイルが存在する環境では managed 分のみを母数とする）
- [ ] [CHECK-006] AC-06 再現性 — 再生成手順実行後: 検証コマンド `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功
- [ ] [CHECK-007] AC-07 既存テスト非破壊: 検証コマンド `bash templates/hooks/tests/run-tests.sh` 全件 PASS
- [ ] [CHECK-008] AC-08 異常系 local_is_file — `.claude/rules/local` を通常ファイルとして配置し `bash install.sh` 実行で exit 0 + WARN 出力 + 内容不変: 検証コマンド `bash templates/hooks/tests/test-local-overlay.sh`（`local_is_file` ケース PASS）
- [ ] [CHECK-009] AC-09 異常系 legacy_state — `unmanaged_paths` なし旧フォーマット install-state で `bash install.sh --verify-checksum` PASS: 検証コマンド `bash templates/hooks/tests/test-local-overlay.sh`（`legacy_state` ケース PASS）
- [ ] [CHECK-010] AC-10 CLAUDE.md 規約記載 — clean install 後 `grep -q 'rules/local/' CLAUDE.md` 成功: 検証コマンド `bash templates/hooks/tests/test-local-overlay.sh`（`claude_md_convention` ケース PASS）

### 非機能検証（該当する場合）

- [ ] NFR-01 後方互換 — `local/` 不在でも `bash install.sh` がエラーにならない: test-local-overlay.sh の clean install ケースで確認
- [ ] NFR-02 再現性 — 再生成2回で `install.sh` バイト一致（TASK-0172 完了条件）
- [ ] NFR-03 dry-run — `bash install.sh --dry-run` で overlay 除外がプラン表示に反映される（test-local-overlay.sh の dry-run 経路で確認）

---

## ブラウザ検証（Playwright MCP 使用時のみ）

N/A — CLI installer のためブラウザ検証なし。スキップする。

---

## Pass/Fail 判定基準

| 項目 | 閾値 | 必須/オプション |
|------|------|---------------|
| `bash templates/hooks/tests/test-local-overlay.sh` | 全ケース PASS（1つでも失敗 = Fail） | 必須 |
| `bash templates/hooks/tests/run-tests.sh` | 全件 PASS（既存テスト非破壊） | 必須 |
| 機能検証 CHECK-001〜010（AC-01〜AC-10） | 全項目 Pass | 必須 |
| `shasum -a 256 -c SHA256SUMS` | PASS | 必須 |
| テストカバレッジ | N/A（bash — 異常系全ケース化で代替） | 対象外 |
| lint/format（Gate 1） | エラー 0（shellcheck 等 config 準拠、未設定分は SKIPPED） | 必須 |
| 非機能検証 NFR-01〜03 | 全項目 Pass | 必須 |
| ブラウザ検証 | N/A | 対象外 |

---

## Fail 時の構造化フィードバック形式

Verify Agent が Fail 判定した場合、以下の YAML 構造で Implementation Agent にフィードバックする。
テキスト 1 行の要約ではなく、修正に必要な全情報を構造化する。

```yaml
fail_feedback:
  round: 1
  iteration: M
  verdict: FAIL
  failed_items:
    - id: "CHECK-001"
      category: "functional"  # functional | structural | security | architecture
      expected: "install.sh 再実行後も .claude/rules/local/my-rule.md の内容が不変"
      actual: "実測値を具体的に記述"
      log_snippet: "エラー出力の抜粋（最大10行）"
  fix_scope:
    - file: "scripts/generator/07-installer-main.sh"
      reason: "修正が必要な具体的理由（該当 TASK の File Scope 内のみ）"
  instruction: "1. [具体的な修正手順1] 2. [具体的な修正手順2]"
  retry_allowed: true   # false の場合、abort して Human にエスカレーション
  same_fail_count: 1    # 同一 CHECK-ID の連続失敗回数（3 で abort）
```

### フィードバック形式のルール

- `failed_items.id` は本 Done Definition の CHECK-ID（CHECK-001〜010）と一致させること
- `category` は 4 種類のいずれか: `functional`, `structural`, `security`, `architecture`
- `log_snippet` は最大 10 行。長い場合はファイルパスで参照する
- `fix_scope` には修正が許可されるファイルのみ記載する（TASK-0171〜0177 の File Scope 内。テストを通すための実装側修正は TASK-0171/0172/0177 へ差し戻す）
- `instruction` は Implementation Agent が即座に実行可能な具体性で記述する
- `same_fail_count` は同一 `id` のフィードバックが連続した回数。オーケストレーターが管理する
