# TASK-0114: docs/codex-security.md (8-section Codex security guide)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0114 |
| SPEC-ID   | SPEC-0013 |
| PLAN-ID   | PLAN-0013 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 90m |

## 責務

`docs/codex-security.md` を新規作成。Codex 利用者向けに以下 8 セクションを「TL;DR + 詳細 + 一次ソース link」3 段構成で整理する。

## 入力

- SPEC-0013 FR-01 〜 FR-05, NFR-02, SEC-01〜03
- Phase 1 SECURITY.md / Phase 2A AGENTS.md §2.1 / Phase 2B governance §9
- 一次ソース:
  - https://developers.openai.com/codex/config-reference
  - https://developers.openai.com/codex/cloud/internet-access
  - https://github.com/openai/codex-action/security
  - https://nvd.nist.gov/vuln/detail/CVE-2025-61260
  - https://nvd.nist.gov/vuln/detail/CVE-2026-33068
  - https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/
  - https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/
  - https://www.beyondtrust.com/blog/entry/openai-codex-command-injection-vulnerability-github-token

## 出力

`docs/codex-security.md` 新規。以下 8 セクション:

1. **概要 (Scope and intent)** — SAGE は Codex runtime enforcement を提供しない (governance §9 link)、補完関係図、本 doc の position
2. **Codex CLI 推奨設定** — `~/.codex/config.toml` 推奨 TOML 全文 (`sandbox_mode = "workspace-write"` + `approval_policy = "on-request"` + `[sandbox_workspace_write] network_access = false` 等)、各 key の根拠
3. **Codex Cloud / web** — agent internet access は環境単位 (default off)、setup phase との分離、agent phase で外部 URL 取得を許す場合の domain allowlist 推奨
4. **CODEX_HOME redirect 攻撃 (CVE-2025-61260) 対策** — Codex CLI 0.23.0+ 必須、`.env` の `CODEX_HOME=` を疑う、Phase 2B `protect-sage-files.sh` content check が `.env` 書き込みでこのキーを block する旨
5. **Untrusted input as code** — branch name / PR title / issue body / `AGENTS.md` を untrusted として扱う、BeyondTrust 報告引用、shell injection 対策
6. **codex-action GitHub Actions hardening** — `allow-users` 制限 / `${{ secrets.OPENAI_API_KEY }}` scope / `drop-sudo` / Codex job 最後 / branch name の `env` 変数経由 (SEC-02 厳守の YAML サンプル)
7. **Incident response** — Codex 関連 incident 検知 → token rotate (`gh auth refresh`)、audit log 確認 (`gh api repos/{owner}/{repo}/audit-log`)、影響 PR 特定
8. **References** — 一次ソース URL 全件、Last reviewed 日付 + 確認 Codex CLI version 明記

## File Scope（変更許可範囲）

- 作成: `docs/codex-security.md`
- 変更: なし
- 削除: なし

## 禁止事項

- 既存 doc (CLAUDE.md / AGENTS.md / SECURITY.md / governance.md / README.md) への変更禁止 (TASK-0115 で扱う)
- TOML / YAML サンプルに本物 secret 値の使用禁止 (SEC-01, SEC-02)
- 推奨設定と公式 docs の不一致禁止 (FR-03, FR-04)
- doc 600 行超過禁止 (NFR-02)
- TL;DR 省略禁止 (各 section 冒頭で 1-3 行 summary 必須)

## 完了条件

- [ ] `test -f docs/codex-security.md`
- [ ] `grep -c "^## " docs/codex-security.md` >= 8
- [ ] `grep -E "CVE-2025-61260|CVE-2025-59536|CVE-2026-33068" docs/codex-security.md | wc -l` >= 3
- [ ] `grep -F "[sandbox_workspace_write]" docs/codex-security.md` 含む
- [ ] `grep -F "developers.openai.com/codex/config-reference" docs/codex-security.md` 含む
- [ ] `grep -F "developers.openai.com/codex/cloud/internet-access" docs/codex-security.md` 含む
- [ ] `grep -F "github.com/openai/codex-action/security" docs/codex-security.md` 含む
- [ ] `wc -l docs/codex-security.md` ≤ 600
- [ ] doc 末尾に `Last reviewed: 2026-05-02` 等の日付 + Codex CLI version 明記
- [ ] commit message に `TASK-0114:` を含む
