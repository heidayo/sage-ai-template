# SPEC-0030: TypeScript Enforcement プリセット — tsc エラー数ラチェットと型抑制の lint 強制

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0030 |
| ステータス | Draft |
| 作成日    | 2026-07-03 |
| 更新日    | 2026-07-03 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0028 (stack presets / ts-pnpm プリセット — 相互参照先), SPEC-0027 (jq 非依存・POSIX ツールのみ方針の先行例), SPEC-0026 (installer preservation 方針 — 配布判断の参照), SPEC-0018 (supply chain hardening / SHA256SUMS — installer 非変更の根拠), SPEC-0002 (CI Gate enforcement) |
| 権限レベル | platform |

## 背景・目的

実プロジェクト (TypeScript/pnpm monorepo) への SAGE 導入で、「`as any` 禁止」を CLAUDE.md / rules の文書ルールにしても、ESLint 設定が warn 止まりのため CI が hard fail せず、運用 (レビュー時の目視) に依存していた。さらに `@ts-ignore` / `@ts-nocheck` の error 化、tsc エラー数のベースライン管理 (増加を CI で止めるラチェット)、tsconfig 変更時の検証証跡といった型安全の enforcement 一式を、導入先が毎回フォーク側で自作する必要があった。これは AP-06 (Human-Only Guard: ルールが文章だけで止まらない) の TypeScript 領域での再演である。

本 SPEC は (1) 汎用 tsc エラー数ラチェットスクリプト `scripts/sage-tsc-ratchet.sh`、(2) 型抑制コメント・`any` を error 化する ESLint 設定断片 `templates/ts-enforcement/`、(3) 運用規約 docs (`docs/ts-enforcement.md`) を提供する。全て **opt-in** であり、非 TypeScript プロジェクト・既存導入先への影響はゼロとする。SPEC-0028 の ts-pnpm プリセット (`templates/project-checks/ts-pnpm.yaml` — `type_check: "pnpm exec tsc --noEmit"`) と docs 相互参照で接続し、「型チェックコマンドの設定 (SPEC-0028)」から「型品質の段階的強制 (本 SPEC)」への導線を作る。

### installer 配布判断 (設計判断の明記)

`scripts/sage-tsc-ratchet.sh` および `templates/ts-enforcement/` は **installer (install.sh) の配布対象に含めない**。理由:

1. opt-in の TS 専用機構であり、非 TS 導入先にファイルを配布する意味がない (SPEC-0028 のプリセットと異なり、自動検出で適用すべき「設定値」ではなく「追加ツール」である)
2. 配布対象化は `--stack ts-pnpm` 指定時の条件付き配布などの installer 分岐設計を要し、単一責務を超える — 将来 SPEC 候補として scope-out に明示する
3. 含めないため `install.sh` の再生成・SHA256SUMS 更新は**不要** (FAIL-0002 の再生成専用 TASK も不要)。generator (`scripts/generator/`) には一切触れない

導入先へは docs 記載の手順 (リポジトリからのファイルコピー) で導入する。

## 対象ユーザー

- SAGE を TypeScript プロジェクト (pnpm monorepo 含む) に導入し、型抑制の禁止と tsc エラー削減を CI で強制したいチーム
- 既存 tsc エラーを抱えたレガシー TS プロジェクトで、「増やさない」から始めて段階的にゼロへ向かいたいチーム
- 非 TS プロジェクト・既存導入先 — **挙動変化ゼロ** (本 SPEC の成果物は使わなければ何も起きない)

## スコープ（含む）

