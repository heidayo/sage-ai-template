# SPEC-0029: Codex ルール層の対称化 — .codex/rules/ テンプレートと優先順位の公式化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0029 |
| ステータス | Draft |
| 作成日    | 2026-07-03 |
| 更新日    | 2026-07-03 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0022 (Codex Delegation Packet / Codex-only boundary), SPEC-0023 (AGENTS/CLAUDE pairing doctrine, paired-update 要件), SPEC-0025 (local overlay 不可侵 — `.codex/rules/local/` は unmanaged_paths 宣言済み), SPEC-0026 (installer preservation 方針), SPEC-0014 (installer modular), SPEC-0018 (supply chain hardening / SHA256SUMS) |
| 権限レベル | platform |

## 背景・目的

Claude Code には `.claude/rules/` (specs / plans / tasks / src / governance の 5 rules、実体は `templates/rules/` を generator 経由で配布) があるが、Codex 側に相当するルール層が存在しない。実プロジェクトでは `.codex/AGENTS.md`・`.codex/LOCAL.md`・`.codex/rules/*` を各導入先が自作し、優先順位 (`.codex/` > ルート `AGENTS.md`) も独自定義する必要があり、SPEC-0023 の pairing doctrine (SHARED rules の semantic alignment) が Codex ルール層で構造的に満たせない状態にある。

SPEC-0025 は `.codex/rules/local/` を overlay として installer 不可侵に宣言済み (`unmanaged_paths`、`07-installer-main.sh:26` / `install.sh` 生成物で確認済) だが、その対になる **managed 側** (`.codex/rules/` の配布テンプレート) は「S5 = 別 SPEC」として明示的にスコープ外とされていた。本 SPEC がその S5 である。

本 SPEC は `templates/codex-rules/` に `.claude/rules/` と意味的に同一 (Codex 向け文言調整のみ) の 5 rules テンプレートを新設し、installer が `.codex/rules/` へ `.claude/rules/` と同方式 (SPEC-0025 marker + 全置換 + overlay 案内注記) で配布し、優先順位・ロード順を `docs/codex-rules.md` に公式文書化する。

## 対象ユーザー

- Codex CLI を SAGE と併用する開発者 (Codex セッションに層別ルールを与えたいチーム)
- Claude Code / Codex を並用し、両 CLI のルール層を semantic alignment で維持したいチーム
- 既存導入先 — `.codex/` を自作済みの環境 (overlay `.codex/rules/local/` は不可侵、managed 側の追加のみ)

## スコープ（含む）

- `templates/codex-rules/` の新設 (5 ファイル):
  - `specs-rules.md` / `plans-rules.md` / `tasks-rules.md` / `src-rules.md` / `sage-governance-rules.md`
  - 内容は `templates/rules/` (= `.claude/rules/` の配布元) と**意味的に同一** (SHARED rules)。Codex 向け文言調整のみ許容 (例: 「Claude Code hooks で強制」→「Codex では guidance として遵守。runtime 強制は Codex 本体設定」— SPEC-0022 SEC-03 と整合)
- installer による `.codex/rules/` 配布 (managed):
  - `write_rules_file` と同方式 (marker コメントによる SAGE-managed 宣言 + install/update 時の全置換 + `is_unmanaged_path` ガードで `*/rules/local/**` 到達不能)
  - marker / overlay 案内注記は `.claude/rules/` 版と対称の文言で、overlay 先を `.codex/rules/local/` として案内 (LOCAL.md 相当のプロジェクト固有カスタマイズ導線)
  - `managed_files` (install-state / SHA256SUMS 検証対象) に `.codex/rules/*.md` 5 件を追加
- `.codex/rules/local/` の不可侵確認 (追加宣言は不要):
  - SPEC-0025 で `unmanaged_paths` に宣言済みであることを前提とし、本 SPEC では **配布側が overlay を作成・変更・削除しない** ことをテストで再確認する (INV は SPEC-0025 INV-01 を継承)
