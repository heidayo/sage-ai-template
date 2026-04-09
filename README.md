# SAGE Development System

**SAGE** = Spec-driven, Agent-governed, Guard-railed, Evolving

AI駆動開発において、複数のAIが同時に開発しても品質・安全性・一貫性が崩れない開発体系。

## SAGEとは

SAGEは「AIにうまくコードを書かせるテクニック集」ではありません。

**AIが逸脱しにくい構造を先に作る技術**です。

## 核心思想

1. **仕様が最上位の真実** — コードは成果物であり、真実ではない
2. **AIは制約内の実行者** — 仕様・役割・権限・制約・検証の中で働く
3. **品質は検証から生まれる** — モデルの優秀さではなく、構造と検証の強さ
4. **並列化は分割設計** — AIを増やすのではなく、責務を分けて粒度を整える
5. **人間は監督者** — 目的定義・仕様承認・優先順位・例外判断・最終責任

## 5層アーキテクチャ

| 層 | 役割 | 由来 |
|----|------|------|
| Philosophy | 仕様中心主義 | Spec-Driven Development |
| Governance | 原則・ルール・禁止事項 | ai-development-patterns |
| Runtime | マルチエージェント分業 | auto-dev |
| Codebase | 契約・レイヤ・型・生成コード分離 | go-boilerplate |
| Tooling | ツールカテゴリ選定 | awesome-AI-driven-development |

## 標準ライフサイクル

```
Specify → Plan → Slice → Execute → Verify → Merge → Observe
```

## ディレクトリ構成

```
.
├── CLAUDE.md          # AI向け最上位ガバナンスルール
├── sage/              # SAGE憲章・原則・品質ゲート・アンチパターン
├── specs/             # SPEC-XXXX 仕様書
├── plans/             # PLAN-XXXX 実装計画
├── tasks/             # TASK-XXXX タスク定義
├── docs/              # アーキテクチャ・ルール・フロー文書
├── scripts/           # 検証・ID生成・適用スクリプト
├── .sage/             # ランタイム設定・実行ログ・メトリクス
├── .claude/           # Claude Code設定・エージェントプロンプト
├── .github/           # CI/CDワークフロー・PRテンプレート
├── src/               # アプリケーションソース
└── tests/             # テスト
```

## クイックスタート

```bash
# 既存リポジトリにSAGE Phase Aを適用
bash scripts/sage-adopt.sh

# ローカル検証
bash scripts/sage-validate.sh
```

詳細は [docs/setup.md](docs/setup.md) を参照。

## 導入フェーズ

| Phase | 内容 |
|-------|------|
| A: Foundation | 仕様テンプレ・タスクテンプレ・基本CI・境界定義 |
| B: Guardrails | architecture check・security scan・生成コード分離・レビュールール |
| C: Multi-Agent | 実装/レビューAI分離・テストAI・並列タスク分解 |
| D: Learning System | 実行履歴分析・失敗パターン蓄積・テンプレ改善 |

## 運用判断の5問

迷った時はこの順で判断:

1. 仕様はあるか
2. 責務は切れているか
3. ルールで止められるか
4. 検証で落とせるか
5. 追跡できるか

## ライセンス

MIT License
