# SPEC-0004: Install Lifecycle + AI Control Plane監査

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0004 |
| ステータス | Draft |
| 作成日    | 2026-04-10 |
| 更新日    | 2026-04-10 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0001, SPEC-0003 |
| 権限レベル | system |

## 背景・目的

### 問題1: Install Lifecycle の欠如 (P1b)

`install.sh` はファイルを一度デプロイするが、以下の機能が欠けている:
- インストール後のファイル破損・削除を検知する手段がない
- どのバージョンがどのファイルをインストールしたかの記録がない
- 部分的な修復（特定ファイルだけ再生成）ができない
- `install.sh --update` は全ファイルを再デプロイするため、ユーザーのカスタマイズが上書きされるリスクがある

### 問題2: AI Control Plane の監査不在 (P2)

`sage-validate.sh` は CLAUDE.md の10必須セクション存在確認とテンプレートフィールド検証を行うが、AI制御ファイルのセキュリティを監査していない:
- CLAUDE.md やプロンプトファイル (`.claude/prompts/`) にシークレット（API キー、トークン）が混入していないか
- `.claude/settings.json` に過剰な権限（`allow: ["*"]` など）が設定されていないか
- hook スクリプトに危険なコマンド（`curl | bash`、`eval` + 外部入力）が含まれていないか

SAGEの本体は src/ ではなく AI 制御ファイルである。コードのセキュリティスキャン（Gitleaks/Trivy）は「コードが本体のプロジェクト」向けの防御であり、SAGEには「設定が本体のプロジェクト」向けの監査が必要。

## 対象ユーザー

SAGEを導入済みのプロジェクトの開発者。SAGEテンプレートのメンテナ。

## スコープ（含む）

- `scripts/sage-doctor.sh` （新規作成）-- インストール健全性 + AI制御ファイルセキュリティの診断
- `scripts/sage-repair.sh` （新規作成）-- 検出された問題の自動修復
- `scripts/sage-report.sh` （新規作成）-- 採用メトリクス集計
- `.sage/install-state.yaml` （新規作成・自動生成）-- インストール状態の記録ファイル
- `install.sh` / `scripts/generate-installer.sh` -- インストール完了時に `.sage/install-state.yaml` を生成するロジックの追加
- `scripts/sage-validate.sh` -- AI control plane チェック（セクション [7/8] として追加）
- `makefile` -- `make doctor` / `make repair` / `make report` コマンドの追加

## スコープ外（明示的に除外）

- SAGE ファイルのバックグラウンド自動アップデート機能（`sage-update-check.sh` の改善は別 SPEC）
- `.sage/install-state.yaml` の暗号化・署名（SHA256 チェックサムで十分）
- AI プロンプトの内容品質の評価（インジェクション検知は含むが「良いプロンプトか」の判定は含まない）
- サードパーティ MCP サーバーの監査
- リモートバージョンとの比較（`sage-update-check.sh` が担当。本SPECはローカル健全性のみ）

## 要件

### 機能要件

#### sage-doctor.sh
- [FR-01] ファイル存在チェック: `.sage/install-state.yaml` に記録された全ファイルの存在を確認する。欠損ファイルを一覧表示
- [FR-02] ファイル整合性チェック: SAGE が管理するファイル（`managed: true`）のSHA256チェックサムを `.sage/install-state.yaml` の記録と比較する
- [FR-03] AI Control Plane セキュリティチェック:
  - シークレット検出: CLAUDE.md, `.claude/prompts/*`, `templates/` 内のファイルを正規表現スキャン（Gitleaks互換パターン）
  - 権限チェック: `.claude/settings.json` の `permissions.allow` に `*` や過度に広いパターンがないか
  - フック安全性: hook スクリプトに `curl | bash`, `eval "$EXTERNAL"`, `wget -O - | sh` 等の危険パターンがないか
  - コマンド設定チェック: `.sage/config.yaml` の `project_checks.*` にパイプライン + ネットワークアクセスの組み合わせがないか
- [FR-04] 診断結果のサマリー出力: OK / WARN / FAIL の3段階で各チェック結果を表示する。全体の exit code は FAIL が1件以上で exit 1
- [FR-05] `--json` オプションで JSON 形式の診断結果を出力する
- [FR-06] `--check-only` オプションで修復提案なしの診断のみ実行する
- [FR-07] WARN/FAIL 検出時、`sage/failures.md` へのappend候補を stderr に出力する（FAIL-IDテンプレート形式）
- [FR-08] 診断結果を `.sage/metrics/doctor-history.jsonl` に1行のJSONとして追記する（同一パターンの検出回数追跡用）