- generator 対応: `scripts/generator/03-rules.sh` に `TMPL_CODEX_RULES_*` embed 5 件 + Codex 向け注記追記、`07-installer-main.sh` に mkdir / write / managed_files / dry-run 表示追加。`install.sh` 再生成 + SHA256SUMS 更新 (FAIL-0002 教訓、専用 TASK・単独コミット)
- 優先順位・ロード順の文書化: `docs/codex-rules.md` 新設 (日本語):
  - 規約「`.codex/rules/` > ルート `AGENTS.md`」(具体則が一般則に優先。矛盾時は `.codex/rules/` 側に従い、矛盾自体を paired-update で解消する)
  - Codex の config (AGENTS.md 参照機構) を前提とした読み込み手順 (Codex は `.codex/rules/` を自動ロードしないため、ルート `AGENTS.md` または `.codex/AGENTS.md` から参照させる手順を記載 — 参照追記の実施自体は Codex follow-up)
  - `.claude/rules/` との対応表 (5 ファイル 1:1 対応、SHARED / CLI-specific の区分)
  - `.codex/rules/local/` overlay の使い方 (SPEC-0025 参照)
- Claude/Codex boundary の遵守 (SPEC-0023):
  - **`AGENTS.md` 本文および `docs/codex-delegation-packet.md` / `docs/codex-security.md` は本 SPEC では編集しない**。`AGENTS.md` への `.codex/rules/` 参照追記は「Codex follow-up task」として、PR 本文に追記案 (差分提案テキスト) を提示するに留める
  - `docs/codex-rules.md` は**本 SPEC で新設する SAGE 管理文書**であり、既存 `docs/codex-*.md` (SPEC-0022 territory) とは別物として扱う。新設後は Codex-specific ファイル群に加わり、以後の修正は Codex 側 task とする (この帰属を doc 冒頭に明記)
- テスト `templates/hooks/tests/test-codex-rules.sh` の追加 (`_helpers.sh` / `run-tests.sh` の既存流儀、テスト実装は Test Agent 責務):
  - (1) 配布: clean install 後に `.codex/rules/` 5 ファイルが存在し marker を含む
  - (2) semantic pairing: `templates/codex-rules/` と `templates/rules/` の installer 配布対象 5 rules (harness-rules.md 除外) の対応 (配布対象ファイル集合が 1:1)
  - (3) overlay 不可侵: `.codex/rules/local/` にファイルを置いた環境で install / 再 install 後もバイト不変・削除されない
  - (4) 再 install 冪等: install 2 回実行で `.codex/rules/` の内容がバイト同一
  - (5) managed 全置換: `.codex/rules/specs-rules.md` を改変後 `install.sh --update` でテンプレート内容へ復元される
  - (6) 異常系: dry-run で `.codex/rules/` 配下に書き込みが発生しない
  - (7) 異常系: `.codex/rules/local` という**通常ファイル** (ディレクトリでない) が存在する環境でも installer が overlay 外へ書き込まず異常終了しない

## スコープ外（明示的に除外）

- `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` の本文修正 — SPEC-0022/0023 boundary。`.codex/rules/` 参照追記は Codex follow-up task として PR 本文に追記案のみ提示
- Codex CLI 側の runtime 読み込み強制 (`.codex/rules/` の自動ロード保証) — Codex 本体の仕様依存であり、本 SPEC は配布 + 文書化された参照規約のみ (SPEC-0022 SEC-03 と同方針)
- `.claude/rules/` / `templates/rules/` 側の変更 — 既存 Claude 側ルール層は不変
- `.codex/AGENTS.md` / `.codex/LOCAL.md` の配布 — rules 層のみが対象。AGENTS 系ファイルの managed 化は需要確認後の別 SPEC
- `.codex/rules/local/` の unmanaged_paths 宣言変更 — SPEC-0025 で宣言済み、本 SPEC は追認のみ
- rules 内容の実質改訂 (新ルールの追加・既存ルールの強化) — 本 SPEC は既存 `templates/rules/` の意味的ミラーのみ
- CLAUDE.md 本文の変更 (Human-only) — §9.1 等への機能追記が必要な場合、マージ後に Human が「Codex rules layer (SPEC-0029) — installer が `.codex/rules/` を配布、詳細: docs/codex-rules.md」を追記する follow-up として分離し、PR 本文に追記案を記載する
- `sage/` 配下 governance 文書の改訂 (Human-only) — pairing doctrine (§10) は SPEC-0023 で規範化済みのため改訂不要
- cosign / provenance 経路の変更 (SPEC-0018/0019/0020 検証フロー非介入)
- `templates/rules/harness-rules.md` の Codex ミラー — harness は Claude Code 専用機構のため対象外 (SPEC-0023 CLI-specific 区分)

