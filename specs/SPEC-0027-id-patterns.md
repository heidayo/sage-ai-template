# SPEC-0027: ID パターンの設定外部化 — 作業者プレフィックス形式との併用サポート

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0027 |
| ステータス | Draft |
| 作成日    | 2026-07-02 |
| 更新日    | 2026-07-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0018 (supply chain hardening / SHA256SUMS), SPEC-0014 (installer modular), SPEC-0002 (CI Gate enforcement) |
| 権限レベル | platform |

## 背景・目的

実プロジェクト導入時、`TASK-hei-a7f3` のような「作業者プレフィックス + ハッシュ」形式の TASK-ID を運用したかったが、受理 regex `TASK-[0-9]{4}` が 5 箇所 (`scripts/sage-id-gen.sh`, `templates/pre-commit-task-id.sh`, `scripts/sage-trace-check.sh`, `scripts/sage-report.sh`, `scripts/sage-validate.sh`) にハードコードされており、カスタム形式の commit が pre-commit hook / trace check で拒否された。フォーク側で `.sage/id-patterns.json` 相当を自作してスクリプト群を書き換える必要があり、テンプレート更新のたびに衝突する。

本 SPEC は ID 受理パターンを `.sage/id-patterns.json` に外部化し、5 箇所すべてが共有ローダー `scripts/sage-id-pattern.sh` 経由で同一設定を参照するようにする。デフォルト挙動 (設定ファイルなし) は現行と完全同一とし、後方互換を要とする。

## 対象ユーザー

- sage-ai-template を導入し、独自の ID 命名規則 (作業者プレフィックス等) を併用したいチーム
- 既存導入先 (設定ファイルなし) — 挙動変化ゼロであることが前提

## スコープ（含む）

- `.sage/id-patterns.json` の新設 (テンプレート同梱・任意ファイル):
  - ID 種別 (spec / plan / task / run / fail) ごとに、受理 regex (POSIX ERE) の配列を定義
  - デフォルト値は現行ハードコード (`TASK-[0-9]{4}` 等) と完全同一
  - 併用サポート: `accept` 配列にデフォルト形式 + 追加パターン (例: `TASK-[a-z]+-[0-9a-f]{4}`) を複数列挙でき、いずれかにマッチすれば受理
- 共有ローダー `scripts/sage-id-pattern.sh` (source 用):
  - `sage_id_accept_regex <type>` : 種別 → 受理用 ERE (複数パターンは `(p1|p2)` に合成) を返す
  - `sage_id_default_regex <type>` : 生成 (連番スキャン) 用のデフォルト形式 ERE を返す
  - 設定ファイル欠損・パース不能・種別未定義時は現行ハードコード regex へ fallback (WARN は stderr、exit は正常)
  - パースは POSIX ツール (grep/sed/awk) のみで行う。jq には依存しない (jq 存在時の高機能化も行わない — 単一コードパス維持)
- 5 箇所の置換 (受理判定はすべて `sage_id_accept_regex`、id-gen の連番スキャンは `sage_id_default_regex` を参照):
  - `scripts/sage-id-gen.sh` — 生成はデフォルト形式のみ (追加形式の生成は外部運用)。既存 ID スキャンはデフォルト形式のみ対象
  - `templates/pre-commit-task-id.sh` — hook は導入先スタンドアロン配布物のため、fallback regex を自己完結で内包しつつ、`.sage/id-patterns.json` が読めれば設定を優先する。generator 経由で `install.sh` に再埋め込みし再配布 (FAIL-0002 教訓)
  - `scripts/sage-trace-check.sh`
  - `scripts/sage-report.sh` (BRE `TASK-[0-9]\{4\}` 箇所は `grep -E` 化して統一)
  - `scripts/sage-validate.sh`
