# SAGE Development System

> **S**pec-driven, **A**gent-governed, **G**uard-railed, **E**volving

複数のAIエージェントが同時にコードを書く環境で、**人間の規律に頼らずアーキテクチャで品質を保証する**開発体系。

---

## なぜ SAGE が必要か

従来の「人間がレビューで品質を守る」方式は、AIエージェントの並列開発では機能しない。

```
❌ 従来：人間の規律 → レビューが追いつかない → 品質崩壊
✅ SAGE：構造が強制 → AIが勝手に守る → 品質維持
```

SAGEは「AIにうまくコードを書かせるテクニック集」ではない。
**AIが逸脱しにくい構造を先に作る技術**。

---

## アーキテクチャ全体図

```mermaid
graph TB
    subgraph L1["🟢 L1: Foundation"]
        CM["CLAUDE.md"]
        AM["AGENTS.md"]
    end

    subgraph L2["🟡 L2: Context-Aware"]
        R1["specs-rules.md"]
        R2["plans-rules.md"]
        R3["tasks-rules.md"]
        R4["src-rules.md"]
        R5["governance-rules.md"]
    end

    subgraph L3["🔵 L3: On-Demand"]
        S1["sage-spec"]
        S2["sage-plan"]
        S3["sage-review"]
        S4["sage-evaluate"]
        S5["sage-harness"]
    end

    subgraph L4["🔴 L4: Enforcement"]
        H4["Claude Code Hooks"]
        H1["commit-msg hook"]
        H2["CI Gate"]
        H3["Quality Gates"]
    end

    CM --> R1
    CM --> R2
    CM --> R3
    CM --> R4
    CM --> R5
    R1 --> S1
    R2 --> S2
    R3 --> S1
    R4 --> S3
    S1 --> S4
    S2 --> S4
    S5 -->|"オーケストレーション"| S1
    S5 --> S2
    S5 --> S3
    S5 --> S4
    S5 -->|"全Phase通過"| H1
    H1 --> H2
    H2 --> H3
```

### 4層ガードレール構造

| 層 | 名前 | 役割 | いつ動くか |
|----|------|------|-----------|
| 🟢 **L1** | **Foundation** | CLAUDE.md / AGENTS.md。AIが最初に読む「憲法」 | **毎セッション自動** |
| 🟡 **L2** | **Context-Aware** | `.claude/rules/`。パス別の詳細ルール | **該当ファイル操作時のみ** |
| 🔵 **L3** | **On-Demand** | `.claude/skills/`。ワークフロー + 自動採点 + ハーネス | **`/sage-spec` `/sage-harness` 等で呼んだ時のみ** |
| 🔴 **L4** | **Enforcement** | Claude Code hooks + commit-msg hook + CI Gate + Quality Gates | **セッション中＋コミット・PR時に機械強制** |

---

## 開発ライフサイクル

```mermaid
graph LR
    A["📝 Specify<br/>仕様定義"] --> B["📐 Plan<br/>実装計画"]
    B --> C["✂️ Slice<br/>タスク分割"]
    C --> D["⚡ Execute<br/>実装"]
    D --> E["✅ Verify<br/>検証"]
    E --> F["🔀 Merge<br/>統合"]
    F --> G["👁️ Observe<br/>観察"]
    G -.->|フィードバック| A

    style A fill:#e8f5e9,stroke:#4caf50,color:#000
    style B fill:#e8f5e9,stroke:#4caf50,color:#000
    style C fill:#fff8e1,stroke:#ff9800,color:#000
    style D fill:#fff8e1,stroke:#ff9800,color:#000
    style E fill:#e3f2fd,stroke:#2196f3,color:#000
    style F fill:#e3f2fd,stroke:#2196f3,color:#000
    style G fill:#fce4ec,stroke:#e91e63,color:#000
```

### 採点・修正ループ（Evaluator Read-Only + Creator Agent 修正）

`/sage-harness` がオーケストレーターとして、Evaluator（採点のみ）と Creator Agent（修正のみ）を分離制御する。**同一エージェントが採点と修正を兼務しない**。