## 要件

### 機能要件

- [FR-01] `templates/codex-rules/{specs,plans,tasks,src,sage-governance}-rules.md` の 5 ファイルが存在し、`templates/rules/` の installer 配布対象 5 rules (harness-rules.md 除外) と 1:1 対応する
- [FR-02] installer は新規 install / `--update` 時に `.codex/rules/` へ 5 ファイルを書き込む。書き込みは `.claude/rules/` と同方式 (SAGE-managed marker + 全置換) で行い、marker と注記は overlay 先として `.codex/rules/local/` を案内する
- [FR-03] installer のいかなる実行経路でも `.codex/rules/local/**` を作成・変更・削除しない (SPEC-0025 FR-01 の配布側継承)。書き込み関数は `is_unmanaged_path` ガードを経由する
- [FR-04] `.codex/rules/*.md` 5 件が install-state の managed_files に追加され、`--verify-checksum` の検証対象となる
- [FR-05] `--dry-run` 時は `.codex/rules/` への書き込み予定を WOULD-* 表示するのみで、ファイルの作成・変更を一切行わない
- [FR-06] `docs/codex-rules.md` が存在し、(a) 優先順位規約「`.codex/rules/` > ルート `AGENTS.md`」、(b) Codex config (AGENTS.md 参照機構) 前提の読み込み手順、(c) `.claude/rules/` との対応表、(d) `.codex/rules/local/` overlay 案内 — の 4 節を含む
- [FR-07] `docs/codex-rules.md` は installer 配布対象 (generator embed + write/update + managed_files) とし、SPEC-0022 の `docs/codex-delegation-packet.md` と同経路で伝播する
- [FR-08] 生成物は generator 経由でのみ変更され、再生成後の `install.sh` は SHA256SUMS と一致する
- [FR-09] `AGENTS.md` への参照追記は行わず、PR 本文に Codex follow-up 用の追記案 (追加位置・文言) を記載する

### 非機能要件

- [NFR-01] 後方互換: `.codex/rules/` を持たない既存導入先で `install.sh --update` を実行しても、既存ファイル (特に自作の `.codex/AGENTS.md` / `.codex/LOCAL.md` / `.codex/rules/local/`) は変更されず、追加されるのは managed 5 ファイル + docs のみ
- [NFR-02] 再現性: 同一 generator 入力から生成される `install.sh` はバイト一致し、SHA256SUMS 検証を壊さない
- [NFR-03] semantic pairing 維持コスト: `templates/rules/` と `templates/codex-rules/` の乖離はテスト (1:1 対応検証) と SPEC-0023 paired-update doctrine で管理し、内容の完全一致 (バイト同一) は要求しない (CLI-specific 文言調整を許容)
- [NFR-04] 既存 hook tests の実行時間を大きく増やさない (新 test は 15 秒以内)

### セキュリティ要件

- [SEC-01] `.codex/rules/` へ書き込まれる内容は install.sh 埋め込みの静的テンプレート文字列のみとし、導入先ファイルの内容を転記しない
- [SEC-02] 書き込みパスは固定文字列 (`.codex/rules/<name>-rules.md`) のみで、外部入力からパスを構成しない (パストラバーサル不能)
- [SEC-03] `.codex/rules/local/**` への不可侵は `unmanaged_paths` 宣言 (SPEC-0025) と `is_unmanaged_path` ガードの両方で担保し、本 SPEC の追加によって SPEC-0025 INV-01 / SPEC-0018 検証フローの対象・強度を縮小しない
- [SEC-04] 新規テンプレート / docs に secret / token / API key / `.env` 例値を含めない (gitleaks 通過必須)。また Codex rules は runtime enforcement ではなく guidance であることを src-rules 相当ファイルと docs に明記する (SPEC-0022 SEC-03 整合)

