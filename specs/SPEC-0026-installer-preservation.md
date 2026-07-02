# SPEC-0026: Installer カスタマイズ保全の強化 — 更新前バックアップ・diff プレビュー・保全リグレッションテスト

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0026 |
| ステータス | Draft |
| 作成日    | 2026-07-02 |
| 更新日    | 2026-07-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0025 (local overlay), SPEC-0018 (supply chain hardening), SPEC-0014 (installer modular), SPEC-0010 (dry-run) |
| 権限レベル | platform |

## 背景・目的

実プロジェクトで template 更新 (`bash install.sh` 再実行) 時に CLAUDE.md / AGENTS.md のプロジェクト固有カスタマイズが消失する実害が発生した。マーカー方式 `upsert_sage_section()` はマーカーが正常に存在する場合のみ安全であり、マーカー破損 (片方欠損・手動編集による変形) や旧フォーマットのファイルではマーカー外コンテンツを守り切れなかった。SPEC-0025 で overlay 層 (`.claude/rules/local/` 等) は導入済みだが、managed ファイル側の更新事故に対する防御 — (1) 上書き前の自動バックアップ、(2) 変更予定内容の可視化 (diff プレビュー)、(3) 保全挙動の再現リグレッションテスト — が不足している。

本 SPEC は installer 生成物に「更新前バックアップ」「diff プレビュー」「マーカーエッジケースの安全側フォールバック」を追加し、カスタマイズ消失事故を再発不能にする。

## 対象ユーザー

- sage-ai-template 導入済みプロジェクトで `bash install.sh` によりテンプレート更新を受け取る開発者
- CLAUDE.md / AGENTS.md / `.claude/rules/` にカスタマイズを持つ (または過去の直接追記が残る) チーム

## スコープ（含む）

- 更新実行前の自動バックアップ (installer 生成物 `install.sh` に実装):
  - 上書き・変更対象の既存ファイル (UPDATE 対象。CREATE 対象は除く) を書き込み前に `.sage/backup/<timestamp>/` へ元の相対パス構造を維持して保存する
  - バックアップ世代数上限は直近3世代とし、超過分の最古世代を削除する。削除時・保存時はその旨を stdout に出力する
  - `--dry-run` 時はバックアップを作成しない (書き込みが発生しないため)
  - `.sage/backup/` は既に `.gitignore` 対象であることを確認済み — 追加変更不要だが、テストで gitignore 対象であることを検証する
- diff プレビュー強化:
  - `install.sh --diff` オプションを新設し、UPDATE 対象ファイルごとに unified diff (`diff -u` 相当) を表示して書き込みは行わない (dry-run + diff 表示)
  - CLAUDE.md / AGENTS.md についてはマーカー内 SAGE managed セクションの差分を表示する (マーカー外は変更されないことが前提であり、diff にマーカー外行が現れた場合はそれ自体が保全違反のシグナル)
  - 既存 `--dry-run` の出力・挙動は変更しない (非破壊)
- マーカーエッジケースの安全側フォールバック:
  - 開始/終了マーカーの片方のみが存在する場合、`upsert_sage_section()` は当該ファイルを上書き・append せず WARN を出力してスキップする (バックアップは通常フローで取得済みであること)
  - この挙動を FR / AC / テストで固定する
- カスタマイズ消失の再現リグレッションテスト `templates/hooks/tests/test-installer-preservation.sh` の追加 (`_helpers.sh` / `run-tests.sh` の既存流儀に従う):
  - (1) マーカー外にユーザー文言を書いた CLAUDE.md / AGENTS.md が更新後も保持される
  - (2) マーカー片方欠損時に上書き・append されず WARN が出る (安全側)
  - (3) install 2回連続実行の冪等性 (managed ファイル群が2回目実行後も1回目と同一内容)
  - (4) バックアップ生成・世代ローテーション (3世代上限)
  - (5) `--diff` が UPDATE 対象の unified diff を表示し、ファイルを変更しない
- generator 変更 (`scripts/generator/` 該当モジュール) → `install.sh` 再生成 → SHA256SUMS 更新 (再現性維持)
- ドキュメント (日本語):
  - README または docs に `.sage/backup/<timestamp>/` からの手動復元手順 (`--restore` 相当の cp 手順案内) を記載する
  - マーカー方式の弱点洗い出し: 「防御されるケース / 防御されないケース」の対比表 (マーカー正常・片方欠損・両方欠損・旧フォーマット・マーカー内手動編集 等) を docs に掲載する