- `scripts/sage-tsc-ratchet.sh` の新設 (汎用 tsc エラー数ラチェット):
  - **検査モード (デフォルト)**: tsc コマンドを実行し、出力から `error TS<番号>` 行数をエラー数としてカウント。`.tsc-baseline.json` の baseline と比較し、
    - 増加 → 現在数・baseline・増分を stderr に出力して exit 1
    - 同数 → exit 0
    - 減少 → exit 0 + 「`--update` で baseline 更新を推奨」の INFO を出力
  - `--update`: 現在のエラー数で `.tsc-baseline.json` を更新する**唯一の正規更新経路** (手動編集禁止、docs に明記)
  - `--init`: baseline ファイルを現在のエラー数で新規作成 (既存 baseline があれば exit 1 — `--update` を案内)
  - tsc コマンドの注入: 第一に環境変数 `SAGE_TSC_COMMAND`、なければ引数 `--tsc-command "<cmd>"`、いずれもなければデフォルト `npx tsc --noEmit`。monorepo では `SAGE_TSC_COMMAND="pnpm --filter app exec tsc --noEmit"` 等で対応
  - baseline ファイル (`.tsc-baseline.json`) の整合検証: 期待フォーマット (単一の非負整数 `errors` フィールドを持つ JSON) から逸脱 (負数・非数値・欠損・パース不能) していれば理由を stderr に出力して exit 1 (手動編集・破損の検出)
  - **jq / eval 非依存**: JSON の読み書きは grep/sed 等 POSIX ツールのみで行う (SPEC-0027 と同方針)。書き込む JSON は固定スキーマ `{"errors": <N>, "updated_at": "<ISO8601>"}` の静的テンプレートに数値を埋めるのみ
- `templates/ts-enforcement/` の新設 (ESLint 設定断片、適用手順コメント付き):
  - `eslint-flat.mjs` — flat config 用: `@typescript-eslint/ban-ts-comment` を error (`ts-ignore` / `ts-nocheck` 禁止、`ts-expect-error` は description 必須で許容)、`@typescript-eslint/no-explicit-any` を error
  - `eslint-flat-transitional.mjs` — 同上だが `no-explicit-any` のみ warn (レガシー移行用バリアント)
  - `eslintrc-fragment.json` — legacy `.eslintrc` 用: 上記 error バリアントと同一ルールの JSON 断片 (transitional は rules 値の差し替え手順をコメント/README 記載で案内)
  - 各ファイル冒頭に適用手順 (既存 config への組込み方法) をコメントで記載
- `.tsc-baseline.json` 手動編集禁止ルールの二重化: docs 明記 (Human-Only Guard 回避のための機械検証は上記の整合検証が担う — 検証不能な「手動編集そのもの」の検出は scope-out に明示)
- tsconfig 変更時の検証証跡規約: `docs/ts-enforcement.md` に「tsconfig(*.json) を変更する PR には ratchet 実行ログ + build/typecheck 結果を添付する」運用規約として記載。**CI 強制はスコープ外** (導入先の CI 構成依存) と docs 内でも明示
- SPEC-0028 ts-pnpm プリセットとの接続: `docs/stack-presets.md` に `docs/ts-enforcement.md` への参照 1 行を追記する (docs 相互参照のみ)。`templates/project-checks/ts-pnpm.yaml` への参照コメント追記は**行わない** — 同ファイルは `scripts/generator/02-config.sh` で install.sh に埋め込まれ、release.yml の drift check により追記が install.sh 再生成 + SHA256SUMS 更新を強制するため、installer 非変更 (AC-09 / INV-05) と矛盾する (リスク5 で判断済み)
- テスト `templates/hooks/tests/test-ts-enforcement.sh` の追加 (`_helpers.sh` / `run-tests.sh` の既存流儀。テスト実装は Test Agent 責務)。**Node / tsc 実物に依存せず**、固定エラー出力を返す mock tsc スクリプト (`templates/hooks/tests/fixtures/` 配下) を `SAGE_TSC_COMMAND` で注入して検証:
  - (1) `--init` で baseline が作成され、エラー数が mock 出力と一致する
  - (2) 検査モード: 同数 → exit 0
  - (3) 検査モード: 減少 → exit 0 + update 推奨 INFO
  - (4) 検査モード: 増加 → exit 1 + 現在数/baseline/増分の出力
  - (5) `--update` で baseline が現在数に更新される
  - (6) 異常系: 不正 baseline (非数値 / 負数 / パース不能) → exit 1 + 理由出力、baseline 非変更
  - (7) 異常系: baseline 不在で検査モード → exit 1 + `--init` 案内
  - (8) tsc 注入: `--tsc-command` 引数経由でも同様に動作する (環境変数と引数の優先順位確認を含む)
  - (9) ESLint 断片の形式検証: 3 ファイルが存在し、`ban-ts-comment` / `no-explicit-any` の期待 severity を含む
