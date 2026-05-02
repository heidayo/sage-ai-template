# Codex Security Guide for SAGE Adopters

> **Scope** — このドキュメントは SAGE Development System を **Codex (Codex CLI / Codex Cloud / codex-action)** と組み合わせて使う組織向けの security guidance をまとめます。Claude Code 専用の hook / sandbox は [`.claude/settings.json`](../.claude/settings.json) と [`templates/hooks/`](../templates/hooks/) で扱います。
>
> **SAGE は Codex runtime enforcement を提供しません** ([sage/governance.md §9.2](../sage/governance.md))。本 doc は Codex 公式設定の **推奨集 + チェックリスト** であり、適用は user 責任です。

---

## 1. 概要 (Scope and intent)

### TL;DR
- Codex の安全性は Codex 本体機能 (`~/.codex/config.toml` / Codex Cloud 環境設定 / codex-action workflow 設定) で構築する
- SAGE は doctrine + 雛形 + ドキュメント + 仕様駆動プロセスを提供する
- 本 doc は Codex 公式 docs と SAGE 既存 doctrine を相互参照しながら、Codex 利用者が **「最小チェックリスト + コピペ可能な設定」** を一箇所で得られるようにする

### SAGE と Codex の補完関係

```
+-----------------------------+   +--------------------------------+
|  SAGE (this repository)     |   |  Codex (CLI / Cloud / Action)  |
|                             |   |                                |
| - SPEC/PLAN/TASK lifecycle  |   | - Sandbox enforcement          |
| - File Scope rules          |<->| - Approval policy              |
| - Anti-pattern learning     |   | - Network access control       |
| - AGENTS.md instruction     |   | - Token / credential handling  |
| - hook templates (Claude    |   | - codex-action runner perms    |
|   Code only — see note)     |   |                                |
+-----------------------------+   +--------------------------------+
              |                                   |
              +----------> Defense in Depth <-----+
                              |
                              v
              + Vault / Secret manager
              + GitHub branch protection
              + Deterministic scanners (gitleaks / trivy / semgrep)
              + Human review at high-risk action
              + Incident response procedure
```

### 本 doc の position
- AGENTS.md §2.1 → 短い callout (12-18 行)
- SECURITY.md §3 / §4 → SAGE 全体の threat model と non-coverage
- sage/governance.md §9 → SAGE Scope Boundary (= 何を提供しないか)
- **本 doc** → Codex 利用者向けの **設定例 + チェックリスト + incident response 手順**

詳細手順や設定例の長文はすべてここに集約し、他 doc は概要 + リンクで済ませます (Codex review R7 doctrine: instruction files を肥大化させない)。

---

## 2. Codex CLI 推奨設定 (`~/.codex/config.toml`)

### TL;DR
- `sandbox_mode = "workspace-write"` + `approval_policy = "on-request"` を base にする
- network 遮断は `[sandbox_workspace_write]` table の `network_access = false` で設定
- `danger-full-access` モードと `approval_policy = "never"` の組み合わせは原則禁止
- Codex CLI は **0.23.0 以上**を必須 ([CVE-2025-61260](https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/) 修正版)

### 推奨 TOML

```toml
# ~/.codex/config.toml
# SAGE-recommended baseline. Customize per project.

# 1. Run agent commands with workspace-write privilege but no host break-out.
sandbox_mode = "workspace-write"

# 2. Surface approval prompts on each non-routine action (not "never").
approval_policy = "on-request"

[sandbox_workspace_write]
# 3. Block network from inside the agent sandbox by default.
#    Add specific upstream allowlist if your workflow needs it.
network_access = false

# 4. Optional: ADD additional writable roots beyond the default cwd.
#    Note: writable_roots EXTENDS write access — it does NOT restrict it.
#    To narrow write scope, launch Codex from a smaller working directory.
# writable_roots = ["/tmp/codex-output"]

[mcp_servers]
# 5. List ONLY trusted MCP servers explicitly. Do NOT import from a
#    cloned repo's .codex/config.toml without auditing it (CVE-2025-61260).
# example_trusted_mcp = { command = "node", args = ["./mcp/example.js"] }
```

### 各 key の根拠

