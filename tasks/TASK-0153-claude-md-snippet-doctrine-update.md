# TASK-0153: CLAUDE.md §2 doctrine 更新 + §2.1 parallel guidance + AGENTS.md §2 sync + claude-md-snippet.md parallel

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0153 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | Yes (TASK-0152 と並列可) |
| 依存TASK  | TASK-0151 |
| 見積     | 45m |

## 責務

CLAUDE.md / AGENTS.md / templates/claude-md-snippet.md に SPEC-0023 paired guidance を追加する。CLAUDE.md ↔ AGENTS.md の §2 doctrine 文言を semantic alignment + CLI-specific divergence 許容に同期更新する。R7 ≤+5 行/file 厳守。

## 入力

- SPEC-0023 §「機能要件」FR-02 (doctrine 更新), FR-03 (CLAUDE.md §2.1 parallel guidance), FR-04 (snippet parallel)
- 既存 CLAUDE.md L26 「AGENTS.md is the Codex-specific counterpart. The two documents must stay semantically aligned.」
- 既存 AGENTS.md L26 「CLAUDE.md is the Claude Code-specific counterpart. The two documents must stay semantically aligned.」
- 既存 AGENTS.md L41-43 (SPEC-0022 で追加された Codex-only 3 bullets、本 TASK で読み取り参照のみ)
- 既存 templates/agents-md-snippet.md L17-18 (SPEC-0022 で追加された Codex-only 2 bullets、本 TASK で読み取り参照のみ)
- TASK-0152 の `docs/claude-collaboration-brief.md` (本 TASK で reference する)

## 出力

### CLAUDE.md (3 箇所更新、≤+5 行)

1. **§2 doctrine 文言更新** (L26): 「The two documents must stay semantically aligned.」を「The two documents must stay semantically aligned for SHARED rules. CLI-specific guidance (Codex Delegation Packet, Claude Collaboration Brief) may diverge but requires a paired update under [SPEC-0023](specs/SPEC-0023-claude-collaboration-pairing.md) §10 doctrine.」に更新
2. **§2.1 末尾に parallel guidance 3 bullets 追加** (AGENTS.md §2.1 末尾の 3 bullets と semantic mirror):
   - Claude Code は協働型 agent として扱う。詳細は [docs/claude-collaboration-brief.md](docs/claude-collaboration-brief.md) を参照
   - Well-scoped task は Codex に委任する判断をする (packet を書いて [docs/codex-delegation-packet.md](docs/codex-delegation-packet.md) に従う)
   - Codex-specific ファイル (`AGENTS.md`, `docs/codex-*.md`) の修正は Codex 側 task に分離し、Claude は直接編集しない

### AGENTS.md (1 箇所更新、≤+1 行)

- **§2 doctrine 文言 sync** (L26): 「The two documents must stay semantically aligned.」を「The two documents must stay semantically aligned for SHARED rules. CLI-specific guidance may diverge but requires a paired update under [SPEC-0023](specs/SPEC-0023-claude-collaboration-pairing.md) §10 doctrine.」に更新

### templates/claude-md-snippet.md (2 bullets 追加、≤+2 行)

- Claude collaboration brief: reference docs/claude-collaboration-brief.md for engagement patterns; well-scoped tasks may be delegated to Codex via packet.
- Claude-only boundary: do not edit Codex-specific files (`AGENTS.md`, `docs/codex-*.md`) unless human explicitly assigns. Record as Codex follow-up otherwise.

## File Scope（変更許可範囲）

- 変更: `CLAUDE.md`
- 変更: `AGENTS.md`
- 変更: `templates/claude-md-snippet.md`

## 禁止事項

- **R7 違反禁止**: CLAUDE.md ≤+5 行 / AGENTS.md ≤+1 行 / claude-md-snippet.md ≤+2 行を厳守
- AGENTS.md §2.1 末尾の SPEC-0022 由来 Codex-only 3 bullets を編集しない (Codex side territory)
- templates/agents-md-snippet.md を編集しない (SPEC-0022 territory)
- CLAUDE.md / AGENTS.md に新規 H2/H3 heading を追加しない (既存節内の文字列更新 + bullet append のみ)
- shellcheck / yaml lint 対象外 (markdown only)
- `docs/claude-collaboration-brief.md` を本 TASK で作成しない (TASK-0152 territory、本 TASK は参照のみ)

## 完了条件

- [ ] `CLAUDE.md` §2 doctrine が更新され、`grep -F "may diverge" CLAUDE.md && grep -F "SPEC-0023" CLAUDE.md` PASS
- [ ] `CLAUDE.md` §2.1 (または近接) に parallel guidance 3 bullets 追加、`grep -F "Claude Code は協働型" CLAUDE.md && grep -F "Codex-specific" CLAUDE.md && grep -F "docs/claude-collaboration-brief.md" CLAUDE.md` PASS
- [ ] `AGENTS.md` §2 doctrine が CLAUDE.md と semantic 整合、`grep -F "may diverge" AGENTS.md` PASS
- [ ] `templates/claude-md-snippet.md` に parallel 2 bullets 追加、`grep -F "Claude collaboration brief" templates/claude-md-snippet.md && grep -F "Claude-only boundary" templates/claude-md-snippet.md` PASS
- [ ] `git diff TASK-0152..HEAD --stat -- CLAUDE.md AGENTS.md templates/claude-md-snippet.md` で各ファイル R7 上限内 (CLAUDE ≤+5、AGENTS ≤+1、snippet ≤+2)
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0153: human-approved meta change` 含む (CLAUDE.md / AGENTS.md 編集のため)
