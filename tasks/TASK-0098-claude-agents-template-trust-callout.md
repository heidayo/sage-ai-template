# TASK-0098: CLAUDE.md / AGENTS.md 冒頭に template-trust callout 追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0098 |
| SPEC-ID   | SPEC-0010 |
| PLAN-ID   | PLAN-0010 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0095 SECURITY.md が先) |
| 依存TASK  | TASK-0095 |
| 見積     | 20m |

## 責務

cloned repository の `.claude/settings.json` / `AGENTS.md` / `CLAUDE.md` を未レビューで信頼してはいけない (Check Point CVE-2025-59536, CVE-2026-33068 と同質の supply chain 攻撃面) 旨を、AI agent が最初に読む位置に配置する。

## 入力

- SPEC-0010 FR-09, リスク1 (callout は最大 8 行)
- Codex review R7 (CLAUDE.md / AGENTS.md を肥大化させない、リンクで逃がす)
- 関連 CVE: CVE-2026-33068 (8.8 HIGH, Claude Code trust dialog bypass)
- 関連事例: Check Point CVE-2025-59536 (Claude Code project files RCE)
- 関連事例: BeyondTrust (Codex branch name injection)

## 出力

CLAUDE.md と AGENTS.md それぞれの **タイトル直後 (Section 0 として)** に、以下構造の callout を挿入:

```markdown
> [!IMPORTANT]
> **これはテンプレートです。未レビューで信頼してはいけません。**
> このリポジトリの `.claude/settings.json`, `.mcp.json`, `templates/hooks/`, `[CLAUDE|AGENTS].md` は AI agent の権限・実行・記憶に影響します。clone 直後のフルパス信頼は、Check Point CVE-2025-59536 / NVD CVE-2026-33068 と同質の supply chain 攻撃面になり得ます。
> 詳細と検証手順は [SECURITY.md](SECURITY.md) と [sage/governance.md §9 Scope Boundary](sage/governance.md) を参照してください。
```

(日本語版 + 英語要約を1ブロック内に含める。最大 8 行以内 / 約 400 文字以内)

## File Scope（変更許可範囲）

- 変更: `CLAUDE.md` (タイトル直後への挿入のみ、その他の節は変更禁止)
- 変更: `AGENTS.md` (タイトル直後への挿入のみ、その他の節は変更禁止)
- 削除: なし

## 禁止事項

- CLAUDE.md / AGENTS.md の他のセクションの修正禁止
- callout 内に詳細な脅威モデルを書かない (SECURITY.md / governance.md にリンクで逃がす — Codex R7 対応)
- callout 高さ 8 行 / 400 文字を超えない (context 圧迫防止)
- 既存の SAGE marker (`<!-- SAGE_INJECT_*_START -->`) の構造を破壊しない
- protect-sage-files hook が CLAUDE.md / AGENTS.md 編集を block する場合: commit message に `TASK-0098: SPEC-0010 human-approved meta change` を明記

## 完了条件

- [ ] `head -50 CLAUDE.md | grep -qi "template\|trust\|review before"`
- [ ] `head -50 AGENTS.md | grep -qi "template\|trust\|review before"`
- [ ] CLAUDE.md と AGENTS.md の callout が同じ意味 (semantic alignment、Codex R7)
- [ ] CLAUDE.md と AGENTS.md それぞれの行数増加が 10 行以内
- [ ] commit message に `TASK-0098:` を含む