## スコープ外（明示的に除外）

- overlay 機構自体の変更 (SPEC-0025 で導入済み。本 SPEC は managed ファイル側の防御)
- 自動 restore コマンド (`install.sh --restore` 等) の実装 — 手動復元手順のドキュメント化に留める (将来 SPEC 候補)
- GitHub Releases 配布フローの変更 (SPEC-0018 で確立済み)
- cosign / SLSA (SPEC-0019 / SPEC-0020 の範囲)
- AGENTS.md 本文・`docs/codex-*.md` の直接編集 — Codex-specific ファイルのため Codex follow-up task として分離 (CLAUDE.md §2.1 boundary。テスト対象としての AGENTS.md 生成検証は installer 経由のため許容)
- `sage/` 配下 governance 文書の改訂 (Human-only)
- マーカー破損ファイルの自動修復 (安全側スキップ + WARN + バックアップまで。修復は人間の作業)
- バックアップの圧縮・リモート退避

## 要件

### 機能要件
- [FR-01] installer は UPDATE 対象 (既存かつ内容が変わる) ファイルを書き込み前に `.sage/backup/<UTC timestamp YYYYMMDD-HHMMSS>/<相対パス>` へコピーする。UPDATE 対象が0件ならバックアップディレクトリを作成しない
- [FR-02] バックアップ世代は直近3世代を保持し、4世代目作成時に最古世代ディレクトリを削除する。保存先パスと削除した世代を stdout に出力する。`-N` suffix 付きディレクトリも独立した1世代として世代数上限 (3) にカウントする
- [FR-03] `install.sh --diff` は UPDATE 対象ファイルごとに unified diff を表示し、いかなるファイルも作成・変更・削除しない (exit 0)
- [FR-04] CLAUDE.md / AGENTS.md の diff 表示は upsert 後の想定内容との差分であり、マーカー外の行が差分に含まれる場合も隠さず表示する
- [FR-05] `upsert_sage_section()` は開始/終了マーカーの片方のみ検出した場合、対象ファイルを変更せず WARN を stderr に出力し、installer 全体は exit 0 で継続する
- [FR-06] install の冪等性: 同一テンプレートで `bash install.sh` を2回連続実行した場合、2回目実行後の managed ファイル群・install-state は1回目実行後と同一である (バックアップ世代は増えない — UPDATE 0件のため)
- [FR-07] generator 変更後、`install.sh` は再生成され SHA256SUMS と一致する
- [FR-08] `templates/claude-md-snippet.md` (CLAUDE.md managed セクションのソース) にバックアップ規約を 1〜2 行追記する: 「Template update backs up modified files to `.sage/backup/<timestamp>/` (3 generations). Restore: `cp .sage/backup/<ts>/<file> <file>`」

### 非機能要件
- [NFR-01] 後方互換: 旧導入先 (`.sage/backup/` 不在・旧 install-state) で `bash install.sh` が失敗しない。新オプション未使用時の既存 CLI 挙動 (`--dry-run` / `--verify-checksum` / provenance) は不変
- [NFR-02] 再現性: 同一 generator 入力から生成される `install.sh` はバイト一致し、SHA256SUMS 検証を壊さない
- [NFR-03] バックアップ処理は install 実行時間を体感上悪化させない (対象は UPDATE ファイルのみのコピーであり、数十ファイル規模で1秒未満)

### セキュリティ要件
- [SEC-01] バックアップは `.sage/backup/` (gitignore 対象) 配下のみに書き込み、リポジトリ外・overlay (`*/rules/local/`) へは一切書き込まない。世代削除は `.sage/backup/` 直下のタイムスタンプ形式ディレクトリのみを対象とし、パターン不一致のエントリは削除しない (誤削除防止)
- [SEC-02] `--diff` / バックアップは SPEC-0018 の SHA256SUMS / `--verify-checksum` / provenance 検証フローを弱体化しない (検証範囲の縮小なし)
- [SEC-03] バックアップ元ファイルに secret が含まれ得るため、バックアップ内容を stdout にダンプしない (パスのみ出力)

