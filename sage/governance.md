# SAGE Governance v0.1

## 1. 基本原則

### 原則1: 仕様がコードより上位
すべての変更は、仕様変更・仕様追加・仕様削除のいずれかとして扱う。コード単体の変更は存在しない。

### 原則2: AIは仕様を実行する
AIは仕様を解釈・実装・検査するが、仕様なき意思決定主体にはならない。

### 原則3: タスクは小さく独立可能
大きな要求をそのまま1エージェントに投げない。並列実行の前提は分割設計である。

### 原則4: AIは役割で分業する
要件、計画、実装、レビュー、テスト、セキュリティ、運用を分離する。

### 原則5: ルールは実行可能でなければならない
文章だけのルールは補助でしかない。型、lint、schema、policy、CIに落ちて初めて有効である。

### 原則6: コードベースは壊れにくく設計する
契約、依存方向、境界、ディレクトリ責務、生成コード分離を固定する。

### 原則7: 品質は生成ではなく検証で守る
AI出力を信用しない。通すべき検証を増やす。

AI出力は非決定的であり（同一プロンプトで異なるコードが生成される確率75%超）、ベンチマーク精度（HumanEval 99%）と実運用バグ率（41%増）の間には大きな乖離がある。AIが「正しい」と主張すること、またはベンチマークスコアは、検証の代替にならない。

### 原則8: 人間は監督者である
人間の仕事は、仕様策定、優先順位付け、例外判断、承認、改善である。

### 原則9: 開発は観測可能でなければならない
どの仕様から、どのタスクが生まれ、どのAIが何を変更したか追跡できること。

### 原則10: ツールはレイヤ別に選ぶ
エディタ、CLI、オーケストレーション、テスト、セキュリティ、レビュー、知識管理を役割別に構成する。

---

## 2. 標準ライフサイクル（7段階）

### Phase 1: Specify
目的、対象、ユースケース、成功条件、非機能要件、リスク、API契約、データ契約、異常系、監視条件を書く。曖昧な要求を残してはいけない。

### Phase 2: Plan
仕様をアーキテクチャに落とす。どのレイヤを触るのか、影響範囲はどこか、どのエージェントが担当するのか、どんな検証が必要かを決める。

### Phase 3: Slice
仕事を小さい単位に分ける。1タスク1責務を原則とし、依存関係、並列可否、統合順序を明示する。

### Phase 4: Execute
役割分担されたエージェントが実装・レビュー・テスト作成を進める。許可された責務範囲外の変更は禁止する。

### Phase 5: Verify
機械検証を行う。lint、type check、schema validation、unit / integration / e2e test、SAST、secret scan、architecture rule check を通す。

### Phase 6: Merge
検証済み変更だけを統合する。並列変更は順番付きで統合し、衝突解決ルールを持つ。

### Phase 7: Observe
本番観測を行い、仕様との差分やAIの失敗パターンを次回のルール・仕様テンプレへ反映する。

#### 3層計測設計

| 層 | 問い | 計測対象 |
|----|------|---------|
| ログ | What happened? | 各操作の成功/失敗・エラー内容・処理時間 |
| メトリクス | How often / How much? | エラー率・レイテンシ・スループット・カバレッジ推移 |
| アラート | Something wrong? | 閾値超過の自動検知・チーム通知 |

#### フィードバックループ

本番シグナルが次の開発サイクルの起点になる:

```
本番イベント → ログ記録 → 閾値超過 → アラート通知 → SPEC追記 → 修正Wave実行
```

#### Observe フェーズの必須アクション
1. デプロイ後の監視が設定されていることを確認
2. 発生した障害・異常を `sage/failures.md` に記録
3. 繰り返すパターン（3回以上）は `sage/anti-patterns.md` に昇格
4. 計測結果を `.sage/metrics/` に蓄積（Phase D以降）

---

## 3. エージェント責務

### 3.1 Spec Agent
仕様の作成と明確化を担当。曖昧さ、不足、衝突、未定義の異常系を検出する。

### 3.2 Planning Agent
仕様を実装計画に変換。影響レイヤ、必要成果物、依存関係、品質ゲートを整理する。