### 運用要件

- [OPS-01] `docs/codex-rules.md` に優先順位・読み込み手順・対応表・overlay 案内を記載し、README から参照する
- [OPS-02] `make doctor` 既存チェックが `.codex/rules/` 配布後も PASS する
- [OPS-03] 定量合格基準: リリース後2週間、`sage/failures.md` に `.codex/rules/` 起因の失敗記録 (overlay 破壊 / 既存 `.codex/` 自作ファイルの上書き / rules 乖離) が0件、かつ少なくとも1導入先で Codex セッションが `.codex/rules/` を参照した RUN log (`bash scripts/sage-runlog-search.sh --keyword "codex-rules"`) が1件以上確認できた場合に安定 (Observe 完了) とみなす。overlay 破壊報告1件で即 issue 起票、同種3件で `sage/anti-patterns.md` へ昇格検討
- [OPS-04] 今後 `templates/rules/` を改訂する SPEC は、`templates/codex-rules/` の paired-update を同 PR または follow-up SPEC として明示する (SPEC-0023 §10 doctrine 準拠。乖離はテストの 1:1 対応検証が検出)

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: テンプレート存在・対応 — `diff <(ls templates/rules/ | grep -v '^harness-rules.md$') <(ls templates/codex-rules/)` が exit 0 (配布対象 5 ファイルの 1:1 対応) (case: `templates_paired`)
- [ ] AC-02: 配布 — 空の一時ディレクトリで `bash install.sh` 実行後、`for f in specs plans tasks src sage-governance; do test -f ".codex/rules/${f}-rules.md" && grep -q 'SAGE managed' ".codex/rules/${f}-rules.md" || exit 1; done` が exit 0、かつ注記が `.codex/rules/local/` を案内している (`grep -q '.codex/rules/local'`) (case: `codex_rules_installed`)
- [ ] AC-03: overlay 不可侵 — `.codex/rules/local/my-rules.md` を配置した一時環境で install → 再 install 後、当該ファイルが `diff` でバイト不変かつ削除されていない (case: `overlay_untouched`)
- [ ] AC-04: 再 install 冪等 — install を 2 回実行し、`.codex/rules/` 全 5 ファイルが 1 回目と 2 回目で `diff -r` バイト同一 (case: `reinstall_idempotent`)
- [ ] AC-05: managed 全置換 — `.codex/rules/specs-rules.md` に行を追記後 `bash install.sh --update` を実行すると、テンプレート内容へ復元される (追記行が消える) (case: `managed_replace`)
- [ ] AC-06: managed_files 登録 — install 後 `grep -c '.codex/rules/' .sage/install-state.yaml` が 5 以上 (unmanaged の local/ 宣言と別に managed 5 件)、かつ `bash install.sh --verify-checksum` が PASS (case: `verify_checksum_covers`)
- [ ] AC-07: 異常系 (dry-run 非介入) — 空の一時ディレクトリで `bash install.sh --dry-run` 実行後、`test ! -e .codex` が真、stdout に `.codex/rules` の WOULD-* 表示が含まれる (case: `dry_run_no_write`)
- [ ] AC-08: 異常系 (local が通常ファイル) — `.codex/rules/local` を通常ファイルとして配置した一時環境で install を実行しても、当該ファイルがバイト不変で、`.codex/rules/` の managed 5 ファイルは正常配布される (case: `local_as_file`)
- [ ] AC-09: docs — `test -f docs/codex-rules.md` かつ `grep -qF '.codex/rules/' docs/codex-rules.md && grep -qF 'AGENTS.md' docs/codex-rules.md && grep -qF '.claude/rules/' docs/codex-rules.md && grep -qF '.codex/rules/local/' docs/codex-rules.md` が exit 0、かつ `grep -qF 'docs/codex-rules.md' README.md` が exit 0 (case: `docs_reference`)
- [ ] AC-10: 再現性 — `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` が 0 行、かつ `shasum -a 256 -c SHA256SUMS` (install.sh エントリ) が成功する
- [ ] AC-11: 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する
- [ ] AC-12: boundary 遵守 — 本 SPEC の PR diff に `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` / `templates/rules/` / `.claude/rules/` が含まれない (`git diff --name-only main | grep -E '^(AGENTS\.md|docs/codex-delegation-packet\.md|docs/codex-security\.md|templates/rules/|\.claude/rules/)'` が exit 非0)、かつ PR 本文に AGENTS.md 追記案 (Codex follow-up) が記載されている、かつ `gh pr view --json body -q .body | grep -qF 'AGENTS.md 追記案' && gh pr view --json body -q .body | grep -qF 'CLAUDE.md §9.1 追記案'` が exit 0 (case: followup_drafts_in_pr)