### 運用要件
- [OPS-01] `make doctor` 既存チェックが `.sage/backup/` 存在下でも PASS する (バックアップを異常として報告しない)
- [OPS-02] docs に「マーカー方式で防御される / されないケース」対比表と手動復元手順を掲載する
- [OPS-03] 定量合格基準: リリース後2週間、`sage/failures.md` に managed ファイルのカスタマイズ消失起因の失敗記録が0件、かつ少なくとも1導入先で「更新 → マーカー外文言保持 + バックアップ生成」を確認できた場合に安定 (Observe 完了) とみなす。消失報告1件で issue 起票 + バックアップからの復元を案内、同種3件で `sage/anti-patterns.md` へ昇格検討

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: マーカー外保持 — 一時ディレクトリで install 済み状態を作り、CLAUDE.md / AGENTS.md のマーカー外にユーザー文言を追記後 `bash install.sh` を再実行し、当該文言が保持される。検証コマンド: `bash templates/hooks/tests/test-installer-preservation.sh` (case: `marker_outside_preserved`) が PASS
- [ ] AC-02: バックアップ生成 — テンプレート差分がある状態で `bash install.sh` を実行後、`ls .sage/backup/*/CLAUDE.md` が成功し、内容が更新前ファイルと一致する (case: `backup_created`)
- [ ] AC-03: 世代ローテーション — 更新を4回発生させた後 `ls -d .sage/backup/*/ | wc -l` が 3 である (case: `backup_rotation`)
- [ ] AC-04: diff プレビュー — `bash install.sh --diff` の出力に UPDATE 対象の unified diff (`---` / `+++` 行) が含まれ、実行前後で全ファイルの checksum が不変 (case: `diff_no_write`)
- [ ] AC-04b: diff 保全違反可視化 (FR-04 対応) — マーカー外を意図的に変更した fixture で `bash install.sh --diff` の出力に当該 sentinel 行が含まれる (case: `diff_shows_outside_marker`)
- [ ] AC-05: 冪等性 — `bash install.sh` を2回連続実行し、2回目後の managed ファイル群の checksum が1回目後と一致し、バックアップ世代数が増えない (case: `idempotent_reinstall`)
- [ ] AC-06: 再現性 — generator 再生成後 `shasum -a 256 -c SHA256SUMS` (install.sh エントリ) が成功する
- [ ] AC-07: 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する (test-local-overlay.sh / test-installer-modularize.sh / test-release-workflow.sh 含む)
- [ ] AC-08: 異常系 (マーカー片方欠損) — CLAUDE.md の終了マーカーのみ削除した状態で `bash install.sh` を実行し、exit 0 + WARN 出力 + 当該ファイル内容が不変 (append もされない) であることを確認する (case: `marker_half_broken_safe`)
- [ ] AC-09: 異常系 (バックアップ先書き込み不可) — `.sage/backup` を書き込み不可 (chmod 555) にした状態で `bash install.sh` を実行し、ファイル更新を行わずエラーメッセージ + 非0 exit で停止する (バックアップなしで上書きしない = fail-safe) (case: `backup_unwritable_aborts`)
- [ ] AC-10: ドキュメント — `grep -rq '\.sage/backup/' README.md docs/` が exit 0 (復元手順)、かつ `grep -rq '防御されないケース' docs/` が exit 0 (対比表) (case: `docs_restore_and_matrix`)
- [ ] AC-11: 異常系 (非タイムスタンプエントリ保持) — `.sage/backup/` 直下にタイムスタンプ形式でないエントリを置いた状態で世代ローテーションを発生させ、当該エントリが削除されず保持される (case: `rotation_skips_foreign_entries`)
- [ ] AC-12: 異常系 (timestamp 衝突) — 同一秒内の連続実行を模した状態で `bash install.sh` を実行し、既存世代ディレクトリが上書きされず `-N` suffix 付きディレクトリに保存される (case: `timestamp_collision_no_overwrite`)
- [ ] AC-13: バックアップ規約の CLAUDE.md 反映 (FR-08 対応) — clean install 後 `grep -q '.sage/backup/' CLAUDE.md` が成功する (case: `claude_md_backup_convention`)

