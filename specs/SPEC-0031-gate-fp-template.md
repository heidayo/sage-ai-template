# SPEC-0031: Gate False Positive 記録テンプレートの標準搭載 — GATE-FP-XXXX 書式と採番

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0031 |
| ステータス | Draft |
| 作成日    | 2026-07-03 |
| 更新日    | 2026-07-03 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0027 (ID pattern loader — gate-fp を**通さない**設計判断の参照先), SPEC-0026 (installer preservation — failures.md は KEEP 対象の根拠), SPEC-0018 (supply chain hardening — install.sh 再生成時の SHA256SUMS 更新義務), SPEC-0024 (failures.md cause enum の先行変更例), SPEC-0002 (Quality Gate enforcement — 誤検知の発生源) |
| 権限レベル | platform |

## 背景・目的

実プロジェクトへの SAGE 導入で、Quality Gate (Gate 1-5) の誤検知 (false positive: CI flake・正しいコードへの誤 FAIL・環境起因の失敗) を記録・再発防止する書式が `sage/failures.md` に存在せず、導入先が独自書式を追加する必要があった。既存の FAIL-XXXX 書式は「実装・プロセスの失敗」(agent 側の誤り) を記録する設計であり、「gate 側が誤っていた」事象の構造化記録 — 誤検知の証跡、一時対応と恒久対応の区別、再発回数の追跡 — に適さない。誤検知が記録されないと、同じ flaky check への再実行対応が繰り返され (盲目的リトライ)、gate 設定の見直しという恒久対応に到達しない。これは AP-06 (Human-Only Guard) の変種であり、「gate は強制されるが gate 自身の品質は誰も追跡しない」状態である。

本 SPEC は (1) `sage/failures.md` に GATE-FP-XXXX 記録テンプレートとエスカレーションルールを追加し、(2) `scripts/sage-id-gen.sh` に `gate-fp` 種別を追加して採番を機械化し、(3) FAIL-XXXX との使い分けを記録ルール節に明記する。

### 設計判断1: generator 埋め込みの確認結果と再生成 TASK の必要性

実コード確認の結果、本 SPEC の変更対象 2 ファイルは**いずれも generator 埋め込み対象**である:

- `sage/failures.md` — `scripts/generator/01-templates.sh:21` で `embed_file "TMPL_FAILURES"` として install.sh に埋め込まれ、`07-installer-main.sh:814` で新規インストール時に `write_file_if_new` で配布される。update モードでは `07-installer-main.sh:864-865` により **KEEP (更新しない)** — 既存導入先のプロジェクト固有データは影響を受けない
- `scripts/sage-id-gen.sh` — `scripts/generator/03-rules.sh:117` で `embed_file "TMPL_ID_GEN"` として埋め込まれ、新規インストール時 `write_file_if_new` (`07-installer-main.sh:830`) かつ update モードでも `update_file` (`07-installer-main.sh:855`) で**上書き更新される**

したがって、FAIL-0002 の教訓 (再生成物は再生成専用 TASK の別コミット) に従い、**install.sh 再生成 + SHA256SUMS 更新の専用 TASK を本 SPEC に含める**。release.yml の drift check により再生成なしでは Gate が FAIL するため、省略は不可。

### 設計判断2: gate-fp を SPEC-0027 ローダーに通さない

GATE-FP-XXXX は `sage/failures.md` 内の記録専用 ID であり、コミットメッセージ規約 (commit-msg hook) や trace check の受理対象ではない。したがって:

- `scripts/sage-id-pattern.sh` の `_sage_id_fallback_regex` には **gate-fp を追加しない**。同関数は `templates/pre-commit-task-id.sh` の埋め込み fallback と同一性維持が必須 (SPEC-0027 INV-03) であり、追加すると pre-commit hook 側の対応変更まで波及して単一責務を超える
- `sage-id-gen.sh` の `gate-fp` 分岐は、ローダーの `sage_id_default_regex` を呼ばず、**ローカル定数 ERE `GATE-FP-[0-9]{4}`** で `sage/failures.md` をスキャンして採番する (`fail` 種別の failures.md スキャン方式を踏襲)
- `.sage/id-patterns.json` によるカスタム受理パターンは gate-fp に適用されない (適用する必要がない — コミット規約対象外)

