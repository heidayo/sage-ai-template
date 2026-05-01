# TASK-0110: templates/settings/sandbox.json + README

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0110 |
| SPEC-ID   | SPEC-0012 |
| PLAN-ID   | PLAN-0012 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 45m |

## 責務

Claude Code の sandbox 推奨設定を `templates/settings/sandbox.json` として提供。SAGE 自身は適用しない (Codex review R2: SAGE は runtime sandbox を提供しない doctrine 維持)、user が自分の `.claude/settings.json` に merge する手順を README に明記する。

## 入力

- SPEC-0012 FR-04, FR-05, OPS-01, SEC-04
- Codex review R2 (Sandbox を SAGE 提供と見せるな)
- Phase 1 SECURITY.md §3.1 と governance §9.1
- 参考: [Anthropic Claude Code Sandboxing 公式](https://www.anthropic.com/engineering/claude-code-sandboxing)

## 出力

1. `templates/settings/sandbox.json` 新規 (valid JSON、コメント不可):
   ```json
   {
     "permissions": {
       "deny": [
         "Read(./.env)",
         "Read(./.env.local)",
         "Read(./.env.production)",
         "Read(~/.ssh/**)",
         "Read(~/.aws/**)",
         "Read(~/.config/gcloud/**)",
         "Bash(rm -rf *)",
         "Bash(curl * | *sh)",
         "Bash(wget * | *sh)",
         "Bash(git push --force *)"
       ],
       "ask": [
         "Bash(git commit *)",
         "Bash(git push *)",
         "Bash(npm install *)",
         "Bash(pnpm add *)"
       ]
     },
     "sandbox": {
       "enabled": true,
       "failIfUnavailable": true,
       "allowUnsandboxedCommands": false,
       "filesystem": {
         "denyRead": [
           "~/.ssh",
           "~/.aws",
           "~/.config/gcloud",
           "./.env",
           "./.env.local",
           "./.env.production",
           "./secrets"
         ]
       },
       "network": {
         "allowedDomains": [
           "registry.npmjs.org",
           "api.github.com",
           "api.anthropic.com",
           "code.claude.com"
         ]
       }
     }
   }
   ```

2. `templates/settings/README.md` 新規 (日本語):
   - **冒頭の disclaimer**: SAGE は runtime sandbox を提供しない (governance §9.2 link)、これは雛形であり user 環境への適用は user 責任
   - **適用手順**:
     - merge 推奨 (既存 `.claude/settings.json` がある場合)
     - jq での merge コマンド例 (`jq -s '.[0] * .[1]' .claude/settings.json templates/settings/sandbox.json`)
     - merge 後は `.claude/settings.json` を必ず diff review してから session 開始
   - **各設定の根拠** (CVE/一次ソース link):
     - `Read(./.env)` deny → CVE-2026-25723, CVE-2025-59536 関連
     - `bypassPermissions` 系の禁止 → CVE-2026-33068
     - `failIfUnavailable: true` → sandbox 不在で sliently 続行する事故防止
     - `denyRead ~/.ssh` → SSH key 漏洩防止
     - `network.allowedDomains` → exfiltration vector 制限
   - **カスタマイズの注意**:
     - `network.allowedDomains` に user の必要 API endpoint を追加してよい (e.g., `api.openai.com` を Codex も使う場合)
     - `denyRead` を緩めるのは慎重に
     - 初回 merge 後は plan mode から始めて挙動確認

## File Scope（変更許可範囲）

- 作成: `templates/settings/sandbox.json`
- 作成: `templates/settings/README.md`
- 削除: なし

## 禁止事項

- `.claude/settings.json` への直接書き込み禁止 (本 TASK は templates/ 配置のみ、`.claude/settings.json` 修正は TASK-0111 で `.claude/settings.json` の hooks 配列拡張のみ)
- sandbox.json にコメント (JSON 標準で無効) 入れる禁止
- README で「SAGE が自動で適用する」など誤解を招く表現禁止
- `network.allowedDomains` に host wildcard (`*.com` 等) 推奨禁止 — exfiltration vector 残る

## 完了条件

- [ ] `jq . templates/settings/sandbox.json` exit 0 (valid JSON)
- [ ] `templates/settings/README.md` に "SAGE does not auto-apply" 旨の disclaimer
- [ ] README に jq merge コマンド例
- [ ] README に CVE 引用 (CVE-2026-25723 / CVE-2025-59536 / CVE-2026-33068 のいずれか)
- [ ] sandbox.json の `network.allowedDomains` に `api.anthropic.com` (Claude API) 含む (SEC-04)
- [ ] commit message に `TASK-0110:` を含む
