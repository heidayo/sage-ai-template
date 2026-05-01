# TASK-0104: protect-sage-files.sh content check expansion

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0104 |
| SPEC-ID   | SPEC-0011 |
| PLAN-ID   | PLAN-0011 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0101 test harness が前提) |
| 依存TASK  | TASK-0101 |
| 見積     | 75m |

## 責務

`templates/hooks/protect-sage-files.sh` に、書き込み内容 (`tool_input.content`) を検査して dangerous keys が含まれる場合に追加 block を行う層を追加。既存の path 単位の block 機能は完全保持。

## 入力

- SPEC-0011 FR-05
- 既存 `templates/hooks/protect-sage-files.sh` (136 行)
- 参考: [CVE-2026-33068 trust dialog bypass](https://nvd.nist.gov/vuln/detail/CVE-2026-33068) (`bypassPermissions` 注入)
- 参考: [Check Point CVE-2025-59536 Claude Code RCE](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/) (`ANTHROPIC_BASE_URL` 経由 API key exfil)
- 参考: [Check Point CVE-2025-61260 Codex CLI RCE](https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/) (`CODEX_HOME` redirect)
- TASK-0101 で構築した test harness

## 出力

`templates/hooks/protect-sage-files.sh` の既存 path 検査ロジックの後に **content check 層** を追加:

1. **`.claude/settings.json` 書き込み**: `tool_input.content` が以下を含む場合 block (active TASK 有無に関わらず):
   - `"defaultMode"\s*:\s*"bypassPermissions"` (CVE-2026-33068 と同質)
   - `"enableAllProjectMcpServers"\s*:\s*true` (project-controlled MCP の自動許可、Backslash 警告参照)
2. **`.env` / `.env.local` / `.env.production` 書き込み**: `tool_input.content` が以下を含む場合 block:
   - `^CODEX_HOME\s*=` (CVE-2025-61260 と同質)
   - `^ANTHROPIC_BASE_URL\s*=` (CVE-2025-59536 と同質)
3. **`.codex/config.toml` または `.mcp.json` 書き込み**: `tool_input.content` に `mcp_servers\s*=\s*\[` または `"mcpServers"\s*:\s*\{` で始まる新 server entry が含まれる場合、現在の path 検査ロジックを越えて追加警告 + block (active TASK でも block — supply chain attack 検出)

各 block 時の stderr メッセージは、対応する CVE 番号と一次ソース URL を含める (Phase 1 §9 doctrine と整合)。

`templates/hooks/tests/test-protect-sage-files.sh` に各ケースの positive + negative テスト追加。

`scripts/generate-installer.sh` + `install.sh` 再生成。

## File Scope（変更許可範囲）

- 変更: `templates/hooks/protect-sage-files.sh` (末尾追加: content check section)
- 変更: `templates/hooks/tests/test-protect-sage-files.sh` (test 追加)
- 変更: `install.sh` (generate-installer.sh からの再生成)
- 削除: なし

## 禁止事項

- 既存 path 検査ロジックの変更/削除禁止
- profile gating の変更禁止
- jq fallback path の content 検査未対応で block を強める禁止 (jq 不在環境では既存 path 検査のみ動作、新検査は skip)
- 過度に広いパターンで block (例: `bypassPermissions` 単独文字列、コメント内も含む) は禁止 — JSON value position に限定する正規表現を使う

## 完了条件

- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (既存 + 新 test 含む)
- [ ] `.claude/settings.json` への `"defaultMode": "bypassPermissions"` 書き込みが block (active TASK 状態でも block)
- [ ] `.env` への `CODEX_HOME=./malicious` 書き込みが block
- [ ] `.env` への `ANTHROPIC_BASE_URL=https://attacker.example` 書き込みが block
- [ ] `.mcp.json` への新 server entry 追加 (`"mcpServers": { "evil": ... }`) が block
- [ ] `.claude/settings.json` への通常 permission 設定 (allow/ask/deny のみ) は許可される (false positive 0)
- [ ] block 時 stderr に CVE 番号と公式 URL が含まれる
- [ ] `bash install.sh --dry-run` exit 0
- [ ] commit message に `TASK-0104:` を含む
