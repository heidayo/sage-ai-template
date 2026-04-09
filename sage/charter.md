# SAGE憲章 v0.1

## 1. 存在目的

SAGEは、AIを使って開発速度を上げるための仕組みではない。

**複数のAIが同時に開発しても、品質・安全性・一貫性が崩れない開発体系を実現するための仕組み**である。

## 2. 最上位原則

**仕様が最上位の真実である。**

コード、会話、口頭指示、個人の解釈は、仕様に従属する。

## 3. AIの位置づけ

AIは万能な実装者ではない。

AIは、**仕様・役割・権限・制約・検証の中で働く実行者**である。

## 4. 品質の考え方

品質は、優秀なモデルから生まれない。

**品質は、壊れにくい構造と強い検証から生まれる。**

## 5. 並列開発の考え方

並列化とは、AIを増やすことではない。

**責務を分け、粒度を整え、統合可能な単位に切ること**である。

## 6. 人間の責務

人間は、実装の主担当ではない。

人間は、**目的を定義し、仕様を承認し、優先順位を決め、例外を判断し、最終責任を持つ監督者**である。

## 7. 守るべき設計姿勢

- 仕様なしに実装しない
- 1回の大生成で大機能を作らない
- AIに無制限の権限を与えない
- ルールを文章だけで終わらせない
- CI未通過の変更を統合しない
- 実行履歴を残さない開発をしない

## 8. SAGEの約束

SAGEは次を保証するために存在する。

- 何を作るかが追える
- 誰が何を変えたかが追える
- どの仕様から変更が生まれたかが追える
- なぜ落ちたかが分かる
- どう直すかが再現できる

## 9. 設計根拠 — 5つのソースから得た思想

SAGEは5つのソースの**思想・設計哲学**を統合して生まれた。ソースコードの統合ではない。各ソースから何を学び、SAGEのどの層に反映したかを以下に明記する。

### 9.1 go-boilerplate —「構造で守る」
- AIが触っても壊れにくいコードベースを**先に設計する**思想
- OpenAPI契約→型生成→レイヤ分離（Onion Architecture）→sqlc型安全SQLにより、依存方向・境界・型で**構造的に逸脱を不可能にする**
- SAGEの **Codebase Layer** の根拠
- 参照: https://github.com/Tomy-ch/go-boilerplate

### 9.2 ai-development-patterns —「パターンで規律する」
- AI開発の成功/失敗を27の再現可能なパターンに体系化した思想
- Foundation（準備）→ Development（実行）→ Operations（運用）の3段階成熟モデル
- アンチパターン（implementation-first, big bang, unrestricted access）を名付けて禁止し、**失敗をパターンとして検出可能にしCIで止める**
- SAGEの **Governance Layer** の根拠
- 参照: https://github.com/PaulDuvall/ai-development-patterns

### 9.3 auto-dev —「役割で分業する」
- SDLC全体（要件→開発→レビュー→テスト→データ→デプロイ→運用）を7エージェントで分担する思想
- 1つのAIに全部やらせるのはワンマン経営と同じ。**責務を分けてこそスケールする**
- SAGEの **Runtime Layer** の根拠
- 参照: https://github.com/phodal/auto-dev

### 9.4 awesome-AI-driven-development —「ツールは役割で選ぶ」
- 522+ツールを機能カテゴリ（IDE/CLI/オーケストレーション/テスト/セキュリティ/レビュー/知識管理）で整理した全体図
- 特定製品に依存せず、**役割ごとにスロットを定義**して差し替え可能にする思想
- SAGEの **Tooling Layer** の根拠
- 参照: https://github.com/AIDrivenDevelopment/awesome-AI-driven-development

### 9.5 Spec-Driven Development —「仕様が真実」
- Requirements → Specification → AI Generation → Validation の流れで、仕様を source of truth とする思想
- AIは指示が明確なら優秀に動く。問題はAIの能力ではなく**指示の品質**。だから仕様を最上位に置く
- 人間の役割は実装からアーキテクチャ・要件・検証へシフトする
- SAGEの **Philosophy Layer** の根拠
- 参照: https://www.softwareseni.com/spec-driven-development-in-2025-the-complete-guide-to-using-ai-to-write-production-code/

### 9.6 統合

SAGEはこの5つを1文に統合したものである。

> **仕様で始め（Spec-Driven）、パターンで規律し（ai-dev-patterns）、役割で分け（auto-dev）、構造で守り（go-boilerplate）、ツールを役割で選ぶ（awesome-AI-driven-dev）**

---

## 10. 最終宣言

**AI駆動開発とは、AIに上手く書かせる技術ではなく、AIが勝手に逸脱しにくい構造を先に作る技術である。**
