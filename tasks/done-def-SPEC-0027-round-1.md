# Done Definition: SPEC-0027 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0027 |
| PLAN-ID   | PLAN-0027 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（スケルトン）→ Implementation Agent（具体値） |
| 検証者     | Verify Agent |

---

## 起動条件

### サーバー起動コマンド

```bash
# サーバー不要（bash スクリプト群 + CLI installer）。検証は一時ディレクトリに fixture を配置して行う
# scratch 環境の作り方は templates/hooks/tests/_helpers.sh / test-local-overlay.sh の流儀に従う
```

### 前提条件チェック

- [ ] bash 3.2+ / POSIX grep・sed・awk / shasum が利用可能: `bash --version && grep --version && shasum --version`（ASM-01、jq は前提としない）
- [ ] ブランチが feature/s3-id-patterns である: `git branch --show-current`
- [ ] 既存テストが起点で全件 PASS: `bash templates/hooks/tests/run-tests.sh`

---

## テスト対象URL

N/A（Web アプリケーションではないためスキップ。検証対象はシェルスクリプトの CLI 挙動）

---

## 受け入れ条件（このラウンドの完了条件）

### 自動検証（コマンドベース）

- [ ] `bash templates/hooks/tests/test-id-patterns.sh` が全ケース PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊, AC-09）
- [ ] `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功（AC-08）
- [ ] テストカバレッジ: N/A（bash スクリプトのため LOC coverage 非適用。代替として下記 CHECK 全件で異常系・境界ケースを網羅 — SPEC 検証方針）

### 機能検証（AC 1:1 対応）

- [ ] [CHECK-001] AC-01 fallback 動作 — `.sage/id-patterns.json` を削除した一時環境で `source scripts/sage-id-pattern.sh; sage_id_accept_regex task` の出力が `TASK-[0-9]{4}` と一致: `bash templates/hooks/tests/test-id-patterns.sh` (case: `fallback_no_config`) PASS
- [ ] [CHECK-002] AC-02 デフォルト形式受理 — デフォルト内容の設定ありで `echo 'TASK-0001: msg' | grep -qE "$(sage_id_accept_regex task)"` が exit 0: (case: `default_accepted`) PASS
- [ ] [CHECK-003] AC-03 カスタム形式受理 — `task.accept` に `TASK-[a-z]+-[0-9a-f]{4}` 追加設定で `TASK-hei-a7f3` を含む commit message fixture が `pre-commit-task-id.sh` を通過: (case: `custom_accepted`) PASS
- [ ] [CHECK-004] AC-04 不正 JSON — 不正 JSON 配置で `sage_id_accept_regex task` が fallback 値 `TASK-[0-9]{4}` を返し、stderr に WARN、exit 0: (case: `invalid_json_fallback`) PASS
- [ ] [CHECK-005] AC-05 空 accept 配列 — fallback regex が使用され、空パターン全マッチが発生しない（`NOTASK` fixture が拒否される）: (case: `empty_accept_fallback`) PASS
- [ ] [CHECK-006] AC-06 5 スクリプト整合 — `grep -rnE 'TASK-\[0-9\](\{4\}|\\\{4\\\})' scripts/sage-id-gen.sh scripts/sage-trace-check.sh scripts/sage-report.sh scripts/sage-validate.sh templates/pre-commit-task-id.sh` のヒットが `templates/pre-commit-task-id.sh` の内包 fallback 定義行のみ（scripts/ 側 4 ファイルは 0 件、INV-03。許容行数・位置を機械検証）: (case: `no_stray_hardcode`) PASS
- [ ] [CHECK-007] AC-07 id-gen 非干渉 — `tasks/TASK-hei-a7f3-x.md` が存在する一時環境で `bash scripts/sage-id-gen.sh task` がデフォルト形式の次連番を返す: (case: `idgen_ignores_custom`) PASS
- [ ] [CHECK-008] AC-08 再現性 — generator 再生成後 `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功
- [ ] [CHECK-009] AC-09 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS
- [ ] [CHECK-010] AC-10 ドキュメント — `grep -rqF '.sage/id-patterns.json' README.md docs/` が exit 0、かつ `grep -qF 'id-patterns' .sage/config.yaml` が exit 0: (case: `docs_and_config_reference`) PASS
- [ ] [CHECK-011] AC-11 eval 不使用（SEC-01） — `grep -nE '(^|[^a-zA-Z_])eval([^a-zA-Z_]|$)' scripts/sage-id-pattern.sh` のヒット 0 件
- [ ] [CHECK-012] AC-12 installer preserve-if-exists — カスタム accept を含む `.sage/id-patterns.json` 配置済み一時環境で `install.sh` 実行後 `grep -qF 'TASK-[a-z]+-[0-9a-f]{4}' .sage/id-patterns.json` が exit 0: (case: `installer_preserves_config`) PASS
- [ ] [CHECK-013] 想定エラー3 種別欠落 — 設定に定義済み種別のみ適用され、欠落種別（例: `run`）は fallback を返す: (case: `fallback_no_config` のバリアント、`missing_type_fallback`) PASS
- [ ] [CHECK-014] 境界ケース1 カスタム ID 混在採番 — カスタム形式 ID 存在下でデフォルト形式最大値 +1 を返す（CHECK-007 と同 fixture のサブアサーション: 採番結果の具体値検証）PASS
- [ ] [CHECK-015] 境界ケース2 ローダー欠損環境の hook 単体動作 — `scripts/sage-id-pattern.sh` が存在しない fixture で `pre-commit-task-id.sh` が内包 fallback で動作し、`TASK-0001` 受理 / `NOTASK` 拒否: (case: `hook_standalone_fallback`) PASS
- [ ] [CHECK-016] 境界ケース3 installer 再実行での設定保持 — CHECK-012 と同 fixture で installer 再実行後も既存設定が上書きされない（preserve-if-exists）PASS