### 検証方針

- `templates/hooks/tests/test-installer-preservation.sh` は integration テストとして、一時ディレクトリ + 生成 `install.sh` 実行で AC-01〜05 (AC-04b 含む), 08, 09, 11, 12, 13 および境界ケース1 (`idempotent_reinstall`) / 境界ケース2 (`marker_both_missing_append`) をケース化する (test-local-overlay.sh の流儀を踏襲)
- テスト種別: bash integration テストのみ。unit テストは対象が生成スクリプト内関数のため非適用
- カバレッジ閾値は N/A — bash スクリプトであり Gate 2 の LOC ベース coverage 計測の適用対象外。代替として本 SPEC の異常系 (想定エラー1〜4・境界ケース1〜2) を全てテストケース化し網羅性を担保する

## 異常系

- 想定エラー1: マーカー片方欠損 (開始のみ / 終了のみ) — 上書き・append せず WARN してスキップ。installer は exit 0 で継続 (AC-08)
- 想定エラー2: `.sage/backup/` が書き込み不可 — バックアップ不能な状態で上書きを続行しない。エラー出力 + 非0 exit で停止 (fail-safe, AC-09)
- 想定エラー3: `.sage/backup/` 直下にタイムスタンプ形式でないエントリ (ユーザーの手動ファイル等) が存在 — ローテーション削除の対象にせず保持する (SEC-01, AC-11, case: `rotation_skips_foreign_entries`)
- 想定エラー4: 同一秒内の連続実行でバックアップ timestamp が衝突 — 既存世代ディレクトリを上書きせず `-N` suffix を付与して保存する (AC-12, case: `timestamp_collision_no_overwrite`)
- 境界ケース1: UPDATE 対象が0件 (完全冪等な再実行) — バックアップ世代を作成しない (空世代でローテーションを消費しない) (AC-05 のサブケース, case: `idempotent_reinstall`)
- 境界ケース2: マーカーが両方欠損 (旧フォーマット / 完全手動ファイル) — 既存の upsert 挙動 (末尾 append) を維持するが、事前バックアップにより復元可能。docs 対比表に「append される (消失はしないが重複し得る)」と明記 (case: `marker_both_missing_append`)

## 契約

- API: なし
- DB: なし
- イベント: なし
- CLI 契約: `install.sh --diff` オプション追加 (既存 `--dry-run` / `--verify-checksum` / `--remote` は不変)
- ファイル契約: `.sage/backup/<YYYYMMDD-HHMMSS>[-N]/<相対パス>` (gitignore 対象、直近3世代。`-N` suffix は同一秒内衝突時のみ付与)

## リスク

- リスク1: バックアップ判定 (UPDATE 検出) と実書き込みのコードパスが乖離し、バックアップ漏れのまま上書きされる → 軽減策: 「書き込み直前に元ファイル存在 + 内容差分ありならバックアップ」を単一関数 (`backup_before_write()` 等) に集約し、全書き込み経路がそれを経由することをテスト (AC-02) と Review (INV-04) で強制
- リスク2: ローテーション削除の対象誤りでユーザーデータを削除する → 軽減策: 削除対象を `.sage/backup/` 直下のタイムスタンプ形式ディレクトリに限定 (SEC-01)、想定エラー3 をテストケース化
- リスク3: `--diff` 追加により generator 出力が変わり、SHA256SUMS / release フローが壊れる → 軽減策: FAIL-0002 の教訓 (下記) に従い、generator 変更 → install.sh 再生成 → SHA256SUMS 更新を同一 TASK 内の完了条件にする (AC-06, AC-07 で機械検証)
- リスク4: 安全側スキップ (FR-05) により、マーカー破損ファイルが更新されないまま放置される → 軽減策: WARN に手動修復手順 (docs へのポインタ) を含め、docs 対比表で「片方欠損 = 更新されない」を明示

### 知識管理 (failures.md 連携フロー)

- 実装中・リリース後に保全違反 (バックアップ漏れ・マーカー外消失・誤削除) を検出した場合、Implementation Agent は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する。同種の失敗が3回発生した場合は `sage/anti-patterns.md` へ昇格する (CLAUDE.md §5 Error Resolution Protocol 準拠、盲目的リトライ禁止)
- エラー報告時は §5 の6要素 (エラーログ / 失敗ファイル+行 / SPEC-0026 の該当 AC / git diff / 修正スコープ / 完了条件) を必ず含める