- テスト `templates/hooks/tests/test-id-patterns.sh` の追加 (`_helpers.sh` / `run-tests.sh` の既存流儀に従う):
  - (1) 設定ファイルなしで現行と同一の受理/拒否 (fallback)
  - (2) デフォルト形式 `TASK-0001` の受理
  - (3) カスタム形式 `TASK-hei-a7f3` の受理 (設定追加時) / 拒否 (設定なし時)
  - (4) 不正 JSON 時に fallback + WARN、非0 exit しない
  - (5) 5 スクリプトが同一設定を参照する整合 (ハードコード regex の残存検出)
- generator 変更 → `install.sh` 再生成 → SHA256SUMS 更新 (再現性維持)
- ドキュメント (日本語):
  - `.sage/config.yaml` の `id_schema` コメントに `.sage/id-patterns.json` への参照を追記し記述整合を取る
  - README または docs にカスタム ID 形式の設定手順 (`.sage/id-patterns.json` の書式・例・注意点) を記載
- installer の preserve-if-exists 対応: installer は既存 `.sage/id-patterns.json` を上書きしない (preserve-if-exists、SPEC-0026 preservation 方針と整合)
- CLAUDE.md への追記案の提示 (human-only ファイルのため直接編集せず、PR 本文に追記案を記載して human が適用): 「ID 受理パターンは .sage/id-patterns.json で拡張可能 (受理のみ。生成はデフォルト形式)。設定手順: docs/id-patterns.md」

## スコープ外（明示的に除外）

- 既存 ID の migration (過去 commit / ファイル名の書き換えは行わない)
- GitHub PR 番号 (merge ID) の検証 — `id_schema.merge` は対象外のまま
- jq 依存の追加 — 設計判断として POSIX ツールのみでパースする (jq 存在時の分岐も設けない。二重コードパスはテスト面積を倍にするため)
- カスタム形式 ID の生成 (`sage-id-gen.sh` での prefix-hash 生成) — 受理のみサポート、生成は外部運用
- CI workflow (`.github/workflows/`) 側の regex 変更 — Gate スクリプト (`sage-validate.sh` 等) 経由で反映されるため直接編集しない
- `AGENTS.md` / `docs/codex-*.md` の編集 (Codex-specific boundary、必要なら Codex follow-up task)
- `sage/` 配下 governance 文書の改訂 (Human-only)
- runlog-index (SPEC-0016) の FTS スキーマ変更 — 検索対象文字列は ID そのものであり regex 非依存
- `gen_digits` による生成桁数変更 — 本 SPEC は受理パターンのみ外部化。生成形式の変更は将来 SPEC 候補
- 集計・表示目的の ID 抽出 regex (scripts/sage-report.sh:146 の glob `specs/SPEC-[0-9]*.md`、:148 の `grep -oE 'SPEC-[0-9]{4}'` 等) — 受理/拒否判定ではなくレポート出力のため外部化対象外。カスタム形式 SPEC-ID の集計対応は将来 SPEC 候補

## 要件

### 機能要件
- [FR-01] `.sage/id-patterns.json` は種別 (spec/plan/task/run/fail) ごとに `accept` (受理判定に使用される ERE 文字列の配列) を定義できる。集計・表示目的の ID 抽出 regex は対象外 (スコープ外参照)
- [FR-02] `scripts/sage-id-pattern.sh` は source 時に設定を読み込み、`sage_id_accept_regex <type>` で受理用 ERE を返す。複数 `accept` パターンは `(p1|p2|...)` に合成する
- [FR-03] 設定ファイル欠損時、`sage_id_accept_regex` は現行ハードコードと同一の ERE (`TASK-[0-9]{4}` 等) を返す (fallback)
- [FR-04] 設定ファイルがパース不能 (不正 JSON / 空 / 種別欠落) の場合、当該種別は fallback regex を使用し、WARN を stderr に1回出力する。呼び出し元スクリプトは失敗しない
- [FR-05] 上記 5 スクリプトのうち受理判定に使用される regex はすべて `sage_id_pattern.sh` の関数経由に置換され、受理判定用ハードコード regex はローダー内の fallback 定義のみに集約される (集計・表示目的の抽出 regex は置換対象外)
- [FR-06] `pre-commit-task-id.sh` は sage-id-pattern.sh が存在しない導入先でも単体動作する (fallback regex を内包)。`.sage/id-patterns.json` が存在し読解可能な場合はそちらの `task.accept` を優先する
- [FR-07] `scripts/sage-id-gen.sh` の生成・連番スキャンはデフォルト形式のみを対象とし、カスタム形式 ID の存在が連番採番を壊さない (無視される)
- [FR-08] generator 変更後、`install.sh` は再生成され SHA256SUMS と一致する (pre-commit hook 埋め込みの追随)

