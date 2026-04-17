# SPEC-0008: SAGE 宣言実装乖離の解消 (Enforcement Gap Closure)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0008 |
| ステータス | Draft |
| 作成日    | 2026-04-17 |
| 更新日    | 2026-04-17 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0002, SPEC-0003, SPEC-0007 |
| 権限レベル | system |

## 背景・目的

外部レビューにより、SAGE テンプレートの「思想文書は緻密だが機械強制が追いついていない」乖離が定量的に確認された。`.sage/config.yaml` に宣言された 32 項目のうち、完全実装 6 / 部分実装 15 / 未実装 11。代表的な乖離:

- Gate 2 `unit_test_coverage: 0.80` — 数値抽出と閾値比較のコードが workflow に存在しない
- Gate 4 `layer_boundary: required`, `forbidden_dependency` — 実装ロジック無し (traceability grep のみ)
- `metrics.cycle_time` 等 — スキーマ定義のみで計算コード不在
- `run_log_schema` — バリデーター不在
- Claude review workflow の fail-open (verdict 未取得時 `core.warning` で通過)
- CLAUDE.md ↔ AGENTS.md のドリフト発生中、検知 CI 無し
- `install.sh` (5551行) と generator / Gist / `installer_url` の 3 経路同期保証無し
- 採点ループ 100 点必須 + LLM 採点ブレ対策ゼロ
- `.DS_Store` が tracked かつ gitignored の矛盾状態
- hooks デフォルトプロファイル `minimal` で実質無効
- TASK ファイル命名 (`TASK-0064〜0069-spec0007.md`) で内容判別不可
- `src/` `tests/` が `.gitkeep` のみで dogfooding 実績ゼロ

これらは SAGE 自身が定義する AP-06 (Human-Only Guard) アンチパターンそのものであり、「このテンプレを使えば AI が勝手に守る」という README の主張と整合しない。本 SPEC は **宣言を削減するのではなく実装側で乖離を埋める** ことで、SAGE を宣言通りの enforcement system に到達させる。

## 対象ユーザー

- SAGE テンプレートを適用する全プロジェクトの AI エージェントおよび開発者
- 本リポジトリ maintainer (dogfooding の実施者)

## スコープ（含む）

Track A-F の 24 TASK (TASK-0070〜0093) で全 18 乖離を解消する:

- **Track A (Gates 実装完成)**: Gate 2 カバレッジ閾値比較、Gate 4 レイヤ境界/禁止依存チェック、Claude review fail-close 化
- **Track B (Metrics / RUN Log)**: RUN ログ YAML バリデーター、metrics 計算 (cycle_time / gate_pass_rate / rework_rate)、RUN ログ生成の標準化
- **Track C (Drift 検知 CI)**: CLAUDE.md ↔ AGENTS.md drift 検知、install.sh 再現性 CI、templates→.claude copy 検証、.gitignore ↔ tracked 整合チェック、installer_url 3 経路同期検証
- **Track D (採点ループ改善)**: 閾値 100→95 緩和、moving window (3 回連続 95 以上で PASS)、best-of-N=3 採点、oscillation 検知 (分散 15 超で human escalation)
- **Track E (表層クリーンアップ)**: 双子文書 drift 埋め、`.DS_Store` untrack、TASK ファイル命名修正、hooks profile standard デフォルト化、危険コマンド検知パターン拡充
- **Track F (Dogfooding)**: Go 電卓 HTTP API サンプル、project_checks の実コマンド化、SPEC-0009 切り出し、5 Gate 全 PASS の実走

## スコープ外（明示的に除外）

- **言語別 linter の新規導入**: Track A Gate 4 は grep ベースで開始。go-arch-lint 等への昇格は別 SPEC (opt-in)
- **codecov / 外部 SaaS 統合**: Track A Gate 2 は標準出力から float 抽出のみ、外部依存追加は避ける
- **Python 版 dogfooding サンプル**: Track F は Go 単一言語。Python 版は SPEC-0009 に逃がす
- **LLM ベースのドリフト検知**: Track C は正規化 diff のみ。非決定的な LLM 判定は CI に不適
- **100 点閾値への復帰**: 採点ブレ対策として 95 点 + moving window を採用、100 点必須には戻さない
- **既存 SPEC-0001〜0007 の再設計**: 乖離解消は本 SPEC でまとめて行う
- **`install.sh` の heredoc 方式変更**: 生成方式自体は維持、再現性 CI で検証する方向