### ロールバック手順

- 本 SPEC のリリースに問題が発生した場合、直前リリースの `install.sh` + SHA256SUMS (GitHub Releases) に差し戻して再実行する。`--diff` は新設オプションのため旧版に存在しなくても既存フローに影響しない
- 導入先でカスタマイズ消失が発生した場合の復元: `cp .sage/backup/<最新timestamp>/<ファイル> <ファイル>` で更新前状態に復元し、issue を起票する (docs の手動復元手順に記載)

## 実装メモ（Implementation Agent向け）

- **File Scope (Implementation Agent が変更可能なファイル)**:
  - `scripts/generator/07-installer-main.sh`
  - `install.sh` (再生成のみ・手動編集禁止)
  - `SHA256SUMS`
  - `templates/hooks/tests/test-installer-preservation.sh`
  - `templates/hooks/tests/run-tests.sh` (登録行のみ、自動 discovery なら不要)
  - `README.md`
  - `docs/installer-preservation.md` (新規)
  - `templates/claude-md-snippet.md`

  上記以外の変更は禁止 (AP-03)。AGENTS.md / `docs/codex-*.md` / `sage/` は特に不可。
- 主要変更点: `scripts/generator/07-installer-main.sh` — `upsert_sage_section()` (マーカー片方欠損の安全側スキップ)、ファイル書き込みループ (バックアップ関数 `backup_before_write()` の挿入)、引数パーサ (L480 付近、`--diff` 追加)、usage (L488 付近)
- SPEC-0025 の overlay 除外 (`is_unmanaged_path()`) と整合すること: overlay 配下は書き込み対象外なのでバックアップ対象にもならない (INV-01 of SPEC-0025 を壊さない)
- **FAIL-0002 の教訓 (SPEC-0025 実装より)**: `sage/failures.md` 等テンプレート同梱ファイルへの追記や generator 変更を行ったら、必ず `install.sh` を再生成して SHA256SUMS を追随させること。再生成漏れは AC-06 で FAIL する
- テストは `templates/hooks/tests/_helpers.sh` + `test-local-overlay.sh` / `test-installer-modularize.sh` の流儀 (一時ディレクトリ + 生成 install.sh 実行) を踏襲
- コミット規約: 全コミットに TASK-ID を含める (commit-msg hook で強制、AP-05)。PR 本文に SPEC-0026 / PLAN-ID / TASK-ID を記載
- 禁止事項: AGENTS.md / `docs/codex-*.md` の直接編集 (Codex follow-up として TASK 分離)、`sage/` 配下の変更、TASK File Scope 外の変更 (AP-03)、generator + tests + docs の一括 Big Bang 変更 (AP-02 — Slice で分割)、テスト未実行での受け入れ (AP-09)、テストを実装に合わせて改変して通すこと (§5 禁止事項)
- Slice 向け分割ヒント:

| TASK | 内容 | 対応 AC | コマンド検証可能な完了条件 | 依存 / 並列可否 |
|------|------|---------|--------------------------|----------------|
| T1 | generator: backup_before_write() + 世代ローテーション | AC-02/03/09/11/12 | `grep -q 'backup_before_write' scripts/generator/07-installer-main.sh` + 既存テスト全件 PASS | 依存なし |
| T2 | generator: upsert マーカー片方欠損の安全側スキップ | AC-01/08 | `bash install.sh` (欠損 fixture) exit 0 + WARN grep | T1 に依存 (07-installer-main.sh を共有するため直列) |
| T3 | generator: `--diff` オプション | AC-04 | `bash install.sh --diff` に `^+++ ` 行 + checksum 不変 | T1 後 (UPDATE 判定ロジック共有) |
| T4 | templates/claude-md-snippet.md へのバックアップ規約追記 (FR-08) + install.sh 再生成 + SHA256SUMS 更新 | AC-06/13 | `shasum -a 256 -c SHA256SUMS` PASS + clean install 後 `grep -q '.sage/backup/' CLAUDE.md` PASS | T1-T3 後 |
| T5 | test-installer-preservation.sh 追加 | AC-01〜05 (AC-04b 含む)/08/09/11/12/13 | `bash templates/hooks/tests/test-installer-preservation.sh` 全ケース PASS | T4 後 |
| T6 | docs: 復元手順 + マーカー方式対比表 | AC-10 | AC-10 の grep 検証 PASS + run-tests.sh 非破壊 | T1 後に並列可 |

  実行順: T1 → T2 → T3 → T4 → T5。T6 は T1 完了後に並列可。各 TASK は単一責務 (generator 機能 / 再生成 / テスト / docs) を維持する。