```mermaid
graph TD
    START["SPEC/PLAN 作成完了"] --> EVAL["Evaluator（Read-Only）<br/>6軸で採点 → eval_feedback YAML"]
    EVAL --> CHECK{100点?}
    CHECK -->|No| FIX["Creator Agent が<br/>fix_instructions に従い修正"]
    FIX --> EVAL
    CHECK -->|Yes| DONE["✅ 実装開始可能"]

    style START fill:#e8f5e9,stroke:#4caf50,color:#000
    style EVAL fill:#fff8e1,stroke:#ff9800,color:#000
    style CHECK fill:#e3f2fd,stroke:#2196f3,color:#000
    style FIX fill:#fce4ec,stroke:#e91e63,color:#000
    style DONE fill:#d4edda,stroke:#28a745,color:#000
```

| 軸 | 満点 | 何を見るか |
|----|------|-----------|
| ① Codified Rules | **20点** | CLAUDE.md連携・Forbidden Shortcuts・機械的ゲート |
| ② Atomic Decomposition | **20点** | タスク独立性・依存グラフ・完了条件 |
| ③ Spec-Driven Development | **20点** | SPEC-ID・受け入れ条件・エラーケース |
| ④ Observable Development | **20点** | 検証コマンド・テスト種別・フィードバック |
| ⑤ Knowledge Management | **15点** | failures.md連携・Error Resolution |
| ⑥ 段階採用戦略 | **5点** | 影響ゼロ設計・ロールバック手順 |

| スコア | グレード | 判定 |
|--------|---------|------|
| **100** | 🏆 S++ | 完璧。即実装可 |
| 95-99 | ⭐ S+ | ほぼ完成。微修正で到達可能 |
| 90-94 | ✨ S | 優秀。小改善あり |
| 85-89 | 🔹 A- | 良好。改善推奨 |
| 70-84 | 🔸 B | 基本OK。要改善 |
| ~69 | ⚠️ C | 大幅改善必要 |

---

## 導入方法

> **⚠️ Trust First**: SAGE installer は約 364KB の large generated shell script (source は SPEC-0014 で `scripts/generator/` 7 module に分割済、配布は単一 file 維持) で、`.git/hooks` / `.github/workflows` / `.claude/settings.json` 等を一括書き換えます。**未検証で実行しないでください**。Phase 1 (SPEC-0010) で provenance 表示と dry-run プレビューを実装済みです — 下記の推奨手順 (Step 1A) を使ってください。詳細は [SECURITY.md](SECURITY.md) を参照。

### Step 1A: 推奨手順 (download → verify → preview → review → execute)

```bash
cd /path/to/your-project

# 1. Download (実行はしない)
curl -fsSL -o install.sh https://gist.githubusercontent.com/heidayo/98c36fbaf41cc5170b071b21bde3bb51/raw/install.sh

# 2. Verify provenance (SHA256 / 由来 / ライセンス確認)
bash install.sh --print-provenance

# 3. Preview without writing (dry-run で副作用なし内容確認)
bash install.sh --dry-run

# 4. (任意) install.sh 自体を読む / shellcheck で検査
less install.sh
shellcheck install.sh

# 5. Execute
bash install.sh

# 6. Post-install drift detection (任意・推奨)
bash install.sh --verify-checksum
```

### Step 1B: 一行導入 (隔離環境・dev container 等で sandbox 済の場合のみ)

> 上記 Step 1A の verify / preview / review を省略するため、**未検証 repository / 本番開発端末では非推奨** です。

```bash
cd /path/to/your-project
curl -fsSL https://gist.githubusercontent.com/heidayo/98c36fbaf41cc5170b071b21bde3bb51/raw/install.sh | bash
```

または既に repository を clone 済の場合:

```bash
bash install.sh
```

### Step 2: 完了

これだけです。以下が自動セットアップされます：