- docs (日本語): `docs/ts-enforcement.md` 新設 — 導入手順 (ファイルコピー)、ESLint 断片の適用 (flat / legacy 両方)、ラチェット運用 (検査/--update/--init、CI への組込み例、手動編集禁止)、tsconfig 変更規約、SPEC-0028 ts-pnpm プリセットとの関係。README からの参照追記

## スコープ外（明示的に除外）

- 実 TypeScript プロジェクトでの ESLint / tsc 実行検証 — 導入先ツールチェーン依存 (テストは mock tsc で完結)
- installer (`install.sh`) への自動組込み — `--stack ts-pnpm` 指定時のファイル自動配布は将来 SPEC 候補。本 SPEC は `scripts/` + `templates/` の提供と docs 手順のみ (上記「installer 配布判断」参照)。したがって `scripts/generator/` / `install.sh` / `SHA256SUMS` は**一切変更しない**
- CI workflow テンプレート (`.github/workflows/` への ratchet 組込み例の配布) — docs にコマンド例を記載するに留める
- 既存 `.claude/rules/` の変更 (src-rules.md への TS ルール追記等) — rules 層は不変
- `.tsc-baseline.json` の「手動編集そのもの」の検出 (git blame / commit hook による編集者検証) — 整合検証 (フォーマット・非負整数) で破損は検出するが、正しいフォーマットでの手動改竄は運用規約 + レビューで担保
- tsc エラーの種別別 (TS コード別) baseline — エラー総数のみを管理。粒度細分化は需要確認後の別 SPEC
- Biome / oxlint 等 ESLint 以外の linter 向け断片 — 需要が確認されたら別 SPEC
- 本リポジトリ自身への ratchet 適用 — 本リポジトリは bash プロジェクトであり対象外
- `AGENTS.md` / `docs/codex-*.md` の編集 (Codex-specific boundary)
- `sage/` 配下 governance 文書の改訂 (Human-only)
- CLAUDE.md への機能追記 (Human-only) — マージ後に Human が「TS enforcement (SPEC-0030) — sage-tsc-ratchet.sh + templates/ts-enforcement/、詳細: docs/ts-enforcement.md」を追記する follow-up として分離。PR 本文に追記案を記載する

## 要件

### 機能要件

- [FR-01] `scripts/sage-tsc-ratchet.sh` は検査モードで tsc コマンドを実行し、出力中の `error TS[0-9]+` パターン行数をエラー数として `.tsc-baseline.json` と比較する。増加なら現在数・baseline・増分を出力して exit 1、同数以下なら exit 0、減少時は baseline 更新推奨 INFO を出力する
- [FR-02] `--update` は現在のエラー数で `.tsc-baseline.json` を上書きする。`--init` は baseline 不在時のみ新規作成し、既存時は exit 1 で `--update` を案内する
- [FR-03] tsc コマンドは環境変数 `SAGE_TSC_COMMAND` > 引数 `--tsc-command` > デフォルト `npx tsc --noEmit` の優先順位で決定される
- [FR-04] baseline の整合検証: `.tsc-baseline.json` が期待フォーマット (非負整数の `errors`) でない場合、理由を stderr に出力して exit 1 とし、baseline を変更しない
- [FR-05] baseline 不在で検査モードを実行した場合、exit 1 とし `--init` の案内を stderr に出力する
- [FR-06] `templates/ts-enforcement/` に `eslint-flat.mjs` / `eslint-flat-transitional.mjs` / `eslintrc-fragment.json` の 3 ファイルが存在し、`ban-ts-comment`=error は全バリアント共通、`no-explicit-any` は error (標準) / warn (transitional) の 2 バリアントを提供する。各ファイルに適用手順コメントを含む
- [FR-07] `docs/ts-enforcement.md` が存在し、導入手順・ESLint 断片適用・ラチェット運用 (手動編集禁止を含む)・tsconfig 変更規約 (CI 強制はスコープ外の明示を含む)・SPEC-0028 ts-pnpm プリセット参照・段階的昇格 (graduation) の 6 節を含む。graduation 節には (a) transitional→error の切替条件: lint 実行で `no-explicit-any` の warn 検出が 0 件であることを確認した後に error 版 (`eslint-flat.mjs` / 標準 fragment) へ切り替える、(b) ratchet baseline 0 到達後の zero-tolerance 運用: baseline を 0 で固定し、以後は増加 (エラー 1 件以上) を即 FAIL とする、を記載する
- [FR-08] `docs/stack-presets.md` から本 SPEC の成果物への参照が存在する (`templates/project-checks/ts-pnpm.yaml` は generator 埋め込み対象のため変更しない — プリセットの 5 キーのコマンド値含め不変)

