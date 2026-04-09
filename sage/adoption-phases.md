# SAGE 導入フェーズ

## 概要

SAGEは一気に全部導入しない。4段階で段階的に導入する。

---

## Phase A: Foundation

**目的**: 最小限の仕組みを入れる。

### チェックリスト

- [ ] `CLAUDE.md` を作成し、10必須セクションを記入
- [ ] `sage/charter.md` を確認（変更不要なら承認）
- [ ] `sage/governance.md` を確認
- [ ] `specs/_template.md` が存在する
- [ ] `plans/_template.md` が存在する
- [ ] `tasks/_template.md` が存在する
- [ ] `.sage/config.yaml` が存在する
- [ ] `.gitignore` に `.sage/runs/` と `.sage/metrics/` が追加されている
- [ ] 最初の SPEC（SPEC-0001）を作成した
- [ ] `make validate` が ALL PASSED

### 必要ファイル
```
CLAUDE.md
sage/charter.md
sage/governance.md
sage/failures.md
.sage/config.yaml
specs/_template.md
plans/_template.md
tasks/_template.md
.gitignore
```

### 次のフェーズへの移行条件
- 上記チェックリストがすべて完了
- 最低1つのSPEC→PLAN→TASKサイクルを回した

---

## Phase B: Guardrails

**目的**: 品質ゲートを設定し、ルールをCIで強制する。

### チェックリスト

- [ ] `.github/workflows/sage-structural-gate.yml` がプロジェクトに合わせて設定済み
- [ ] `.github/workflows/sage-functional-gate.yml` がプロジェクトに合わせて設定済み
- [ ] `.github/workflows/sage-security-gate.yml` が動作確認済み
- [ ] `.github/pull_request_template.md` が配置されている
- [ ] `sage/quality-gates.md` の閾値が確認済み
- [ ] `sage/anti-patterns.md` がチーム内で共有済み
- [ ] Branch protection が設定されている（required status checks）
- [ ] 生成コードと手書きコードが分離されている

### 必要ファイル（Phase Aに追加）
```
.github/workflows/sage-structural-gate.yml
.github/workflows/sage-functional-gate.yml
.github/workflows/sage-security-gate.yml
.github/pull_request_template.md
.github/settings/labels.json
sage/quality-gates.md
sage/anti-patterns.md
```

### 次のフェーズへの移行条件
- 品質ゲート3種（Structural, Functional, Security）がPRで自動実行される
- ゲート未通過のPRがマージされない設定が有効

---

## Phase C: Multi-Agent

**目的**: エージェント分業を開始し、並列開発の基盤を作る。

### チェックリスト

- [ ] `.claude/prompts/` に最低4種のエージェントプロンプトが配置
- [ ] 実装AIとレビューAIが分離されている
- [ ] テストAIが導入されている（または人間がテストを担当）
- [ ] `scripts/sage-validate.sh` が正常動作する
- [ ] `scripts/sage-trace-check.sh` が正常動作する
- [ ] `.github/workflows/sage-architecture-gate.yml` が設定済み
- [ ] `.github/workflows/sage-claude-review.yml` が設定済み
- [ ] TASK-ID別にブランチを分けるワークフローが確立
- [ ] 実行ログを `.sage/runs/` に記録する習慣がある

### 必要ファイル（Phase Bに追加）
```
.claude/prompts/spec-agent.md
.claude/prompts/planning-agent.md
.claude/prompts/implementation-agent.md
.claude/prompts/review-agent.md
.claude/prompts/test-agent.md
.claude/prompts/security-agent.md
.claude/prompts/operations-agent.md
.claude/settings.json
.github/workflows/sage-architecture-gate.yml
.github/workflows/sage-claude-review.yml
scripts/sage-validate.sh
scripts/sage-trace-check.sh
scripts/sage-id-gen.sh
scripts/sage-adopt.sh
```

### 次のフェーズへの移行条件
- 最低3回のマルチエージェント開発サイクルを完了
- エージェント間の責務分離が機能している

---

## Phase D: Learning System

**目的**: 学習サイクルを回し、SAGEを進化させる。

### チェックリスト

- [ ] `sage/failures.md` に失敗が記録されている
- [ ] 3回以上繰り返す失敗が `sage/anti-patterns.md` に昇格されている
- [ ] メトリクス（cycle_time, gate_pass_rate, rework_rate）を計測している
- [ ] 仕様テンプレートが実績に基づいて改善されている
- [ ] エージェントプロンプトが実績に基づいて調整されている
- [ ] `.github/workflows/sage-release-gate.yml` が設定済み
- [ ] Observe フェーズが各リリースで実行されている

### 必要ファイル（Phase Cに追加）
```
.github/workflows/sage-release-gate.yml
sage/adoption-phases.md
sage/traceability.md
docs/architecture.md
docs/rules.md
docs/development-flow.md
specs/SPEC-0001-example.md
```

### 成熟の指標
- Gate初回通過率 >= 80%
- リワーク率 <= 20%
- サイクルタイム（p50）<= 24h
- 新規アンチパターンの発生頻度が減少傾向