```
your-project/
├── 🟢 CLAUDE.md              ← AI が毎セッション自動で読む
├── 🟢 AGENTS.md              ← Codex が自動で読む
├── 🟡 .claude/rules/         ← パス別ルール（5ファイル）
├── 🔵 .claude/skills/        ← ワークフロー（5スキル）
├── 📝 specs/                 ← SPEC テンプレート
├── 📐 plans/                 ← PLAN テンプレート
├── ✂️  tasks/                 ← TASK テンプレート
├── 📜 sage/                  ← ガバナンス文書
├── 📜 templates/hooks/     ← Claude Code hooks（5スクリプト）
├── 🔴 .git/hooks/commit-msg  ← TASK-ID 強制
├── ⚙️  .sage/install-state.yaml ← インストール状態記録
└── ⚙️  scripts/               ← ID生成・検証
```

### Step 3: 普通に開発を始める

```mermaid
sequenceDiagram
    participant Dev as 👤 開発者
    participant AI as 🤖 AI Agent
    participant SAGE as 📜 SAGE

    Dev->>AI: 「お気に入りボタンを追加して」
    AI->>SAGE: CLAUDE.md を読む
    SAGE-->>AI: SPECなしの実装は禁止
    AI->>Dev: 「SPECが見つかりません。<br/>まず仕様を整理しましょう」
    Dev->>AI: /sage-harness で自律開発を開始
    AI->>SAGE: Spec Agent → Evaluator（Read-Only採点）
    SAGE-->>AI: eval_feedback → Creator Agent が修正 → 100点到達 ✅
    AI->>SAGE: Implementation → Test → Review（3エージェント分離）
    SAGE-->>AI: review_feedback → 全Gate通過 ✅
    AI->>Dev: 「実装完了。PRの準備ができています」
```

---

## AIエージェントでの運用

### セッション分離（必須）

```mermaid
graph LR
    A["🅰️ 仕様セッション<br/>SPEC + PLAN + TASK"]
    B["🅱️ 実装セッション<br/>src/ のみ"]
    T["🅲️ テストセッション<br/>tests/ のみ"]
    C["🅳️ レビューセッション<br/>Read-Only 採点"]

    A -->|"Evaluator 100点"| B
    B --> T
    T --> C
    C -.->|"fix_scope で振り分け"| B
    C -.->|"fix_scope で振り分け"| T

    style A fill:#e8f5e9,stroke:#4caf50,color:#000
    style B fill:#fff8e1,stroke:#ff9800,color:#000
    style T fill:#e8eaf6,stroke:#5c6bc0,color:#000
    style C fill:#e3f2fd,stroke:#2196f3,color:#000
```

| セッション | 役割 | 使うスキル | Write権限 | 禁止事項 |
|-----------|------|-----------|----------|---------|
| 🅰️ **仕様** | SPEC・PLAN・TASKを作る | `/sage-spec` `/sage-plan` | specs/, plans/, tasks/ | コードを書かない |
| 🅱️ **実装** | TASKのFile Scopeに従って実装 | — | src/（File Scope内） | tests/, specs/ を触らない |
| 🅲️ **テスト** | テストを作成・修正 | — | tests/ | src/ を修正しない |
| 🅳️ **レビュー** | 6軸100点で採点 + Gate実行 | `/sage-review` | NONE | コードを一切修正しない |

> **鉄則**: 同じセッションで実装とレビューを行わない。`/sage-harness` はこの分離を自動で制御する

---

## 開発レーン（Lanes）

変更のリスクと規模に応じて4つのレーンを用意。ブランチ名で**自動判定**される。

```mermaid
graph LR
    subgraph EXPLORE["🟢 explore"]
        V["vibe/*<br/>TASK-ID不要・Gate免除"]
    end

    subgraph LITE["🟡 lite"]
        F["fix/* chore/* docs/*<br/>TASK-ID必須・Gate 1+3"]
    end

    subgraph STANDARD["🔵 standard"]
        FE["feature/* その他<br/>TASK-ID+SPEC必須・Gate 1-4"]
    end

    V -->|"sage-promote.sh"| P["promote/*<br/>昇格プロトコル"]
    P --> FE

    style EXPLORE fill:#d4edda,stroke:#28a745,color:#000
    style LITE fill:#fff3cd,stroke:#ffc107,color:#000
    style STANDARD fill:#cce5ff,stroke:#007bff,color:#000
    style P fill:#f8d7da,stroke:#dc3545,color:#000
```

