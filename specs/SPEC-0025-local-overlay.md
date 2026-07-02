# SPEC-0025: Local Overlay 機構 — installer 絶対不可侵のプロジェクト固有カスタマイズ層

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0025 |
| ステータス | Draft |
| 作成日    | 2026-07-02 |
| 更新日    | 2026-07-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0004 (install-state), SPEC-0014 (installer modular), SPEC-0018 (supply chain hardening) |
| 権限レベル | platform |

## 背景・目的

sage-ai-template を実プロジェクトに導入した際、`.claude/rules/*.md` 等の managed ファイルにプロジェクト固有ルールを直接追記せざるを得ず、`bash install.sh` による template 更新時にカスタマイズが消失する実害が発生した。既存のマーカー方式 (`upsert_sage_section()` in `scripts/generator/07-installer-main.sh`) は CLAUDE.md / AGENTS.md のマーカー外コンテンツは保護するが、`.claude/rules/` 配下の managed ファイルは全置換されるため、プロジェクト固有ルールの安全な置き場が存在しない。

本 SPEC は `.claude/rules/local/` および `.codex/rules/local/` を installer が**絶対に作成・変更・削除しない** overlay ディレクトリとして公式定義し、テンプレート更新とプロジェクト固有カスタマイズの共存を保証する。

## 対象ユーザー

- sage-ai-template を実プロジェクトに導入し、`bash install.sh` で継続的にテンプレート更新を受け取る開発者
- プロジェクト固有ルールを AI agent (Claude Code / Codex) に読ませたいチーム

## スコープ（含む）

- `.claude/rules/local/` および `.codex/rules/local/` を installer 不可侵の overlay ディレクトリとして公式定義する (governance 文書ではなく本 SPEC + docs で定義。`sage/` は File Scope 外のため変更しない)
- installer への overlay 不可侵保証の実装:
  - `scripts/generator/03-rules.sh` (rules 生成) および `scripts/generator/07-installer-main.sh` (メインフロー・install-state 生成・verify) を対象に、`*/rules/local/**` を書き込み・削除・checksum 検証の対象から明示的に除外する
  - 更新時 (`bash install.sh` 再実行) に既存 `local/` 配下ファイルを一切上書き・削除しないこと
  - `local/` が存在しなくても installer は作成しないこと (ユーザーが必要時に自分で作る)
  - generator 変更に伴い `install.sh` を再生成し、SHA256SUMS を更新する
- `.sage/install-state.yaml` に managed / unmanaged (overlay) の宣言セクションを追加する (`unmanaged_paths:` として `.claude/rules/local/`, `.codex/rules/local/` を列挙。`--verify-checksum` はこれらを検証対象外とする)
- managed ルールファイル (`templates/rules/` 由来の `.claude/rules/*.md`) の末尾に「プロジェクト固有ルールは `local/` に置く。このファイルは install.sh 更新で全置換される」旨の参照規約注記 (英語コメント + 日本語1行) を追加する
- CLAUDE.md テンプレート (SAGE managed セクション、`scripts/generator/01-templates.sh` 内) に overlay ディレクトリの存在と読み込み規約 (「`.claude/rules/local/*.md` はプロジェクト固有ルールとして managed rules と同順位で参照する」) を記載する
- overlay 不可侵を検証する bash テスト `templates/hooks/tests/test-local-overlay.sh` を追加する (`_helpers.sh` / `run-tests.sh` の既存流儀に従う)
- README / docs に「カスタマイズと更新の共存」ガイドを新設または更新する (日本語)

## スコープ外（明示的に除外）

- AGENTS.md 本文の直接編集 — Codex-specific ファイルのため Codex follow-up task として分離 (CLAUDE.md §2.1 の boundary 遵守)
- `.codex/rules/` の managed テンプレート群の新設 (S5 = 別 SPEC。本 SPEC は `.codex/rules/local/` の不可侵宣言のみ)
- バックアップ / diff プレビュー機構 (S2 = 別 SPEC)
- hook による overlay 読み込みの runtime 強制 (PreToolUse 等での enforcement は行わない。読み込みは instruction 規約に留める)
- `sage/` 配下 governance 文書の改訂 (Human-only。必要なら別途人間承認で追随)
- installer の配布方式・cosign / SLSA (SPEC-0019 / SPEC-0020 の範囲)
- 既存プロジェクトで managed ファイルに直接追記済みのカスタマイズを `local/` へ自動移行する機能