### 非機能要件
- [NFR-01] 後方互換: `.sage/id-patterns.json` が存在しない場合、5 スクリプトの入出力 (受理/拒否/生成 ID/exit code) は変更前と完全同一
- [NFR-02] 再現性: 同一 generator 入力から生成される `install.sh` はバイト一致し、SHA256SUMS 検証を壊さない
- [NFR-03] ローダーの読み込みは pre-commit 体感を悪化させない (外部プロセス起動は定数回、目安 50ms 未満の追加)

### セキュリティ要件
- [SEC-01] 設定値 (regex 文字列) はシェルコマンドとして評価しない (`eval` 禁止)。`grep -E` のパターン引数としてのみ使用し、コマンドインジェクションを不能にする
- [SEC-02] `.sage/id-patterns.json` は protect-sage-files hook の保護対象 (`.sage/` 設定) として扱い、AI agent による無断変更を既存機構で検知可能にする (hook 側の allowlist 変更は行わない — 既存の `.sage/config.yaml` 保護と同等ポリシーが及ぶ範囲で)
- [SEC-03] パターン合成結果が空文字になる入力 (空配列等) の場合は fallback に切り替え、`grep -E ''` (全マッチ) による検証無効化を防ぐ

### 運用要件
- [OPS-01] docs にカスタム ID 形式の設定手順・書式例・「生成はデフォルト形式のみ」の制約を記載する
- [OPS-02] `make doctor` 既存チェックが `.sage/id-patterns.json` の有無いずれでも PASS する
- [OPS-03] 定量合格基準: リリース後2週間、`sage/failures.md` に ID 受理誤判定 (正規 ID の拒否 / 不正 ID の受理) 起因の失敗記録が0件、かつ少なくとも1導入先でカスタム形式併用 (`TASK-<worker>-<hash>` commit が pre-commit を通過) を確認できた場合に安定 (Observe 完了) とみなす。誤判定報告1件で issue 起票、同種3件で `sage/anti-patterns.md` へ昇格検討

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: fallback 動作 — `.sage/id-patterns.json` を削除した一時環境で `source scripts/sage-id-pattern.sh; sage_id_accept_regex task` の出力が `TASK-[0-9]{4}` と一致する。検証コマンド: `bash templates/hooks/tests/test-id-patterns.sh` (case: `fallback_no_config`) が PASS
- [ ] AC-02: デフォルト形式受理 — 設定ファイルあり (デフォルト内容) で `echo 'TASK-0001: msg' | grep -qE "$(sage_id_accept_regex task)"` が exit 0 (case: `default_accepted`)
- [ ] AC-03: カスタム形式受理 — `task.accept` に `TASK-[a-z]+-[0-9a-f]{4}` を追加した設定で、`TASK-hei-a7f3` を含む commit message fixture が `pre-commit-task-id.sh` を通過する (case: `custom_accepted`)
- [ ] AC-04: 異常系 (不正 JSON) — `.sage/id-patterns.json` に不正 JSON を置いた状態で `sage_id_accept_regex task` が fallback 値 `TASK-[0-9]{4}` を返し、stderr に WARN が含まれ、exit 0 である (case: `invalid_json_fallback`)
- [ ] AC-05: 異常系 (空 accept 配列) — `task.accept` が空配列の設定で fallback regex が使用され、空パターンによる全マッチが発生しない (`NOTASK` fixture が拒否される) (case: `empty_accept_fallback`)
- [ ] AC-06: 5 スクリプト整合 — ERE/BRE 両表記を検出対象とし、`grep -rnE 'TASK-\[0-9\](\{4\}|\\\{4\\\})' scripts/sage-id-gen.sh scripts/sage-trace-check.sh scripts/sage-report.sh scripts/sage-validate.sh templates/pre-commit-task-id.sh` (ERE 表記 `TASK-[0-9]{4}` と BRE 表記 `TASK-[0-9]\{4\}` の両方を検出) のヒットが `templates/pre-commit-task-id.sh` の内包 fallback 定義行のみである (scripts/ 側 4 ファイルは 0 件、INV-03 準拠。テストが許容行数・位置を機械検証) (case: `no_stray_hardcode`)
- [ ] AC-07: id-gen 非干渉 — カスタム形式 ID ファイル (`tasks/TASK-hei-a7f3-x.md`) が存在する一時環境で `bash scripts/sage-id-gen.sh task` がデフォルト形式の次連番を返す (case: `idgen_ignores_custom`)
- [ ] AC-08: 再現性 — generator 再生成後 `shasum -a 256 -c SHA256SUMS` (install.sh エントリ) が成功する
- [ ] AC-09: 既存テスト非破壊 — `bash templates/hooks/tests/run-tests.sh` が全件 PASS する
- [ ] AC-10: ドキュメント — `grep -rqF '.sage/id-patterns.json' README.md docs/` が exit 0、かつ `grep -qF 'id-patterns' .sage/config.yaml` が exit 0 (id_schema 記述との整合) (case: `docs_and_config_reference`)
- [ ] AC-11: eval 不使用 (SEC-01) — `grep -nE '(^|[^a-zA-Z_])eval([^a-zA-Z_]|$)' scripts/sage-id-pattern.sh` のヒットが 0 件である
- [ ] AC-12: installer preserve-if-exists — カスタム accept を含む `.sage/id-patterns.json` 配置済み一時環境で `install.sh` 実行後、`grep -qF 'TASK-[a-z]+-[0-9a-f]{4}' .sage/id-patterns.json` が exit 0 (case: `installer_preserves_config`)