### 検証方針

- `templates/hooks/tests/test-codex-rules.sh` は integration テストとして、一時ディレクトリで install.sh を実行し AC-01〜09 の各ケースを検証する (test-local-overlay.sh / test-installer-preservation.sh の流儀を踏襲)。テスト実装は Test Agent 責務 (Implementation Agent と分離、AP-04 回避)
- テスト種別: bash integration テストのみ。unit テストは対象がシェルスクリプトのため非適用
- カバレッジ閾値は N/A — bash スクリプトであり Gate 2 の LOC ベース coverage 計測の適用対象外。代替として異常系 (想定エラー1〜3・境界ケース1〜3) を全てテストケース化し網羅性を担保する
- AC-12 (boundary) は全 TASK 横断の制約として PR レビュー + Review Agent の Scope Check で確認

## 異常系

- 想定エラー1: `--dry-run` で `.codex/` 配下に書き込みが発生する — FR-05 違反として AC-07 で FAIL 検出
- 想定エラー2: `.codex/rules/local` が通常ファイルとして存在する (ディレクトリ前提の破れ) — installer は当該パスを不可侵として扱い、managed 5 ファイルの配布は継続する (FR-03, AC-08)
- 想定エラー3: generator 再生成漏れで install.sh 内の Codex rules embed が欠落 — AC-10 の byte-identical + SHA256SUMS 検証で FAIL (FAIL-0002 再演防止)
- 境界ケース1: 既存導入先が `.codex/rules/specs-rules.md` を自作済み — managed 方式のため `--update` で SAGE テンプレートに全置換される (AC-05 と同挙動)。docs に「プロジェクト固有ルールは `.codex/rules/local/` へ」の移行案内を記載し、初回配布時の上書きリスクを明示
- 境界ケース2: `templates/rules/` に配布対象の rules ファイルが追加され `templates/codex-rules/` が未追随 — AC-01 の配布対象 5 rules (harness-rules.md 除外) 1:1 対応検証が FAIL し paired-update 漏れを検出 (OPS-04)
- 境界ケース3: `.codex/` ディレクトリ自体が存在しない新規導入先 — installer が `mkdir -p .codex/rules` で作成し 5 ファイル配布 (AC-02)。`.codex/rules/local/` は作成しない (SPEC-0025 AC-02 継承)

## 契約

- API: なし
- DB: なし
- イベント: なし
- CLI 契約: `install.sh` の既存オプション (`--dry-run` / `--update` / `--verify-checksum` / `--stack` 等) の意味・exit code 規約は不変。新規オプションなし (配布は無条件、`.codex/rules/` は managed 追加のみ)
- ファイル契約: `templates/codex-rules/<name>-rules.md` (5 ファイル固定、`templates/rules/` と 1:1) — `.codex/rules/` への配布元。`.codex/rules/local/**` は unmanaged (SPEC-0025 契約を継承)。`docs/codex-rules.md` は SAGE 管理文書 (installer update 対象、以後の本文修正は Codex 側 task)

## リスク