## 要件

### 機能要件
- [FR-01] installer (生成された `install.sh`) は `.claude/rules/local/` および `.codex/rules/local/` 配下のファイル・ディレクトリを作成・上書き・削除しない
- [FR-02] `.sage/install-state.yaml` に `unmanaged_paths` セクションが出力され、overlay ディレクトリが宣言される
- [FR-03] `install.sh --verify-checksum` は `unmanaged_paths` 配下を検証対象外とし、overlay ファイルの存在有無・内容で PASS/FAIL が変わらない
- [FR-04] managed ルールファイル (`.claude/rules/*.md`) 末尾に local overlay への参照規約注記が含まれる
- [FR-05] CLAUDE.md の SAGE managed セクションに overlay の存在と読み込み規約が記載される
- [FR-06] generator 変更後、`install.sh` は再生成され SHA256SUMS と一致する (再現性維持)

### 非機能要件
- [NFR-01] 後方互換: v1.1.0 系から `bash install.sh` で更新しても失敗せず、`local/` 不在でもエラーにならない
- [NFR-02] 再現性: 同一 generator 入力から生成される `install.sh` はバイト一致し、SHA256SUMS 検証を壊さない
- [NFR-03] dry-run: `install.sh --dry-run` の既存フローを維持し、overlay 除外がプラン表示にも反映される

### セキュリティ要件
- [SEC-01] overlay ディレクトリは install-state の checksum 管理外 = テンプレート供給元から改変されない領域であることを docs に明記する (supply chain 境界の明確化)。逆に、overlay は checksum 検証されないため、`local/` 配下は導入プロジェクト自身のレビュー責任である旨を README ガイドに記載する
- [SEC-02] installer は `unmanaged_paths` 宣言を書き込み許可リストとして解釈しない (宣言はあくまで「触らない」の宣言であり、path traversal 等で overlay 外へ波及しないこと)
- [SEC-03] SHA256SUMS / `--verify-checksum` / provenance の既存検証フローを弱体化しない (managed ファイルの検証範囲は縮小しない)

### 運用要件
- [OPS-01] `make doctor` 既存チェックが overlay 存在下でも PASS すること (overlay を異常として報告しない)
- [OPS-02] README ガイドに「managed ファイル直接編集 → 更新で消える / local/ 配置 → 保持される」の対比表を掲載する
- [OPS-03] リリース後、導入先で `bash install.sh` 更新 → `local/` 保持 + `--verify-checksum` PASS を確認する手順を release note に記載する。失敗報告があった場合は `sage/failures.md` に記録し issue を起票する
- [OPS-04] 定量合格基準: リリース後2週間、`sage/failures.md` に overlay 起因の失敗記録が0件、かつ少なくとも1導入先で `bash install.sh` 更新 → `local/` 保持 + `--verify-checksum` PASS を確認できた場合に安定 (Observe 完了) とみなす。失敗報告1件で issue 起票、同種3件で `sage/anti-patterns.md` へ昇格検討

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: overlay 保持 — 一時ディレクトリで install 済み状態を作り、`.claude/rules/local/my-rule.md` を配置後に `bash install.sh` を再実行し、ファイル内容が不変であることを確認する。検証コマンド: `bash templates/hooks/tests/test-local-overlay.sh` が PASS
- [ ] AC-02: 非作成 — clean install 後に `test ! -e .claude/rules/local -a ! -e .codex/rules/local` が真である (installer は overlay を作成しない)。test-local-overlay.sh 内ケースで検証
- [ ] AC-03: install-state 宣言 — install 後に `grep -A3 'unmanaged_paths' .sage/install-state.yaml | grep -q '.claude/rules/local/'` が成功する
- [ ] AC-04: verify-checksum 非干渉 — overlay ファイルを追加・変更した状態で `bash install.sh --verify-checksum` が PASS する (overlay は検証対象外)
- [ ] AC-05: 参照規約注記 — `grep -l 'rules/local/' .claude/rules/*.md | wc -l` が managed ルールファイル数と一致する (全 managed rules 末尾に注記)
- [ ] AC-06: 再現性 — `bash scripts/generate-installer.sh` (相当の再生成手順) 実行後、`shasum -a 256 -c SHA256SUMS` (install.sh エントリ) が成功する
- [ ] AC-07: 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する
- [ ] AC-08: 異常系 (local が通常ファイル) — `.claude/rules/local` を通常ファイルとして配置した状態で `bash install.sh` を実行し、exit 0 + WARN 出力 + 当該ファイル内容が不変であることを確認する (test case: `local_is_file` in test-local-overlay.sh)
- [ ] AC-09: 異常系 (旧フォーマット install-state) — `unmanaged_paths` を含まない旧フォーマットの `.sage/install-state.yaml` に対して `bash install.sh --verify-checksum` が PASS する (test case: `legacy_state` in test-local-overlay.sh)
- [ ] AC-10: CLAUDE.md 規約記載 — 生成された CLAUDE.md (SAGE managed セクション) に overlay 読み込み規約が含まれる。検証コマンド: 一時ディレクトリで clean install 後 `grep -q 'rules/local/' CLAUDE.md` が成功する (test case: claude_md_convention in test-local-overlay.sh)

