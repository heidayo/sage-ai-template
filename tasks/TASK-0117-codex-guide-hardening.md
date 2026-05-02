# TASK-0117: Codex Guide Hardening — primary-source corrections (PR #15 followup)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0117 |
| SPEC-ID   | (lite lane — fix/*、SPEC 不要) |
| PLAN-ID   | (lite lane — PLAN 不要) |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0114 (PR #15 で merged 済) |
| 見積     | 30m |

## 責務

PR #15 (merged 済) の Codex 1st-round adversarial review で指摘された **P1×2 / P2×2 = 4 件** の factual 不整合を解消する。全件、Codex 公式 docs / GitHub REST API spec を一次ソース確認済 (本 task 着手前に WebFetch 実施)。

## 入力 (Codex review 4 件)

1. **[P1]** `docs/codex-security.md:75-76` `writable_roots` を「tighten writable roots beyond default cwd」と説明していたが、Codex 公式 [config-reference](https://developers.openai.com/codex/config-reference) では「Additional writable roots when sandbox_mode = "workspace-write"」と定義されている。**追加** writable パスであって**制限**ではない。読者が `["./src", "./tests"]` を書くと「src と tests だけに制限」と誤解する。
2. **[P1]** `docs/codex-security.md:211-222` の codex-action YAML sample が公式 [openai/codex-action README](https://github.com/openai/codex-action/blob/main/README.md) の input schema と不整合:
   - `OPENAI_API_KEY` を `env:` に置いていたが、公式は `with: openai-api-key:` (input)
   - `prompt` / `prompt-file` 未指定 (どちらか必須)
   - `drop-sudo: true` という input は存在しない (正しくは `safety-strategy: drop-sudo`、これが既定値)
3. **[P2]** `docs/codex-security.md:245-248` `gh api repos/<OWNER>/<REPO>/audit-log` は **404**。GitHub REST API の audit log は org / enterprise endpoint のみ存在 (`orgs/<ORG>/audit-log` / `enterprises/<ENTERPRISE>/audit-log`)。owner / admin 権限と `read:audit_log` scope の併記も必要。
4. **[P2]** `docs/codex-security.md:115-124` Codex Cloud の「audit log を有効化」「environment 単位の audit log を無効化」記述が公式 [Cloud / web — Internet Access](https://developers.openai.com/codex/cloud/internet-access) docs に該当機能名なし。公式は「review the agent output and work log」表現。

## 出力

- `docs/codex-security.md` の 4 箇所修正:
  - L75-76: 「追加 writable root を明示する」コメントに変更 (例も `["./extra-output"]` 等の cwd 外パスに置換)
  - L211-222: codex-action sample 全面差し替え (公式 README v1 example 準拠、`with: openai-api-key:` / `prompt:` heredoc / `safety-strategy: drop-sudo` / `sandbox: workspace-write`)
  - L245-248: `orgs/<ORG>/audit-log?phrase=...` に変更 + admin 権限 / `read:audit_log` scope note
  - L115-124: 「audit log 有効化」を「agent output と work log の review」に書き換え (公式表現と整合)

- `tasks/TASK-0117-codex-guide-hardening.md` 新規 (本ファイル)

## File Scope（変更許可範囲）

- 変更: `docs/codex-security.md`
- 作成: `tasks/TASK-0117-codex-guide-hardening.md`
- 削除: なし

## 禁止事項

- TASK-0114/0115 で確定した他の 7 セクションを触らない (本 TASK は 4 箇所のピンポイント fix)
- AGENTS.md / CLAUDE.md / SECURITY.md / sage/governance.md / README.md の cross-reference 行は不変 (R7 doctrine 維持)
- `safety-strategy` の他値 (`unprivileged-user` / `read-only` / `unsafe`) を sample に列挙しない (本 TASK 範囲外、簡潔さ優先)

## 完了条件

- [ ] `docs/codex-security.md` で `writable_roots` 説明が「追加」と明示
- [ ] codex-action sample の `with:` block に `openai-api-key`, `prompt` (or `prompt-file`), `safety-strategy: drop-sudo`, `sandbox: workspace-write` 全て含む
- [ ] `repos/.*/audit-log` 文字列が `docs/codex-security.md` から消滅、`orgs/.*/audit-log` に置換
- [ ] Codex Cloud section に「audit log」表記なし、「agent output」「work log」表記あり
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (regression、109/109)
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0117:` を含む
- [ ] branch `fix/codex-guide-hardening` (lite lane、Gate 1+3 のみ)