| レーン | ブランチ | TASK-ID | SPEC | 必須Gate | 用途 |
|-------|---------|---------|------|---------|------|
| 🟢 **explore** | `vibe/*` | 不要 | 不要 | なし | プロトタイプ・PoC・技術検証 |
| 🟡 **lite** | `fix/*` `chore/*` `docs/*` | 必須 | 不要 | Gate 1 + 3 | typo fix・依存更新・ドキュメント修正 |
| 🔵 **standard** | `feature/*` その他 | 必須 | 必須 | Gate 1-4 | 本番機能開発 |
| 🔴 **promotion** | `promote/*` | 必須 | Retro-SPEC | Gate 1-4 | explore 成果の昇格と本番統合前の管理 |

### 昇格プロトコル（explore → promotion → standard）

探索で得た成果を本番に持ち込むには、昇格プロトコルを通す。
操作環境に応じて3つの方法がある:

| 環境 | 操作方法 |
|------|---------|
| 🖥️ **ターミナル** | `bash scripts/sage-promote.sh vibe/my-feature` |
| 💬 **デスクトップアプリ** (Claude Code) | `/sage-promote` またはチャットで「本番に持っていきたい」 |
| 🌐 **ブラウザアプリ** (Claude Code) | `/sage-promote` またはチャットで「昇格して」 |

```mermaid
sequenceDiagram
    participant Dev as 👤 開発者
    participant AI as 🤖 Claude Code
    participant SAGE as 📜 SAGE

    Dev->>AI: 「vibe/auth-poc を本番に持っていきたい」
    AI->>SAGE: sage-promote.sh 実行
    SAGE-->>AI: promote/* ブランチ作成 + Retro-SPEC ドラフト
    AI->>AI: diff + commit log から TBD を自動補完
    AI->>Dev: 「Retro-SPEC を確認してください」
    Dev->>AI: 「OK」
    AI->>SAGE: Gate 1-4 実行
    SAGE-->>AI: ALL PASSED ✅
    AI->>Dev: 「PR の準備ができました」
```

`vibe/*` → `main` への直接マージは禁止。必ず `promote/*` を経由する。

### セッション開始時の自動レーン通知

どの環境でも、セッション開始時に `session-start` hook が現在のレーンを自動表示する:

```
--- Current Lane ---
  Branch: vibe/auth-poc
  Lane:   🟢 explore
  Rules:  Free exploration. No SPEC, no TASK-ID, no gates required.
```

AIはこの情報を読み取り、レーンに応じた行動を自動で切り替える。

---

## 核心思想

| # | 原則 | 説明 |
|---|------|------|
| 1 | 📝 **仕様が最上位の真実** | コードは成果物であり、真実ではない |
| 2 | 🤖 **AIは制約内の実行者** | 仕様・役割・権限・制約・検証の中で働く |
| 3 | ✅ **品質は検証から生まれる** | モデルの優秀さではなく、構造と検証の強さ |
| 4 | ✂️ **並列化は分割設計** | AIを増やすのではなく、責務を分けて粒度を整える |
| 5 | 👤 **人間は監督者** | 目的定義・仕様承認・優先順位・例外判断・最終責任 |

---

## ディレクトリ構成