### 検証方針

- `templates/hooks/tests/test-local-overlay.sh` は integration テストとして、install / 再 install / `--dry-run` / `--verify-checksum` の各経路で overlay 不変 (内容・存在状態) を検証する
- カバレッジ閾値は N/A — bash スクリプトであり、Gate 2 のカバレッジ計測ツール (LOC ベース coverage) の適用対象外のため。代替として、本 SPEC の異常系 (想定エラー1〜3・境界ケース1) を全てテストケース化することで機能検証の網羅性を担保する

## 異常系

- 想定エラー1: 更新先プロジェクトの `.claude/rules/local/` が通常ファイル (ディレクトリでない) として存在する場合 — installer はエラーで停止せず WARN を出力し、当該 path には一切書き込まない
- 想定エラー2: `.sage/install-state.yaml` が旧フォーマット (unmanaged_paths なし) の場合 — `--verify-checksum` は旧来通り managed ファイルのみ検証し、overlay 有無で FAIL しない (後方互換)
- 想定エラー3: `local/` 配下に symlink が置かれ overlay 外を指す場合 — installer は symlink を辿らない (触らない原則により read/write とも行わない)
- 境界ケース1: `local/` が空ディレクトリの場合 — installer は削除しない (空でも不可侵)

## 契約

- API: なし
- DB: なし
- イベント: なし
- ファイル契約: `.sage/install-state.yaml` に `unmanaged_paths:` (string list) を追加 — 追加のみで既存キーの変更なし

## リスク

- リスク1: generator 修正漏れで一部コードパス (repair / verify) が overlay を触る → 軽減策: 除外判定を単一関数 (`is_unmanaged_path()` 等) に集約し、test-local-overlay.sh で install / 再 install / verify の各経路をカバー
- リスク2: 注記追加により managed rules の checksum が全て変わり、既存導入先で `--verify-checksum` が一時 FAIL に見える → 軽減策: 通常のテンプレート更新と同じ扱い (install-state 再生成で解消) であることを README ガイドと release note に明記
- リスク3: 「local/ を読む」規約が instruction のみで enforcement がない (AP-06 Human-Only Guard の残存) → 軽減策: 本 SPEC では不可侵側 (installer 挙動) をテストで機械強制し、読み込み側の runtime 強制は明示的にスコープ外・将来 SPEC 候補として記録。昇格条件: `local/` ルール不読込に起因する失敗が `sage/failures.md` に記録された時点で、読み込み enforcement SPEC を起票する

### 知識管理 (failures.md 連携フロー)

- installer が overlay を変更する不具合を検出した場合、Implementation Agent は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する。同種の失敗が3回発生した場合は `sage/anti-patterns.md` へ昇格する (CLAUDE.md §5 Error Resolution Protocol 準拠、盲目的リトライ禁止)

### ロールバック手順

- 問題発生時は直前リリースの `install.sh` + SHA256SUMS (GitHub Releases) に差し戻して再実行する。旧 verify は `unmanaged_paths` を無視するため後方互換で動作し、overlay は不可侵のためロールバック影響を受けない

## 実装メモ（Implementation Agent向け）