## 対象ユーザー

- SAGE 導入先で Quality Gate / CI の誤検知に遭遇し、再実行・SKIP の判断を記録して恒久対応につなげたいチーム
- gate 設定 (project_checks・閾値・flaky テスト) の見直し時期を、記録された再発回数から機械的に判断したい運用者
- 既存導入先 — failures.md は update モードで KEEP のため**既存ファイルへの影響ゼロ**。テンプレート恩恵は新規インストールまたは手動追記で得る

## スコープ（含む）

- `sage/failures.md` への GATE-FP-XXXX エントリテンプレート追加 (「エントリフォーマット」節の直後に新節「Gate False Positive エントリフォーマット」を追加)。必須フィールド:
  - **発生日**: YYYY-MM-DD
  - **誤検知した Gate**: Gate 1-5 のいずれか + チェック名 (例: Gate 2 / unit test `test_foo`, Gate 3 / secret scan)
  - **TASK-ID**: 誤検知に遭遇した作業の TASK-ID
  - **誤検知の根拠**: 「正しいのに FAIL した」ことの証跡 (再実行で PASS したログ、環境差異の特定、誤検出パターンの説明等)
  - **一時対応**: 再実行 / SKIP / 手動オーバーライド等、その場の回避策
  - **恒久対応**: gate 設定修正・閾値調整・flaky テスト修正等 (未実施なら「未対応」と明記 — TBD は不可)
  - **再発回数**: 同一チェックでの累計発生回数 (初回 = 1)
- エスカレーションルールの追記 (failures.md 記録ルール節): **同一チェックの誤検知が累計 3 回に達したら「gate 設定の見直し」を必須化**する。anti-patterns.md 昇格ルール (3 回で昇格) と同型の運用だが、昇格先は anti-patterns.md ではなく gate 設定変更 (project_checks / 閾値 / テスト修正) のアクション実施。見直し結果は該当 GATE-FP エントリの恒久対応欄に追記する
- FAIL-XXXX との使い分けの明記 (failures.md 記録ルール節): **FAIL-XXXX = 実装・プロセス側の失敗 (agent が誤った)、GATE-FP-XXXX = gate 側の誤検知 (コードは正しいのに gate が誤った)**。判断に迷う場合 (両方に誤りがある等) は FAIL を優先し GATE-FP から相互参照する
- `scripts/sage-id-gen.sh` への `gate-fp` 種別追加:
  - `bash scripts/sage-id-gen.sh gate-fp` で `GATE-FP-XXXX` を採番 (sage/failures.md 内の既存 GATE-FP-XXXX の最大番号 + 1、4 桁ゼロ埋め)
  - usage 文言 (`type: spec | plan | task | run | fail`) に `gate-fp` を追加
  - スクリプト内コメントに「GATE-FP は記録専用 ID であり、SPEC-0027 ローダー・コミット規約 (commit-msg hook / trace check) の受理対象外」を明記
- install.sh 再生成 + SHA256SUMS 更新 (**専用 TASK に分離** — FAIL-0002 教訓。上記「設計判断1」参照)
- テスト `templates/hooks/tests/test-gate-fp-idgen.sh` の追加 (`_helpers.sh` / `run-tests.sh` の既存流儀。テスト実装は Test Agent 責務): `sage-id-gen.sh gate-fp` の採番動作を一時ディレクトリの fixture failures.md で検証
- 実装中に検出された gate FP (test-ts-enforcement.sh 開放レンジ誤検知) の恒久対応と GATE-FP-0001 記録 (dogfooding — TASK-0212 遡及承認)

## スコープ外（明示的に除外）