- リスク1: 既存導入先が `.codex/rules/` 直下に自作ルールを置いていた場合、managed 同名ファイルが `--update` で上書きされる → 軽減策: docs とリリースノートに移行案内 (`.codex/rules/local/` への退避) を明記。上書き対象は SAGE 管理名 5 件のみで、別名ファイルは触らない (write 対象は固定 5 パス、SEC-02)
- リスク2: `templates/rules/` と `templates/codex-rules/` の semantic drift (片側だけ改訂) → 軽減策: AC-01 の 1:1 対応検証 + OPS-04 の paired-update doctrine (SPEC-0023 §10)。ファイル増減は機械検出、文言 drift はレビュー運用で管理
- リスク3: generator 再埋め込み漏れで install.sh とテンプレートが乖離する (FAIL-0002 再演) → 軽減策: 再生成 + SHA256SUMS 更新を専用 TASK・単独コミットとし AC-10 で機械検証
- リスク4: Codex が `.codex/rules/` を実際に読まない (AGENTS.md からの参照が未追記のまま放置) → 軽減策: FR-09 で PR 本文に Codex follow-up 追記案を必須化し、OPS-03 の Observe 基準 (RUN log 参照実績 1 件以上) で読み込み実態を確認。強制はスコープ外と明示
- リスク5: `docs/codex-rules.md` 新設が SPEC-0023 の「Claude は docs/codex-*.md を編集しない」boundary と衝突して見える → 軽減策: スコープ節で「新設は本 SPEC、以後の修正は Codex 側 task」と帰属を明文化し、doc 冒頭にも同旨を記載。既存 codex docs 2 件には触れない (AC-12 で機械検証)

### 知識管理 (failures.md 連携フロー)

- 実装中・リリース後に overlay 破壊・自作 `.codex/` ファイルの意図しない上書き・rules 乖離を検出した場合、Implementation Agent は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する。同種の失敗が3回発生した場合は `sage/anti-patterns.md` へ昇格する (CLAUDE.md §5 Error Resolution Protocol 準拠、盲目的リトライ禁止)
- エラー報告時は §5 の6要素 (エラーログ / 失敗ファイル+行 / SPEC-0029 の該当 AC / git diff / 修正スコープ / 完了条件) を必ず含める

### ロールバック手順

- 本 SPEC のリリースに問題が発生した場合、直前リリースの `install.sh` + SHA256SUMS (GitHub Releases) に差し戻して再実行する。`.codex/rules/` は additive な managed 追加のため、旧 install.sh は当該ファイルに関知せず旧挙動へ完全に戻る (配布済みファイルは残置されるが無害。撤去したい場合は手動削除)
- 導入先で自作ルールが上書きされた場合の暫定回避: git 履歴から復元し `.codex/rules/local/` へ再配置する。overlay は installer 不可侵のため再実行で悪化しない
- `docs/codex-rules.md` のみ無効化したい場合: rename すれば installer は managed 復元するため、完全撤去はロールバック (旧 install.sh) でのみ行う

## 実装メモ（Implementation Agent向け）

- **File Scope (Implementation Agent が変更可能なファイル)**:
  - `templates/codex-rules/specs-rules.md` (新規)
  - `templates/codex-rules/plans-rules.md` (新規)
  - `templates/codex-rules/tasks-rules.md` (新規)
  - `templates/codex-rules/src-rules.md` (新規)
  - `templates/codex-rules/sage-governance-rules.md` (新規)
  - `docs/codex-rules.md` (新規)
  - `scripts/generator/03-rules.sh` (`TMPL_CODEX_RULES_*` embed 5 件 + Codex 向け overlay 注記)
  - `scripts/generator/07-installer-main.sh` (mkdir `.codex/rules` / write 5 件 / docs write / managed_files 追加 / dry-run WOULD-* 表示)
  - `install.sh` (再生成のみ・手動編集禁止)
  - `SHA256SUMS`
  - `templates/hooks/tests/test-codex-rules.sh` (新規 — **Test Agent 責務**)
  - `templates/hooks/tests/run-tests.sh` (登録行のみ、自動 discovery なら不要 — Test Agent 責務)
  - `README.md` (参照追記のみ)

  上記以外の変更は禁止 (AP-03)。**特に不可**: `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` / `templates/rules/` / `.claude/rules/` / `sage/` / `CLAUDE.md` / 本リポジトリの `.sage/config.yaml`