### 3.3 Task Slicing Agent
計画を小さい作業単位へ落とす。並列可能性を評価し、タスクグラフを作る。

### 3.4 Implementation Agent
許可された範囲で実装を行う。仕様にない振る舞いの追加は禁止する。

### 3.5 Review Agent
責務逸脱、アーキテクチャ違反、仕様不整合、不要複雑化を検出する。

### 3.6 Test Agent
受け入れ条件からテストケースを作成する。正常系だけでなく異常系、境界値、回帰条件も作る。

### 3.7 Security & Policy Agent
秘密情報、脆弱性、権限違反、危険な依存、ポリシー違反を検査する。

### 3.8 Operations Agent
デプロイ準備、監視設定、リリース後観測、インシデント学習を担当する。

### エージェント最小構成（Claude Code単独時）

| 構成 | 役割 |
|------|------|
| Session A | Spec / Planning / TaskSlicing |
| Session B | Implementation |
| Session C | Review / Test |
| CI | Security & Policy |
| Human | Operations（承認・判断） |

---

## 4. エージェント運用ルール

### 4.1 分離原則
同じエージェントが以下を同時に持つのを避ける:
- 実装と最終承認
- 実装とセキュリティ承認
- 実装と本番反映判断

### 4.2 エージェント指示の4必須要素

エージェントへの指示には、以下の4要素を必ず含める。
曖昧な指示はエージェントが合理的な仮定を積み重ね、意図とズレた実装を返す。

| 要素 | 内容 | 悪い例 | 良い例 |
|------|------|--------|--------|
| ① 目標 | 動詞で始め、成果物を明示 | 「認証を実装して」 | 「POST /api/auth/login を実装し、JWTを返す関数を作成」 |
| ② スコープ | 触れるファイルを列挙。「これ以外は変更禁止」と明言 | 「認証周りを修正」 | 「src/auth/login.ts, src/auth/types.ts のみ変更可」 |
| ③ 文脈 | 前フェーズの成果物を直接貼る（スキーマ・型定義等） | 「DBと整合を取って」 | 「以下のスキーマを参照: (SQLを貼付)」 |
| ④ 完了条件 | テストのPass/Failで定義。「動けばいい」は禁句 | 「正しく動くこと」 | 「型エラー0件、make test全件Pass、未認証で401を返す」 |

**暗黙の依存のサイン**: 「〜と整合を取りながら」が指示に出てきたら、ファイル名とインタフェースを明示する。

### 4.3 エージェントへの禁止事項
AIに以下を許可しない:
- スコープ外変更
- サイレント仕様変更
- テスト省略
- 例外系未定義のまま進行
- 既存境界をまたぐ無断修正
- 実行ログなしの変更

### 4.4 Claude Code Hooks

セッション中の自動防御として、以下の5つの hooks を `.claude/settings.json` に設定する:

| Hook | イベント | プロファイル | 動作 |
|------|---------|------------|------|
| block-dangerous-commands | PreToolUse (Bash) | standard+ | `--no-verify`, `--force`, `rm -rf` をブロック |
| protect-sage-files | PreToolUse (Edit\|Write) | standard+ | CLAUDE.md, sage/, .sage/config.yaml の無断変更をブロック |
| check-file-scope | PreToolUse (Edit\|Write) | standard(warn) / strict(block) | TASK の File Scope 外のファイル編集を検出 |
| session-start | SessionStart | minimal+ | 直近 RUN ログ・保留 TASK・failures.md 要約をコンテキストに注入 |
| session-stop | Stop | minimal+ | セッションメトリクスを `.sage/metrics/sessions.jsonl` に記録 |

#### Hook プロファイル

`.sage/config.yaml` の `hooks.profile` で制御:

| プロファイル | Phase | 有効な hooks |
|-------------|-------|------------|
| minimal | Phase A | session-start + session-stop のみ |
| standard | Phase B | minimal + 危険コマンドブロック + SAGE ファイル保護 |
| strict | Phase C+ | standard + File Scope チェックをブロック化 |
| none | — | 全 hooks 無効 |