### 非機能要件

- [NFR-01] 後方互換: 本 SPEC の成果物は全て新規ファイル追加 + 既存ファイルへのコメント/参照 1 行追記のみであり、既存スクリプト・installer・hooks の入出力は変更前と完全同一
- [NFR-02] 可搬性: `sage-tsc-ratchet.sh` は bash 3.2+ / POSIX ツール (grep/sed/wc 等) のみで動作し、jq / node / python に依存しない
- [NFR-03] テスト独立性: テストは mock tsc により Node.js / TypeScript 実物なしで CI 実行可能

### セキュリティ要件

- [SEC-01] tsc コマンド文字列は `eval` せず、シェル関数経由の直接実行 (`sh -c` 等の単一経路) に限定する。docs に「`SAGE_TSC_COMMAND` は信頼できる値のみ設定する (CI secrets や外部入力を渡さない)」を明記する — コマンド注入面はユーザー自身の設定値に閉じる
- [SEC-02] `.tsc-baseline.json` への書き込みは静的スキーマへの数値埋め込みのみで、tsc 出力の内容 (ファイルパス・メッセージ) を baseline に転記しない (出力からのコンテンツ注入を遮断)
- [SEC-03] baseline 読み取り値は非負整数として検証してから数値比較に使用し、検証前の値をコマンド・パスとして評価しない
- [SEC-04] installer / SHA256SUMS / provenance の検証フローに一切介入しない (ファイル無変更、SPEC-0018 非破壊)

### 運用要件

- [OPS-01] `docs/ts-enforcement.md` に導入手順・運用規約を記載し、README から参照する
- [OPS-02] `bash templates/hooks/tests/run-tests.sh` が既存テスト含め全件 PASS する
- [OPS-03] 定量合格基準: リリース後2週間、`sage/failures.md` にラチェット誤判定 (エラー数の誤カウント / 不正 exit code) 起因の失敗記録が0件、かつ少なくとも1つの TS 導入先で ratchet の CI 組込み (検査モードが CI で実行され増加検出が機能) を確認できた場合に安定 (Observe 完了) とみなす。誤判定報告1件で issue 起票、同種3件で `sage/anti-patterns.md` へ昇格検討

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: ラチェット基本動作 — mock tsc (固定 3 エラー出力) を `SAGE_TSC_COMMAND` で注入し、`bash scripts/sage-tsc-ratchet.sh --init` 後の `.tsc-baseline.json` に `"errors": 3` が含まれ (`grep -F '"errors": 3'` が exit 0)、続く検査モードが exit 0 (case: `init_and_check_equal`)
- [ ] AC-02: 増加検出 — baseline 3 の状態で mock tsc を 5 エラー版に差し替えて検査モード実行 → exit 1、出力に現在数 5・baseline 3・増分 2 が含まれる (case: `increase_detected`)
- [ ] AC-03: 減少 + 正規更新経路 — baseline 3 の状態で 1 エラー版 mock で検査モード → exit 0 + update 推奨 INFO。`--update` 実行後 `grep -F '"errors": 1' .tsc-baseline.json` が exit 0 (case: `decrease_and_update`)
- [ ] AC-04: 異常系 (不正 baseline) — `.tsc-baseline.json` に `{"errors": -1}` / `{"errors": "abc"}` / `not-json` の各不正値を置いて検査モード実行 → いずれも exit 1、stderr に理由、baseline ファイルがバイト不変 (case: `invalid_baseline_rejected`)
- [ ] AC-05: 異常系 (baseline 不在) — baseline なしで検査モード実行 → exit 1、stderr に `--init` 案内 (`grep -F -- '--init'` が exit 0) (case: `missing_baseline_guided`)
- [ ] AC-06: tsc 注入の優先順位 — `--tsc-command` 引数のみで mock を注入して動作すること、および `SAGE_TSC_COMMAND` と `--tsc-command` 併存時に環境変数側が優先されること (case: `tsc_injection_priority`)
- [ ] AC-07: ESLint 断片形式 — `for f in eslint-flat.mjs eslint-flat-transitional.mjs eslintrc-fragment.json; do test -f "templates/ts-enforcement/$f" || exit 1; done` が exit 0、かつ `grep -F 'ban-ts-comment' templates/ts-enforcement/eslint-flat.mjs` / `grep -F 'no-explicit-any' templates/ts-enforcement/eslint-flat-transitional.mjs` が exit 0 で transitional 版の `no-explicit-any` が warn 指定 (case: `eslint_fragments_present`)
- [ ] AC-08: jq/eval 非依存 — `grep -E '\bjq\b|\beval\b' scripts/sage-tsc-ratchet.sh` が exit 非0 (case: `no_jq_no_eval`)
- [ ] AC-09: installer 非変更 — 本 SPEC の PR diff に `install.sh` / `SHA256SUMS` / `scripts/generator/` が含まれない (`git diff --name-only main | grep -E '^(install\.sh|SHA256SUMS|scripts/generator/)'` が exit 非0)
- [ ] AC-10: 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する
- [ ] AC-11: ドキュメント — `grep -qF 'sage-tsc-ratchet' docs/ts-enforcement.md && grep -qF 'ts-enforcement' docs/stack-presets.md && grep -qF 'ts-enforcement' README.md` が exit 0、かつ `grep -qF 'tsconfig' docs/ts-enforcement.md` が exit 0、かつ `grep -qE '昇格|graduation' docs/ts-enforcement.md` が exit 0 (case: `docs_reference`)
- [ ] AC-12: ts-pnpm プリセット不変 — `templates/project-checks/ts-pnpm.yaml` の `lint`/`format`/`type_check`/`test_command`/`coverage_command` 5 キーの値が main と同一 (`git diff main -- templates/project-checks/ts-pnpm.yaml` の差分がコメント行のみ) (case: `preset_values_unchanged`)