#### sage-repair.sh
- [FR-09] 欠損ファイルの復元: `.sage/install-state.yaml` の記録を参照し、テンプレートからファイルを再生成する
- [FR-10] 改ざんされた SAGE 管理ファイル（`managed: true`）の復元: ユーザーに確認プロンプトを表示し、承認後に再生成する
- [FR-11] セキュリティ問題の自動修正:
  - `.claude/settings.json` の `permissions.allow: ["*"]` を `permissions.allow: []` に修正（確認プロンプト付き）
  - 検出されたシークレットのマスク表示（自動削除はしない。ユーザーに手動修正を促す）
- [FR-12] `--dry-run` オプションで修復内容のプレビューのみ表示する
- [FR-13] `--file <path>` オプションで特定ファイルのみ修復する

#### sage-report.sh
- [FR-14] `sessions.jsonl` からセッション数を集計する
- [FR-15] `doctor-history.jsonl` から FAIL イベント数を集計する
- [FR-16] 合格基準に基づきステータスを表示する:
  - 10セッション未満: "INSUFFICIENT DATA"
  - FAIL 0件: "HEALTHY"
  - FAIL 再発: "WARN (recurring failures)"
- [FR-17] `doctor-history.jsonl` の直近14日間に FAIL が0件の場合、"READY FOR STRICT" を出力する

#### install-state
- [FR-18] `install.sh` 実行完了時に `.sage/install-state.yaml` を生成する
- [FR-19] `install.sh --update` 実行時に、`managed: false` のファイルは上書きせず、差分がある場合は `.sage/backup/` にバックアップしてから更新する

#### sage-validate.sh 拡張
- [FR-20] 新セクション `[7/8] AI Control Plane セキュリティチェック` を追加。sage-doctor.sh のセキュリティチェック（FR-03）のサブセットを実行する

### 非機能要件
- [NFR-01] sage-doctor.sh の実行時間: 1000ファイル以下のリポジトリで 5 秒以内
- [NFR-02] sage-repair.sh は対話的確認なしに既存ファイルを上書きしない（`--yes` フラグで確認スキップ可能）
- [NFR-03] `.sage/install-state.yaml` のファイルサイズは SAGE 管理ファイル 100 件で 10KB 以下

### セキュリティ要件
- [SEC-01] sage-doctor.sh のシークレット検出パターンは Gitleaks の基本ルールセットと互換にする
- [SEC-02] sage-repair.sh は root 権限で実行された場合にエラー終了する（意図しない権限昇格の防止）
- [SEC-03] `.sage/install-state.yaml` に記録されるのはファイルパスとハッシュのみ。ファイル内容は含めない

### 運用要件
- [OPS-01] `make doctor` で `bash scripts/sage-doctor.sh` を実行
- [OPS-02] `make repair` で `bash scripts/sage-repair.sh` を実行
- [OPS-03] `make report` で `bash scripts/sage-report.sh` を実行
- [OPS-04] sage-doctor.sh のチェック結果は sage-validate.sh と同じフォーマット（OK / MISSING / FAIL プレフィックス）で出力する

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `make doctor` を実行し、正常なインストール状態で exit code 0 + "ALL CHECKS PASSED" メッセージが表示される
- [ ] AC-02: SAGE 管理ファイル（例: `sage/governance.md`）を削除した後に `make doctor` を実行すると、"MISSING: sage/governance.md" が表示され exit code 1 となる
- [ ] AC-03: `make repair` を実行した後、削除されたファイルが復元され、再度 `make doctor` が exit code 0 を返す
- [ ] AC-04: CLAUDE.md に `api_key = "sk-test123"` を追記した後に `make doctor` を実行すると、"WARN: potential secret detected in CLAUDE.md" が表示される
- [ ] AC-05: `.claude/settings.json` に `"allow": ["*"]` を設定した後に `make doctor` を実行すると、"FAIL: overly permissive allow rule in settings.json" が表示される
- [ ] AC-06: `bash install.sh` 実行後に `.sage/install-state.yaml` が存在し、`yq '.version' .sage/install-state.yaml` が SAGE_VERSION と一致する
- [ ] AC-07: `make validate` を実行し、AI Control Plane チェックセクションが含まれ、引き続き ALL PASSED を返す（回帰なし）
- [ ] AC-08: `bash scripts/sage-repair.sh --dry-run` が実際のファイル変更を行わない
- [ ] AC-09: `.sage/install-state.yaml` が存在しない場合、doctor が "install-state.yaml not found" + exit 1
- [ ] AC-10: `sage-repair.sh` でテンプレートソースが見つからない場合、明示的エラーメッセージ + exit 1
- [ ] AC-11: `make report` が10セッション未満の場合 "INSUFFICIENT DATA" + exit 0
- [ ] AC-12: `make report` が `doctor-history.jsonl` 不在の場合でも exit 0
- [ ] AC-13: `doctor-history.jsonl` の直近14日間に FAIL が0件の場合、`make report` が "READY FOR STRICT" を出力する