```
.
├── 🟢 CLAUDE.md                    # Claude Code 向けのブートストラップ
├── 🟢 AGENTS.md                    # Codex向けルール
│
├── 🟡 .claude/
│   ├── rules/                      # パス別ルール（自動ロード）
│   │   ├── specs-rules.md          # specs/** 操作時
│   │   ├── plans-rules.md          # plans/** 操作時
│   │   ├── tasks-rules.md          # tasks/** 操作時
│   │   ├── src-rules.md            # src/** app/** 操作時
│   │   └── sage-governance-rules.md # sage/** 操作時
│   │
│   └── skills/                     # オンデマンドワークフロー
│       ├── 🔵 sage-spec/           # /sage-spec → SPEC作成
│       ├── 🔵 sage-plan/           # /sage-plan → PLAN+TASK作成
│       ├── 🔵 sage-review/         # /sage-review → コードレビュー（6軸100点）
│       │   └── references/         # コードレビュー採点基準
│       ├── 🔵 sage-evaluate/       # /sage-evaluate → SPEC/PLAN採点（Read-Only）
│       │   └── references/         # SPEC/PLAN採点基準・知識ベース
│       └── 🔵 sage-harness/        # /sage-harness → 自律開発オーケストレーター
│
├── 📜 templates/                    # テンプレート・フック
│   └── 📜 hooks/                   # Claude Code hooks（5スクリプト）
│
├── 📝 specs/                       # SPEC-XXXX 仕様書
├── 📐 plans/                       # PLAN-XXXX 実装計画
├── ✂️  tasks/                       # TASK-XXXX タスク定義
├── 📜 sage/                        # ガバナンス文書（人間の承認が必要）
├── ⚙️  scripts/                     # ID生成・検証・公開スクリプト
│   ├── sage-doctor.sh              # SAGE健全性チェック
│   ├── sage-repair.sh              # ファイル修復
│   └── sage-report.sh              # 採用メトリクス
├── 🔴 .git/hooks/                  # commit-msg hook（TASK-ID強制）
├── 🔧 .sage/                       # ランタイム設定・実行ログ
│   ├── install-state.yaml          # インストール状態記録
│   └── metrics/                    # 採用メトリクスデータ
└── 🔴 .github/                     # CI/CDワークフロー
```

---

## カスタマイズと更新の共存

```mermaid
graph TD
    subgraph SAFE["✅ 安全（更新で消えない）"]
        A["CLAUDE.md<br/>SAGEマーカーの上"]
        B[".claude/rules/<br/>別名ファイル"]
        C[".claude/skills/<br/>別名ディレクトリ"]
        D[".sage/config.yaml"]
        E["sage/failures.md"]
    end

    subgraph DANGER["⚠️ 上書きされる（編集禁止）"]
        F["specs-rules.md 等<br/>SAGE管理の5ルール"]
        G["sage-spec/ 等<br/>SAGE管理の5スキル"]
        H["sage/*.md<br/>ガバナンス文書"]
        I["scripts/sage-*.sh"]
    end

    style SAFE fill:#d4edda,stroke:#28a745,color:#000
    style DANGER fill:#f8d7da,stroke:#dc3545,color:#000
```

| やりたいこと | やり方 | 更新時 |
|:------------|:-------|:------:|
| プロジェクト固有ルールを追加 | CLAUDE.md のSAGEマーカーより**上**に書く | ✅ 安全 |
| パス別ルールを追加 | `.claude/rules/` に**別名で**ファイル作成 | ✅ 安全 |
| スキルを追加 | `.claude/skills/` に**別名で**ディレクトリ作成 | ✅ 安全 |
| SAGE管理ファイルを直接編集 | **やらない** | ❌ 消える |

---

## 更新方法

### 更新通知（推奨）

`.sage/config.yaml` に `installer_url` を設定するだけ：

```yaml
auto_update:
  installer_url: "https://gist.githubusercontent.com/heidayo/98c36fbaf41cc5170b071b21bde3bb51/raw/install.sh"
```

```mermaid
graph LR
    A["🤖 セッション開始"] --> B["sage-update-check.sh"]
    B --> C{今日チェック済み?}
    C -->|Yes| D["スキップ"]
    C -->|No| E["Gist からバージョン取得"]
    E --> F{新バージョン?}
    F -->|No| G["最新です"]
    F -->|Yes| H["更新通知を表示"]

    style A fill:#e8f5e9,stroke:#4caf50,color:#000
    style H fill:#fff8e1,stroke:#ff9800,color:#000
    style D fill:#f5f5f5,stroke:#9e9e9e,color:#000
    style G fill:#f5f5f5,stroke:#9e9e9e,color:#000
```

新バージョンが見つかった場合も、このスクリプトは remote installer を自動実行しません。通知を見てから、手動で更新します。

### 手動更新

```bash
bash install.sh
```

---

## 既存 CLAUDE.md がある場合

初回導入時に既存ルールを自動監査します。