### 検証方針

- `templates/hooks/tests/test-id-patterns.sh` は integration テストとして、一時ディレクトリに設定 fixture を配置し AC-01〜07, 10 の各ケースを検証する (test-local-overlay.sh の流儀を踏襲)
- テスト種別: bash integration テストのみ。unit テストは対象がシェル関数のため非適用
- カバレッジ閾値は N/A — bash スクリプトであり Gate 2 の LOC ベース coverage 計測の適用対象外。代替として本 SPEC の異常系 (想定エラー1〜3・境界ケース1〜2) を全てテストケース化し網羅性を担保する

## 異常系

- 想定エラー1: `.sage/id-patterns.json` が不正 JSON / 空ファイル — 当該種別は fallback regex + WARN (stderr)、スクリプトは正常続行 (AC-04)
- 想定エラー2: `accept` が空配列 / 空文字要素のみ — fallback へ切替。空パターンで全マッチさせない (SEC-03, AC-05)
- 想定エラー3: 設定に未知の種別 / 種別欠落 — 定義済み種別のみ設定を適用し、欠落種別は fallback (AC-01 のバリアント)
- 境界ケース1: カスタム形式 ID がリポジトリに存在する状態での id-gen 連番採番 — カスタム ID は無視され、デフォルト形式の最大値 +1 を返す (FR-07, AC-07)
- 境界ケース2: ローダー (`scripts/sage-id-pattern.sh`) 自体が存在しない導入先での pre-commit hook 実行 — hook 内包の fallback で単体動作する (FR-06)
- 境界ケース3: カスタム accept を含む `.sage/id-patterns.json` が配置済みの環境で installer を再実行 — 既存設定は上書きされず保持される (preserve-if-exists, AC-12)