- 既存機構の再利用: `.claude/rules/` の配布は `scripts/generator/03-rules.sh` (embed + `RULES_LOCAL_NOTICE` 注記 + `write_rules_file` 定義) と `07-installer-main.sh` L865-874 (write 呼び出し) / L1074-1079 (managed_files)。Codex 版は同構造をミラーし、注記の overlay 先のみ `.codex/rules/local/` に差し替える。`is_unmanaged_path` ガード (SPEC-0025) は既存の `write_rules_file` 経路に組み込み済みのため、同関数 (または対称の `write_codex_rules_file`) を経由すれば SEC-03 を満たす
- テンプレート内容: `templates/rules/` の各ファイルを起点に、Claude Code 固有記述 (hooks による runtime 強制、`/sage-*` slash command 等) を Codex 文脈 (guidance 遵守 + Codex Delegation Packet 参照) に置換する。ルールの追加・削除は行わない (semantic 同一、NFR-03)
- `docs/codex-rules.md` 冒頭に「本文書は SPEC-0029 で新設。以後の本文修正は Codex 側 task (SPEC-0023 boundary)」を明記
- **FAIL-0002 の教訓**: generator 変更後は必ず `install.sh` を再生成して SHA256SUMS を追随させること。再生成 + SHA256SUMS 更新は専用 TASK・単独コミットとする。再生成漏れは AC-10 で FAIL する
- コミット規約: 全コミットに TASK-ID を含める (commit-msg hook で強制、AP-05)。PR 本文に SPEC-0029 / PLAN-ID / TASK-ID + **AGENTS.md 追記案 (Codex follow-up)** + **CLAUDE.md §9.1 追記案 (Human follow-up)** を記載
- 禁止事項: install.sh の手動編集、AGENTS.md / 既存 codex docs への直接編集 (FR-09 / AC-12)、テスト未実行での受け入れ (AP-09)、テストを実装に合わせて改変して通すこと (§5 禁止事項)、導入先ファイル内容の転記 (SEC-01)
- Slice 向け分割ヒント:

| TASK | 内容 | 対応 AC | コマンド検証可能な完了条件 | 依存 / 並列可否 |
|------|------|---------|--------------------------|----------------|
| T1 | `templates/codex-rules/` 5 ファイル新設 | AC-01 | `diff <(ls templates/rules/ | grep -v '^harness-rules.md$') <(ls templates/codex-rules/)` exit 0 | 依存なし |
| T2 | generator: embed + write + managed_files + dry-run 表示 (03-rules.sh / 07-installer-main.sh) | AC-02〜08 (実装) | generator 単体で TMPL_CODEX_RULES_* 5 件 embed 確認 + 一時ディレクトリでの手動 install 検証 | T1 に依存 |
| T3 | `docs/codex-rules.md` 新設 + generator 配布経路 + README 参照追記 | AC-09 | AC-09 の grep 検証 PASS | T1 後に並列可 (generator 部分は T2 と調整) |
| T4 | install.sh 再生成 + SHA256SUMS 更新 (**専用 TASK・単独コミット** = FAIL-0002) | AC-10 | `diff install.sh /tmp/new.sh` 0 行 + `shasum -a 256 -c SHA256SUMS` PASS | T2, T3 後 |
| T5 | test-codex-rules.sh 追加 + run-tests.sh 登録 (**Test Agent 責務・別セッション**) | AC-01〜09/11 | `bash templates/hooks/tests/test-codex-rules.sh` 全ケース PASS + run-tests.sh 全件 PASS | T4 後 |
| T6 | PR 本文: AGENTS.md 追記案 (Codex follow-up) + CLAUDE.md §9.1 追記案 (Human follow-up) 起草 | AC-12 (部分) | `gh pr view --json body -q .body | grep -qF 'AGENTS.md 追記案' && gh pr view --json body -q .body | grep -qF 'CLAUDE.md §9.1 追記案'` が exit 0 | T4 後に並列可 |

  実行順: T1 → T2 → T4 → T5。T3 は T1 後に並列可 (T4 前に合流)。T6 は T4 後。各 TASK は単一責務を維持する。AC-12 (boundary) は全 TASK 横断の制約として PR レビューで確認。

## Properties

権限レベル platform + Security 要件あり → 5 件以上。