---

## 5. マルチエージェント競合解決

複数エージェントが同時に作業する場合の優先チェーン:

**Security > Review > Implementation**

- TASK-ID別にブランチを分ける
- マージ競合はReview Agentが判断
- セキュリティ指摘はすべてのマージをブロック

---

## 6. 禁止事項

- 仕様なし実装
- 1回の大きな生成で主要機能を完成させようとすること（Big Bang Prompt）
- 権限境界なしでAIに広範な変更権限を与えること
- 実行ログを残さないこと
- CI未通過の変更を統合すること（Vibe Merge）
- 人の勘だけで本番品質判定を行うこと
- 役割の異なるエージェント責務を曖昧にすること（AI Monolith）
- 生成コードを手で直接修正し続けること

---

## 7. 人間の責務

SAGEにおける人間の責務:

- 目的定義
- 仕様の承認
- 優先順位付け
- リスク判断
- 例外承認
- 最終統合判断
- 失敗学習の反映

人間は**実装者中心**から**開発システムの監督者**へ役割が移る。

---

## 8. 開発レーンとバイブコーディング

SAGEは「仕様なしに実装しない」を原則とするが、変更のリスクと規模に応じて4つのレーンを用意する。
レーンはブランチ命名規約で自動判定される。開発者が明示的にレーンを選ぶ必要はない。

### 8.1 レーン定義

| レーン | ブランチパターン | TASK-ID | SPEC | 必須Gate | 用途 |
|-------|----------------|---------|------|---------|------|
| **explore** | `vibe/*` | 不要 | 不要 | なし | プロトタイプ・PoC・技術検証・UI探索 |
| **lite** | `fix/*`, `chore/*`, `docs/*` | 必須 | 不要 | Gate 1 + 3 + 対象テスト | 低リスク修正（typo fix, 依存更新, ドキュメント修正） |
| **standard** | `feature/*`, その他 | 必須 | 必須 | Gate 1-4 | 本番機能開発・アーキテクチャ変更 |
| **promotion** | `promote/*` | 必須 | Retro-SPEC | Gate 1-4 | explore 成果の昇格と本番統合前の管理 |

#### explore レーン（バイブコーディング）が許される場面
- プロトタイピング・PoC
- 新技術のフィージビリティ確認
- UIの見た目確認・デザイン探索
- 小規模ユーティリティの試作

#### lite レーンの適用条件
以下を**すべて**満たす場合に限り lite レーンで開発できる:
- 変更ファイル数が3以下
- 公開契約（API/DB/イベントスキーマ）の変更を含まない
- セキュリティ要件の変更を含まない

条件を超える場合は standard レーンに切り替えること。

#### standard レーン（SDD）が必須の場面
- 本番システムへのデプロイ
- チーム開発・並列エージェント開発
- 複雑なアーキテクチャ変更
- セキュリティ・コンプライアンス要件

### 8.2 昇格プロトコル（Promotion Gate）

explore レーンの成果物を本番に持ち込む場合、以下の昇格プロトコルに従う。
「探索で書いたコードをそのまま本番に入れる」はアンチパターンとして扱う。

#### 昇格手順

```
vibe/my-feature
    │
    ▼  bash scripts/sage-promote.sh vibe/my-feature
promote/my-feature  ← 新しい管理ブランチ（探索履歴をそのまま正規履歴にしない）
    │
    ├─ 1. Retro-SPEC ドラフト自動生成（diff + commit log から）
    ├─ 2. TASK-ID 付与
    ├─ 3. 人間が Retro-SPEC を確認・承認
    ├─ 4. Gate 1-4 通過
    └─ 5. main へマージ可能
```

#### 昇格ルール
- `vibe/*` ブランチから `main` への直接マージは**禁止**
- `promote/*` ブランチには Retro-SPEC が必須（`sage-validate.sh` で検証）
- Retro-SPEC はドラフト自動生成 + **人間承認で正式化**（自動承認しない）
- 50コミット超の `vibe/*` ブランチは Retro-SPEC の精度が下がるため、手動SPEC作成を推奨