- `scripts/generator/07-installer-main.sh`: `upsert_sage_section()`、install-state 生成部 (L697 付近)、`--verify-checksum` (L62/L72/L433 付近) が主要変更点
- `scripts/generator/03-rules.sh`: rules ファイル生成に末尾注記を追加
- `scripts/generator/01-templates.sh`: CLAUDE.md managed セクションに overlay 規約を追記
- テストは `templates/hooks/tests/_helpers.sh` と `test-installer-modularize.sh` の流儀 (一時ディレクトリ + 生成 install.sh 実行) を踏襲
- 禁止事項: AGENTS.md / `docs/codex-*.md` の直接編集 (Codex follow-up として TASK 分離)、`sage/` 配下の変更、TASK File Scope 外の変更 (AP-03)、1 TASK で generator + docs + tests を一括変更する Big Bang (AP-02 — Slice で分割すること)、テスト未実行での受け入れ (AP-09)、TASK-ID を含まないコミット禁止 (commit-msg hook で強制、AP-05)
- Slice 向け分割ヒント:

| TASK | 内容 | 対応 AC | コマンド検証可能な完了条件 |
|------|------|---------|--------------------------|
| T1 | generator 除外ロジック (03/07 モジュール) | AC-01/02/08 | `grep -q 'is_unmanaged_path' scripts/generator/07-installer-main.sh` + 既存テスト全件 PASS |
| T2 | install.sh 再生成 + SHA256SUMS 更新 | AC-06 | `shasum -a 256 -c SHA256SUMS` PASS |
| T3 | test-local-overlay.sh 追加 | AC-01〜04/08/09 | `bash templates/hooks/tests/test-local-overlay.sh` 全ケース PASS |
| T4 | managed rules 末尾注記 | AC-05 | AC-05 の grep 検証 PASS |
| T5 | CLAUDE.md 規約追記 (01-templates.sh) | AC-10 | 生成 CLAUDE.md に `rules/local/` 規約行を grep 確認 |
| T6 | README ガイド新設/更新 | AC-07 | `grep -q 'local/' README.md` + run-tests.sh 非破壊 |

  実行順: T1 → T2 → T3。T4 / T5 / T6 は T1 完了後に並列可。
  T1 は INV-03 (除外判定は単一関数に集約し各モジュールが参照) を実現する1責務であり、03/07 の変更は同一関数の定義+参照追加のみで分離不能なため1タスクとする。

## Properties

権限レベル platform + Security 要件あり → 5 件以上。

### Invariants
- [INV-01] (Gate 2) installer のいかなる実行経路 (install / 再 install / --dry-run / --verify-checksum) においても、`.claude/rules/local/**` および `.codex/rules/local/**` の mtime・内容・存在状態は変化しない
- [INV-02] (Gate 3) `unmanaged_paths` 宣言の有無・内容によって、managed ファイルの checksum 検証範囲が縮小しない (検証対象は SPEC-0018 時点の集合を維持)
- [INV-03] (Gate 4) overlay 除外判定は generator 内の単一箇所に定義され、各モジュールはそれを参照する (重複実装による drift 禁止)

### Pre-conditions
- [PRE-01] (Gate 2) installer は書き込み前に対象 path が `unmanaged_paths` 配下でないことを判定する
- [PRE-02] (Gate 2) `local/` が非ディレクトリまたは symlink の場合、installer は WARN のみで当該 path への操作を行わない

### Post-conditions
- [POST-01] (Gate 2) install 完了後、`.sage/install-state.yaml` は `unmanaged_paths` を含み、managed ファイル全件の checksum を含む
- [POST-02] (Gate 2) 再生成された `install.sh` は SHA256SUMS のエントリと一致する

### Assumptions
- [ASM-01] (Gate 横断) 導入先は bash 3.2+ / shasum または sha256sum が利用可能 (既存 installer と同一前提)
- [ASM-02] (Gate 横断) overlay 読み込みは Claude Code / Codex の instruction 遵守に依存し、runtime enforcement は本 SPEC の範囲外

## 関連ID

- PLAN-ID: PLAN-0025
- TASK-ID: TASK-0171, TASK-0172, TASK-0173, TASK-0174, TASK-0175, TASK-0176, TASK-0177