### 検証方針

- `templates/hooks/tests/test-ts-enforcement.sh` は integration テストとして、一時ディレクトリに mock tsc (固定の `error TS2345: ...` 行を N 件出力する fixture スクリプト、`templates/hooks/tests/fixtures/mock-tsc-*.sh`) を配置し、`SAGE_TSC_COMMAND` / `--tsc-command` で注入して AC-01〜08 を検証する (test-stack-presets.sh / test-installer-preservation.sh の流儀を踏襲)。テスト実装は Test Agent 責務 (Implementation Agent と分離、AP-04 回避)
- Node.js / tsc 実物には依存しない — mock は `printf` でエラー行を出力する bash スクリプトのみ
- テスト種別: bash integration テストのみ。カバレッジ閾値は N/A — bash スクリプトであり Gate 2 の LOC ベース coverage 計測の適用対象外。代替として異常系 (想定エラー1〜3・境界ケース1〜3) を全てテストケース化し網羅性を担保する

## 異常系

- 想定エラー1: 不正 baseline (負数 / 非数値 / パース不能 / `errors` 欠損) — 理由を stderr に出力して exit 1、baseline 非変更 (FR-04, AC-04)
- 想定エラー2: baseline 不在で検査モード — exit 1 + `--init` 案内 (FR-05, AC-05)
- 想定エラー3: `--init` を既存 baseline がある状態で実行 — exit 1 + `--update` 案内、baseline 非変更 (FR-02)
- 境界ケース1: tsc エラー 0 件 (クリーンなプロジェクト) — baseline 0 で正常動作し、検査モードは exit 0。0 件からの増加も検出される
- 境界ケース2: tsc コマンド自体の実行失敗とエラー検出の区別 — tsc は型エラー時も非0 exit するため exit code では区別せず、出力の `error TS` パターンで数える。出力にパターンが 1 件もなく tsc が非0 終了した場合 (コマンド不在等) は「tsc 実行失敗」として exit 1 + 出力全文を stderr へ透過 (エラー 0 件と誤認しない)
- 境界ケース3: エラー数同数だが内容が入れ替わったケース — 総数管理のため exit 0 (仕様として docs に明記。種別別管理は scope-out)

