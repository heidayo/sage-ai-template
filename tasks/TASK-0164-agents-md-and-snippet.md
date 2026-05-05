# TASK-0164: AGENTS.md §9 cross-ref + agents-md-snippet.md parallel bullet

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0164 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Done |
| 担当Agent | Implementation (Codex-facing) |
| 並列可否  | Yes (TASK-0163 と並列、別 File Scope) |
| 依存TASK  | TASK-0162 |
| 見積     | 30m |

## 責務

Codex 利用者向けに AGENTS.md / agents-md-snippet.md の 2 ファイルへ Property doctrine cross-reference を追加。CLAUDE.md / claude-md-snippet.md (TASK-0163) と semantic 整合 (paired-update doctrine 準拠、SPEC-0023 §10 で formalized)。

## 入力

- SPEC-0024 FR-08 (AGENTS.md cross-ref schema、CLAUDE.md と同 semantic)
- SPEC-0024 FR-09 (agents-md-snippet.md parallel bullet schema、claude-md-snippet.md と同 semantic)
- TASK-0162 で確定した governance §11 reference path
- 既存 AGENTS.md §9 相当箇所
- 既存 templates/agents-md-snippet.md

## 出力

### AGENTS.md §9 相当章末に追加 (≤+5 行、R7 厳守、CLAUDE.md と semantic 整合)

```markdown
### 9.x Property-based Verify (SPEC-0024)

全 SPEC は権限レベルに応じて Properties セクション (Invariant/Pre/Post/Assumption) を持つ。
Review Agent は Dead Code / Trust Boundary / Scope Check の 3-gate FP filter を適用。
詳細: sage/governance.md §11
```

(CLAUDE.md TASK-0163 と完全一致、shared rule のため identical 維持)

### templates/agents-md-snippet.md (≤+2 行)

```markdown
- Properties section is required for new SPECs (system/platform). See sage/governance.md §11.
- Review uses 3-gate FP filter (Dead Code / Trust Boundary / Scope Check).
```

(claude-md-snippet.md と同文、shared rule)

## File Scope（変更許可範囲）

- 変更: `AGENTS.md` (§9 章末 ≤+5 行のみ)
- 変更: `templates/agents-md-snippet.md` (≤+2 行のみ)

## 禁止事項

- AGENTS.md の既存 §1〜§9 の本文を変更しない (Codex-specific bullets を含む §2.1 末尾も不変)
- CLAUDE.md / claude-md-snippet.md を本 TASK で編集しない (TASK-0163 で実施、Claude/Codex 担当境界)
- `docs/codex-delegation-packet.md` 本文を編集しない (SPEC-0024 scope 外、将来 paired SPEC 候補)
- Codex agent prompt 深部修正を行わない (SAGE audit-only 原則維持)
- snippet 既存 bullet を変更しない (additive)
- ≤+5 行 (AGENTS.md) / ≤+2 行 (snippet) を超えない (R7)
- CLAUDE.md / claude-md-snippet.md と semantic drift しない (shared rule の identical 維持)

## 完了条件

- [ ] `grep -F "Property-based Verify" AGENTS.md` で 1 件 hit
- [ ] `grep -F "SPEC-0024" AGENTS.md` で 1 件以上 hit
- [ ] `grep -F "Properties section" templates/agents-md-snippet.md` で 1 件 hit
- [ ] `diff <(grep -A3 "Property-based Verify" CLAUDE.md) <(grep -A3 "Property-based Verify" AGENTS.md)` で 0 行 (semantic 完全一致)
- [ ] `diff templates/claude-md-snippet.md templates/agents-md-snippet.md | grep "Properties section\|3-gate FP filter"` で差分 0 件
- [ ] `git diff main HEAD -- AGENTS.md | grep -c "^+"` で ≤+8 行
- [ ] `git diff main HEAD -- templates/agents-md-snippet.md | grep -c "^+"` で ≤+5 行
- [ ] commit message に `TASK-0164:` 含む