- CI での gate-fp の自動検出・自動記録 (再実行 PASS の検知による自動エントリ生成等) — 記録は human / agent の手動運用。自動化は需要確認後の別 SPEC
- `sage/anti-patterns.md` 本体の変更 — エスカレーション先は gate 設定見直しであり、anti-patterns.md への新 AP 追加は本 SPEC では行わない
- 既存 FAIL エントリ (FAIL-0001 / FAIL-0002) の書式変更・遡及分類 — 既存エントリはバイト単位で不変
- FAIL-XXXX エントリフォーマット自体の変更 — GATE-FP は独立した新節として追加し、既存節は変更しない
- `scripts/sage-id-pattern.sh` / `templates/pre-commit-task-id.sh` への gate-fp 追加 (設計判断2 — コミット規約対象外のため不要かつ INV-03 波及を回避)
- `.sage/id-patterns.json` カスタムパターンの gate-fp 対応
- commit-msg hook / sage-trace-check.sh での GATE-FP 受理 — GATE-FP はコミットメッセージに書く ID ではない
- gate-fp の SQLite FTS インデックス対応 (SPEC-0016 runlog-index) — failures.md は RUN ログではない
- `AGENTS.md` / `docs/codex-*.md` の編集 (Codex-specific boundary)
- CLAUDE.md への機能追記 (Human-only) — マージ後に Human が「Gate 誤検知は GATE-FP-XXXX で sage/failures.md に記録 (SPEC-0031)、採番: `bash scripts/sage-id-gen.sh gate-fp`」を §5 付近へ追記する follow-up として分離。PR 本文に追記案を記載する

## human 承認要件 (sage/ 変更)

`sage/failures.md` は File Scope Rules 上 **human-only 領域** (「Human only (or with explicit approval)」) である。本 SPEC による同ファイルの変更は、**PR レビューとマージをもって human 承認とする**:

- 本 SPEC を実装する PR の本文に「**sage/failures.md (human-only 領域) の変更を含むため、human によるレビュー承認とマージが本変更の承認行為である**」旨を必ず記載する (AC-08 で検証)
- human 承認 (PR approve + merge) なしに main へ取り込まないこと。protect-sage-files hook が session 内の直接編集をブロックする場合は、本 SPEC を明示承認の根拠として human がブロック解除を判断する

## 要件

### 機能要件

- [FR-01] `sage/failures.md` に GATE-FP エントリテンプレート節が存在し、必須 7 フィールド (発生日 / 誤検知した Gate + チェック名 / TASK-ID / 誤検知の根拠 / 一時対応 / 恒久対応 / 再発回数) を含む
- [FR-02] `sage/failures.md` の記録ルール節に (a) FAIL-XXXX と GATE-FP-XXXX の使い分け、(b) 同一チェック誤検知 3 回で gate 設定見直し必須化のエスカレーションルール、が記載されている
- [FR-03] `bash scripts/sage-id-gen.sh gate-fp` が `GATE-FP-XXXX` 形式の次番号を出力する。既存 GATE-FP エントリが 0 件なら `GATE-FP-0001`、既存最大が NNNN なら NNNN+1 を 4 桁ゼロ埋めで出力する
- [FR-04] gate-fp の採番スキャンは `sage/failures.md` のみを対象とし、ローカル定数 ERE `GATE-FP-[0-9]{4}` を用いる (SPEC-0027 ローダーの `sage_id_default_regex` は呼ばない)。スクリプト内コメントで記録専用 ID (コミット規約対象外) であることを明記する
- [FR-05] `sage-id-gen.sh` の既存種別 (spec / plan / task / run / fail) の入出力・挙動は変更前と完全同一である
- [FR-06] install.sh を再生成し、埋め込みテンプレート (TMPL_FAILURES / TMPL_ID_GEN) が変更後の内容と一致し、SHA256SUMS が更新されている

### 非機能要件

