# SPEC-0001: SAGE テンプレートリポジトリの初期構築

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0001 |
| ステータス | Implemented |
| 作成日    | 2025-04-09 |
| 更新日    | 2026-04-10 |
| 担当Agent | Spec Agent (Claude Code) |
| 依存SPEC  | none |
| 権限レベル | system |

## 背景・目的

SAGE Development System v0.1 の仕様書が完成したが、実際に使えるリポジトリテンプレートが存在しない。
仕様をそのまま使えるファイル群・テンプレート・CI・スクリプトとして実体化する必要がある。

## 対象ユーザー

SAGE を導入したい開発チーム（1-3名 + AI エージェント）。

## スコープ（含む）

- CLAUDE.md（10必須セクション + 7フェーズexit criteria）
- sage/ ディレクトリ（charter, governance, quality-gates, anti-patterns, failures, adoption-phases, traceability）
- specs/, plans/, tasks/ テンプレートと README
- .sage/config.yaml（品質ゲート閾値 + メトリクススキーマ）
- .github/workflows/（5品質ゲート + Claude Code review）
- .github/ テンプレート（PR, Issue）
- .claude/prompts/（7エージェントプロンプト）
- scripts/（validate, trace-check, id-gen, adopt）
- docs/（architecture, rules, development-flow, decisions, setup）
- README.md, .gitignore, .editorconfig, makefile

## スコープ外（明示的に除外）

- アプリケーションの実装コード（src/ は stub のみ）
- 言語固有の lint/test 設定（コメントでテンプレート提供のみ）
- Branch protection の GitHub API 経由での自動設定
- メトリクス収集の自動化スクリプト（Phase D で対応）

## 要件

### 機能要件
- [FR-01] `make validate` で CLAUDE.md の10セクション存在を自動検証できる
- [FR-02] `make validate` でテンプレート必須フィールドを自動検証できる
- [FR-03] `make id-gen TYPE=spec` で次の SPEC-ID を生成できる
- [FR-04] `bash scripts/sage-adopt.sh` で既存リポジトリに非破壊で Phase A を適用できる

### 非機能要件
- [NFR-01] 言語・フレームワーク非依存であること
- [NFR-02] 段階的導入（Phase A-D）が可能であること

### セキュリティ要件
- [SEC-01] Gitleaks による secret scan が CI に含まれていること
- [SEC-02] Trivy による dependency vulnerability scan が CI に含まれていること

### 運用要件
- [OPS-01] ドキュメントは日本語、コード・設定は英語

## 受け入れ条件（Acceptance Criteria）

- [x] AC-01: `make validate` が ALL PASSED を返す
- [x] AC-02: `make id-gen TYPE=spec` が SPEC-0002 を返す
- [x] AC-03: すべてのGitHub Actions YAML が有効な構文である
- [x] AC-04: `bash scripts/sage-adopt.sh` が空リポジトリで正常実行できる

## 異常系

- sage-validate.sh 実行時に CLAUDE.md が存在しない場合: エラーメッセージを表示して exit 1
- sage-id-gen.sh に無効な TYPE を指定した場合: Usage を表示して exit 1

## 契約

- API: なし
- DB: なし
- イベント: なし

## リスク

- リスク1: 言語固有のCI設定がないため、そのままではGate 1/2が実質的にスキップされる → 軽減策: コメントで言語別テンプレートを提供

## 実装メモ（Implementation Agent向け）

- go-boilerplate の AGENTS.md を CLAUDE.md の構造参考にする
- go-boilerplate の trivy-fs.yaml の PR コメント upsert パターンを全ゲートに適用
- ai-development-patterns の claude-code-review.yml を Claude Code review の参考にする

## 関連ID

- PLAN-ID: PLAN-0001
- TASK-ID: TASK-0001 〜 TASK-0026

## トレーサビリティ補足

- `PLAN-0001` と `TASK-0001`〜`TASK-0026` は 2026-04-10 に retrospective placeholder として補完した
- 元の粒度・実装順の完全再現ではなく、SPEC-0001 の traceability 欠損を解消するための履歴補助 artifact である
