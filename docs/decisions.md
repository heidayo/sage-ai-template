# SAGE 設計判断ログ（ADR）

## フォーマット

```
## ADR-XXXX: [タイトル]
- **日付**: YYYY-MM-DD
- **ステータス**: Proposed / Accepted / Deprecated / Superseded
- **背景**: なぜこの判断が必要になったか
- **決定**: 何をどうするか
- **理由**: なぜこの選択肢を選んだか
- **代替案**: 検討した他の選択肢
- **影響**: この判断による影響
```

---

## ADR-0001: SAGE 5層アーキテクチャの採用

- **日付**: 2025-01-01
- **ステータス**: Accepted
- **背景**: AI駆動開発のための統一的なフレームワークが必要
- **決定**: Philosophy / Governance / Runtime / Codebase / Tooling の5層構造を採用
- **理由**: 5つのソース（go-boilerplate, ai-development-patterns, auto-dev, awesome-AI-driven-development, Spec-Driven Development）の統合に最適な抽象度
- **代替案**: 3層（Spec / Code / CI）、フラット構造
- **影響**: すべてのSAGEドキュメントとツールがこの5層に沿って整理される

## ADR-0002: 品質ゲート5段階の採用

- **日付**: 2025-01-01
- **ステータス**: Accepted
- **背景**: AI生成コードの品質担保には多層的な検証が必要
- **決定**: Structural / Functional / Security / Architecture / Release の5段階ゲートを採用
- **理由**: Spec-Driven Development記事の5本柱（Security, Testing, Code Quality, Performance, Deployment Readiness）と整合
- **代替案**: 3段階（Lint / Test / Security）、単一CI
- **影響**: GitHub Actionsで5つのワークフローを管理する必要がある

## ADR-0003: 参照ソースコードの削除

- **日付**: 2025-04-09
- **ステータス**: Accepted
- **背景**: SAGEテンプレートリポジトリに4つの参照ソースのコピーが同梱されていた（計4,500+ファイル）。テンプレートとして配布するには不適切なサイズと構造。
- **決定**: 4つのコピーディレクトリを削除し、参照元URLのみを記録する
- **理由**: テンプレートの利用者に不要なファイルを配布しない。参照資料は元リポジトリで閲覧可能。
- **代替案**: 別ブランチに退避、サブモジュール化
- **影響**: SAGEの設計根拠を確認するには以下の元リポジトリを参照する必要がある

### SAGE設計の参照ソース

| ソース | SAGE層 | 参照URL |
|--------|--------|---------|
| go-boilerplate | Codebase Layer | https://github.com/Tomy-ch/go-boilerplate |
| ai-development-patterns | Governance Layer | https://github.com/PaulDuvall/ai-development-patterns |
| auto-dev | Runtime Layer | https://github.com/phodal/auto-dev |
| awesome-AI-driven-development | Tooling Layer | https://github.com/AIDrivenDevelopment/awesome-AI-driven-development |
| Spec-Driven Development (記事) | Philosophy Layer | https://www.softwareseni.com/spec-driven-development-in-2025-the-complete-guide-to-using-ai-to-write-production-code/ |