## 要件

### 機能要件

- [FR-01] Gate 2 workflow がカバレッジ値を数値として抽出し `functional.unit_test_coverage` と比較、閾値未達で exit 1
- [FR-02] Gate 4 workflow が `.sage/architecture.yaml` のレイヤ違反 / 禁止依存を grep ベースで検出し違反件数 > 0 で exit 1
- [FR-03] Claude review workflow が verdict 未取得 / 解釈不能 / timeout で `core.setFailed`
- [FR-04] `scripts/sage-runlog-validate.sh` が `.sage/runs/*.yaml` の必須フィールド欠落で exit 1
- [FR-05] `scripts/sage-report.sh` が cycle_time / gate_pass_rate / rework_rate の 3 メトリクスを追加出力 (既存 2 + 新規 3 = 計 5)
- [FR-06] `scripts/sage-doc-drift.sh` が CLAUDE.md ↔ AGENTS.md の共通節非対称を検出し exit 1
- [FR-07] structural-gate workflow が `generate-installer.sh` 生成結果と tracked `install.sh` の diff 非空で exit 1
- [FR-08] structural-gate workflow が `sage-publish.sh --dry-run` 実行後の `.claude/` 差分非空で exit 1
- [FR-09] `scripts/sage-validate.sh` が `git ls-files -ci --exclude-standard` 非空で exit 1 (Check 8)
- [FR-10] `scripts/sage-validate.sh` が `install.sh` / Gist / `installer_url` の sha256 不一致で exit 1 (Check 9、オフライン CI では SKIP)
- [FR-11] harness が `harness.scoring_window_size` 直近ラウンドの最小スコアが閾値 (95) 以上で PASS と判定
- [FR-12] harness が `harness.scoring_best_of_n` 回採点のうち最高値を採用、分散が `harness.scoring_variance_abort` 超で `abort_reason: scoring_oscillation` として human escalation
- [FR-13] `.DS_Store` が tracked から除外され、`.gitignore` ↔ tracked 整合が取れる
- [FR-14] `block-dangerous-commands.sh` が pipe-to-shell / `find -delete` / `shutil.rmtree` / `mkfs` / `dd if=*of=/dev/*` / `chmod -R 777 /` / `git add -f .DS_Store` の 7 パターンを追加でブロック
- [FR-15] TASK-0064〜0069 のファイル名が H1 タイトルから派生した意味的サフィックスを持つ
- [FR-16] hooks の default profile が `minimal` → `standard` に変更される
- [FR-17] AGENTS.md に Section 4.1 Harness および Section 9.1 Hooks が追加され、CLAUDE.md に Sub-agent invocation pattern が追加される
- [FR-18] `src/calculator/` に Go 単純 HTTP API (加減乗除) が配置され、`tests/calculator/` でカバレッジ 80% 以上のテストが付属

### 非機能要件

- [NFR-01] CI 所要時間: Track A-C の追加検査で 1 PR あたり CI 時間増 30 秒以内
- [NFR-02] API コスト: best-of-N=3 により採点 API コストが 3 倍化する。`scoring_best_of_n: 1` で旧挙動に戻せること
- [NFR-03] 後方互換: 既存の `.sage/runs/*.yaml` 3 件が validator を通過すること

### セキュリティ要件

- [SEC-01] `block-dangerous-commands.sh` の追加パターンが既存の正常コマンド (例: `docker run` 中の `bash`) を誤って block しないこと
- [SEC-02] `scripts/sage-doc-drift.sh` は read-only で動作し、CLAUDE.md / AGENTS.md を書き換えないこと
- [SEC-03] installer_url 検証 (`curl -sI`) は main 直コミット以外では fail-soft (SKIP) 動作とする

### 運用要件