- [NFR-01] 後方互換: 既存 FAIL-XXXX 書式・既存エントリ (FAIL-0001 / FAIL-0002) はバイト単位で不変。GATE-FP 節は既存節を変更せず追加のみで実現する
- [NFR-02] 可搬性: `sage-id-gen.sh` の gate-fp 分岐は bash 3.2+ / POSIX ツール (grep/sed/sort/printf) のみで動作し、jq / eval を使用しない (既存実装と同方針)
- [NFR-03] 既存導入先への非破壊: update モードで failures.md は KEEP (SPEC-0026 の preservation 方針)。sage-id-gen.sh の update 上書きは gate-fp 追加のみの後方互換変更であり、既存 ID の採番結果は変わらない

### セキュリティ要件

- [SEC-01] gate-fp 採番の ERE はスクリプト内のローカル定数のみを使用し、外部設定 (`.sage/id-patterns.json`) やユーザー入力をパターンとして評価しない (SPEC-0027 の accept パターン注入面を gate-fp には開けない)
- [SEC-02] install.sh 再生成に伴い SHA256SUMS を必ず更新し、checksum 検証 (`bash install.sh --verify-checksum`) が PASS する状態でマージする (SPEC-0018 非破壊)
- [SEC-03] failures.md への追記はテンプレート文書のみであり、実行可能コード・コマンドの埋め込みを含まない

### 運用要件

- [OPS-01] `bash templates/hooks/tests/run-tests.sh` が既存テスト含め全件 PASS する
- [OPS-02] 定量合格基準: リリース後 4 週間で (a) 本リポジトリまたは導入先で GATE-FP エントリが実際に 1 件以上記録され運用が回ること、(b) gate-fp 採番の誤動作 (重複 ID / 誤った次番号) の報告が 0 件であること、をもって安定 (Observe 完了) とみなす。採番誤動作の報告 1 件で issue 起票、同種 3 件で `sage/anti-patterns.md` へ昇格検討
- [OPS-03] PR 本文に SPEC-0031 / PLAN-ID / TASK-ID に加え、「sage/ 変更の human 承認が merge 前提」の明記と CLAUDE.md 追記案 (follow-up) を含める

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: テンプレート存在 — `grep -qF 'GATE-FP-XXXX' sage/failures.md` が exit 0、かつ必須 7 フィールドが揃う: `for kw in '発生日' '誤検知した Gate' 'TASK-ID' '誤検知の根拠' '一時対応' '恒久対応' '再発回数'; do grep -qF "$kw" sage/failures.md || exit 1; done` が exit 0 (case: `template_fields_present`)
- [ ] AC-02: 使い分け・エスカレーション — `grep -qF 'GATE-FP' sage/failures.md && grep -qE '3\s*回' sage/failures.md && grep -qF 'gate 設定の見直し' sage/failures.md` が exit 0 (case: `escalation_rule_present`)
- [ ] AC-03: 採番 (初回) — GATE-FP エントリを含まない fixture failures.md を配した一時リポジトリで `bash scripts/sage-id-gen.sh gate-fp` の出力が `GATE-FP-0001` (case: `idgen_first`)
- [ ] AC-04: 採番 (継続) — `GATE-FP-0001` / `GATE-FP-0003` を含む fixture failures.md で出力が `GATE-FP-0004` (最大値 + 1、欠番は詰めない) (case: `idgen_next`)
- [ ] AC-05: 既存種別不変 — `bash scripts/sage-id-gen.sh spec|plan|task|run|fail` の各出力が変更前と同一形式・同一番号ロジックであり、`bash scripts/sage-id-gen.sh` (引数なし) と未知種別が従来どおり exit 1 で usage を出す (case: `existing_types_unchanged`)
- [ ] AC-06: 異常系 (failures.md 不在) — `sage/failures.md` が存在しない一時ディレクトリで `bash scripts/sage-id-gen.sh gate-fp` が `GATE-FP-0001` を出力し exit 0 (fail 種別の既存挙動と同型 — ファイル不在は LAST_NUM=0 として扱う) (case: `idgen_missing_file`)
- [ ] AC-07: 異常系 (未知種別の拒否維持) — `bash scripts/sage-id-gen.sh gatefp` (typo) が exit 非 0 で、usage に `gate-fp` を含む有効種別一覧を stderr/stdout に出力する (case: `unknown_type_rejected`)
- [ ] AC-08: human 承認明記 — PR 本文に「sage/ 変更の human 承認が merge 前提」の記載があることをレビューで確認する (機械検証: `gh pr view --json body | grep -F 'human 承認'` が exit 0)
- [ ] AC-09: installer 再生成整合 — install.sh 再生成後、`bash install.sh --verify-checksum` (または release.yml の drift check 相当: 再生成 → `git diff --exit-code install.sh SHA256SUMS`) が PASS し、埋め込み TMPL_FAILURES に `GATE-FP-XXXX`、TMPL_ID_GEN に `gate-fp` が含まれる (`grep -qF 'GATE-FP-XXXX' install.sh && grep -qF 'gate-fp' install.sh`) (case: `installer_regenerated`)
- [ ] AC-10: ローダー非変更 — `git diff --name-only main | grep -E '^(scripts/sage-id-pattern\.sh|templates/pre-commit-task-id\.sh)$'` が exit 非 0 (SPEC-0027 INV-03 波及なし) (case: `loader_untouched`)
- [ ] AC-11: 既存エントリ不変 — `git diff main -- sage/failures.md` の差分に FAIL-0001 / FAIL-0002 エントリ行の変更 (追加以外の `-` 行) が含まれない (case: `existing_entries_unchanged`)
- [ ] AC-12: 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する (case: `all_tests_pass`)