### 8.3 Retro-SPEC（事後仕様）

Retro-SPEC は「探索で得た知見を仕様に変換する」仕組みである。
完全な自動生成ではなく、以下のソースからドラフトを起こし、人間が承認する。

| 入力ソース | 用途 |
|-----------|------|
| `git diff main...HEAD` | 変更差分 → スコープ（含む）の候補 |
| `git log --oneline main..HEAD` | コミット履歴 → 背景・目的の候補 |
| 変更ファイル一覧 | 影響レイヤの推定 |
| テスト実行結果 | 受け入れ条件の候補 |

#### 生成コマンド
```bash
bash scripts/sage-retro-spec.sh [branch-name]
```

### 8.4 ブランチ規約

| ブランチ | 行き先 | 条件 |
|---------|--------|------|
| `vibe/*` | `promote/*` | `sage-promote.sh` で昇格 |
| `fix/*`, `chore/*`, `docs/*` | `main` | TASK-ID + Gate 1 + 3 |
| `feature/*` | `main` | TASK-ID + SPEC + Gate 1-4 |
| `promote/*` | `main` | Retro-SPEC承認 + Gate 1-4 |

- `vibe/*` → `main` 直接マージ禁止（CIで検出・ブロック）
- `promote/*` → `main` は Retro-SPEC 承認後のみ

### 8.5 操作環境別の対応

SAGEのレーン・昇格プロトコルは、以下の3環境すべてで動作する:

| 操作 | 🖥️ ターミナル | 💬 デスクトップアプリ | 🌐 ブラウザアプリ |
|------|-------------|-------------------|----------------|
| レーン確認 | `session-start` hook が自動表示 | `session-start` hook が自動表示 | `session-start` hook が自動表示 |
| ブランチ作成 | `git checkout -b vibe/...` | チャットで「vibe で○○を試したい」 | チャットで「vibe で○○を試したい」 |
| 昇格 | `bash scripts/sage-promote.sh` | `/sage-promote` またはチャット | `/sage-promote` またはチャット |
| Retro-SPEC 生成 | `bash scripts/sage-retro-spec.sh` | `/sage-promote` 内で自動実行 | `/sage-promote` 内で自動実行 |
| Retro-SPEC 補完 | 手動でTBDを埋める | AIがdiffからTBDを自動補完 → 人間承認 | AIがdiffからTBDを自動補完 → 人間承認 |
| Gate 実行 | `bash scripts/sage-validate.sh` | AIが自動実行・結果報告 | AIが自動実行・結果報告 |

#### ターミナルとアプリの責務分離

- **スクリプト** (`scripts/sage-*.sh`): 実際の処理ロジック。どの環境からも呼び出し可能
- **スキル** (`/sage-promote` 等): Claude Code アプリ上の対話的ワークフロー。スクリプトを内部で呼び出す
- **hook** (`session-start`): セッション開始時の自動コンテキスト注入。全環境共通

スクリプトが単一実装（Single Source of Truth）となり、スキルはそのラッパーとして機能する。

---

## 9. SAGE Scope Boundary

> **章の姿勢**: SAGE は「強い」と見せるよりも、「何が SAGE の責務外か」を正直に開示することが、長期的な信頼と correct adoption を生む。本章は SAGE と AI agent runtime tool (Claude Code / Codex 他) の **補完関係** を明示するために設けられた (Phase 1, SPEC-0010)。

### 9.1 SAGE が提供するもの (What SAGE provides)

SAGE は以下の **テンプレート・構造・ルール** を提供する:

