# SAGE Development System

**SAGE** = Spec-driven, Agent-governed, Guard-railed, Evolving

AI駆動開発において、複数のAIが同時に開発しても品質・安全性・一貫性が崩れない開発体系。

## SAGEとは

SAGEは「AIにうまくコードを書かせるテクニック集」ではありません。

**AIが逸脱しにくい構造を先に作る技術**です。

## 導入方法

### 1. install.sh を取得する

このリポジトリの `install.sh` を入手してください（Gist、Slack、社内URLなど）。

### 2. 導入したいリポジトリで実行する

```bash
cd /path/to/your-project
bash install.sh
```

これだけで完了です。以下が自動的にセットアップされます：

| セットアップ内容 | 説明 |
|----------------|------|
| `specs/`, `plans/`, `tasks/` | 仕様書・計画書・タスクのテンプレート |
| `sage/` | ガバナンス文書（原則・品質ゲート・アンチパターン） |
| `.claude/rules/` | パス別ルール（5ファイル、該当パス操作時のみ自動読み込み） |
| `.claude/skills/` | ワークフロー（`/sage-spec` `/sage-plan` `/sage-review`） |
| `CLAUDE.md` への追記 | 最小ブートストラップ（15-20行のルーティング） |
| `AGENTS.md` の作成 | Codexが自動でSAGEに従うルール |
| `commit-msg` フック | TASK-IDなしのコミットを自動で拒否 |
| `scripts/` | ID生成・構造検証スクリプト |

**既存ファイルは上書きしません。** CLAUDE.mdが既にある場合は監査レポート（`.sage/adoption-audit.md`）を生成してからSAGEセクションを追記します。

### 3. 普通に開発を始める

開発者が特別なことをする必要はありません。Claude CodeやCodexを開いてチャットを始めるだけです。

```
開発者：「お気に入りボタンを追加して」
    ↓
AI：CLAUDE.mdを自動で読む
    ↓
AI：「SPECが見つかりません。まず仕様を整理しましょう」
```

AIが自動的にSAGEのワークフローに従います。

### 更新方法

#### 自動更新（推奨）

`.sage/config.yaml` に `installer_url` を設定すると、AIが毎日自動でバージョンチェック＆更新します。

```yaml
# .sage/config.yaml
auto_update:
  installer_url: "https://gist.githubusercontent.com/YOUR_USER/GIST_ID/raw/install.sh"
```

仕組み：
- Claude Code / Codex がセッション開始時に `sage-update-check.sh` を自動実行
- 1日1回だけチェック（同日2回目以降はスキップ）
- 新バージョンがあれば自動で `install.sh --update` を実行
- ネットワークエラーやURL未設定の場合は警告のみで開発を止めない

#### 手動更新

新しい `install.sh` を同じプロジェクトで再実行するだけです。

```bash
bash install.sh
```

- バージョンが上がっていれば自動でアップデートモードになります
- CLAUDE.mdのプロジェクト固有部分はそのまま残ります
- `sage/failures.md` や `.sage/config.yaml` など、プロジェクト固有データも保持されます

### カスタマイズと更新の共存

SAGE更新時にプロジェクト固有の設定が消えないよう、以下のルールで管理されています。

| やりたいこと | やり方 | 更新時 |
|------------|--------|--------|
| プロジェクト固有ルールを追加 | CLAUDE.md の SAGEマーカーより**上**に書く | 安全（マーカー間だけ置換） |
| パス別ルールを追加 | `.claude/rules/` に**別名で**ファイル作成 | 安全（SAGEは自分のファイルだけ上書き） |
| スキルを追加 | `.claude/skills/` に**別名で**ディレクトリ作成 | 安全 |
| SAGEのルールを上書き | `.claude/rules/` に同じ globs で優先ルールを書く | 安全 |
| SAGE管理ファイルを直接編集 | **やらない** | 上書きされて消える |

#### SAGE管理ファイル一覧（更新時に上書きされるもの）

```
.claude/rules/specs-rules.md       ← SAGE管理
.claude/rules/plans-rules.md       ← SAGE管理
.claude/rules/tasks-rules.md       ← SAGE管理
.claude/rules/src-rules.md         ← SAGE管理
.claude/rules/sage-governance-rules.md ← SAGE管理
.claude/skills/sage-spec/SKILL.md  ← SAGE管理
.claude/skills/sage-plan/SKILL.md  ← SAGE管理
.claude/skills/sage-review/SKILL.md ← SAGE管理
sage/charter.md, governance.md ... ← SAGE管理
scripts/sage-*.sh                  ← SAGE管理
```

#### 安全にカスタマイズする例

```bash
# プロジェクト固有のAPIルールを追加
cat > .claude/rules/my-api-rules.md << 'EOF'
---
description: "Project-specific API rules"
globs: ["src/api/**", "src/routes/**"]
---
# API Rules
- All endpoints must return JSON
- Authentication required on all routes except /health
- Rate limiting must be configured
EOF

# CLAUDE.md にプロジェクト固有ルールを追加（SAGEマーカーの上に書く）
# ※ SAGEマーカー（<!-- === SAGE ... === -->）より下は触らない
```

## 仕組み：4層の自動防御

開発者は何も意識しなくてOK。4層で自動的にSAGEが守られます。

```
第1層：CLAUDE.md / AGENTS.md（常時ロード）
  → 最小ブートストラップ（15-20行）。SPECなしの実装を拒否

第2層：.claude/rules/（パス別自動ロード）
  → specs/ plans/ tasks/ src/ sage/ 操作時に該当ルールだけ読み込み

第3層：.claude/skills/（オンデマンド）
  → /sage-spec /sage-plan /sage-review で詳細ワークフローを呼び出し

第4層：commit-msg hook + CI Gate（機械強制）
  → TASK-IDなしコミット拒否 + SPEC-IDなしPRマージ防止
```