### 検証方針

- `templates/hooks/tests/test-gate-fp-idgen.sh` は integration テストとして、一時ディレクトリに `scripts/sage-id-gen.sh` + `scripts/sage-id-pattern.sh` + fixture `sage/failures.md` (GATE-FP 0 件版 / 複数件版) を配置し、AC-03〜07 を検証する (test-id-patterns.sh の流儀を踏襲)。fixture は `templates/hooks/tests/fixtures/` 配下に置く。テスト実装は Test Agent 責務 (Implementation Agent と分離、AP-04 回避)
- AC-01 / AC-02 / AC-11 は grep / git diff によるドキュメント検証。AC-09 は再生成 + drift check。AC-08 はレビュー時の PR 本文確認 (+ gh コマンド検証)
- テスト種別: bash integration テストのみ。カバレッジ閾値は N/A — bash スクリプトであり Gate 2 の LOC ベース coverage 計測の適用対象外。代替として異常系 (想定エラー1〜2・境界ケース1〜3) をテストケース化して網羅性を担保する

## 異常系

- 想定エラー1: `sage/failures.md` 不在で `gate-fp` 採番 — エラーにせず `GATE-FP-0001` を返す (`fail` 種別の既存挙動と同型: ファイル不在 = 記録 0 件、AC-06)
- 想定エラー2: 未知種別 (typo 含む) — 従来どおり exit 1 + 有効種別一覧の usage 出力。gate-fp 追加後も spec/plan/task/run/fail の拒否メッセージ形式は不変 (AC-07)
- 境界ケース1: GATE-FP 番号に欠番がある (0001, 0003 のみ存在) — 最大値 + 1 (`GATE-FP-0004`) を返し、欠番を再利用しない (既存種別と同一方針、AC-04)
- 境界ケース2: failures.md 内の本文中に `GATE-FP-9999` のような参照文字列が含まれる — エントリ見出しと本文参照を区別しない (既存 `fail` 種別も grep ベースで同様)。9999 到達時は次が 10000 となり 4 桁を超えるが、既存種別と同じ制約として許容 (仕様として明記、対策は scope-out)
- 境界ケース3: 既存 FAIL-XXXX と GATE-FP-XXXX の番号空間は**独立** — `fail` 採番は `FAIL-[0-9]{4}` のみ、`gate-fp` 採番は `GATE-FP-[0-9]{4}` のみをスキャンし、相互に影響しない。特に `GATE-FP-0002` が存在しても `fail` の次番号は変わらない (AC-05 で機械検証)。注: `fail` の既存 ERE `FAIL-[0-9]{4}` は `GATE-FP-` にマッチしないことを確認済み (プレフィックス不一致)

