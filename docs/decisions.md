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

## ADR-0004: CI Gate を advisory から enforcement に変更

- **日付**: 2026-04-10
- **ステータス**: Accepted
- **SPEC**: SPEC-0002
- **背景**: 5つのCI Gate workflowがすべてadvisory-only（WARNコメントのみ、jobをfailさせない）で、AP-06（Human-Only Guard）に該当していた
- **決定**: Gate 1-2は `.sage/config.yaml` の `project_checks` 経由でコマンド実行。未設定時はSKIPPED（偽PASSにしない）。Gate 4はWARN→FAIL（exit 1）。Gate 5はGate 1-4のAPI prerequisiteチェック
- **理由**: SAGEの原則5「ルールは実行可能でなければならない」に準拠。ECC (everything-claude-code) の「守るべきことは止める」思想を参考
- **代替案**: 全チェックをローカルhookで実行（CI不要）→ 却下（CIとhookの二段構えが安全）
- **影響**: プロジェクトは `.sage/config.yaml` にlint/testコマンドを設定する必要がある。未設定はSKIPPED

## ADR-0005: Claude Code hooks を bash で実装

- **日付**: 2026-04-10
- **ステータス**: Accepted
- **SPEC**: SPEC-0003
- **背景**: Claude Codeのruntime保護（危険コマンドブロック、設定ファイル保護、File Scopeチェック、セッション文脈復元）が必要
- **決定**: 5つのhookをbashスクリプトで実装。jqでJSON parse、不在時はgrepフォールバック。プロファイル制御（minimal/standard/strict）をSAGE Phase A-Dと対応
- **理由**: SAGEの既存スクリプトが全てbash。Node.js依存を避け、配布物の依存関係を最小化。ECCのNode.js hookパターンを参考にしたが、SAGEの文脈に合わせてbash化
- **代替案**: Node.js（ECC互換）→ 却下（依存追加）。Python → 却下（bashより重い）
- **影響**: jq推奨（なくても動作するがパース精度が落ちる）

## ADR-0006: install-state.yaml によるインストール状態管理

- **日付**: 2026-04-10
- **ステータス**: Accepted
- **SPEC**: SPEC-0004
- **背景**: install.shは一括展開のみで、破損検知・部分修復ができなかった。ECC (everything-claude-code) のdoctor/repair/install-stateパターンを参考
- **決定**: `.sage/install-state.yaml` にファイルパス・SHA256・managed/unmanagedフラグを記録。`sage-doctor.sh`で診断、`sage-repair.sh`で修復、`sage-report.sh`で採用メトリクス
- **理由**: managed:true（SAGE管理、update時上書き）とmanaged:false（ユーザーカスタマイズ、上書きしない）の区別が必須。AI制御ファイル（CLAUDE.md/settings.json/prompts/）のセキュリティ監査も統合
- **代替案**: checksumなし（ファイル存在チェックのみ）→ 却下（改ざん検知不能）
- **影響**: install.sh実行時にinstall-state.yaml自動生成。`make doctor`で健全性チェック可能
