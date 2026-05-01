# TASK-0105: AGENTS.md + governance §9.2 に Codex specificity 明記

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0105 |
| SPEC-ID   | SPEC-0011 |
| PLAN-ID   | PLAN-0011 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 30m |

## 責務

`AGENTS.md` (Codex 向け instruction file) と `sage/governance.md §9.2` (SAGE が提供しないもの) に、**hook が Claude Code の PreToolUse/PostToolUse 機構に依存しており Codex セッションでは直接効かない** という事実を明示する。

## 入力

- SPEC-0011 FR-06, FR-07, リスク4
- Codex review R2 (Sandbox を SAGE 提供に見せるな) — 同根の課題
- Phase 1 SPEC-0010 §9 SAGE Scope Boundary (補完関係図)
- 既存 `AGENTS.md` (312 行)、`sage/governance.md` (§9 章追加済)

## 出力

### AGENTS.md 修正

§1 (Project Overview) または §2 (Instruction Priority) の末尾に **§ Codex specificity** 短いセクションを追加 (1 段落、約 6-8 行 / 300 字以内):

```markdown
## Codex specificity (hooks ≠ Codex enforcement)

SAGE の `templates/hooks/` (block-dangerous-commands.sh / protect-sage-files.sh 他) は Claude Code の `PreToolUse` / `PostToolUse` 機構で実行されます。**Codex セッションではこれらの hook は直接動作しません**。Codex 側では、対応する防御を以下で別途構築してください:

- `~/.codex/config.toml` で `sandbox_mode = "workspace-write"` + `approval_policy = "on-request"` (既定推奨)
- network access は agent phase で off (`internet_access = false`)
- `.env` の `CODEX_HOME` 書き換えは Codex CLI 0.23.0+ で防止 ([CVE-2025-61260](https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/))
- branch name / PR title / issue body は untrusted input として扱う ([BeyondTrust 報告](https://www.beyondtrust.com/blog/entry/openai-codex-command-injection-vulnerability-github-token))
- 詳細は [SECURITY.md §3](SECURITY.md) と [sage/governance.md §9 Scope Boundary](sage/governance.md) を参照

SAGE が提供する Codex 向け価値は: SPEC/PLAN/TASK lifecycle、File Scope、anti-pattern 学習枠組み、AGENTS.md ルール — **runtime enforcement ではなく仕様駆動の構造設計**。
```

### sage/governance.md §9.2 修正

§9.2 「SAGE が提供しないもの」テーブルの該当行を強化:

- 既存「**Claude Code / Codex 本体の runtime sandbox 強制**」行の説明に追記:
  > `templates/hooks/` は Claude Code 専用機構。**Codex セッションでは hook は直接動作せず、Codex sandbox 設定 (`sandbox_mode` / `approval_policy` / `internet_access`) で同等の防御を別途構築する必要がある**。AGENTS.md "Codex specificity" 段落参照。

## File Scope（変更許可範囲）

- 変更: `AGENTS.md` (新セクション追加のみ、既存セクション変更禁止)
- 変更: `sage/governance.md` (§9.2 該当行のみ追記)
- 削除: なし

## 禁止事項

- AGENTS.md の他のセクション (§0 callout / §1 / §2 / §3 SAGE Lifecycle 等) の変更禁止
- governance.md の §9 以外の章の変更禁止
- protect-sage-files hook が AGENTS.md / sage/governance.md 編集を block する場合は active TASK (本 TASK-0105) を SAGE-managed として明示し、commit message に `human-approved meta change` 明記
- 過度に長い説明 (15 行超) を追加禁止 — Codex review R7 (CLAUDE.md/AGENTS.md を肥大化させない) 同根

## 完了条件

- [ ] `grep -q "Codex specificity\|hook は Claude Code\|Codex sessions" AGENTS.md`
- [ ] `grep -q "Codex セッションでは hook は直接動作せず\|Codex sandbox" sage/governance.md`
- [ ] AGENTS.md 行数増加 ≤ 15 行
- [ ] sage/governance.md 行数増加 ≤ 5 行
- [ ] AGENTS.md / governance.md 編集が hook で block されないこと (TASK-0105 を sage-managed: true で起票することで対応)
- [ ] commit message に `TASK-0105:` を含む