## 契約

- API: なし
- DB: なし
- イベント: なし
- CLI 契約: `bash scripts/sage-id-gen.sh gate-fp` — stdout に `GATE-FP-XXXX` (次番号) を 1 行出力、exit 0。既存契約 `spec | plan | task | run | fail` は不変。usage 文言に `gate-fp` が加わる (usage 文字列の変更は許容される契約変更として明記)
- ドキュメント契約: `sage/failures.md` の GATE-FP エントリは必須 7 フィールドを持つ。GATE-FP はコミットメッセージ・PR 本文の必須 ID ではない (トレーサビリティチェーンの対象外、記録専用)

## リスク

- リスク1: usage 文言変更が導入先の出力パースを壊す → 軽減策: usage はエラー時のみの表示でありパース対象として想定されない。正常系の stdout (ID 1 行) は完全不変。契約節に明記
- リスク2: 導入先の既存 failures.md には GATE-FP 節がない (update KEEP のため) が、gate-fp 採番は動作する → 挙動: エントリ 0 件として `GATE-FP-0001` を返す (AC-06 と同型で正常)。テンプレート節の手動追記手順を failures.md 更新内容自体が例示する (新規インストールで配布される内容をコピーすればよい)。docs への別掲は不要と判断
- リスク3: install.sh 再生成コミットが実装コミットに混入する (FAIL-0002 再演) → 軽減策: 再生成を専用 TASK (T4) の別コミットに分離し、Slice で File Scope を install.sh / SHA256SUMS のみに限定する
- リスク4: 「gate 設定の見直し必須化」が文書ルールに留まり強制されない (AP-06) → 軽減策: 本 SPEC は記録テンプレートの提供までを責務とし、再発回数フィールドで見直し時期を可視化する。CI による自動検出は scope-out に明示済み (残存リスクとして認識)
- リスク5: sage/ は human-only のため agent 実装がブロックされる → 対応: 「human 承認要件」節のとおり PR レビュー・マージを承認行為とし、PR 本文に明記する (AC-08)。protect-sage-files hook のブロックに遭遇した場合は human の明示承認を得てから進める

### 知識管理 (failures.md 連携フロー)

- 実装中・リリース後に gate-fp 採番の誤動作 (重複 ID / 誤番号 / 既存種別への影響) を検出した場合、Implementation Agent は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する。同種の失敗が 3 回発生した場合は `sage/anti-patterns.md` へ昇格する (CLAUDE.md §5 準拠、盲目的リトライ禁止)
- エラー報告時は §5 の 6 要素 (エラーログ / 失敗ファイル+行 / SPEC-0031 の該当 AC / git diff / 修正スコープ / 完了条件) を必ず含める

### ロールバック手順

- `sage/failures.md` の GATE-FP 節・記録ルール追記、`scripts/sage-id-gen.sh` の gate-fp 分岐、テストファイルを revert コミットで削除し、install.sh を再生成 + SHA256SUMS 更新すれば完全に旧状態へ戻る (再生成 revert も FAIL-0002 教訓により専用コミット)
- 既に記録された GATE-FP エントリがある場合はエントリ自体を残す (履歴保全 — failures.md の「昇格後もログは削除しない」方針と同型)。テンプレート節のみ削除する
- 導入先への影響: update モードで failures.md は KEEP のため、テンプレート revert は導入先の記録に波及しない。sage-id-gen.sh は次回 update で旧版に戻る

## 実装メモ（Implementation Agent向け）