## 契約

- API: なし
- DB: なし
- イベント: なし
- CLI 契約: `scripts/sage-tsc-ratchet.sh [--update|--init] [--tsc-command "<cmd>"]`。exit 0 = baseline 以下 / 更新成功、exit 1 = 増加検出・不正 baseline・baseline 不在・tsc 実行失敗・引数エラー。環境変数 `SAGE_TSC_COMMAND` が引数より優先
- ファイル契約: `.tsc-baseline.json` — 固定スキーマ `{"errors": <非負整数>, "updated_at": "<ISO8601>"}`。更新は `--update` / `--init` のみが正規経路 (手動編集禁止)。`templates/ts-enforcement/*` — 導入先が自身の ESLint config に組み込む断片 (installer 非配布・コピー導入)

## リスク

- リスク1: tsc 出力フォーマットの将来変更 (`error TS` パターンの変化) で誤カウントする → 軽減策: パターンを docs に明記し、mock tsc テストでパターン依存を固定。誤カウント報告は OPS-03 の failures.md フローで捕捉
- リスク2: 正しいフォーマットでの baseline 手動改竄 (数値だけ増やす) は機械検出できない → 軽減策: docs で手動編集禁止 + PR レビューで `.tsc-baseline.json` 変更コミットに ratchet ログ添付を要求する運用規約を記載。完全な機械強制は scope-out と明示 (AP-06 の残存リスクとして認識)
- リスク3: `SAGE_TSC_COMMAND` 経由の任意コマンド実行がリスクと誤解される → 軽減策: 本スクリプトは「ユーザーが自分の tsc を指定して自分の環境で実行する」ツールであり信頼境界を跨がない。SEC-01 で外部入力を渡さない旨を docs 明記
- リスク4: ESLint 断片が導入先の @typescript-eslint バージョンと不整合 (ルール名変更等) → 軽減策: 実行検証は scope-out と明示し、断片コメントに前提バージョン (@typescript-eslint v6+) を記載。不整合は導入先の lint 実行で自然に顕在化する
- リスク5: SPEC-0028 プリセットへのコメント追記が generator 埋め込みと乖離する → **判断済み: 追記しない**。`templates/project-checks/ts-pnpm.yaml` は `scripts/generator/02-config.sh` (52行目付近) で install.sh に埋め込まれる対象であり、release.yml の drift check により 1 行のコメント追記でも install.sh 再生成 + SHA256SUMS 更新が強制される。これは AC-09 / INV-05 (installer 非変更) と矛盾するため、参照は `docs/stack-presets.md` 側のみに置く (AC-09/AC-12 で機械検証)

### 知識管理 (failures.md 連携フロー)

- 実装中・リリース後にラチェット誤判定 (誤カウント / 不正 exit code / baseline 破壊) を検出した場合、Implementation Agent は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する。同種の失敗が3回発生した場合は `sage/anti-patterns.md` へ昇格する (CLAUDE.md §5 Error Resolution Protocol 準拠、盲目的リトライ禁止)
- エラー報告時は §5 の6要素 (エラーログ / 失敗ファイル+行 / SPEC-0030 の該当 AC / git diff / 修正スコープ / 完了条件) を必ず含める

### ロールバック手順

- 本 SPEC の成果物は全て opt-in の新規ファイルであり、installer 非配布のため、問題発生時は該当ファイル (`scripts/sage-tsc-ratchet.sh` / `templates/ts-enforcement/` / `docs/ts-enforcement.md`) を revert コミットで削除するだけで完全に旧状態へ戻る。既存機能への波及はない
- 導入先で ratchet が CI を誤って FAIL させる場合の暫定回避: CI から ratchet ステップを外す (opt-in のため他の Gate に影響しない)。ESLint 断片は導入先 config から該当ブロックを除去する

## 実装メモ（Implementation Agent向け）

