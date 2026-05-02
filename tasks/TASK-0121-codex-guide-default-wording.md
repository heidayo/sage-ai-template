# TASK-0121: Codex Guide Default Wording — 「公式既定」→「公式で定義された値 + SAGE 推奨 baseline」 (PR #19 followup)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0121 |
| SPEC-ID   | (lite lane — fix/*、SPEC 不要) |
| PLAN-ID   | (lite lane — PLAN 不要) |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0120 (PR #19 で merged 済) |
| 見積     | 10m |

## 責務

Codex 5th-round adversarial review (final convergence check) で指摘された **P3×1 = 1 件** (確信度 0.64、過去最低) を解消。本 fix で Phase 3 review が完全収束する見込み。R10 doctrine (一次ソース整合性) の wording 精度向上のみ、factual error なし。

## 入力 (Codex 5th-round 指摘 1 件)

1. **[P3]** `docs/codex-security.md:90-91` の「各 key の根拠」表で `sandbox_mode = "workspace-write"` と `approval_policy = "on-request"` を **「Codex 公式既定」** と説明している。Codex 公式 [config-reference](https://developers.openai.com/codex/config-reference) を WebFetch 確認した結果、これらは **「有効な設定値」** として列挙されているが **「default」と明示はされていない**。本 TASK 着手前に再 WebFetch して「neither has an explicitly stated default value with a 'Default:' label」を確認済。R10 doctrine としては「公式既定」と言い切るのは過大主張。

## 出力

- `docs/codex-security.md` の 1 箇所修正:
  - L90-91 (各 key の根拠 表): `Codex 公式既定` → `Codex 公式で定義された値 + SAGE 推奨 baseline` に置換 (2 行とも)

- `tasks/TASK-0121-codex-guide-default-wording.md` 新規 (本ファイル)

## File Scope（変更許可範囲）

- 変更: `docs/codex-security.md`
- 作成: `tasks/TASK-0121-codex-guide-default-wording.md`
- 削除: なし

## 禁止事項

- TASK-0114〜0120 で確定した他箇所を触らない (本 TASK は 2 行のみ)
- AGENTS.md / CLAUDE.md / SECURITY.md / sage/governance.md / README.md は不変
- 推奨値自体を変えない (`sandbox_mode = "workspace-write"` / `approval_policy = "on-request"` の SAGE 推奨は維持、wording のみ精緻化)
- 表中の他 2 行 (`[sandbox_workspace_write] network_access = false` / `mcp_servers` 明示列挙) は触らない

## 完了条件

- [ ] `docs/codex-security.md` から「Codex 公式既定」表現消滅 (2 箇所)
- [ ] 「Codex 公式で定義された値 + SAGE 推奨 baseline」表現に置換 (2 箇所)
- [ ] 推奨値そのもの (`workspace-write` / `on-request`) は変えない
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (109/109、regression)
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0121:` を含む
- [ ] branch `fix/codex-guide-default-wording` (lite lane、Gate 1+3 のみ)