- **File Scope (変更可能なファイル)**:
  - `sage/failures.md` (GATE-FP 節 + 記録ルール追記のみ — **human-only 領域: PR レビュー・マージが承認行為**。既存エントリ・既存節は不変)
  - `scripts/sage-id-gen.sh` (gate-fp 分岐 + usage 追記のみ)
  - `install.sh` / `SHA256SUMS` (再生成のみ — **専用 TASK T4 の別コミット**)
  - `templates/hooks/tests/test-gate-fp-idgen.sh` (新規 — **Test Agent 責務**)
  - `templates/hooks/tests/fixtures/` 配下の fixture failures.md (新規 — Test Agent 責務)
  - `templates/hooks/tests/run-tests.sh` (登録行のみ、自動 discovery なら不要 — Test Agent 責務)

  上記以外の変更は禁止 (AP-03)。特に `scripts/sage-id-pattern.sh` / `templates/pre-commit-task-id.sh` (SPEC-0027 INV-03) / `sage/anti-patterns.md` / `.sage/id-patterns.json` / `AGENTS.md` / `docs/codex-*.md` / `CLAUDE.md` は不可。`scripts/generator/` は原則不変 — TMPL_FAILURES / TMPL_ID_GEN は `embed_file` によりソースファイルを実行時読み込みするため、generator ソースの変更は不要のはず。万一 generator 変更が必要と判明した場合は Spec Agent へ差し戻す (silent scope expansion 禁止)
- gate-fp 分岐の実装: 既存 `case "$TYPE"` に `gate-fp)` を追加。`DIR="sage"` / `PREFIX="GATE-FP"` とし、`DEFAULT_RE` はローダーを呼ばず `DEFAULT_RE='GATE-FP-[0-9]{4}'` を直接代入 (設計判断2 のコメントを添える)。スキャンは `fail` 種別と同じ failures.md grep 方式。番号抽出の `grep -oE '[0-9]{4}'` は `GATE-FP-0001` から `0001` を正しく抽出することを確認 (ハイフン 2 個の prefix でも `sort -t'-' -k2 -n` のキー位置に注意 — GATE-FP は `-` 区切りで 3 フィールドになるため、`sort -t'-' -k3 -n` 相当が必要。実装時に既存 `fail` と共通化せず gate-fp 専用のソートキーを使うこと)
- failures.md への追記位置: 「エントリフォーマット」節 (FAIL-XXXX) の直後に「Gate False Positive エントリフォーマット (GATE-FP-XXXX)」節を追加、「記録ルール」節に使い分け + エスカレーション 2 項目を追記。言語は日本語 (Language Rules)
- コミット規約: 全コミットに TASK-ID (AP-05)。PR 本文に SPEC-0031 / PLAN-ID / TASK-ID + 「sage/ 変更の human 承認が merge 前提」+ CLAUDE.md 追記案 (follow-up)
- 禁止事項: jq / eval の使用、ローダー・pre-commit への波及 (AC-10)、既存エントリの変更 (AC-11)、再生成の実装コミット混入 (リスク3)、テスト未実行での受け入れ (AP-09)
- Slice 向け分割ヒント:

| TASK | 内容 | 対応 AC | コマンド検証可能な完了条件 | 依存 / 並列可否 |
|------|------|---------|--------------------------|----------------|
| T1 | `sage/failures.md` に GATE-FP テンプレート + 使い分け + エスカレーションルール追記 (human 承認前提) | AC-01, 02, 11 | AC-01/02 の grep exit 0 + AC-11 の diff 検証 | 依存なし |
| T2 | `scripts/sage-id-gen.sh` に gate-fp 分岐 + usage 追記 | AC-03〜07 (実装) | 手動で fixture を置き各 AC の出力確認 | 依存なし (T1 と並列可) |
| T3 | test-gate-fp-idgen.sh + fixtures + run-tests.sh 登録 (**Test Agent 責務・別セッション**) | AC-03〜07, 12 | `bash templates/hooks/tests/test-gate-fp-idgen.sh` 全ケース PASS + run-tests.sh 全件 PASS | T2 後 |
| T4 | install.sh 再生成 + SHA256SUMS 更新 (**専用 TASK・別コミット** — FAIL-0002 教訓) | AC-09 | 再生成後 `git diff --exit-code install.sh SHA256SUMS` (drift なし) + AC-09 の grep exit 0 | T1, T2 後 |

  実行順: T1 / T2 並列 → T3 / T4。AC-08 (human 承認明記) / AC-10 (ローダー非変更) は PR レビューで全 TASK 横断確認。