| カテゴリ | 提供物 |
|---------|-------|
| ライフサイクル | SPEC / PLAN / TASK テンプレート + ID 採番 (`scripts/sage-id-gen.sh`) + 7-phase protocol (Specify→Plan→Slice→Execute→Verify→Merge→Observe) |
| Quality Gate | Gate 1-5 の構造と CI workflow テンプレート (`.github/workflows/sage-*-gate.yml`) |
| Lane 設計 | vibe / lite / standard / promotion の 4 Lane と昇格プロトコル (`scripts/sage-promote.sh`) |
| File Scope | TASK ごとの変更可能ファイル明示と pre-commit hook |
| Anti-pattern 学習 | `sage/anti-patterns.md`, `sage/failures.md` の蓄積枠組み |
| Hook テンプレート | `templates/hooks/` (block-dangerous-commands / protect-sage-files / check-file-scope / session-start / session-stop / **lethal-trifecta-detect (Phase 2B, warn-only)** / **secret-read-multi-layer (Phase 2B)** / **security-filter (Phase 2B, Stop hook で全 RUN-*.yaml を per-file atomic redact)** / **mcp-allowlist-audit (Phase 5, SessionStart audit-only with supply-chain pin)**) — pattern matching による補助ガード。**agent identity inventory (Phase 5+, SPEC-0017, validator-only)** で declared vs observed runtime drift を検出 |
| Settings template | `templates/settings/sandbox.json` + README (Phase 2B, **雛形のみ — 適用は user 責任**) — Claude Code sandbox / permission 推奨設定 |
| AI agent 向け instruction | CLAUDE.md / AGENTS.md / `.claude/rules/` のテンプレート |
| Skill / governance / traceability | `templates/skills/sage-*/`, 本ドキュメント, `sage/traceability.md` |
| Doctor / repair / report | `scripts/sage-doctor.sh` (Phase 5+ で `[5/6]` RUN log DB check 追加、SPEC-0016), `scripts/sage-repair.sh`, `scripts/sage-report.sh` |
| RUN log 検索基盤 | `scripts/sage-runlog-index.sh` + `scripts/sage-runlog-search.sh` (Phase 5+, SPEC-0016, SQLite FTS5) |
| Installer modular structure | `scripts/generator/` 7 modules + parent `scripts/generate-installer.sh` (Phase 5+, SPEC-0014, byte-identical refactor) |
| Installer supply chain hardening | `.github/workflows/release.yml` + SHA256SUMS publication + URL pinning + `install.sh --verify-checksum --remote` (Phase 6.1, [SPEC-0018](../specs/SPEC-0018-installer-supply-chain-hardening.md)). cosign 署名は SPEC-0019、SLSA は SPEC-0020 |

### 9.2 SAGE が提供しないもの (What SAGE does NOT provide)

⭐ **重要**: SAGE は **runtime enforcement** を提供しない。以下はすべて Claude Code / Codex 本体機能、外部ツール、または運用設計の責任範囲である。

| 項目 | 理由 / 代替手段 |
|-----|-----------------|
| **Claude Code / Codex 本体の runtime sandbox 強制** | filesystem isolation / network allowlist は Claude/Codex 側設定で実現する。SAGE は `templates/settings/` で雛形を示すのみ |
| **Codex セッションでの hook 実行** | `templates/hooks/` は Claude Code の PreToolUse/PostToolUse 機構専用。**Codex セッションでは hook は直接動作しない** — Codex sandbox 設定 (`sandbox_mode` / `approval_policy` / `internet_access`) で同等防御を別途構築する。詳細は [AGENTS.md §2.1 Codex specificity](../AGENTS.md) |
| **MCP server の実行時許可制御** | runtime での起動 block は Claude/Codex 本体機能。**audit / drift / supply-chain pin (sha256 / version_pin / publisher) 検出は [SPEC-0015](../specs/SPEC-0015-mcp-allowlist-audit-and-agent-identity.md) で提供** (audit-only) |
| **GitHub branch protection の自動セットアップ** | GitHub token を要求して installer 権限が肥大化するため、opt-in script として別途提供予定 (SPEC-0012) |
| **Production credential / secret の保管** | Vault / 1Password / GitHub Encrypted Secrets / cloud KMS で別途構築 |
| **AI モデル自体の脆弱性検出・修正** | deterministic security scanner (gitleaks / trivy / semgrep / npm audit 等) と組み合わせる前提。SAGE 単独で safety を保証しない |
| **CVE 検出を block で強制する hook** | pattern matching の限界 (Adversa AI 50+subcommand bypass 等) のため warn-only で起動。block は本体 sandbox の責務 |
| **Codex の sandbox / approval / network access** | Codex CLI / Codex web 設定で実現 (`workspace-write` + `on-request` + domain allowlist 推奨)。SAGE は `AGENTS.md` で prompt-level guidance を示すのみ |
| **Codex GitHub Action の hardening** | OpenAI codex-action security guide と GitHub Actions 設定で実現。SAGE は doc reference のみ提供 |
| **Incident response の運用** | 担当者と連絡網は組織が用意する (SAGE は SECURITY.md にチャネル定義のみ) |