- **File Scope (Implementation Agent が変更可能なファイル)**:
  - `scripts/sage-tsc-ratchet.sh` (新規)
  - `templates/ts-enforcement/eslint-flat.mjs` (新規)
  - `templates/ts-enforcement/eslint-flat-transitional.mjs` (新規)
  - `templates/ts-enforcement/eslintrc-fragment.json` (新規)
  - `docs/ts-enforcement.md` (新規)
  - `docs/stack-presets.md` (参照追記 1 行のみ)
  - `README.md` (参照追記のみ)
  - `templates/hooks/tests/test-ts-enforcement.sh` (新規 — **Test Agent 責務**)
  - `templates/hooks/tests/fixtures/mock-tsc-*.sh` (新規 fixture — Test Agent 責務)
  - `templates/hooks/tests/run-tests.sh` (登録行のみ、自動 discovery なら不要 — Test Agent 責務)

  上記以外の変更は禁止 (AP-03)。特に `install.sh` / `SHA256SUMS` / `scripts/generator/` / 本リポジトリの `.sage/config.yaml` / `AGENTS.md` / `docs/codex-*.md` / `sage/` / `templates/project-checks/ts-pnpm.yaml` (generator 埋め込み対象) は不可。
- エラーカウント: `grep -cE 'error TS[0-9]+' ` を基本とする (tsc の標準出力フォーマット `path(line,col): error TS1234: message` 前提)。stdout/stderr 両方を捕捉すること (tsc はバージョンにより出力先が異なる)
- JSON 読み書き: 読み取りは `sed -n 's/.*"errors"[[:space:]]*:[[:space:]]*\([0-9-][0-9]*\).*/\1/p'` 相当の POSIX 抽出 + 非負整数検証 (`case`/`grep -E '^[0-9]+$'`)。書き込みは `printf` による固定テンプレート。既存スクリプトの JSON 取り扱い流儀 (SPEC-0027 の `scripts/` 実装) を参照
- コマンド実行: `sh -c "$TSC_CMD"` の単一経路のみ。`eval` 禁止 (AC-08 で機械検証)。tsc 失敗と型エラーの区別は境界ケース2 の仕様に従う
- ESLint 断片: flat config は `export default` の配列要素 1 つ (導入先が spread で取り込む形)、legacy は `rules` オブジェクト断片。`ts-expect-error` は `{"ts-expect-error": "allow-with-description"}` とし、完全禁止にしない (正当な抑制には説明を強制する設計)
- 既存スクリプトの流儀 (usage 関数 / `set -euo pipefail` / INFO/ERROR プレフィックス) は `scripts/sage-promote.sh` 等に合わせる
- コミット規約: 全コミットに TASK-ID を含める (commit-msg hook で強制、AP-05)。PR 本文に SPEC-0030 / PLAN-ID / TASK-ID + CLAUDE.md 追記案 (follow-up) を記載
- 禁止事項: jq / eval の使用 (AC-08)、tsc 出力内容の baseline への転記 (SEC-02)、installer / generator への変更 (AC-09)、テスト未実行での受け入れ (AP-09)、テストを実装に合わせて改変して通すこと (§5 禁止事項)
- Slice 向け分割ヒント:

| TASK | 内容 | 対応 AC | コマンド検証可能な完了条件 | 依存 / 並列可否 |
|------|------|---------|--------------------------|----------------|
| T1 | `scripts/sage-tsc-ratchet.sh` 新設 (検査/--update/--init/注入/整合検証) | AC-01〜06, 08 (実装) | 手動 mock 注入で各モードが仕様どおりの exit code / 出力 | 依存なし |
| T2 | `templates/ts-enforcement/` 3 ファイル新設 | AC-07 | AC-07 の test/grep が exit 0 | 依存なし (T1 と並列可) |
| T3 | docs (`docs/ts-enforcement.md` 新規 + `docs/stack-presets.md` / README 参照追記。ts-pnpm.yaml は変更しない — リスク5 判断済み) | AC-11, 12 | AC-11/12 の grep / git diff 検証 PASS | T1, T2 後 |
| T4 | test-ts-enforcement.sh + mock tsc fixtures + run-tests.sh 登録 (**Test Agent 責務・別セッション**) | AC-01〜08, 10 | `bash templates/hooks/tests/test-ts-enforcement.sh` 全ケース PASS + run-tests.sh 全件 PASS | T1, T2 後 |

  実行順: T1 / T2 並列 → T3 / T4。AC-09 (installer 非変更) は全 TASK 横断の制約として PR レビューで確認。installer 非配布の設計判断により **install.sh 再生成 TASK は不要** (含める場合は FAIL-0002 教訓により再生成専用 TASK が必須になるが、本 SPEC は非該当)。

