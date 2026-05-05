# TASK-0163: CLAUDE.md §9 cross-ref + claude-md-snippet.md parallel bullet

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0163 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Done |
| 担当Agent | Implementation (Claude-facing) |
| 並列可否  | Yes (TASK-0164 と並列、別 File Scope) |
| 依存TASK  | TASK-0162 |
| 見積     | 30m |

## 責務

Claude Code 利用者向けに CLAUDE.md / claude-md-snippet.md の 2 ファイルへ Property doctrine cross-reference を追加。AGENTS.md / agents-md-snippet.md (TASK-0164) と semantic 整合させる (paired-update doctrine 準拠)。

## 入力

- SPEC-0024 FR-08 (CLAUDE.md cross-ref schema)
- SPEC-0024 FR-09 (claude-md-snippet.md parallel bullet schema)
- TASK-0162 で確定した governance §11 reference path
- 既存 CLAUDE.md §9 (Quality Gate Checklist)
- 既存 templates/claude-md-snippet.md

## 出力

### CLAUDE.md §9 章末に追加 (≤+5 行、R7 厳守)

```markdown
### 9.x Property-based Verify (SPEC-0024)

全 SPEC は権限レベルに応じて Properties セクション (Invariant/Pre/Post/Assumption) を持つ。
Review Agent は Dead Code / Trust Boundary / Scope Check の 3-gate FP filter を適用。
詳細: sage/governance.md §11
```

### templates/claude-md-snippet.md (≤+2 行)

```markdown
- Properties section is required for new SPECs (system/platform). See sage/governance.md §11.
- Review uses 3-gate FP filter (Dead Code / Trust Boundary / Scope Check).
```

## File Scope（変更許可範囲）

- 変更: `CLAUDE.md` (§9 章末 ≤+5 行のみ)
- 変更: `templates/claude-md-snippet.md` (≤+2 行のみ)

## 禁止事項

- CLAUDE.md の既存 §1〜§9 の本文を変更しない
- AGENTS.md / agents-md-snippet.md を本 TASK で編集しない (TASK-0164 で実施、Claude/Codex 担当境界)
- snippet 既存 bullet を変更しない (additive)
- governance §11 reference 以外の新 doctrine を追加しない (scope 厳守)
- ≤+5 行 (CLAUDE.md) / ≤+2 行 (snippet) を超えない (R7)

## 完了条件

- [ ] `grep -F "Property-based Verify" CLAUDE.md` で 1 件 hit
- [ ] `grep -F "SPEC-0024" CLAUDE.md` で 1 件以上 hit
- [ ] `grep -F "Properties section" templates/claude-md-snippet.md` で 1 件 hit
- [ ] `git diff main HEAD -- CLAUDE.md | grep -c "^+"` で ≤+8 行 (header + 5 lines + buffer)
- [ ] `git diff main HEAD -- templates/claude-md-snippet.md | grep -c "^+"` で ≤+5 行
- [ ] commit message に `TASK-0163:` 含む