```mermaid
graph TD
    A["install.sh 実行"] --> B{CLAUDE.md<br/>は存在する?}
    B -->|No| C["新規作成"]
    B -->|Yes| D{SAGEセクション<br/>は存在する?}
    D -->|Yes| E["SAGEセクションだけ置換"]
    D -->|No| F["🔍 監査レポート生成<br/>.sage/adoption-audit.md"]
    F --> G["SAGEセクションを追記"]

    style F fill:#fff8e1,stroke:#ff9800,color:#000
    style C fill:#d4edda,stroke:#28a745,color:#000
    style E fill:#e3f2fd,stroke:#2196f3,color:#000
```

### 監査レポートの3区分

| 区分 | 意味 | 対応 |
|:-----|:-----|:-----|
| ✅ **SAFE_AUTO_APPLY** | SAGEと無関係 | 何もしなくてOK |
| 🟡 **NEEDS_REVIEW** | SAGEと重複の可能性 | 手動で確認、重複を削除 |
| 🔴 **CONFLICT** | SAGEと矛盾の可能性 | **手動で解決が必要** |

---

## 導入フェーズ

`install.sh` は Phase A を自動セットアップします。

```mermaid
graph LR
    A["🟢 Phase A<br/>Foundation"] --> B["🟡 Phase B<br/>Guardrails"]
    B --> C["🔵 Phase C<br/>Multi-Agent"]
    C --> D["🟣 Phase D<br/>Learning System"]

    style A fill:#d4edda,stroke:#28a745,color:#000
    style B fill:#fff3cd,stroke:#ffc107,color:#000
    style C fill:#cce5ff,stroke:#007bff,color:#000
    style D fill:#e8daef,stroke:#8e44ad,color:#000
```

| Phase | 内容 | 状態 |
|-------|------|:----:|
| 🟢 **A: Foundation** | 仕様テンプレ・タスクテンプレ・基本CI・境界定義 | ✅ 自動 |
| 🟡 **B: Guardrails** | architecture check・security scan・レビュールール・hooks profile設定 | 📋 手動 |
| 🔵 **C: Multi-Agent** | 実装/テスト/レビューAI 3分離・`/sage-harness` 自律ループ・doctor/repair/report | 📋 手動 |
| 🟣 **D: Learning System** | 実行履歴分析・失敗パターン蓄積・テンプレ改善 | 📋 手動 |

詳細は [sage/adoption-phases.md](sage/adoption-phases.md) を参照。

---

## よく使うコマンド

```bash
# SPEC-ID を発行
bash scripts/sage-id-gen.sh spec

# PLAN-ID を発行
bash scripts/sage-id-gen.sh plan

# TASK-ID を発行
bash scripts/sage-id-gen.sh task

# 構造検証
bash scripts/sage-validate.sh

# SAGE健全性チェック
bash scripts/sage-doctor.sh

# ファイル修復
bash scripts/sage-repair.sh

# 採用メトリクス
bash scripts/sage-report.sh

# vibe/* ブランチを本番用に昇格
bash scripts/sage-promote.sh vibe/my-feature

# Retro-SPEC ドラフト生成（昇格時に自動実行される）
bash scripts/sage-retro-spec.sh
```

---

## ライセンス

SAGE Development System は **Apache License, Version 2.0** で配布されます。
詳細は [LICENSE](LICENSE) を参照してください。

```
Copyright 2026 heidayo and SAGE Development System contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```

### 帰属表示・統合知識源

SAGE は単独著作物ですが、設計思想・ベストプラクティスの統合源があります:

- 設計インスピレーション (5 source) は [ATTRIBUTION.md](ATTRIBUTION.md) に列挙
- v2 改修にあたり参照した一次ソース (OWASP / NVD CVE / Anthropic 公式 / OpenAI 公式 / Check Point 等 65 資料) も同 [ATTRIBUTION.md](ATTRIBUTION.md) に整理

### Contribution

contribution 受付方針は [CONTRIBUTING.md](CONTRIBUTING.md)、脆弱性報告は [SECURITY.md](SECURITY.md) を参照してください。

### Codex 利用者向け

Codex (CLI / Cloud / codex-action) を SAGE と組み合わせて使う場合は [docs/codex-security.md](docs/codex-security.md) を参照してください (Phase 3 / SPEC-0013): config.toml 推奨設定 / Codex Cloud / CODEX_HOME 対策 / codex-action hardening / IR 手順。