## Properties

権限レベル platform + Security 要件あり → 5 件以上。

### Invariants

- [INV-01] (Gate 2) `.tsc-baseline.json` のエラー数は `--update` / `--init` 以外のいかなる実行経路 (検査モード・異常終了含む) でも変更されない (正規更新経路の一意性)
- [INV-02] (Gate 2) 検査モードの exit code は「現在エラー数 ≤ baseline なら 0、超過または判定不能 (不正 baseline / 不在 / tsc 失敗) なら 1」を常に満たす (fail-closed: 判定不能を成功扱いしない)
- [INV-03] (Gate 3) `sage-tsc-ratchet.sh` は jq / eval を使用せず、baseline 読み取り値は非負整数検証を通過した後でのみ数値比較に使用される
- [INV-04] (Gate 3) baseline へ書き込まれる内容は静的スキーマ + 数値 + タイムスタンプのみであり、tsc 出力の文字列は転記されない
- [INV-05] (Gate 4) 本 SPEC の変更は `install.sh` / `SHA256SUMS` / `scripts/generator/` に差分を発生させない (installer 非配布の設計判断の機械的表現)
- [INV-06] (Gate 4) `templates/project-checks/ts-pnpm.yaml` の 5 キーのコマンド値は不変である (SPEC-0028 の契約非破壊)

### Pre-conditions

- [PRE-01] (Gate 2) `--update` / `--init` の書き込みは、tsc 実行とエラーカウントが正常完了 (境界ケース2 の「tsc 実行失敗」でない) した場合のみ行われる
- [PRE-02] (Gate 2) 検査モードの比較は baseline の整合検証 (フォーマット・非負整数) の成功後にのみ行われる
- [PRE-03] (Gate 3) tsc コマンド文字列は FR-03 の優先順位で決定された単一の値のみが `sh -c` に渡され、途中で加工・連結されない

### Post-conditions

- [POST-01] (Gate 2) 増加検出時、stderr に現在数・baseline・増分が必ず出力される (Invisible Development 回避 — CI ログから判断根拠を追跡可能)
- [POST-02] (Gate 2) `--update` / `--init` 成功後の baseline は直近の tsc 実行のエラー数と一致し、`updated_at` が更新される
- [POST-03] (Gate 2) 減少検出時 (exit 0)、update 推奨 INFO が出力される (baseline の陳腐化を運用に通知)

### Assumptions

- [ASM-01] (Gate 横断) 導入先は bash 3.2+ / POSIX ツールが利用可能 (既存 scripts と同一前提)。tsc の出力は `error TS<番号>` パターンを含む標準フォーマットである
- [ASM-02] (Gate 横断) `SAGE_TSC_COMMAND` / `--tsc-command` にはユーザー自身が信頼するコマンドのみが設定される (信頼境界内。外部入力を渡さない運用は docs 明記)
- [ASM-03] (Gate 横断) ESLint 断片が実際に動くか (@typescript-eslint 導入済みか) は導入先の運用責任。不適合は導入先の lint 実行で顕在化する
- [ASM-04] (Gate 横断) tsconfig 変更時の証跡添付は運用規約であり、CI 強制は導入先の責任範囲 (本 SPEC は規約文書の提供まで)

## 関連ID

- PLAN-ID: [PLAN-0030](../plans/PLAN-0030-ts-enforcement.md)
- TASK-ID:
  - [TASK-0204](../tasks/TASK-0204-tsc-ratchet-script.md) — T1: `scripts/sage-tsc-ratchet.sh` 新設
  - [TASK-0205](../tasks/TASK-0205-ts-enforcement-eslint-fragments.md) — T2: `templates/ts-enforcement/` 3 ファイル新設
  - [TASK-0206](../tasks/TASK-0206-ts-enforcement-docs.md) — T3: docs 新設 + 参照追記
  - [TASK-0207](../tasks/TASK-0207-ts-enforcement-tests.md) — T4: テスト + mock tsc fixtures (Test Agent 責務・別セッション)
- Done Definition: [tasks/done-def-SPEC-0030-round-1.md](../tasks/done-def-SPEC-0030-round-1.md)