## 契約

- API: なし
- DB: なし
- イベント: なし
- CLI 契約: 既存 5 スクリプトの CLI 引数・exit code 規約は不変。`scripts/sage-id-pattern.sh` は source 専用 (直接実行はサポート外)
- ファイル契約: `.sage/id-patterns.json` — `{"<type>": {"accept": ["<ERE>", ...]}}` (type ∈ spec/plan/task/run/fail、全キー任意・欠落は fallback)。installer は既存 `.sage/id-patterns.json` を上書きしない (preserve-if-exists、SPEC-0026 preservation 方針と整合)

## リスク

- リスク1: 5 箇所の置換漏れ・部分置換で受理判定が不整合になる → 軽減策: ハードコード残存を検出するテスト (AC-06) で機械強制。fallback 定義はローダー (+hook 内包分) に集約 (INV-03)
- リスク2: POSIX ツールによる JSON パースが正規 JSON の表記揺れ (改行・空白) で誤読する → 軽減策: 書式を docs で「1 パターン 1 行」の制約付きサブセットとして規定し、テスト fixture に表記揺れケースを含める。パース不能時は常に安全側 (fallback)
- リスク3: pre-commit hook の generator 再埋め込み漏れで、テンプレート側とインストール済み hook が乖離する (FAIL-0002 再演) → 軽減策: generator 変更 → install.sh 再生成 → SHA256SUMS 更新を同一 TASK の完了条件にし AC-08 で機械検証
- リスク4: 緩すぎるカスタム regex (`TASK-.*` 等) で traceability が形骸化する → 軽減策: docs に推奨パターンとアンチ例を記載。受理は導入先責任 (ASM-02)、テンプレートデフォルトは現行厳格形式を維持

### 知識管理 (failures.md 連携フロー)

- 実装中・リリース後に ID 受理誤判定・fallback 不作動・hook 乖離を検出した場合、Implementation Agent は修正コミット前に `sage/failures.md` へ TASK-ID 付きで記録する。同種の失敗が3回発生した場合は `sage/anti-patterns.md` へ昇格する (CLAUDE.md §5 Error Resolution Protocol 準拠、盲目的リトライ禁止)
- エラー報告時は §5 の6要素 (エラーログ / 失敗ファイル+行 / SPEC-0027 の該当 AC / git diff / 修正スコープ / 完了条件) を必ず含める

### ロールバック手順

- 本 SPEC のリリースに問題が発生した場合、直前リリースの `install.sh` + SHA256SUMS (GitHub Releases) に差し戻して再実行する。`.sage/id-patterns.json` は任意ファイルのため、削除すれば全スクリプトが fallback (= 旧挙動) に戻る
- 導入先で誤判定が発生した場合の暫定回避: `.sage/id-patterns.json` を削除 (または種別エントリを除去) して現行デフォルトへ即時復帰し、issue を起票する

## 実装メモ（Implementation Agent向け）

- **File Scope (Implementation Agent が変更可能なファイル)**:
  - `scripts/sage-id-pattern.sh` (新規)
  - `.sage/id-patterns.json` (新規テンプレート、人間承認の上で追加 — `.sage/` 保護対象のため PR で明示)
  - `scripts/sage-id-gen.sh`
  - `scripts/sage-trace-check.sh`
  - `scripts/sage-report.sh`
  - `scripts/sage-validate.sh`
  - `templates/pre-commit-task-id.sh`
  - `scripts/generator/02-config.sh` (hook 埋め込み経路に変更が必要な場合のみ)
  - `scripts/generator/07-installer-main.sh` (実装フェーズで追加: ローダー `scripts/sage-id-pattern.sh` の配布 + install-state manifest 登録、および `.sage/id-patterns.json` の preserve-if-exists 書き込みは 07 側でのみ実装可能)
  - `install.sh` (再生成のみ・手動編集禁止)
  - `SHA256SUMS`
  - `templates/hooks/tests/test-id-patterns.sh` (新規)
  - `templates/hooks/tests/run-tests.sh` (登録行のみ、自動 discovery なら不要)
  - `README.md`
  - `docs/id-patterns.md` (新規)
  - `.sage/config.yaml` (id_schema コメント整合のみ — protect-sage-files 対象のため人間承認必須、変更行を PR で明示)

  上記以外の変更は禁止 (AP-03)。AGENTS.md / `docs/codex-*.md` / `sage/` は特に不可。