| Key | 根拠 |
|---|---|
| `sandbox_mode = "workspace-write"` | Codex 公式で定義された値 + SAGE 推奨 baseline ([config-reference](https://developers.openai.com/codex/config-reference)、CLI default は明示されていないため独自に baseline を定める) |
| `approval_policy = "on-request"` | Codex 公式で定義された値 + SAGE 推奨 baseline (high-risk operation の人間 review を保つため、SAGE Scope Boundary §9.2 に基づく) |
| `[sandbox_workspace_write] network_access = false` | exfiltration vector 制限 ([Lethal Trifecta — Airia](https://airia.com/ai-security-in-2026-prompt-injection-the-lethal-trifecta-and-how-to-defend/)) |
| `mcp_servers` 明示列挙 | [CVE-2025-61260](https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/) — project-local config の自動 MCP 起動を防ぐ |

### Codex CLI の禁止運用

- `sandbox_mode = "danger-full-access"` の常用 → **原則禁止**。dev container / VM の中でしか使わない
- `approval_policy = "never"` + 任意 sandbox_mode → 高リスク operation の人間 review が消える
- `--yolo` flag (もし将来追加されても) → 通常開発では使わない

---

## 3. Codex Cloud / web

### TL;DR
- Codex Cloud (web 経由) の agent internet access は **環境単位** で管理、既定 off
- setup phase (依存 install) と agent phase (実行) は分離されている — agent phase での internet access はさらに保守的に
- 必要時のみ allowlist で解除し、agent output / work log を必ず review (公式 docs 表現、後述)

### Setup phase vs Agent phase

| Phase | 既定 internet access | 推奨 |
|---|---|---|
| Setup (dependency install) | controlled (registry 等) | そのまま |
| Agent execution | **off** | 必要 endpoint のみ allowlist |

### 公式リファレンス

- [Codex Cloud / web — Internet Access](https://developers.openai.com/codex/cloud/internet-access)
- 公式表現 (引用): "allow only the domains and HTTP methods you need, and review the agent output and work log."
- 運用: agent phase 完了後に **agent output** と **work log** を必ず review (公式 docs で明示されている唯一の監視手段)

### Codex Cloud で避ける運用

- すべての environment を internet access on にする
- prompt injection 由来で agent が外部サーバへ POST する経路を許す (例: webhook.site / pastebin)
- agent output / work log を review せずに merge / 反映する

---

## 4. CODEX_HOME redirect 攻撃 (CVE-2025-61260) 対策

### TL;DR
- `CODEX_HOME` 環境変数を悪意ある `.env` 経由で書き換えると、Codex CLI が project-local `.codex/config.toml` を読み込んで MCP server を起動する経路ができる
- **Codex CLI 0.23.0+** で修正済 — 必ずアップデート
- SAGE Phase 2B `templates/hooks/protect-sage-files.sh` は `.env` への `CODEX_HOME=` 書き込みを Claude Code セッションで block する

### Why it matters
- 攻撃シナリオ: 悪意ある repo を clone → `.env` に `CODEX_HOME=./.codex` → そこに `.codex/config.toml` で `mcp_servers` 定義 → Codex 起動時に reverse shell 実行
- 詳細: [Check Point: OpenAI Codex CLI Command Injection](https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/)

### 対策チェックリスト

- [ ] Codex CLI version 確認: `codex --version` で 0.23.0 以上
- [ ] cloned repo を Codex で開く前に `.env` を visual review
- [ ] `.env` に `CODEX_HOME=` / `ANTHROPIC_BASE_URL=` の不審な記述がないか確認
- [ ] Claude Code 利用時は SAGE protect-sage-files hook が `.env` 書き込みを content-check するため自動防御 (Phase 2B 以降)
- [ ] Codex のみ利用時は手動 review が唯一の防御 — 怪しい repo は dev container で開く

---

## 5. Untrusted input as code

### TL;DR
- branch name / PR title / PR body / issue body / `AGENTS.md` はすべて **攻撃者が制御可能** な untrusted input
- Codex がこれらを shell command や prompt として解釈すると command injection / prompt injection が成立する
- BeyondTrust 報告: [OpenAI Codex Command Injection Vulnerability — GitHub Token Exfiltration](https://www.beyondtrust.com/blog/entry/openai-codex-command-injection-vulnerability-github-token)

### 攻撃面の例

| Input | 攻撃シナリオ |
|---|---|
| branch name | `git checkout` / `git log` で shell に展開される時の injection |
| PR title / body | Codex が要約・分析を求められた時の prompt injection、悪意ある instruction 注入 |
| issue body | 上に同じ + retrieval-augmented 文脈での poisoning |
| commit message | Codex の git history 分析時の prompt injection |
| `AGENTS.md` (cloned repo の) | Codex の system prompt 相当として読まれる経路 |

### 対策チェックリスト

- [ ] codex-action / GitHub Actions では branch name を **shell に直挿ししない** (env 変数経由 + `${{ }}` ではなく `$VAR` で quote)
- [ ] PR body / issue body を Codex に渡す時は plain string として、コードブロック内に閉じ込める
- [ ] cloned repo の `AGENTS.md` は **必ず人間が review** してから Codex を起動 (SAGE template-trust callout と同根)
- [ ] Codex CLI 0.23.0+ + SAGE Phase 2B hooks 併用で多層防御

---

## 6. codex-action GitHub Actions hardening

### TL;DR
- `allow-users` を信頼できる user / org member に厳しく制限
- `${{ secrets.OPENAI_API_KEY }}` は **専用 secret** として、scope を最小化
- Codex action **step** は Codex **job** の最後の step に配置 (公式表現: "last step in a job"。後続 step の host state 汚染防止)
- PR comment 投稿のような固定処理は **別 job** への output 受け渡しで対応 (公式 example の `post_feedback` パターン)
- `drop-sudo` でルート権限を落とす
- branch name / PR title はすべて `env` 経由で渡し、shell に展開しない

### 公式リファレンス

- [openai/codex-action — Security Considerations](https://github.com/openai/codex-action/security)

### 安全 YAML サンプル

```yaml
# .github/workflows/codex-review.yml
name: "Codex Review"

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  # Job 1: Codex execution. contents: read のみ (least privilege)。
  # PR comment 投稿は別 job で行い、Codex プロセスからは write 権限を完全に切り離す。
  codex:
    # 1. 信頼できる user のみが trigger 可能
    if: github.event.pull_request.user.login == 'YOUR_TRUSTED_USER'
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      final_message: ${{ steps.run_codex.outputs.final-message }}
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
        with:
          # PR's merge commit (公式 README example 準拠)
          ref: refs/pull/${{ github.event.pull_request.number }}/merge

      # 2. allow-users + safety-strategy: drop-sudo + sandbox: workspace-write + last-step-only
      #    branch / PR title / body は prompt heredoc 内で expression として参照しても、
      #    Codex は CLI sandbox 内で実行されるため shell injection 経路にならない。
      #    ただし `run:` で展開する場合は env 経由 + double quote 必須 (本 sample は `uses:` のみ)。
      - name: Codex review (last step)
        id: run_codex
        uses: openai/codex-action@<PIN_TO_SHA>  # commit SHA pin (tag は再現性低)
        with:
          openai-api-key: ${{ secrets.OPENAI_API_KEY }}
          allow-users: 'YOUR_TRUSTED_USER,ANOTHER_REVIEWER'
          safety-strategy: drop-sudo  # 既定値、明示で意図を残す
          sandbox: workspace-write
          prompt: |
            Review PR #${{ github.event.pull_request.number }} for ${{ github.repository }}.

            Title: ${{ github.event.pull_request.title }}
            Body:
            ${{ github.event.pull_request.body }}

            Focus on: security, correctness, primary-source citations.
            Be concise. Prioritize findings as P1/P2/P3.

  # Job 2: Codex の出力を PR コメントとして投稿。
  # ① write token を持つ runner で Codex を実行しない (token exfil の compute 経路なし)
  # ② 固定 script で comment 投稿のみ → shell/code execution 経路なし
  # ③ ただし comment body は Codex の final_message そのまま = untrusted model
  #    output として扱う (HTML/script は GitHub 側で sanitize されるが、
  #    phishing link / 偽情報 / 人間 reader への偽指示などは内容として残り得る)
  post_feedback:
    runs-on: ubuntu-latest
    needs: codex
    if: needs.codex.outputs.final_message != ''
    permissions:
      issues: write
      pull-requests: write
    steps:
      - name: Post Codex feedback as PR comment
        uses: actions/github-script@<PIN_TO_SHA>  # v7.0.1 (write 権限 job では full-length SHA pin 推奨)
        env:
          CODEX_FINAL_MESSAGE: ${{ needs.codex.outputs.final_message }}
        with:
          github-token: ${{ github.token }}
          script: |
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.payload.pull_request.number,
              body: process.env.CODEX_FINAL_MESSAGE,
            });
```

### 禁止事項

- `allow-users: '*'` → **絶対禁止**。任意の external PR submitter が API を消費 + 任意 prompt 実行
- `${{ github.head_ref }}` を直接 shell command に展開 (`run: git fetch origin ${{ github.head_ref }}`) → **禁止**。env 経由 + double quote 必須
- Codex action step を **同一 job 内** で deploy/build/privileged step より前に配置 → 禁止 (Codex が後続 step の host state を汚染し得る、[公式 security docs](https://github.com/openai/codex-action/blob/main/docs/security.md) 推奨)。**別 job** への output 受け渡し (例: post_feedback) は OK
- `OPENAI_API_KEY` を他の workflow と共有 → 禁止 (専用 secret + 最小 quota)

---

## 7. Incident response

### TL;DR
- Codex 関連 incident を疑ったら: ① Codex session 停止、② OpenAI API key rotate、③ GitHub audit log で影響 PR 特定、④ branch revert / force-push 可否を判断、⑤ SECURITY.md report

### 即時対応手順

```bash
# 1. OpenAI API key rotate (web console + GitHub secret 更新)
#    https://platform.openai.com/api-keys

# 2. GitHub audit log で Codex 関連 PR / commit を特定
#    audit log REST API は organization (または enterprise) scope のみ。
#    repos/* の audit-log endpoint は存在しない (404)。
#    要件: org owner/admin 権限 + PAT に `read:audit_log` scope。
#    org plan によっては Enterprise Cloud / Audit Log Streaming が必要。
gh api -H "Accept: application/vnd.github+json" \
  "orgs/<ORG>/audit-log?phrase=actor:openai-codex" 2>&1 | head -50
# Enterprise の場合:
# gh api "enterprises/<ENTERPRISE>/audit-log?phrase=actor:openai-codex"

# 3. 影響 PR / branch / commit のリスト化
gh pr list --repo <OWNER>/<REPO> --state all --search "author:app/openai-codex created:>2026-XX-XX"

# 4. 必要なら問題コミットを revert (force push は最終手段)
git revert <SHA>
git push

# 5. SAGE security policy に従って report
#    → SECURITY.md "Reporting a Vulnerability" 節
```

### Postmortem 観点

- Codex CLI / Codex Cloud / codex-action のどの surface か
- 攻撃 input 経路 (branch name / PR body / `.env` / config.toml / MCP server)
- 影響範囲 (commit / merged PR / leaked secret 種別)
- 修正と再発防止 (Codex CLI version / config 強化 / allow-users 縮小 / hook 追加)

詳細は SAGE [SECURITY.md §6 IR procedure](../SECURITY.md) と [sage/governance.md §10 Operations](../sage/governance.md) を参照。

---

## 8. References

### Codex 公式

- [Codex CLI — config-reference](https://developers.openai.com/codex/config-reference)
- [Codex Cloud / web — Internet Access](https://developers.openai.com/codex/cloud/internet-access)
- [openai/codex-action — Security](https://github.com/openai/codex-action/security)

### CVE / 第三者研究

- [NVD CVE-2025-61260](https://nvd.nist.gov/vuln/detail/CVE-2025-61260) — Codex CLI command injection (fixed 0.23.0)
- [NVD CVE-2026-33068](https://nvd.nist.gov/vuln/detail/CVE-2026-33068) — Claude Code trust dialog bypass (related, fixed 2.1.53)
- [Check Point — OpenAI Codex CLI Command Injection](https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/)
- [Check Point — Claude Code Project Files RCE & API Token Exfiltration](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/)
- [BeyondTrust — OpenAI Codex Command Injection Vulnerability — GitHub Token Compromise](https://www.beyondtrust.com/blog/entry/openai-codex-command-injection-vulnerability-github-token)
- [Airia — AI Security in 2026: Prompt Injection, the Lethal Trifecta, and How to Defend](https://airia.com/ai-security-in-2026-prompt-injection-the-lethal-trifecta-and-how-to-defend/)

### SAGE 内部関連

- [AGENTS.md §2.1 Codex specificity](../AGENTS.md) — 短い callout
- [SECURITY.md §3 Threat Model / §4 Out of Scope](../SECURITY.md)
- [sage/governance.md §9 SAGE Scope Boundary](../sage/governance.md)
- [`.gitleaks.toml`](../.gitleaks.toml) — secret-scanning allowlist (Phase 2B)
- [`templates/hooks/protect-sage-files.sh`](../templates/hooks/protect-sage-files.sh) — `.env` 書き込み時の `CODEX_HOME` content check (Phase 2B)

---

*Last reviewed: 2026-05-02. 確認した Codex CLI version: 0.23.0+ baseline. Codex Cloud / web は 2026-05 時点の公式 docs を参照。*
*This guide is part of SAGE v2 / SPEC-0013 / TASK-0114.*