- [OPS-01] 本 SPEC は PLAN-0008-A〜F の 6 本に分割され、各 Track が独立 PR として進行
- [OPS-02] TASK-0086 (`.DS_Store` untrack) は他 PR のノイズ防止のため最先行単独マージ
- [OPS-03] Track F (Dogfooding) は Track A/B/D が全て main にマージされた後に実施
- [OPS-04] Big Bang Prompt (20 ファイル超) 回避のため、governance ファイル (SPEC/PLAN/TASK 合計 31 本) の作成も Track 単位で分割 PR する

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `git ls-files | grep -c DS_Store` が 0
- [ ] AC-02: `bash scripts/sage-validate.sh` が全 Check PASS で exit 0
- [ ] AC-03: `make report` 実行で cycle_time / gate_pass_rate / rework_rate / sessions / failures の 5 メトリクスが出力される
- [ ] AC-04: Track F 実走 PR で 5 Gate (structural/functional/security/architecture/release) 全てが ✅
- [ ] AC-05: 意図的な違反 PR (coverage 低下 / architecture.yaml 違反 / AGENTS.md 節削除 / `git add -f .DS_Store`) が全て CI または hook で FAIL となる
- [ ] AC-06: 採点スコア `[96, 95, 97]` で PASS、`[94, 95, 96]` で FAIL、`[100, 80, 90]` で `scoring_oscillation` abort が再現できる (harness SKILL のロジック記述レベル)
- [ ] AC-07: `diff -u templates/skills/sage-harness/SKILL.md .claude/skills/sage-harness/SKILL.md` が空 (drift なし)
- [ ] AC-08: `bash scripts/generate-installer.sh > /tmp/e.sh && diff /tmp/e.sh install.sh` が exit 0

## 異常系

- **採点 oscillation の永久ループ**: 分散 15 超の場合 `human_escalation` を発火させ、自動ループで 10 回回すことを禁止する
- **Gist 到達不能時**: installer_url 検証は main 直コミットのみ FAIL、それ以外の CI では SKIP 表示
- **言語別カバレッジ形式の未対応**: `project_checks.coverage_command` 未設定なら Gate 2 は SKIPPED、ユーザーに対するエラーではない
- **`.DS_Store` が複数サブディレクトリに存在**: TASK-0086 は root の 1 件を対象、`.gitignore` 経由で他サブディレクトリも自動 ignored 扱いとする
- **best-of-N=3 実行中に evaluator が 1 回だけ応答**: 有効サンプル < N の場合は FAIL ではなく `abort_reason: evaluator_unavailable` で human escalation

## 契約

- API: なし
- DB: なし
- イベント: `.sage/runs/*.yaml` スキーマ (既存 `.sage/config.yaml` の `run_log_schema` セクションをソースオブトゥルースとする)

## リスク

- **リスク 1 (採点コスト 3 倍化)**: best-of-N=3 で API 呼び出しが 3 倍 → 軽減策: `scoring_best_of_n` を config 化して 1 に落とせるフォールバック、リポジトリデフォルトは 3 としつつドキュメントで注意喚起
- **リスク 2 (grep ベースレイヤ境界の誤検知)**: パス正規表現の取りこぼし・過剰検知 → 軽減策: `.sage/architecture.yaml` のサンプル設定を最小限にし、段階採用戦略に従って opt-in で拡張
- **リスク 3 (install.sh 再現性 CI の保守負担)**: `templates/` 編集後に必ず `generate-installer.sh` 再実行が必要になる → 軽減策: エラーメッセージに再生成コマンドを明記、pre-commit hook でも検査
- **リスク 4 (双子文書 drift 検知の偽陰性)**: 節見出しは一致しつつ本文が大きく乖離するケース → 軽減策: 共通節本文の正規化 diff も検査に含める (TASK-0077)

## 実装メモ（Implementation Agent向け）

- 既存 `scripts/sage-validate.sh` は拡張方式で Check を追加 (新規スクリプト乱立を避ける)
- `templates/hooks/` と `.claude/hooks/` の非対称性は SPEC-0003 で文書化済み、本 SPEC では触らない
- 採点ロジックの実装は `.claude/skills/sage-harness/SKILL.md` と `templates/skills/sage-harness/SKILL.md` の両方を更新しないと `generate-installer.sh` 再生成で drift
- Track F の Go サンプルは標準ライブラリのみ使用 (外部依存追加禁止)、`go test -coverprofile` で coverage.out を出力

## 関連ID

- PLAN-ID: PLAN-0008-A, PLAN-0008-B, PLAN-0008-C, PLAN-0008-D, PLAN-0008-E, PLAN-0008-F
- TASK-ID: TASK-0070 〜 TASK-0093
