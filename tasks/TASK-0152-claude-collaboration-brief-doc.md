# TASK-0152: docs/claude-collaboration-brief.md 新規作成

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0152 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes (TASK-0153 と並列可) |
| 依存TASK  | TASK-0151 |
| 見積     | 75m |

## 責務

Claude Code 利用者向けの collaboration guidance を `docs/claude-collaboration-brief.md` として新規作成する。docs/codex-delegation-packet.md と semantic mirror になる「役割分担」節を持ち、Plan Mode / Skills / auto memory / Codex Handoff Triggers を含む。

## 入力

- SPEC-0023 §「機能要件」FR-01 (7 セクション必須)
- 既存 `docs/codex-delegation-packet.md` (semantic mirror の参照元、新規 brief で相互参照する)
- Anthropic Claude Code 公式 docs (Plan Mode / Skills / auto memory / model aliases、一次ソース)
- 8 件 Notion 教材の Claude Code 特性 (collaboration、質問先行、Plan Mode、Skills)

## 出力

`docs/claude-collaboration-brief.md` (新規、約 130-180 行) — 以下 7 セクション:

1. **使う場面** — Claude Code が適切な engagement の typical scenario
2. **Claude Collaboration Brief template** — markdown blockquote で 6 入力欄 (Goal / Open Questions / Decision Points / Plan Mode trigger / Codex Handoff trigger / Memory Hooks)
3. **Plan Mode 判定** — when to enter Plan Mode (大規模変更 / 設計判断必要 / 複数ファイル影響時)
4. **Skill / slash command guide** — `/sage-spec`, `/sage-plan`, `/sage-evaluate`, `/sage-review`, `/sage-promote`, `/sage-harness` の使い分け
5. **Auto memory 利用方針** — 何を保存するか (user / feedback / project / reference 4 types) と保存しないもの (ephemeral / git-derivable)
6. **Codex Handoff Triggers** — Claude が「これは Codex に委任すべき」と判断する signal (well-scoped / clear AC / 反復処理 / GitHub Issue / PR コメント対応)
7. **Codex / Claude 役割分担** — docs/codex-delegation-packet.md の同名節と semantic mirror

## File Scope（変更許可範囲）

- 作成: `docs/claude-collaboration-brief.md`
- 変更: なし
- 削除: なし

## 禁止事項

- `docs/codex-delegation-packet.md` を編集しない (SPEC-0022 territory)
- `CLAUDE.md` / `AGENTS.md` / snippet / installer 等を本 TASK で修正しない (TASK-0153/0154 territory)
- secret / credential / `.env` 例値を含めない (gitleaks 通過必須、SEC-04)
- Plan Mode / Skill / auto memory の Claude Code 機能を不正確に記述しない (一次ソース参照)
- markdown 内 link は existing file path を相対参照のみ (例: `../specs/SPEC-0023-...md`)

## 完了条件

- [ ] `docs/claude-collaboration-brief.md` が存在し、FR-01 の 7 セクション全て含む
- [ ] `grep -F "## 使う場面" docs/claude-collaboration-brief.md` PASS
- [ ] `grep -F "## Codex Handoff Triggers" docs/claude-collaboration-brief.md` PASS
- [ ] `grep -F "## Codex / Claude 役割分担" docs/claude-collaboration-brief.md` PASS
- [ ] `grep -F "docs/codex-delegation-packet.md" docs/claude-collaboration-brief.md` PASS (cross-reference)
- [ ] `gitleaks detect --no-git --redact --source docs/claude-collaboration-brief.md` PASS (no leaks)
- [ ] commit message に `TASK-0152:` 含む
