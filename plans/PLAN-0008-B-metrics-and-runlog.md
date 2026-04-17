# PLAN-0008-B: Metrics 計算と RUN ログ標準化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0008-B |
| SPEC-ID   | SPEC-0008 |
| ステータス | Active |
| 作成日    | 2026-04-17 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infra (scripts + harness skill)
- [ ] frontend
- [ ] test

## 影響範囲

`scripts/sage-report.sh` の metrics 計算ロジック、`scripts/sage-runlog-validate.sh` (新規)、harness SKILL.md の RUN ログ生成手順、`templates/run-log-template.yaml` (新規)。

## 実装方針

- **RUN ログ validator (TASK-0074)**: python3 + yaml で必須フィールド + enum + ISO8601 timestamp を検証。新規外部依存は追加しない。
- **metrics 拡張 (TASK-0075)**: `sage-report.sh` に cycle_time (GitHub API: issue created_at → PR merged_at)、gate_pass_rate (workflow runs 集計)、rework_rate (FAIL 連続数) を追加。API アクセス不可時は metric 個別に SKIPPED 表示して全体 fail させない。
- **RUN ログ生成標準化 (TASK-0076)**: harness Verify フェーズ終了時に RUN ログを append する手順を SKILL.md に明記。書き手 = オーケストレーター、タイミング = Verify gate 完了時。テンプレートは `templates/run-log-template.yaml` に集約。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0074 | RUN ログ YAML validator | Implementation | 1h | - | Yes |
| TASK-0075 | sage-report.sh metrics 拡張 | Implementation | 2h | - | Yes |
| TASK-0076 | harness RUN ログ生成の標準化 | Implementation | 1h | TASK-0074 | No |

## リスク

- リスク 1: GitHub API レート制限で metric 計算が不安定 → 軽減策: API 不可時 SKIPPED 表示、事前集計キャッシュは今回の scope 外
- リスク 2: RUN ログ append のタイミングを SKILL 記述に依存するため、オーケストレーター以外が書き換えるリスク → 軽減策: validator で schema 違反を検知、append-only を File Scope Rules で再確認

## 必要な検証

- [x] unit test (validator の negative case テスト済)
- [ ] integration test
- [ ] security scan
- [ ] e2e test
- [ ] architecture boundary check
