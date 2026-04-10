---
name: sage-evaluate
description: "SAGE要件定義・プラン自動採点スキル: SPEC/PLANを6軸・100点満点で採点し、構造化フィードバックを返す。修正はCreator Agentの責務。MANDATORY TRIGGERS: プランを評価, SPECを評価, 採点して, evaluate, score plan, score spec"
---

# SAGE 要件定義・プラン自動採点スキル

SAGE の SPEC / PLAN / TASK を、AI駆動開発のベストプラクティスに基づいて採点し、**構造化フィードバック（eval_feedback YAML）を返す** Read-Only 採点スキル。修正は Creator Agent（Spec Agent / Planning Agent）の責務であり、本スキルはドキュメントを一切変更しない。

## 採点の背景

このスキルは以下の知識を評価軸として使用する：

1. **SAGE Development System** — Spec-driven, Agent-governed, Guard-railed, Evolving
2. **ai-development-patterns** — SPEC-IDトレーサビリティ・failures.md蓄積
3. **awesome-AIDD** — TDD Guard・cc-sddワークフロー
4. **auto-dev** — Error Recovery・Observable Development
5. **SoftwareSeni SDD** — 仕様書品質基準・5本柱検証

詳細な知識ベースは `references/knowledge-base.md` を参照。

---

## 評価フロー（Read-Only）

本スキルは **採点 → 構造化フィードバック返却** のみを行う。改善ループの制御はオーケストレーター（sage-harness）が担当する。

```
┌─────────────────────────────────────────┐
│  1. SPEC/PLAN/TASK を読み込む            │
│  2. 6軸で採点する                        │
│  3. eval_feedback YAML を返却する        │
│     → ループ制御はオーケストレーターが行う │
└─────────────────────────────────────────┘
```

### Read-Only ルール
- **ドキュメントの修正は一切行わない**（Write/Edit ツール使用禁止）
- 問題を発見した場合は `findings` + `fix_instructions` として報告する
- 修正の実行は Creator Agent（Spec Agent / Planning Agent）の責務

---

## 採点手順

### Step 1: ドキュメントを読む

対象ファイルを読み、以下を把握する：
- SPEC: スコープ・除外範囲・受け入れ条件・エラーケース
- PLAN: 影響層・リスク・検証方法
- TASK: 単一責任・File Scope・依存関係・完了条件

### Step 2: 6軸で採点する

各軸を採点し、合計点を算出する。詳細な採点基準は `references/scoring-rubric.md` を参照。

**重要: 1回の採点で全指摘を網羅すること。**
- 各軸の「満点条件」を全てチェックし、不足があれば全て `findings` に含める
- 「次回指摘しよう」と先送りしない。1回で全減点トリガーを検出する
- 採点は `scoring-rubric.md` の減点トリガー表を上から順にチェックリストとして使用する
- 1回の採点で2回以上の修正ラウンドが必要な指摘が出る場合、rubric自体の改善が必要（rubric不備として `sage/failures.md` に記録する）

| 軸 | 満点 | 評価観点 |
|----|------|---------|
| ① Codified Rules | 20点 | CLAUDE.md連携・Forbidden Shortcuts・機械的ゲート |
| ② Atomic Decomposition | 20点 | タスクの独立性・依存グラフ・完了条件の明確さ |
| ③ Spec-Driven Development | 20点 | SPEC-ID・受け入れ条件の具体性・エラーケース |
| ④ Observable Development | 20点 | 検証コマンド・フィードバックループ・計測方法 |
| ⑤ Knowledge Management | 15点 | failures.md連携・Error Resolution・知識蓄積 |
| ⑥ 段階採用戦略 | 5点（加点） | 既存コード影響ゼロ・段階的導入設計 |

### Step 3: 出力フォーマット（eval_feedback YAML）

採点結果を以下の構造化 YAML で返却する：

```yaml
eval_feedback:
  target_file: "specs/SPEC-XXXX-*.md"
  target_type: SPEC | PLAN | TASK
  verdict: PASS | FAIL
  total_score: N
  grade: "S++ | S+ | S | A- | B | C"
  subscores:
    codified_rules: N/20
    atomic_decomposition: N/20
    spec_driven_development: N/20
    observable_development: N/20
    knowledge_management: N/15
    gradual_adoption: N/5
  findings:
    - id: "EVAL-001"
      axis: "codified_rules"
      severity: "critical | major | minor"
      location: "セクション名"
      problem: "問題の1行説明"
      expected: "期待される記述"
      actual: "現在の記述"
  fix_instructions:
    - finding_id: "EVAL-001"
      target_file: "specs/SPEC-XXXX-*.md"
      section: "File Scope"
      action: "修正内容の具体的指示"
      example: "修正例"
```

### 判定基準

- `verdict: PASS` — total_score >= 100（グレード S++）
- `verdict: FAIL` — total_score < 100（fix_instructions を参照して修正が必要）

---

## グレード基準

| スコア | グレード | 判定 |
|--------|---------|------|
| 100 | S++ | 完璧。即実装可。verdict: PASS |
| 95-99 | S+ | ほぼ完成。微修正で到達可能 |
| 90-94 | S | 優秀。小改善あり |
| 85-89 | A- | 良好。改善推奨 |
| 70-84 | B | 基本OK。要改善 |
| ~69 | C | 大幅改善必要 |

---

## 呼び出し方

### 手動呼び出し
```
/sage-evaluate
```

### オーケストレーター経由（推奨）
`/sage-harness` 内で Evaluator として呼び出される。
オーケストレーターが eval_feedback を受け取り、verdict: FAIL の場合は Creator Agent に fix_instructions を渡して修正させ、再採点を依頼する。

---

## 評価時の注意

- 採点は厳格に行う。「書いてあれば満点」ではなく「具体性・実行可能性」で判断する
- findings は必ず実行可能な形（コマンド・コードスニペット）で fix_instructions に示す
- 「実装を止める問題」か「実装後に気づく小さな穴」かを severity で区別する
- 前バージョンがある場合は差分を明示し、改善が反映されているか確認する
- スコアが100点なら verdict: PASS を返す

---

## File scope for this skill
- Read: `specs/`, `plans/`, `tasks/`, `sage/`, `.sage/config.yaml`
- Write: NONE（採点エージェントはドキュメントを一切修正しない）
- Forbidden: `src/`, `tests/`, `.github/`, `CLAUDE.md`, `specs/`, `plans/`, `tasks/`（書き込み）

## 参照ファイル

- `references/knowledge-base.md` — 5ソースの知識ベース詳細（評価の根拠）
- `references/scoring-rubric.md` — 6軸の詳細採点基準と減点トリガー一覧