## Properties

権限レベル platform + Security 要件あり → 5 件以上。

### Invariants

- [INV-01] (Gate 2) `sage-id-gen.sh` の既存 5 種別 (spec/plan/task/run/fail) の出力は、gate-fp 追加の前後で任意の入力状態に対して同一である (後方互換の機械的表現)
- [INV-02] (Gate 2) `fail` と `gate-fp` の番号空間は独立であり、一方のエントリ追加が他方の次番号に影響しない
- [INV-03] (Gate 3) gate-fp の採番 ERE はスクリプト内定数のみで、外部設定・ユーザー入力がパターンとして評価されることはない (SEC-01)
- [INV-04] (Gate 4) 本 SPEC の変更は `scripts/sage-id-pattern.sh` / `templates/pre-commit-task-id.sh` に差分を発生させない (SPEC-0027 INV-03 非波及、AC-10)
- [INV-05] (Gate 4) 既存 FAIL エントリ (FAIL-0001 / FAIL-0002) の行はバイト単位で不変である (AC-11)
- [INV-06] (Gate 3/5) マージ時点で install.sh と SHA256SUMS は再生成済みかつ整合しており、checksum 検証が PASS する (SPEC-0018 非破壊、SEC-02)

### Pre-conditions

- [PRE-01] (Gate 2) gate-fp の採番は `sage/failures.md` の GATE-FP-XXXX スキャン結果 (不在時は 0) に基づいてのみ行われる
- [PRE-02] (Gate 5) sage/failures.md の変更を含む PR は、PR 本文に human 承認前提の明記 (AC-08) がある場合のみマージ可能である

### Post-conditions

- [POST-01] (Gate 2) `gate-fp` 採番の出力は常に `GATE-FP-[0-9]{4,}` 形式の 1 行 + exit 0 であり、既存最大番号より大きい
- [POST-02] (Gate 4) 再生成後の install.sh 埋め込みテンプレートは、リポジトリの `sage/failures.md` / `scripts/sage-id-gen.sh` の内容と一致する (drift check PASS)

### Assumptions

- [ASM-01] (Gate 横断) 導入先は bash 3.2+ / POSIX ツールが利用可能 (既存 scripts と同一前提)
- [ASM-02] (Gate 横断) GATE-FP エントリの記録・再発回数の更新は human / agent の手動運用であり、正確性は運用責任 (自動検出は scope-out)
- [ASM-03] (Gate 横断) 既存導入先の failures.md は update KEEP のため GATE-FP 節を持たないが、gate-fp 採番はエントリ 0 件として正常動作する (リスク2)

## 関連ID

- PLAN-ID: [PLAN-0031](../plans/PLAN-0031-gate-fp-template.md)
- TASK-ID:
  - T1: [TASK-0208](../tasks/TASK-0208-failures-gate-fp-template.md) — sage/failures.md GATE-FP テンプレート追記
  - T2: [TASK-0209](../tasks/TASK-0209-idgen-gate-fp-type.md) — sage-id-gen.sh gate-fp 種別追加
  - T3: [TASK-0210](../tasks/TASK-0210-test-gate-fp-idgen.md) — テスト + fixtures（Test Agent）
  - T4: [TASK-0211](../tasks/TASK-0211-regen-install-sha256sums.md) — install.sh 再生成 + SHA256SUMS 更新
  - T5: [TASK-0212](../tasks/TASK-0212-gate-fp-remediation.md) — gate FP (test-ts-enforcement.sh) 恒久対応 + GATE-FP-0001 記録（遡及 TASK）
- Done Definition: [tasks/done-def-SPEC-0031-round-1.md](../tasks/done-def-SPEC-0031-round-1.md)