### 9.3 ユーザーが別途用意すべきもの (What you must bring)

SAGE 採用組織は以下を別途構築する:

1. **Claude Code / Codex 本体の最新 version** — CVE-2026-25723 / CVE-2026-33068 / CVE-2025-61260 fix が適用されていること (それぞれ 2.0.55 / 2.1.53 / 0.23.0 以上)
2. **Claude Code / Codex の sandbox 設定** — filesystem denyRead (`~/.ssh`, `~/.aws`, `.env*`, `secrets/`), network allowlist (必要 domain のみ), `bypassPermissions` 禁止, `failIfUnavailable: true`
3. **GitHub branch protection 設定** — required status checks (Gate 1-5 の必要分), 1+ reviewer, signed commits 推奨。人間が GitHub UI または管理 script で実行
4. **secret 管理基盤** — Vault / 1Password / GitHub Encrypted Secrets / cloud KMS
5. **deterministic security scanner** — gitleaks (secret), trivy (dep / fs / image), semgrep (SAST), npm audit / pip-audit / cargo audit (SCA)
6. **Incident response 担当者と連絡網** — SECURITY.md `Reporting a Vulnerability` セクションで指す先
7. **MCP server allowlist** — 利用する MCP server の publisher / SHA / version pin (Phase 5 で SAGE テンプレ提供予定)
8. **Codex 専用 docs** — sandbox mode / approval policy / network / token / codex-action 設定 (SPEC-0014 で SAGE 側 docs 強化予定)

### 9.4 補完関係の図式

```
+-------------------------------+    +----------------------------------+
|   SAGE (this repository)      |    |   Claude Code / Codex (runtime)  |
|                               |    |                                  |
| - SPEC/PLAN/TASK structure    |    | - Sandbox enforcement (filesystem|
| - Quality Gate templates       | <->|   + network)                     |
| - Lane / File Scope / Anti-pat |    | - Permission system (allow/ask/  |
| - Hook templates (warn aux)    |    |   deny + modes)                  |
| - AI instruction templates     |    | - MCP runtime + trust dialog     |
| - failures.md learning loop    |    | - Approval policy (auto/on-req)  |
+-------------------------------+    +----------------------------------+
              |                                       |
              +----------> Combined: Defense in Depth <-----+
                                       |
                                       v
                          + Deterministic scanners (gitleaks/trivy/SAST)
                          + GitHub branch protection (required checks)
                          + Vault / Secret manager
                          + Human review at high-risk action
                          + Incident response procedure
```

### 9.5 採用判断のチェックリスト

組織が SAGE を採用する前に、以下を確認すること:

- [ ] Claude Code / Codex 本体が最新 version (CVE 修正適用済) か
- [ ] sandbox / approval / network access の組織標準を持っているか
- [ ] GitHub branch protection の運用設計があるか
- [ ] secret 管理基盤を持っているか
- [ ] deterministic security scanner を CI に組み込めるか
- [ ] AI 生成コード review の最終承認者が定義されているか
- [ ] Incident response 担当者がいるか
- [ ] 上記が揃わない領域については、SAGE 採用と並行して整備する計画があるか

これらが整わないまま SAGE を導入しても、**SAGE は補助でしかなく、安全保証にはならない**。Phase 1 の正直な開示は、長期的な信頼と correct adoption を生むための投資である。

### 9.6 関連ドキュメント

