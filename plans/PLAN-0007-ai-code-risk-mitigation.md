# PLAN-0007: AI生成コードのリスク対策強化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0007 |
| SPEC-ID   | SPEC-0007 |
| ステータス | Completed |
| 作成日    | 2026-04-15 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [ ] infrastructure
- [ ] frontend
- [ ] infra
- [ ] test

※ 本変更はドキュメント・設定・テンプレートのみ。ソースコード・テストコードの変更なし。

## 影響範囲

- **sage/**: ガバナンス文書（anti-patterns.md, governance.md）
- **templates/rules/**: 実装ルール（src-rules.md）
- **templates/skills/**: レビュースキル（sage-review）、ハーネススキル（sage-harness）
- **.sage/**: 設定ファイル（config.yaml）
- **install.sh**: 配布用インストーラー

## 実装方針

既存のSAGE構造に対する拡張として実装する。新規ファイルの作成は行わず、既存ファイルへの追記のみ。

1. ガバナンス文書に研究知見を反映（アンチパターン・原則補強）
2. ルールとレビュー基準を更新（強制レイヤー: Claude Code自動ロード + Review Agentスコアリング）
3. ハーネスのTest Agentプロンプトを制約強化（強制レイヤー: ハーネスプロンプト制約）
4. config.yamlにオプション検査を追加（強制レイヤー: プロジェクトopt-in）
5. installerを再生成して配布経路に反映

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0064 | ガバナンス文書更新（AP-07〜09 + governance原則7） | Implementation | 15m | - | Yes |
| TASK-0065 | src-rules同期（テンプレート＋ランタイム） | Implementation | 10m | TASK-0064 | Yes* |
| TASK-0066 | レビュースキル・採点基準同期（テンプレート＋ランタイム） | Implementation | 15m | TASK-0064 | Yes* |
| TASK-0067 | ハーネスTest Agent独立性強化（テンプレート＋ランタイム） | Implementation | 10m | TASK-0066 | No |
| TASK-0068 | config.yamlオプション検査項目追加 | Implementation | 10m | TASK-0064 | Yes* |
| TASK-0069 | installer再生成 | Implementation | 5m | TASK-0065〜0068 | No |

*TASK-0065, TASK-0066, TASK-0068はTASK-0064完了後に並列可

## リスク

- Risk-1: 3系統同期漏れ（templates/.claude/install.sh）→ 軽減策: diff検証 + installerキーワードチェック
- Risk-2: AC-N参照ルールの形骸化 → 軽減策: rubricに「参照の正確性」減点（-2）を追加
- Risk-3: オプション閾値の誤検知 → 軽減策: コメントアウト状態で提供 + 有効化/ロールバック条件を明記

## 必要な検証

- [x] unit test: 該当なし（ドキュメント変更のみ）
- [ ] integration test: 該当なし
- [x] security scan: Gate 3（gitleaks + trivy）
- [ ] e2e test: 該当なし
- [x] architecture boundary check: make validate
- [x] installer test: 空リポジトリでのinstall.sh実行テスト