### Invariants
- [INV-01] (Gate 2) installer のいかなる実行経路 (install / 再 install / --update / --dry-run / --verify-checksum) でも `.codex/rules/local/**` の存在・内容・mtime は変化しない (SPEC-0025 INV-01 の配布側継承)
- [INV-02] (Gate 2) installer が `.codex/` 配下に書き込むのは固定 5 パス (`.codex/rules/<name>-rules.md`) のみであり、導入先の自作ファイル (別名・`.codex/AGENTS.md` 等) は変更されない
- [INV-03] (Gate 3) `.codex/rules/` へ書き込まれる内容は install.sh 埋め込みの静的テンプレート文字列のみで、導入先ファイル内容・外部入力からの転記経路が存在しない
- [INV-04] (Gate 3) 再生成された `install.sh` は SHA256SUMS と一致し、SPEC-0018/0025 の検証フローの対象・強度を縮小しない (managed_files は追加のみ)
- [INV-05] (Gate 4) Codex rules の実体は `templates/codex-rules/` の 5 ファイルのみであり、install.sh 内の埋め込みは generator による派生物である (二重管理による drift 禁止)
- [INV-06] (Gate 4) `templates/rules/` の installer 配布対象 5 rules (harness-rules.md 除外) と `templates/codex-rules/` のファイル集合は 1:1 対応を維持する (paired-update の機械検証点)

### Pre-conditions
- [PRE-01] (Gate 2) `.codex/rules/` への書き込みは `is_unmanaged_path` 判定 (対象が `*/rules/local/**` でないこと) の成立後にのみ実行される
- [PRE-02] (Gate 2) `--dry-run` 判定は `.codex/` 配下を含む全書き込みに先行して評価される

### Post-conditions
- [POST-01] (Gate 2) install 完了後、`.codex/rules/` の managed 5 ファイルは marker + overlay 案内注記を含み、install-state の managed_files に登録されている
- [POST-02] (Gate 2) 再 install / --update 後の `.codex/rules/` managed 5 ファイルはテンプレート由来の内容にバイト収束する (冪等性)

### Assumptions
- [ASM-01] (Gate 横断) 導入先は bash 3.2+ / POSIX ツールが利用可能 (既存 install.sh と同一前提)
- [ASM-02] (Gate 横断) Codex CLI が `.codex/rules/` を実際にロードするかは Codex 本体設定と AGENTS.md からの参照 (Codex follow-up) に依存する。本 SPEC は配布と規約文書化のみを保証し、runtime 読み込みは強制しない
- [ASM-03] (Gate 横断) SPEC-0025 の `unmanaged_paths` 宣言 (`.codex/rules/local/`) は有効なまま維持される。本 SPEC はこれを変更しない

## 関連ID

- PLAN-ID: [PLAN-0029](../plans/PLAN-0029-codex-rules.md)
- TASK-ID:
  - T1 → [TASK-0198](../tasks/TASK-0198-codex-rules-templates.md) (templates/codex-rules/ 5 ファイル新設)
  - T2 → [TASK-0199](../tasks/TASK-0199-generator-codex-rules.md) (generator embed + write + managed_files + dry-run)
  - T3 → [TASK-0200](../tasks/TASK-0200-docs-codex-rules.md) (docs/codex-rules.md + README 参照)
  - T4 → [TASK-0201](../tasks/TASK-0201-regen-install-sha256sums.md) (install.sh 再生成 + SHA256SUMS、専用・単独コミット)
  - T5 → [TASK-0202](../tasks/TASK-0202-test-codex-rules.md) (test-codex-rules.sh、Test Agent 責務・別セッション)
  - T6 → [TASK-0203](../tasks/TASK-0203-pr-followup-drafts.md) (PR 本文 follow-up 追記案)
- Done Definition: [tasks/done-def-SPEC-0029-round-1.md](../tasks/done-def-SPEC-0029-round-1.md)
- Codex follow-up: AGENTS.md への `.codex/rules/` 参照追記 (PR 本文に追記案を記載、Codex 側 task として起票)
- Human follow-up: CLAUDE.md §9.1 相当への機能追記 (PR 本文に追記案を記載)
