---
name: sage-evaluate
description: "SAGE要件定義・プラン自動採点スキル: SPEC/PLANを6軸・100点満点で採点し、100点になるまで改善ループを回す。MANDATORY TRIGGERS: プランを評価, SPECを評価, 採点して, evaluate, score plan, score spec"
---

# SAGE 要件定義・プラン自動採点スキル

SAGE の SPEC / PLAN / TASK を、AI駆動開発のベストプラクティスに基づいて採点・改善提案し、**100点（S++）になるまで自動で改善ループを回す**スキル。

## 採点の背景

このスキルは以下の知識を評価軸として使用する：

1. **SAGE Development System** — Spec-driven, Agent-governed, Guard-railed, Evolving
2. **ai-development-patterns** — SPEC-IDトレーサビリティ・failures.md蓄積
3. **awesome-AIDD** — TDD Guard・cc-sddワークフロー
4. **auto-dev** — Error Recovery・Observable Development
5. **SoftwareSeni SDD** — 仕様書品質基準・5本柱検証

詳細な知識ベースは `references/knowledge-base.md` を参照。

---

## 自動改善ループ

このスキルの核心は **Score → Fix → Re-score** の自動ループ。

```
┌─────────────────────────────────────────┐
│  1. SPEC/PLAN/TASK を読み込む            │
│  2. 6軸で採点する                        │
│  3. スコア < 100 ?                       │
│     ├─ YES → 減点箇所を自動修正          │
│     │        → 修正内容を表示            │
│     │        → Step 2 に戻る             │
│     └─ NO  → 「実装を開始してください」   │
│              → ループ終了                │
└─────────────────────────────────────────┘
```

### ループルール
- **最大10回**まで改善を繰り返す（無限ループ防止）
- 各イテレーションで**変更差分**を明示する
- 10回で100点に届かない場合、現状スコアと残課題を報告して人間に判断を委ねる
- 改善は**ドキュメントのみ**修正する（コードは触らない）

---

## 採点手順

### Step 1: ドキュメントを読む

対象ファイルを読み、以下を把握する：
- SPEC: スコープ・除外範囲・受け入れ条件・エラーケース
- PLAN: 影響層・リスク・検証方法
- TASK: 単一責任・File Scope・依存関係・完了条件

### Step 2: 6軸で採点する

各軸を採点し、合計点を算出する。詳細な採点基準は `references/scoring-rubric.md` を参照。

| 軸 | 満点 | 評価観点 |
|----|------|---------|
| ① Codified Rules | 20点 | CLAUDE.md連携・Forbidden Shortcuts・機械的ゲート |
| ② Atomic Decomposition | 20点 | タスクの独立性・依存グラフ・完了条件の明確さ |
| ③ Spec-Driven Development | 20点 | SPEC-ID・受け入れ条件の具体性・エラーケース |
| ④ Observable Development | 20点 | 検証コマンド・フィードバックループ・計測方法 |
| ⑤ Knowledge Management | 15点 | failures.md連携・Error Resolution・知識蓄積 |
| ⑥ 段階採用戦略 | 5点（加点） | 既存コード影響ゼロ・段階的導入設計 |

### Step 3: 自動修正（スコア < 100 の場合）

減点した項目について：
1. **問題を1行で明示**する
2. **対象ファイルを直接修正**する（SPEC/PLAN/TASKファイル）
3. **修正差分を表示**する
4. Step 2 に戻り再採点する

### Step 4: 出力フォーマット

各イテレーションで以下を出力する：

```
## 採点結果（イテレーション N/10）

**総合スコア：XX / 100（グレード）**

| 軸 | スコア | 備考 |
|----|--------|------|
| ① Codified Rules | XX/20 | ... |
| ② Atomic Decomposition | XX/20 | ... |
| ③ Spec-Driven Development | XX/20 | ... |
| ④ Observable Development | XX/20 | ... |
| ⑤ Knowledge Management | XX/15 | ... |
| ⑥ 段階採用戦略 | XX/5 | ... |

### 修正内容（このイテレーション）
- [修正1]: ...
- [修正2]: ...

### 残課題
- ...
```

最終イテレーション（100点）では：

```
**総合スコア：100 / 100（グレード S++）**

✓ 全軸が基準を満たしています。このまま実装を開始してください。
次のステップ: 実装セッションで TASK の File Scope に従ってコードを書く
```

---

## グレード基準

| スコア | グレード | 判定 |
|--------|---------|------|
| 100 | S++ | 完璧。即実装可。ループ終了 |
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

### 自動呼び出し（推奨）
`/sage-spec` または `/sage-plan` の完了後に自動的に呼び出される。
100点になるまでドキュメントを自動改善し、到達したら実装可能と判定する。

---

## 評価時の注意

- 採点は厳格に行う。「書いてあれば満点」ではなく「具体性・実行可能性」で判断する
- 改善は必ず実行可能な形（コマンド・コードスニペット）で示す
- 「実装を止める問題」か「実装後に気づく小さな穴」かを区別する
- 前バージョンがある場合は差分を明示し、改善が反映されているか確認する
- スコアが100点なら「このまま実装を開始してください」と明示する

---

## File scope for this skill
- Read: `specs/`, `plans/`, `tasks/`, `sage/`, `.sage/config.yaml`
- Write: `specs/`, `plans/`, `tasks/`（採点対象ドキュメントの改善のみ）
- Forbidden: `src/`, `tests/`, `.github/`, `CLAUDE.md`

## 参照ファイル

- `references/knowledge-base.md` — 5ソースの知識ベース詳細（評価の根拠）
- `references/scoring-rubric.md` — 6軸の詳細採点基準と減点トリガー一覧
