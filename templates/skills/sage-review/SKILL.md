---
name: sage-review
description: "Review code changes against SAGE spec and quality gates"
---

# SAGE Code Review Workflow

## When to use
After implementation. Must be in a SEPARATE session from implementation.

## Review checklist (in order)

### 1. Spec Alignment
- Does the code match the SPEC's acceptance criteria?
- Are there changes not covered by the SPEC? (= Silent Scope Expansion)

### 2. Scope Compliance
- Do changes stay within the TASK's File Scope?
- Flag any files modified that are not in the TASK definition

### 3. Responsibility Alignment
- Single responsibility per TASK maintained?
- Layer boundaries respected?

### 4. Complexity
- Unnecessary abstractions or over-engineering?
- Could the same result be achieved more simply?

### 5. Test Adequacy
- Normal, boundary, and error cases covered?
- Coverage above threshold (default 80% per .sage/config.yaml)?
- テストの期待値はSPECの受入条件から導出されているか？（src/の実装をコピーしていないか = AP-07防止）
- テストケース名またはコメントにSPEC受入条件への参照があるか？（AC-N形式等）
- AC-N参照が付いているだけでなく、そのテストの期待値が参照先の受入条件内容と一致しているか確認する

### 6. Safety
- No hardcoded secrets or credentials
- Input validation at system boundaries
- Dependencies up to date and secure

### 7. Code Quality
コードが「動く」だけでなく「読みやすく保守しやすい」かを確認:
- **変更の意図性**: 各変更ブロックにTASK目的との対応があるか。目的を説明できない追加・変更がないか
- **既存コードとの一貫性**: 同ファイル内の既存パターンと異なる記法・命名がある場合、改善の理由が説明できるか
- **インターフェース設計**: 関数の引数設計に一貫性があるか（同種の値が引数と外部依存に分散していないか）
- **セルフレビュー遵守**: src-rules の「Code readability and maintainability」が実際に守られているか

## Quality gates to verify
| Gate | Checks |
|------|--------|
| 1. Structural | lint, format, type check |
| 2. Functional | tests pass, coverage >= threshold |
| 3. Security | secret scan, dependency vuln scan |
| 4. Architecture | layer boundary, traceability (SPEC->PLAN->TASK->commit) |
| 5. Release | migration safety, rollback readiness |

## Anti-patterns to flag
Reference: `sage/anti-patterns.md`
- Vibe Merge: PR merged without gate pass
- Big Bang Prompt: single commit >20 files without TASK-ID
- Silent Scope Expansion: changes outside File Scope
- Invisible Development: no TASK-ID in commits
- Hallucination Propagation: テストとコードが同じ幻覚を共有（AP-07）
- Comprehension Debt Accumulation: AI生成コードを理解せず受入（AP-08）
- Benchmark Illusion: ベンチマークスコアで品質を判断（AP-09）

## Rules
- This review MUST be in a separate session from implementation
- Never approve changes that fail quality gates
- Never approve changes outside TASK's File Scope
- Flag new anti-patterns for `sage/anti-patterns.md`

## After review
レビューで新しい品質問題パターンを発見した場合、`sage/failures.md` に症状/原因/対策/検出層の4項目で追記すること。

---

## Scoring Rubric（コードレビュー採点基準）

| 軸 | 満点 | 評価観点 |
|----|------|---------|
| Spec Alignment | 25点 | SPECの受け入れ条件との一致。Silent Scope Expansionの有無 |
| Scope Compliance | 20点 | TASK File Scope内のみ変更。違反は即Hard Fail |
| Responsibility Alignment | 15点 | 単一責任維持。レイヤー境界遵守 |
| Complexity | 10点 | 不要な抽象化・過度な結合がないか |
| Test Adequacy | 15点 | 正常系・境界値・異常系カバレッジ。閾値達成 |
| Safety | 15点 | secrets/credentials検出なし。入力バリデーション。依存脆弱性なし |

合計: 100点

詳細な満点条件と減点トリガーは `references/review-scoring-rubric.md` を参照。

### Hard Fail条件（点数に関係なく即FAIL）

以下のいずれかに該当する場合、スコアに関係なく `verdict: FAIL` + `retry_allowed: false`:

- **File Scope違反**: TASK File Scope外のファイルを変更
- **Gate 1-4のいずれかFail**: Structural / Functional / Security / Architecture
- **secrets/credentialsのハードコード**: APIキー、パスワード、トークン等
- **既知脆弱性を持つ依存の追加**: CVEが報告されている依存パッケージ

---

## 出力フォーマット（review_feedback YAML）

レビュー結果を以下の構造化 YAML で返却する：

```yaml
review_feedback:
  round: N
  iteration: M
  verdict: PASS | FAIL
  review_score: N
  subscores:
    spec_alignment: N/25
    scope_compliance: N/20
    responsibility_alignment: N/15
    complexity: N/10
    test_adequacy: N/15
    safety: N/15
  gate_results:
    structural: pass | fail
    functional: pass | fail
    security: pass | fail
    architecture: pass | fail
  findings:
    - id: "REV-001"
      category: "spec_alignment | scope_compliance | responsibility | complexity | test | safety"
      severity: "critical | major | minor"
      file: "path/to/file"
      expected: "期待される状態"
      actual: "現在の状態"
  fix_scope:
    implementation: [{ file, reason }]
    test: [{ file, reason }]
  instruction:
    - target: "implementation"
      action: "Implementation Agentへの具体的修正指示"
    - target: "test"
      action: "Test Agentへの具体的修正指示"
  retry_allowed: true | false
  same_fail_count: N
```

---

## File scope for this skill
- Read: all files
- Write: NONE（review_feedback YAML を出力として返すのみ。コード修正は行わない）