- 現行ハードコード位置: `templates/pre-commit-task-id.sh:56`、`scripts/sage-trace-check.sh:19`、`scripts/sage-validate.sh:195`、`scripts/sage-report.sh:123-125` (BRE 混在に注意)、`scripts/sage-id-gen.sh:47,52` (`${PREFIX}-[0-9]{4}` — 生成用スキャンなのでデフォルト形式のまま `sage_id_default_regex` 経由に)
- `sage-report.sh:123-124` は `git log --grep` (BRE) を使用 — `--grep` に ERE を渡す場合は `-E` 相当 (`--extended-regexp` は git log では `--grep` に非対応のため `--perl-regexp` を避け、合成 regex を BRE 互換に落とすか `--format` 出力を `grep -E` でフィルタする方式へ変更) に注意。ここが最も置換事故が起きやすい
- **FAIL-0002 の教訓 (SPEC-0025 実装より)**: `templates/pre-commit-task-id.sh` は `scripts/generator/02-config.sh` で `install.sh` に埋め込まれる。テンプレート変更後は必ず `install.sh` を再生成して SHA256SUMS を追随させること。再生成漏れは AC-08 で FAIL する
- テストは `templates/hooks/tests/_helpers.sh` + `test-local-overlay.sh` の流儀 (一時ディレクトリ + fixture 実行) を踏襲
- コミット規約: 全コミットに TASK-ID を含める (commit-msg hook で強制、AP-05)。PR 本文に SPEC-0027 / PLAN-ID / TASK-ID を記載
- 禁止事項: `eval` の使用 (SEC-01)、jq 依存の追加 (スコープ外)、5 スクリプト + テスト + docs の一括 Big Bang 変更 (AP-02 — Slice で分割)、テスト未実行での受け入れ (AP-09)、テストを実装に合わせて改変して通すこと (§5 禁止事項)
- Slice 向け分割ヒント:

| TASK | 内容 | 対応 AC | コマンド検証可能な完了条件 | 依存 / 並列可否 |
|------|------|---------|--------------------------|----------------|
| T1 | ローダー `scripts/sage-id-pattern.sh` + `.sage/id-patterns.json` テンプレート | AC-01/02/04/05/11 | `source scripts/sage-id-pattern.sh; sage_id_accept_regex task` が期待値 + eval grep 0件 | 依存なし |
| T2 | `sage-trace-check.sh` / `sage-validate.sh` / `sage-report.sh` のローダー参照化 | AC-06 (部分) | 各スクリプト単体実行が既存挙動維持 + fixture で custom 受理 | T1 に依存。3 ファイルは相互独立だが同種変更のため直列1タスク (単一責務: 受理判定の参照化) |
| T3 | `sage-id-gen.sh` のデフォルト形式スキャン参照化 | AC-07 | カスタム ID 混在 fixture で次連番が正しい | T1 に依存、T2 と並列可 |
| T4 | `templates/pre-commit-task-id.sh` の設定優先 + fallback 内包化 | AC-03/06 (部分) | 欠損環境 fixture で単体動作 + custom 受理 | T1 に依存、T2/T3 と並列可 |
| T5 | install.sh 再生成 + SHA256SUMS 更新 (専用 TASK)。installer の `.sage/id-patterns.json` preserve-if-exists 対応を含む | AC-08/12 | `shasum -a 256 -c SHA256SUMS` PASS + AC-12 の grep 検証 exit 0 | T4 後 |
| T6 | test-id-patterns.sh 追加 + run-tests.sh 登録 | AC-01〜07/09/11 | `bash templates/hooks/tests/test-id-patterns.sh` 全ケース PASS + run-tests.sh 全件 PASS | T5 後 |
| T7 | docs (`docs/id-patterns.md` + README) + `.sage/config.yaml` id_schema コメント整合 | AC-10 | AC-10 の grep 検証 PASS | T1 後に並列可 (.sage/config.yaml 行は人間承認を PR で明示) |

  実行順: T1 → (T2 / T3 / T4 並列) → T5 → T6。T7 は T1 完了後に並列可。各 TASK は単一責務を維持する。