- [SECURITY.md](../SECURITY.md) — 脆弱性報告手順、threat model、Out of Scope (本章と整合)
- [CONTRIBUTING.md](../CONTRIBUTING.md) — contribution の最小要件と Quality Gate 概要
- [ATTRIBUTION.md](../ATTRIBUTION.md) — 一次ソース・統合知識源
- [CLAUDE.md](../CLAUDE.md) §0 — Claude Code 向け template-trust callout
- [AGENTS.md](../AGENTS.md) §0 — Codex 向け template-trust callout

## 10. AI Agent Doc Pairing Doctrine

[SPEC-0023](../specs/SPEC-0023-claude-collaboration-pairing.md) で formalize された、CLAUDE.md ↔ AGENTS.md 整合性運用ルール。SPEC-0022 (Codex Delegation Packet) → SPEC-0023 (Claude Collaboration Brief) が最初の paired SPEC 事例。

### 10.1 趣旨

Codex / Claude Code は実務上の特性が異なる (delegation vs collaboration、短く速い vs 説明厚い)。SAGE はどちらにも対応するため、**全 rule を identical 維持** ではなく **shared rules / CLI-specific rules を分離** し、CLI-specific guidance の追加に paired-update 手続を要求する。

### 10.2 Shared rules (両 doc で identical 維持必須)

以下は CLAUDE.md / AGENTS.md / templates/{claude,agents}-md-snippet.md 全てで semantic identical を維持する:

- SAGE 7-phase lifecycle (Specify → Plan → Slice → Execute → Verify → Merge → Observe)
- Quality Gate 1-5
- Lane 設計 (vibe / lite / standard / promotion)
- Traceability (SPEC-ID → PLAN-ID → TASK-ID → COMMIT-ID)
- Forbidden Shortcuts
- File Scope rules
- Language rules
- Template-trust callout

### 10.3 CLI-specific rules (divergence 許容)

以下は CLI 別に divergence してよい:

- Codex Delegation Packet (`docs/codex-delegation-packet.md`) — Codex 専用 input 形式
- Claude Collaboration Brief (`docs/claude-collaboration-brief.md`) — Claude 専用 engagement guide
- Hook implementation (templates/hooks/) — Claude Code `PreToolUse`/`PostToolUse` 専用、Codex は AGENTS.md prompt-level guidance で代替
- slash commands (`.claude/skills/`) — Claude Code 専用、Codex には skill 概念なし
- Plan Mode / auto memory / model aliases — Claude Code 専用機能
- Codex sandbox / approval / network 推奨設定 (`docs/codex-security.md`) — Codex CLI/Cloud 専用

### 10.4 Paired-update 要件

CLI-specific guidance を片側 (例: AGENTS.md) に追加する SPEC は、以下のいずれかを満たす必要がある:

1. 同 PR で対側 (CLAUDE.md) を parallel update する (例: SPEC-0022 + SPEC-0023 を同 PR で merge する pattern)
2. 別 SPEC として paired SPEC-ID を起票し、SPEC body に「paired with SPEC-XXXX」を明記する (SPEC-0022 → SPEC-0023 の現実例)
3. 「対側に該当機能なし」を明示する場合は、対側 SPEC の SPEC body に「N/A: <理由>」を 1 文以上で記述する

### 10.5 Drift 検知

`templates/hooks/tests/test-claude-collaboration-pairing.sh` (SPEC-0023 TASK-0155) が CI で常時検証:

- CLAUDE.md / AGENTS.md §2 doctrine が semantic alignment 文言を含む
- claude-md-snippet.md / agents-md-snippet.md に CLI-specific guidance が parallel に存在
- governance.md §10 (本節) の存在
- docs/{codex-delegation-packet, claude-collaboration-brief}.md の必須セクション存在

drift 検出時は CI fail → paired SPEC 起票または対側 update を要求。

### 10.6 例外

CLI 一方にしか存在しない機能 (例: Plan Mode は Claude 専用、Codex App computer use は Codex 専用) は対側 SPEC で「N/A: <理由>」を明示すれば paired 完了とみなす。例: 将来「SPEC-XXXX: Codex App computer use guide」が起票された場合、Claude 側 paired SPEC は「N/A: Claude Code には computer use 機能がないため」と SPEC body に記述すれば doctrine 遵守。