### 非機能検証（該当する場合）

- [ ] NFR-01 後方互換 — 設定ファイルなし環境で 5 スクリプトの受理/拒否/生成 ID/exit code が変更前と完全同一（CHECK-001/007 + 既存テスト全 PASS で担保）
- [ ] NFR-02 再現性 — generator 再実行で install.sh がバイト一致（CHECK-008）
- [ ] NFR-03 性能 — ローダー読み込みの外部プロセス起動が定数回で、pre-commit 体感を悪化させない（目安 +50ms 未満）
- [ ] SEC-03 — 空パターンによる `grep -E ''` 全マッチが発生しない（CHECK-005）
- [ ] OPS-02 — `.sage/id-patterns.json` の有無いずれでも `make doctor` が PASS

---

## ブラウザ検証（Playwright MCP 使用時のみ）

N/A — シェルスクリプト/CLI のためスキップ。

---

## Pass/Fail 判定基準

| 項目 | 閾値 | 必須/オプション |
|------|------|---------------|
| test-id-patterns.sh | 全ケース PASS | 必須（1つでも失敗 = Fail） |
| run-tests.sh（既存テスト） | 全件 PASS | 必須 |
| SHA256SUMS 検証 | PASS | 必須 |
| 機能検証 CHECK-001〜016 | 全項目 Pass | 必須 |
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
    - id: "CHECK-XXX"          # 上記 CHECK-001〜016 のいずれか
      category: "functional"   # functional | structural | security | architecture
      expected: "対応する AC の期待値を具体的に記述（例: AC-01 出力 TASK-[0-9]{4}）"
      actual: "実測値を具体的に記述（例: 出力が空文字）"
      log_snippet: "テスト出力の抜粋（最大10行）"
  fix_scope:
    - file: "scripts/sage-id-pattern.sh"
      reason: "修正が必要な具体的理由（該当 TASK の File Scope 内に限る）"
  instruction: "1. [具体的な修正手順1] 2. [具体的な修正手順2]"
  retry_allowed: true   # false の場合、abort して Human にエスカレーション
  same_fail_count: 1    # 同一 CHECK-ID の連続失敗回数（3 で abort → sage/failures.md 記録）
```

### フィードバック形式のルール

- `failed_items.id` は本 Done Definition の CHECK-ID（CHECK-001〜016）と一致させること
- `category` は 4 種類のいずれか: `functional`, `structural`, `security`, `architecture`
- `log_snippet` は最大 10 行。長い場合はファイルパスで参照する
- `fix_scope` には該当 TASK（TASK-0185〜0191）の File Scope 内のファイルのみ記載する
- `instruction` は Implementation Agent が即座に実行可能な具体性で記述する
- `same_fail_count` が 3 に達した場合は abort し、`sage/failures.md` へ TASK-ID 付きで記録する（CLAUDE.md §5）
