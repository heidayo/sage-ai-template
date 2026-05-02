# TASK-0118: Codex Guide Hardening 2 — privilege separation + access-log wording (PR #16 followup)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0118 |
| SPEC-ID   | (lite lane — fix/*、SPEC 不要) |
| PLAN-ID   | (lite lane — PLAN 不要) |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0117 (PR #16 で merged 済) |
| 見積     | 30m |

## 責務

PR #16 (merged 済) の Codex 2nd-round adversarial review で指摘された **P2×2 = 2 件** を解消する。両件、Codex 公式 docs / openai/codex-action 公式 README example を一次ソース確認済 (TASK-0117 で WebFetch 済)。

## 入力 (Codex 2nd-round 指摘 2 件)

1. **[P2]** `docs/codex-security.md:201-208` codex-action sample の Codex 実行 job に `pull-requests: write` が付与されている。公式 [openai/codex-action README example](https://github.com/openai/codex-action/blob/main/README.md) では Codex 実行 job は `contents: read` のみで、PR comment を投稿する `post_feedback` job が分離されている (least-privilege + 投稿 step を Codex 実行から isolate)。本 sample 内では comment 投稿 step を含まないため `pull-requests: write` 自体不要。
2. **[P2]** `docs/codex-security.md:108` Codex Cloud TL;DR に「access log を運用で confirm」と残存。前回 (TASK-0117) で本文側の「audit log」表記は修正したが TL;DR 側に「access log」が見落とし。Codex Cloud Internet Access [公式 docs](https://developers.openai.com/codex/cloud/internet-access) で裏付けられる用語は「agent output」と「work log」のみ。

## 出力

- `docs/codex-security.md` の 2 箇所修正:
  - L108 (TL;DR): 「access log を運用で confirm」→「agent output / work log を必ず review (公式 docs 参照)」
  - L201-235 (codex-action sample): Codex 実行 job の `permissions` を `contents: read` のみに削減 + `outputs:` で `final_message` を export + 公式 example 準拠の `post_feedback` job (issues/pull-requests write、actions/github-script で comment 投稿) を追加。privilege separation の意図を inline コメントで明示

- `tasks/TASK-0118-codex-guide-hardening-2.md` 新規 (本ファイル)

## File Scope（変更許可範囲）

- 変更: `docs/codex-security.md`
- 作成: `tasks/TASK-0118-codex-guide-hardening-2.md`
- 削除: なし

## 禁止事項

- TASK-0114/0115/0117 で確定した他 6 セクションを触らない (本 TASK は 2 箇所のピンポイント fix)
- AGENTS.md / CLAUDE.md / SECURITY.md / sage/governance.md / README.md の cross-reference 行は不変 (R7 doctrine 維持)
- `safety-strategy` の他値 (`unprivileged-user` / `read-only` / `unsafe`) を sample に追加しない (TASK-0117 で意図的に省略済、本 TASK 範囲外)

## 完了条件

- [ ] `docs/codex-security.md` TL;DR (§3) に `access log` / `audit log` 文字列が無い (Cloud section 内のみ確認、§7 IR 内の GitHub audit log 記述は別物で残存可)
- [ ] codex-action sample の `codex` job `permissions:` が `contents: read` のみ
- [ ] `post_feedback` job が分離されており `permissions: { issues: write, pull-requests: write }` を持つ
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (109/109、regression)
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0118:` を含む
- [ ] branch `fix/codex-guide-hardening-2` (lite lane、Gate 1+3 のみ)
