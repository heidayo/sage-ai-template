# Done Definition: SPEC-0026 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0026 |
| PLAN-ID   | PLAN-0026 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（スケルトン）→ Implementation Agent（具体値） |
| 検証者     | Verify Agent |

---

## 起動条件

### サーバー起動コマンド

```bash
# サーバー不要（CLI installer）。検証は一時ディレクトリで生成 install.sh を実行して行う
# scratch 環境の作り方は templates/hooks/tests/_helpers.sh / test-local-overlay.sh の流儀に従う
```

### 前提条件チェック

- [ ] bash 3.2+ / diff / shasum が利用可能: `bash --version && diff --version && shasum --version` (ASM-01)
- [ ] ブランチが feature/s2-installer-preservation である: `git branch --show-current`
- [ ] 既存テストが起点で全件 PASS: `bash templates/hooks/tests/run-tests.sh`

---

## テスト対象URL

N/A（Web アプリケーションではないためスキップ。検証対象は生成 `install.sh` の CLI 挙動）

---

## 受け入れ条件（このラウンドの完了条件）

### 自動検証（コマンドベース）

- [ ] `bash templates/hooks/tests/test-installer-preservation.sh` が全ケース PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊, AC-07）
- [ ] `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功（AC-06）
- [ ] テストカバレッジ: N/A（bash スクリプトのため LOC coverage 非適用。代替として下記 CHECK 全件で異常系・境界ケースを網羅）

### 機能検証（AC 1:1 対応）

- [ ] [CHECK-001] AC-01 マーカー外保持 — マーカー外にユーザー文言を追記した CLAUDE.md / AGENTS.md が `bash install.sh` 再実行後も保持される: `bash templates/hooks/tests/test-installer-preservation.sh` (case: `marker_outside_preserved`) PASS
- [ ] [CHECK-002] AC-02 バックアップ生成 — テンプレート差分がある状態で install 後 `ls .sage/backup/*/CLAUDE.md` が成功し内容が更新前と一致: (case: `backup_created`) PASS
- [ ] [CHECK-003] AC-03 世代ローテーション — 更新4回後 `ls -d .sage/backup/*/ | wc -l` が 3: (case: `backup_rotation`) PASS
- [ ] [CHECK-004] AC-04 diff プレビュー — `bash install.sh --diff` 出力に `---` / `+++` 行が含まれ、実行前後で全ファイル checksum 不変: (case: `diff_no_write`) PASS
- [ ] [CHECK-005] AC-04b diff 保全違反可視化 — マーカー外を変更した fixture で `--diff` 出力に sentinel 行が含まれる: (case: `diff_shows_outside_marker`) PASS
- [ ] [CHECK-006] AC-05 冪等性 — `bash install.sh` 2回連続実行で managed ファイル群の checksum が一致し、バックアップ世代数が増えない: (case: `idempotent_reinstall`) PASS
- [ ] [CHECK-007] AC-06 再現性 — generator 再生成後 `shasum -a 256 -c SHA256SUMS` (install.sh エントリ) が成功
- [ ] [CHECK-008] AC-07 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS（test-local-overlay.sh / test-installer-modularize.sh / test-release-workflow.sh 含む）
- [ ] [CHECK-009] AC-08 マーカー片方欠損 — 終了マーカーのみ削除した CLAUDE.md で `bash install.sh` が exit 0 + WARN 出力 + ファイル内容不変（append なし）: (case: `marker_half_broken_safe`) PASS
- [ ] [CHECK-010] AC-09 バックアップ先書き込み不可 — `.sage/backup` を chmod 555 にした状態で `bash install.sh` がファイル更新せずエラーメッセージ + 非0 exit: (case: `backup_unwritable_aborts`) PASS
- [ ] [CHECK-011] AC-10 ドキュメント — `grep -rq '\.sage/backup/' README.md docs/` が exit 0 かつ `grep -rq '防御されないケース' docs/` が exit 0: (case: `docs_restore_and_matrix`) PASS
- [ ] [CHECK-012] AC-11 非タイムスタンプエントリ保持 — `.sage/backup/` 直下の非タイムスタンプ形式エントリがローテーションで削除されない: (case: `rotation_skips_foreign_entries`) PASS
- [ ] [CHECK-013] AC-12 timestamp 衝突 — 同一秒内連続実行で既存世代を上書きせず `-N` suffix ディレクトリに保存: (case: `timestamp_collision_no_overwrite`) PASS
- [ ] [CHECK-014] AC-13 バックアップ規約の CLAUDE.md 反映 — clean install 後 `grep -q '.sage/backup/' CLAUDE.md` が成功: (case: `claude_md_backup_convention`) PASS
- [ ] [CHECK-015] 境界ケース1 UPDATE 0件 — 完全冪等な再実行でバックアップ世代を作成しない（空世代でローテーションを消費しない）: (case: `idempotent_reinstall` のサブアサーション) PASS
- [ ] [CHECK-016] 境界ケース2 マーカー両方欠損 — 既存の末尾 append 挙動を維持し既存行は不変（事前バックアップあり）: (case: `marker_both_missing_append`) PASS

### 非機能検証（該当する場合）

- [ ] NFR-01 後方互換 — `.sage/backup/` 不在の旧導入先相当環境で `bash install.sh` が失敗しない（テストの clean install ケースで担保）
- [ ] SEC-03 — install 実行の stdout にバックアップ対象ファイルの内容がダンプされない（パスのみ出力）
- [ ] OPS-01 — `.sage/backup/` 存在下で `make doctor` が PASS する

---

## ブラウザ検証（Playwright MCP 使用時のみ）

N/A — CLI installer のためスキップ。

---

## Pass/Fail 判定基準

| 項目 | 閾値 | 必須/オプション |
|------|------|---------------|
| test-installer-preservation.sh | 全ケース PASS | 必須（1つでも失敗 = Fail） |
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
      expected: "対応する AC の期待値を具体的に記述（例: AC-03 世代数 3）"
      actual: "実測値を具体的に記述（例: 世代数 4）"
      log_snippet: "テスト出力の抜粋（最大10行）"
  fix_scope:
    - file: "scripts/generator/07-installer-main.sh"
      reason: "修正が必要な具体的理由（該当 TASK の File Scope 内に限る）"
  instruction: "1. [具体的な修正手順1] 2. [具体的な修正手順2]"
  retry_allowed: true   # false の場合、abort して Human にエスカレーション
  same_fail_count: 1    # 同一 CHECK-ID の連続失敗回数（3 で abort → sage/failures.md 記録）
```

### フィードバック形式のルール

- `failed_items.id` は本 Done Definition の CHECK-ID（CHECK-001〜016）と一致させること
- `category` は 4 種類のいずれか: `functional`, `structural`, `security`, `architecture`
- `log_snippet` は最大 10 行。長い場合はファイルパスで参照する
- `fix_scope` には該当 TASK（TASK-0178〜0183）の File Scope 内のファイルのみ記載する
- `instruction` は Implementation Agent が即座に実行可能な具体性で記述する
- `same_fail_count` が 3 に達した場合は abort し、`sage/failures.md` へ TASK-ID 付きで記録する（CLAUDE.md §5）