## 核心思想

1. **仕様が最上位の真実** — コードは成果物であり、真実ではない
2. **AIは制約内の実行者** — 仕様・役割・権限・制約・検証の中で働く
3. **品質は検証から生まれる** — モデルの優秀さではなく、構造と検証の強さ
4. **並列化は分割設計** — AIを増やすのではなく、責務を分けて粒度を整える
5. **人間は監督者** — 目的定義・仕様承認・優先順位・例外判断・最終責任

## 標準ライフサイクル

```
Specify → Plan → Slice → Execute → Verify → Merge → Observe
（仕様）   （計画） （分割）  （実装）  （検証）  （統合） （観察）
```

## AIエージェントでの運用

Claude Code・Codex などで開発する場合、セッションを3つに分けます：

| セッション | 役割 | やること |
|-----------|------|---------|
| A | 仕様 | SPECとTASKを作る |
| B | 実装 | TASKのFile Scopeに従ってコードを書く |
| C | レビュー | SPECとの整合性を確認する |

同じセッションで実装とレビューを行わないでください。

## ディレクトリ構成

```
.
├── CLAUDE.md              # 最小ブートストラップ（15-20行、ルーティングのみ）
├── AGENTS.md              # Codex向けルール（自動で読まれる）
├── .claude/
│   ├── rules/             # パス別ルール（該当ファイル操作時のみ読み込み）
│   │   ├── specs-rules.md
│   │   ├── plans-rules.md
│   │   ├── tasks-rules.md
│   │   ├── src-rules.md
│   │   └── sage-governance-rules.md
│   └── skills/            # オンデマンドワークフロー
│       ├── sage-spec/     # /sage-spec で呼び出し
│       ├── sage-plan/     # /sage-plan で呼び出し
│       └── sage-review/   # /sage-review で呼び出し
├── sage/                  # SAGE憲章・原則・品質ゲート・アンチパターン
├── specs/                 # SPEC-XXXX 仕様書
├── plans/                 # PLAN-XXXX 実装計画
├── tasks/                 # TASK-XXXX タスク定義
├── docs/                  # アーキテクチャ・ルール・フロー文書
├── scripts/               # 検証・ID生成スクリプト
├── .sage/                 # ランタイム設定・実行ログ
└── .github/               # CI/CDワークフロー
```

### 関心の分離

| 層 | 何を置くか | いつ読まれるか |
|----|-----------|---------------|
| `CLAUDE.md` | 最小ルーティング | 毎セッション |
| `.claude/rules/` | パス別の詳細ルール | 該当ファイル操作時のみ |
| `.claude/skills/` | ワークフロー手順 | `/sage-spec` 等で呼んだ時のみ |
| hooks / CI | 機械的チェック | コミット・PR時 |

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
```

## 導入フェーズ

SAGEは段階的に導入します。`install.sh` はPhase Aを自動セットアップします。

| Phase | 内容 |
|-------|------|
| A: Foundation | 仕様テンプレ・タスクテンプレ・基本CI・境界定義 |
| B: Guardrails | architecture check・security scan・レビュールール |
| C: Multi-Agent | 実装/レビューAI分離・テストAI・並列タスク分解 |
| D: Learning System | 実行履歴分析・失敗パターン蓄積・テンプレ改善 |

詳細は [sage/adoption-phases.md](sage/adoption-phases.md) を参照。

## Gist の設定（管理者向け）

### 初回：Gist を作成する

```bash
# 1. install.sh を生成
bash scripts/generate-installer.sh > install.sh

# 2. GitHub CLI で secret Gist を作成
gh gist create install.sh --desc "SAGE Development System Installer"
# → https://gist.github.com/YOUR_USER/GIST_ID が表示される
```

表示されたURLを控えてください。raw URLは以下の形式になります：
```
https://gist.githubusercontent.com/YOUR_USER/GIST_ID/raw/install.sh
```

### 導入先プロジェクトでの設定

`install.sh` を実行した後、`.sage/config.yaml` の `installer_url` を設定します：

```yaml
# .sage/config.yaml
auto_update:
  installer_url: "https://gist.githubusercontent.com/YOUR_USER/GIST_ID/raw/install.sh"
```

これにより、各プロジェクトで日次の自動更新チェックが有効になります。

### 更新：Gist を更新する

sage-ai-template を更新した場合：

```bash
# ワンコマンドで更新（バージョン・再生成・Gist更新を一括実行）
bash scripts/sage-publish.sh 0.2.0
```

または手動で：

```bash
# 1. バージョンを上げる
echo "0.2.0" > .sage-version

# 2. install.sh を再生成する
bash scripts/generate-installer.sh > install.sh

# 3. Gist を更新する
gh gist edit GIST_ID install.sh

# 4. 各プロジェクトは次回セッション開始時に自動更新される
```

> **Note**: `sage-publish.sh` を使う場合は、初回に `.sage/gist-id` ファイルにGist IDを保存してください。
> ```bash
> echo "YOUR_GIST_ID" > .sage/gist-id
> ```

## テンプレートの更新（手動配布の場合）

Gistを使わず手動で配布する場合：

```bash
# 1. バージョンを上げる
echo "0.2.0" > .sage-version

# 2. install.sh を再生成する
bash scripts/generate-installer.sh > install.sh

# 3. install.sh を配布する（Slack、社内URLなど）

# 4. 各プロジェクトで再実行してもらう
bash install.sh
```

## ライセンス

MIT License