## Properties

権限レベル platform + Security 要件あり → 5 件以上。

### Invariants
- [INV-01] (Gate 2) `.sage/id-patterns.json` が存在しない環境では、5 スクリプトの受理/拒否/生成結果は本 SPEC 適用前と完全同一である (後方互換の要)
- [INV-02] (Gate 3) 設定由来の文字列はいかなる経路でもシェル評価 (`eval` / コマンド置換の引数外使用) されない。`grep` 系のパターン引数としてのみ使用される
- [INV-03] (Gate 4) ID 受理 regex のハードコード定義は `scripts/sage-id-pattern.sh` の fallback と `templates/pre-commit-task-id.sh` の内包 fallback の2箇所のみに存在し、両者は同一値である (重複実装による drift 禁止)
- [INV-04] (Gate 2) 受理用 regex が空文字列として使用されることはない (空・不正設定は必ず fallback に解決される)
- [INV-05] (Gate 3) 再生成された `install.sh` は SHA256SUMS と一致し、SPEC-0018 の検証フロー (--verify-checksum / provenance) の対象・強度を縮小しない

### Pre-conditions
- [PRE-01] (Gate 2) ローダーは regex 返却前に設定の存在・パース可否・値の非空を判定し、いずれか不成立なら fallback を返す
- [PRE-02] (Gate 2) `sage-id-gen.sh` は採番前に既存 ID をデフォルト形式 regex のみでスキャンする (カスタム形式は採番計算に混入しない)

### Post-conditions
- [POST-01] (Gate 2) `sage_id_accept_regex <type>` は常に非空の有効な ERE を返し、exit 0 で完了する (設定異常時も WARN のみ)
- [POST-02] (Gate 2) カスタムパターン設定後、当該パターンにマッチする ID を含む commit message は pre-commit / trace-check / validate のすべてで一貫して受理される (スクリプト間不整合なし)
- [POST-03] (Gate 3) generator 実行後の `install.sh` はバイト再現性を持ち、SHA256SUMS 検証が成功する

### Assumptions
- [ASM-01] (Gate 横断) 導入先は bash 3.2+ / POSIX grep・sed・awk が利用可能 (既存スクリプト群と同一前提)。jq は前提としない
- [ASM-02] (Gate 横断) カスタム regex の厳格さ (traceability を保てる粒度か) は導入先の運用責任。テンプレートデフォルトは現行の厳格形式を維持する
- [ASM-03] (Gate 横断) `.sage/id-patterns.json` の書式は docs 規定のサブセット (1 パターン 1 行) に従って人間が編集する。逸脱時は fallback により安全側に倒れる

## 関連ID

- PLAN-ID: PLAN-0027
- TASK-ID: TASK-0185 (T1 ローダー), TASK-0186 (T2 trace-check/validate/report), TASK-0187 (T3 id-gen), TASK-0188 (T4 pre-commit hook), TASK-0189 (T5 installer 再生成), TASK-0190 (T6 テスト), TASK-0191 (T7 docs)
- Done Definition: tasks/done-def-SPEC-0027-round-1.md
