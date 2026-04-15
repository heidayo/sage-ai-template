# SPEC-0007: AI生成コードのリスク対策強化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0007 |
| ステータス | Implemented |
| 作成日    | 2026-04-15 |
| 更新日    | 2026-04-15 |
| 担当Agent | Spec Agent |
| 依存SPEC  | none |
| 権限レベル | system |

## 背景・目的

2つの研究レポートの分析結果に基づき、SAGEのAI生成コードに対するリスク対策を強化する。

- **レポート1「AI駆動開発の生産性パラドックス」**: コーディングはSDLCの25-35%。AI導入でバグ率41%増、セキュリティ脆弱性29.1%増。理解負荷（Comprehension Debt）が59%の開発者に影響
- **レポート2「AI生成コードの正確性と再現性」**: ハルシネーションは数学的に不可避。パッケージ幻覚5.2%(Python)/21.7%(JS)。同一プロンプトで75.76%が異なるコードを生成。ベンチマーク精度（HumanEval 99%）と実運用バグ率（41%増）に巨大なギャップ

SAGEのライフサイクルとゲート構造は両レポートの推奨に概ね合致しているが、ハルシネーション検出・テストの独立性・理解負荷の3領域に具体的な対策が不足している。

## 対象ユーザー

SAGEテンプレートを使用する全てのAIエージェントおよび開発者。

## スコープ（含む）

- アンチパターン3件（AP-07〜09）の追加
- governance原則7の非決定性データによる補強
- src-rulesへのAI出力検証セクション追加
- レビュー採点基準へのテスト独立性・コードチャーン減点トリガー追加
- ハーネスTest Agentプロンプトへのテスト独立性ルール追加
- config.yamlへのオプション検査項目・メトリクス追加
- installer再生成

## スコープ外（明示的に除外）

- パッケージ存在チェックスクリプトの新規作成（言語依存が大きく汎用テンプレート化が困難）
- 形式検証ゲートの導入（技術的に未成熟）
- DORAメトリクスとの統合（SAGE外部インフラに依存）
- CIワークフロー（Gate 1-4）の修正（プロジェクト固有のためconfig.yamlオプション提供に留める）
- src/やtests/への変更（ドキュメント・設定・テンプレート変更のみ）

## 要件

### 機能要件
- [FR-01] AP-07（Hallucination Propagation）をsage/anti-patterns.mdに追加する
- [FR-02] AP-08（Comprehension Debt Accumulation）をsage/anti-patterns.mdに追加する
- [FR-03] AP-09（Benchmark Illusion）をsage/anti-patterns.mdに追加する
- [FR-04] governance原則7にAI出力の非決定性データを追記する
- [FR-05] src-rulesに「AI Output Verification」セクションを追加する（必須/条件付き必須の2段階）
- [FR-06] レビュー採点基準にテスト-SPEC対応の減点トリガーを追加する（-4/-2/-2）
- [FR-07] レビュー採点基準にコードチャーン比率の減点トリガーを追加する（-2）
- [FR-08] ハーネスTest Agentプロンプトにsrc/参照制限ルールを追加する
- [FR-09] config.yamlにhallucination_check/duplication_check/complexity_checkのコメント例を追加する
- [FR-10] config.yamlにcode_churn/duplication_rateメトリクスを追加する

### 非機能要件
- [NFR-01] 既存ゲートの動作に影響を与えない（新規チェックは全てコメントアウト/opt-in）
- [NFR-02] templates/と.claude/のファイルが同期されていること
- [NFR-03] install.shが正常に実行できること

### セキュリティ要件
- [SEC-01] 新規チェックコマンドは全てコメントアウト状態で追加する（デフォルト無効）
- [SEC-02] 外部コマンド例は任意opt-inとし、デフォルト有効化しない

### 運用要件
- [OPS-01] AP-07/08/09に該当するレビュー指摘はsage/failures.mdに記録する
- [OPS-02] 同一パターンが3回出た場合はsage/anti-patterns.mdへ昇格する

## 受け入れ条件（Acceptance Criteria）

- [x] AC-01: `rg -c '## AP-07|## AP-08|## AP-09' sage/anti-patterns.md` → 3件
- [x] AC-02: `diff -u templates/rules/src-rules.md .claude/rules/src-rules.md` → 差分なし
- [x] AC-03: `diff -u templates/skills/sage-review/SKILL.md .claude/skills/sage-review/SKILL.md` → 差分なし
- [x] AC-04: `diff -u templates/skills/sage-review/references/review-scoring-rubric.md .claude/skills/sage-review/references/review-scoring-rubric.md` → 差分なし
- [x] AC-05: `diff -u templates/skills/sage-harness/SKILL.md .claude/skills/sage-harness/SKILL.md` → 差分なし
- [x] AC-06: `rg -c 'hallucination_check|duplication_check|complexity_check|code_churn|duplication_rate' .sage/config.yaml` → 5件以上
- [x] AC-07: `rg -q 'Hallucination Propagation' install.sh && rg -q 'AI Output Verification' install.sh && rg -q 'テスト独立性ルール' install.sh && rg -q 'code_churn' install.sh` → 全て exit 0
- [x] AC-08: `make validate` → PASS

## 異常系

- `.claude/skills/`または`install.sh`への同期が欠ける場合、この変更は未完了としてFAIL
- `templates/`と`.claude/`の対応ファイルに差分がある場合FAIL（AC-02〜05で検出）
- install.shが構文エラーを含む場合FAIL（`bash -n install.sh`で検出）

## 契約

- API: なし
- DB: なし
- イベント: なし

## リスク

- Risk-1: 3系統同期漏れ — templates/.claude/install.shの同期が欠けると実行経路が分岐する → 軽減策: AC-02〜05のdiffチェックとAC-07のinstallerチェックで検出
- Risk-2: AC-N参照ルールの形骸化 — 自由記述テストでAC-N参照が形式的になり、実質的なSPEC追跡にならない可能性 → 軽減策: Review Agentが「参照の正確性」もチェック（rubricの-2減点で抑止）
- Risk-3: オプション閾値の誤検知 — duplication/complexityの閾値がプロジェクトに合わず誤検知を増やす可能性 → 軽減策: コメントアウト状態で提供し、有効化条件・ロールバック条件を明記

## 実装メモ（Implementation Agent向け）

- ハーネスは起動時にanti-patterns.mdを全エージェントに自動注入するため、AP-07〜09を追加するだけで即座に効果がある
- src-rulesは.claude/rules/のglob matchでsrc/**編集時に自動適用される
- オプション検査はconfig.yamlのコメント例として提供し、プロジェクト固有の設定で有効化する設計

## 関連ID

- PLAN-ID: PLAN-0007
- TASK-ID: TASK-0064, TASK-0065, TASK-0066, TASK-0067, TASK-0068, TASK-0069
