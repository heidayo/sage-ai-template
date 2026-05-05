# TASK-0165: sage-review SKILL.md 3-gate FP filter + 6 verdict 拡張

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0165 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Done |
| 担当Agent | Implementation (shared-core) |
| 並列可否  | Yes (TASK-0166 / TASK-0167 と並列、別 File Scope) |
| 依存TASK  | TASK-0162 |
| 見積     | 60m |

## 責務

`templates/skills/sage-review/SKILL.md` および `.claude/skills/sage-review/SKILL.md` (同期コピー) に SPECA Phase 04 由来の 3-gate FP filter と 6 verdict 体系を追加。

## 入力

- SPEC-0024 FR-03 (3-gate FP filter セクション schema)
- SPEC-0024 FR-04 (review_feedback YAML schema 拡張)
- TASK-0162 で確定した governance §11 reference
- 既存 templates/skills/sage-review/SKILL.md (現状 verdict は PASS/FAIL のみ)
- 既存 .claude/skills/sage-review/SKILL.md (templates/ と同期維持)

## 出力

### templates/skills/sage-review/SKILL.md 追加セクション

「Anti-patterns to flag」の直後に「## 3-gate FP filter (SPEC-0024)」追加:

```markdown
## 3-gate FP filter (SPEC-0024)

Review Agent は finding 確定後、以下の順で FP filter を適用 (early-exit):

### Gate 1: Dead Code
Finding 対象コードが実行されない経路 (router で reachable でない、feature flag で off 等) なら DISPUTED_FP。
- audit log: `fp_gate: dead_code`, `fp_reason: <unreachability の根拠>`

### Gate 2: Trust Boundary
Finding が信頼境界外 (untrusted input が制御不可な場合)、別 finding に切り分け (新 finding raise)。
- audit log: `fp_gate: trust_boundary`, `fp_reason: <boundary 説明>`

### Gate 3: Scope Check
Finding が TASK File Scope 外の既存問題 → OUT_OF_TASK_SCOPE。
本 TASK で fix しない判断 → FOLLOW_UP_REQUIRED (follow-up TASK 起票必須)。
- audit log: `fp_gate: scope_check`, `fp_reason: <scope 外と判断した根拠>`

### Hard Fail (3-gate で覆せない)
以下は DISPUTED_FP にできない (recall-safe、§11.4):
- File Scope 違反 (実装が TASK 許可範囲外を変更)
- Gate 1-4 のいずれか fail
- secret / credentials のハードコード
- 既知脆弱性を持つ依存の追加

### SKIPPED_WITH_APPROVAL_REQUIRED
Property が証明できないが反例も出せない場合、SKIPPED_WITH_APPROVAL_REQUIRED。
人間 approver の signature を PR body に `Approved-by: <username> <reason>` で記載必須。空 signature / AI agent 名は merge block。
```

### review_feedback YAML schema 拡張 (既存 schema を更新):

```yaml
review_feedback:
  round: N
  iteration: M
  verdict: PASS | FAIL | OUT_OF_TASK_SCOPE | FOLLOW_UP_REQUIRED | DISPUTED_FP | SKIPPED_WITH_APPROVAL_REQUIRED
  review_score: N
  subscores: { ... }
  gate_results: { ... }
  findings:
    - id: "REV-001"
      category: "spec_alignment | scope_compliance | responsibility | complexity | test | safety"
      severity: "critical | major | minor"
      file: "path/to/file"
      expected: "..."
      actual: "..."
      fp_gate: "dead_code | trust_boundary | scope_check | none"  # NEW
      fp_reason: "..."  # NEW (fp_gate != none 時必須)
  approval_required:  # NEW (verdict = SKIPPED_WITH_APPROVAL_REQUIRED 時必須)
    approver: null  # human username, AI agent 名は無効
    reason: null
    signed_at: null  # ISO 8601 UTC
  fix_scope: { ... }
  instruction: [ ... ]
  retry_allowed: true | false
  same_fail_count: N
```

### .claude/skills/sage-review/SKILL.md 同期

`templates/` と内容 byte-identical。`scripts/sage-doc-drift.sh` で diff 0 必須。

## File Scope（変更許可範囲）

- 変更: `templates/skills/sage-review/SKILL.md` (3-gate FP filter セクション追加 + verdict enum 拡張 + YAML schema 更新)
- 変更: `.claude/skills/sage-review/SKILL.md` (templates/ の byte-identical コピー)

## 禁止事項

- 既存 review checklist (1. Spec Alignment 〜 7. Code Quality) の本文を変更しない (additive)
- Hard Fail 条件 (§11.4) を緩和しない (File Scope 違反 / Gate fail / secret / 既知脆弱性は DISPUTED_FP 不可)
- `references/review-scoring-rubric.md` を本 TASK で変更しない (subscore 変更は scope 外、別 TASK 候補)
- templates/ と .claude/ の content drift を作らない (byte-identical 必須)
- AI agent を approver として認める (SEC-04 違反、検証で block)

## 完了条件

- [ ] `grep -F "3-gate FP filter" templates/skills/sage-review/SKILL.md` で 1 件 hit
- [ ] `grep -F "Dead Code" templates/skills/sage-review/SKILL.md && grep -F "Trust Boundary" templates/skills/sage-review/SKILL.md && grep -F "Scope Check" templates/skills/sage-review/SKILL.md`
- [ ] `for v in PASS FAIL OUT_OF_TASK_SCOPE FOLLOW_UP_REQUIRED DISPUTED_FP SKIPPED_WITH_APPROVAL_REQUIRED; do grep -qF "$v" templates/skills/sage-review/SKILL.md || exit 1; done`
- [ ] `grep -F "fp_gate" templates/skills/sage-review/SKILL.md && grep -F "approval_required" templates/skills/sage-review/SKILL.md`
- [ ] `diff templates/skills/sage-review/SKILL.md .claude/skills/sage-review/SKILL.md` で 0 行
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0165:` 含む