## 異常系

- `.sage/install-state.yaml` が存在しない場合: sage-doctor.sh は "install-state.yaml not found. Run 'bash install.sh' first." を表示して exit 1
- `.sage/install-state.yaml` の YAML が不正な場合: パースエラーメッセージを表示して exit 1
- sage-repair.sh でテンプレートソースが見つからない場合: "Cannot restore: template source not available. Re-run install.sh" を表示
- ファイルのチェックサムが不一致だが `managed: false` の場合: "INFO: user-customized file differs from template (expected)" として WARN にしない
- macOS と Linux で sha256 コマンドが異なる場合: `sha256sum` (Linux) / `shasum -a 256` (macOS) を自動検出
- `doctor-history.jsonl` が存在しない場合: sage-report.sh は "No history data" と表示して exit 0
- `sessions.jsonl` が存在しない場合: sage-report.sh は "No session data" と表示して exit 0

## 契約

- API: なし
- DB: なし
- イベント:
  - `.sage/install-state.yaml` -- YAML 形式
  - `.sage/metrics/doctor-history.jsonl` -- JSONL 形式
  - `.sage/metrics/sessions.jsonl` -- JSONL 形式（SPEC-0003 で定義済み、本SPECでは読み取りのみ）

## リスク

- リスク1: install-state.yaml のチェックサム不一致がユーザーの正当なカスタマイズと区別できない -> 軽減策: `managed: true/false` フラグで区別
- リスク2: シークレット検出の false positive が多い -> 軽減策: 検出パターンを保守的に設定
- リスク3: sage-repair.sh がユーザーの意図しないファイル上書きを行う -> 軽減策: 対話的確認を必須化。`--dry-run` でプレビュー。`.sage/backup/` にバックアップ
- リスク4: generate-installer.sh の変更で install.sh のサイズが増加する -> 軽減策: install-state 生成ロジックは軽量（SHA256 計算 + YAML 生成のみ）

## 実装メモ（Implementation Agent向け）

- SHA256 クロスプラットフォーム対応: `command -v sha256sum` で Linux を、`command -v shasum` で macOS を検出
- sage-doctor.sh のシークレット検出パターン: `(api[_-]?key|secret[_-]?key|access[_-]?token|password|credential)\s*[:=]\s*["']?[A-Za-z0-9+/=_-]{8,}` を `grep -rEn` で検索
- install-state.yaml の生成は install.sh の最終ステップ。`generate-installer.sh` の出力に `finalize()` 関数を追加
- sage-repair.sh は install.sh の埋め込みテンプレート変数（`TMPL_SPEC` 等）と同じ仕組みを使って復元
- makefile への追加: `doctor`, `repair`, `report` ターゲットを `.PHONY` に追加（既存パターン参照）
- sage-validate.sh の拡張: 既存の6セクション構造に `[7/8]` を追加し、カウンターを全体で 8 に変更
- doctor-history.jsonl のスキーマ: `{"timestamp":"ISO8601","level":"OK|WARN|FAIL","checks":{"files":N,"security":N},"details":[...]}`

### CLAUDE.md追記ルール
- doctor の WARN/FAIL は `sage/failures.md` に自動 append 候補として出力する（手動承認後に記録）
- repair.sh は対話的確認なしに既存ファイルを上書きしない（`--yes` でスキップ可能）
- install-state.yaml にはファイルパスとハッシュのみ記録（ファイル内容は含めない）

### failures.md 更新フロー
- **更新タイミング**: `make doctor` で WARN/FAIL が出た PR のマージ前
- **更新責任者**: PR 作成者（レビュアーではない）
- **手順**:
  1. `make doctor` の stderr 出力を確認
  2. append 候補の FAIL-ID テンプレートをコピー
  3. `sage/failures.md` に手動で追記してコミット
  4. 同一 FAIL-ID が 3回以上 `doctor-history.jsonl` に記録されたら `anti-patterns.md` 昇格を PR コメントで提案
- **スキップ条件**: WARN のみ（FAIL なし）の場合は任意

## 関連ID

- PLAN-ID: PLAN-0004
- TASK-ID: TASK-0045 〜 TASK-0053