## Properties

権限レベル platform + Security 要件あり → 5 件以上。

### Invariants
- [INV-01] (Gate 2) installer のいかなる実行経路 (install / 再 install / --dry-run / --diff / --verify-checksum) においても、CLAUDE.md / AGENTS.md のマーカー外コンテンツは変化しない (マーカー両方欠損時の append を除く。その場合も既存行は不変)
- [INV-02] (Gate 2) 既存ファイルの内容が変わる書き込みは、必ず同一実行内で当該ファイルのバックアップが `.sage/backup/<timestamp>/` に存在した後にのみ行われる (バックアップなし上書きの禁止)
- [INV-03] (Gate 3) `.sage/backup/` 配下のローテーション削除は、ディレクトリ名が正規表現 `^[0-9]{8}-[0-9]{6}(-[0-9]+)?$` にマッチするディレクトリのみを対象とする (それ以外のエントリは削除しない)
- [INV-04] (Gate 4) バックアップ判定・実行は generator 内の単一関数に集約され、全書き込み経路がそれを経由する (重複実装による防御漏れ禁止)
- [INV-05] (Gate 3) SHA256SUMS / --verify-checksum / provenance の検証対象・強度は SPEC-0018/0025 時点から縮小しない

### Pre-conditions
- [PRE-01] (Gate 2) installer はファイル書き込み前に「既存 + 内容差分あり」を判定し、真の場合のみバックアップを実行する
- [PRE-02] (Gate 2) `--diff` 指定時、installer は書き込みフェーズに入る前に diff 表示のみで終了する
- [PRE-03] (Gate 2) `upsert_sage_section()` は編集前にマーカーの整合 (両方存在 / 両方不在 / 片方のみ) を判定し、片方のみの場合は編集を行わない

### Post-conditions
- [POST-01] (Gate 2) UPDATE が1件以上発生した install 完了後、`.sage/backup/` の世代数は 3 以下であり、最新世代に全 UPDATE 対象の更新前内容が含まれる
- [POST-02] (Gate 2) `--diff` 実行後、作業ディレクトリの全ファイル checksum は実行前と一致する
- [POST-03] (Gate 2) 再生成された `install.sh` は SHA256SUMS のエントリと一致する

### Assumptions
- [ASM-01] (Gate 横断) 導入先は bash 3.2+ / `diff` / `shasum` または `sha256sum` が利用可能 (既存 installer と同一前提)
- [ASM-02] (Gate 横断) `.sage/backup/` は gitignore 済みであり、導入先がこれを VCS 管理に含めない運用を前提とする (含めた場合の repo 肥大は導入先責任)

## 関連ID

- PLAN-ID: [PLAN-0026](../plans/PLAN-0026-installer-preservation.md)
- TASK-ID:
  - [TASK-0178](../tasks/TASK-0178-backup-before-write.md) (T1: backup_before_write + 世代ローテーション)
  - [TASK-0179](../tasks/TASK-0179-upsert-marker-safe-skip.md) (T2: upsert マーカー片方欠損の安全側スキップ)
  - [TASK-0180](../tasks/TASK-0180-diff-option.md) (T3: --diff オプション)
  - [TASK-0181](../tasks/TASK-0181-snippet-and-regenerate.md) (T4: snippet 追記 + install.sh 再生成 + SHA256SUMS)
  - [TASK-0182](../tasks/TASK-0182-test-installer-preservation.md) (T5: test-installer-preservation.sh)
  - [TASK-0183](../tasks/TASK-0183-docs-restore-and-matrix.md) (T6: docs 復元手順 + 対比表)
- Done Definition: [done-def-SPEC-0026-round-1](../tasks/done-def-SPEC-0026-round-1.md)
