# Security Policy — SAGE Development System

> **このドキュメントの位置づけ**
> SAGE は AI coding agent (Claude Code / Codex 他) 向けの **開発プロセステンプレート** であり、runtime sandbox や agent enforcement そのものを提供するツールではありません。脅威モデルと **non-coverage** を以下に明示します。

---

## 1. Supported Versions

セキュリティ修正は最新メジャー version に対してのみ提供されます。

| SAGE Version | Status               | Security Updates | Notes                                  |
| ------------ | -------------------- | ---------------- | -------------------------------------- |
| 1.1.x        | ✅ Active            | Yes              | Current stable line (Phase 1 baseline) |
| 1.0.x        | ⚠️ Best-effort       | Critical only    | Migrate to 1.1.x recommended           |
| 0.x          | ❌ Unsupported       | No               | Pre-stabilization snapshots            |

`bash install.sh --version` で現在の SAGE_VERSION を確認できます (`bash install.sh --print-provenance` で SHA256 と由来も表示)。

---

## 2. Reporting a Vulnerability

**公開 Issue を作らないでください。** SAGE 自身またはテンプレートに起因する以下の事象は private channel で報告してください。

- AI agent の権限・実行・記憶に影響する設計上の欠陥
- `install.sh` / hooks / scripts の任意コード実行・情報漏洩経路
- governance / template の解釈で AI agent が安全境界を越える攻撃ベクター
- supply chain (release artifact / installer URL / Gist) に関する整合性問題

### 報告チャネル

1. **GitHub Security Advisory (推奨)**: <https://github.com/heidayo/sage-ai-template/security/advisories/new>
2. **Email** (上記が利用できない場合): リポジトリ owner ([heidayo on GitHub](https://github.com/heidayo)) のプロフィール記載メール

### 含めてほしい情報

- 影響対象 (SAGE_VERSION / 該当ファイル / 該当 hook / 該当 skill)
- 再現手順 (PoC があれば)
- 想定攻撃シナリオと blast radius
- 既存 CVE / 公開資料との関連 (該当すれば)

### Response SLA (best-effort, no warranty)

| Severity                                         | Initial Response | Mitigation Target |
| ------------------------------------------------ | ---------------- | ----------------- |
| Critical (RCE / token exfil / silent privesc)    | 3 営業日以内     | 14 日             |
| High (auth bypass / supply chain compromise)     | 5 営業日以内     | 30 日             |
| Medium (info disclosure / DoS / config drift)    | 10 営業日以内    | 60 日             |
| Low (hardening / doc / pattern improvement)     | next release    | next release      |

SAGE は単独 maintainer プロジェクトであり、上記 SLA は努力目標です ("best-effort, no warranty" / Apache-2.0 License Section 7-8 を参照)。

---

## 3. Threat Model Summary

SAGE が想定する **主要な脅威カテゴリ** は以下です。これらは AI coding agent 時代に固有の攻撃面であり、各カテゴリへの対応状況を ([covered] / [partial] / [out-of-scope]) で示します。

### 3.1 Template Supply Chain

| 脅威                                                              | SAGE 対応      |
| ----------------------------------------------------------------- | -------------- |
| 悪意ある fork / clone repository が `.claude/settings.json` で `bypassPermissions` に誘導 | [partial] CLAUDE.md / AGENTS.md 冒頭 callout (TASK-0098) で警告 |
| `install.sh` 自体の改ざん                                         | [partial] `--print-provenance` / `--verify-checksum` (TASK-0097) |
| `installer_url` (auto-update) 取得先の悪意ある書き換え            | [partial] local install-state.yaml の sha256 drift 検出は `--verify-checksum` で実装済 (TASK-0097)。remote installer_url の pinning / signing / trust flow は未実装 (SPEC-0011 で扱う) |
| Skill / hook ファイル経由の任意コード実行                         | [partial] hook テスト + shellcheck (CONTRIBUTING.md)、本格対応は Phase 2-3 |

参考: [Trend Micro Claude Code Source Leak Campaign](https://www.trendmicro.com/en_us/research/26/d/weaponizing-trust-claude-code-lures-and-github-release-payloads.html), [OWASP Agentic Skills Top 10](https://owasp.org/www-project-agentic-skills-top-10/) AST01-AST10

### 3.2 AI Agent Configuration Attacks

| 脅威                                                                                | SAGE 対応 |
| ----------------------------------------------------------------------------------- | --------- |
| `.claude/settings.json` に `permissions.defaultMode = "bypassPermissions"` 注入    | [partial] template-trust callout で警告。block は Claude Code 本体の責務 (CVE-2026-33068 fixed in 2.1.53) |
| `.codex/config.toml` + `.env` `CODEX_HOME` redirect で MCP RCE (CVE-2025-61260)     | [partial] CONTRIBUTING.md / governance §9 で警告。block は Codex CLI 0.23.0+ の責務 |
| `ANTHROPIC_BASE_URL` 書き換えで API key exfil (CVE-2025-59536)                     | [partial] template-trust callout で警告。block は Claude Code 本体の責務 |

### 3.3 Prompt Injection / Lethal Trifecta

| 脅威                                                                                       | SAGE 対応 |
| ------------------------------------------------------------------------------------------ | --------- |
| 外部由来コンテンツ (PR/issue/branch/README) からの indirect prompt injection              | [partial] doctrine 化 (Phase 2 で warn-only hook 追加予定) |
| Lethal Trifecta (private data + untrusted input + exfil vector) の同時成立                | [partial] governance §9 で原則記載。検出 hook は Phase 2 で warn-only 起動予定 |

参考: [Lethal Trifecta — Simon Willison via Airia](https://airia.com/ai-security-in-2026-prompt-injection-the-lethal-trifecta-and-how-to-defend/)

### 3.4 Code Quality / Hallucination Risks

| 脅威                                                              | SAGE 対応 |
| ----------------------------------------------------------------- | --------- |
| Package hallucination / slopsquatting                             | [partial] anti-pattern 記載。Gate 追加は Phase 4 |
| AI 生成コードの security correctness 低さ (Endor: 23.5%)         | [partial] Gate 2 (functional) 提供。FuncPass/SecPass 概念分離は Phase 4 |
| Recursive hallucination spiral (693行迷走パターン)                | [partial] anti-pattern AP-07 (SPEC-0007) で記載済 |

---

## 4. Out of Scope / Non-Coverage

⭐ **重要**: SAGE は以下を **提供しません**。これらは Claude Code / Codex 本体機能、外部ツール、または運用設計の責任範囲です。

### 4.1 Runtime Enforcement (SAGE は強制しない)

- **Filesystem isolation** — Claude Code の sandbox 設定または OS-level container (Incus / Colima / microVM) で実現
- **Network egress allowlist** — Claude Code sandbox `network.allowedDomains` または OS proxy で実現
- **Bash subprocess deny** — pattern matching hook は補助に過ぎない (参考: [Adversa AI deny rule bypass](https://adversa.ai/blog/claude-code-security-bypass-deny-rules-disabled/))
- **MCP server consent / sandboxing** — Claude Code / Codex 本体の trust 機構に依存
- **Codex sandbox / approval policy** — Codex CLI / cloud 設定で実現 (`workspace-write` + `on-request` 推奨)

### 4.2 External Operations (ユーザーが別途用意)

- GitHub branch protection / required checks (人間が GitHub UI または別 opt-in script で設定)
- Production secret 管理 (Vault / 1Password / GitHub Encrypted Secrets 等)
- Deterministic security scanner 統合 (gitleaks / trivy / semgrep / npm audit 等)
- Incident response 担当者と連絡網
- Application 層の入力検証・認可・rate limit

### 4.3 What SAGE Provides (補完関係)

詳細は [sage/governance.md §9 SAGE Scope Boundary](sage/governance.md) を参照。要約:

- ✅ ライフサイクル (SPEC/PLAN/TASK) と Quality Gate **構造**
- ✅ Lane 設計 / File Scope / anti-pattern 学習枠組み
- ✅ Hook **テンプレート** (実行は Claude Code / Codex 本体)
- ✅ AI agent 向け instruction file (CLAUDE.md / AGENTS.md / .claude/rules/)
- ❌ Runtime sandbox 強制 / MCP allowlist enforcement / branch protection 自動化

---

## 5. Known Risks (Honest Disclosure)

SAGE は単独 maintainer プロジェクトであり、以下を **正直に開示** します:

1. **`install.sh` は約 213KB / 5779 行の自己完結スクリプト** であり、`.git/hooks/`, `.github/workflows/`, `.claude/settings.json` 等を一括書き込みします。`bash install.sh --dry-run` で内容を確認してから実行してください。分割は後続 SPEC で扱います。
2. **`AGENTS.md` / `CLAUDE.md` / `.claude/rules/` を導入することは AI agent の context に外部記述を注入する行為** です。clone した repository の内容を fork 元のレビューなしで信頼してはいけません ([CLAUDE.md](CLAUDE.md) / [AGENTS.md](AGENTS.md) 冒頭 callout 参照)。
3. **Hook (`templates/hooks/`) は pattern matching であり sandbox の代替ではありません**。`bash -c "$VAR"`, base64 decode, `find -exec rm`, `git clean -fdx`, redirection redirect, Unicode obfuscation 等で回避され得ます。
4. **AI 評価 (sage-evaluate / sage-review skill) は補助** であり、人間レビュー / deterministic scanner の代替ではありません。
5. **Codex 向け enforcement は AGENTS.md 中心の prompt-level guidance** にとどまります。Codex sandbox / approval / network / token 制御は Codex 本体設定で別途構築してください ([Codex Sandbox 公式](https://developers.openai.com/codex/concepts/sandboxing) / [Codex Internet Access 公式](https://developers.openai.com/codex/cloud/internet-access))。

---

## 6. References (Primary Sources)

### Standards

- [OWASP AI Agent Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html)
- [OWASP Agentic Skills Top 10 (AST01-AST10)](https://owasp.org/www-project-agentic-skills-top-10/)
- [OWASP GenAI Exploit Round-up Q1 2026](https://genai.owasp.org/2026/04/14/owasp-genai-exploit-round-up-report-q1-2026/)

### CVEs Cited Above

- [CVE-2025-59536](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/) — Claude Code project files RCE & API token exfil
- [CVE-2025-61260](https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/) — Codex CLI project-local config RCE (fixed 0.23.0)
- [CVE-2026-25723](https://nvd.nist.gov/vuln/detail/CVE-2026-25723) — Claude Code file write bypass via piped sed (6.5 MEDIUM, fixed 2.0.55)
- [CVE-2026-33068](https://nvd.nist.gov/vuln/detail/CVE-2026-33068) — Claude Code trust dialog bypass via repo-controlled `.claude/settings.json` (8.8 HIGH, fixed 2.1.53)

### Vendor Documentation

- [Anthropic Claude Code Sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)
- [Anthropic Claude Code Security Docs](https://code.claude.com/docs/en/security)
- [OpenAI Codex Sandbox](https://developers.openai.com/codex/concepts/sandboxing)
- [OpenAI Codex Cloud Internet Access](https://developers.openai.com/codex/cloud/internet-access)
- [openai/codex-action Security](https://github.com/openai/codex-action/security)

完全な参考一覧は [ATTRIBUTION.md](ATTRIBUTION.md) を参照してください。

---

## 7. Acknowledgments

本 Security Policy は以下のコミュニティ貢献から知見を得ています (Phase 1 統合, 2026-05):

- Cross-model adversarial review pattern (Claude → Codex)
- [BeyondTrust Phantom Labs](https://www.beyondtrust.com/blog/entry/openai-codex-command-injection-vulnerability-github-token), [Check Point Research](https://research.checkpoint.com/), [Adversa AI](https://adversa.ai/blog/claude-code-security-bypass-deny-rules-disabled/), [Trend Micro](https://www.trendmicro.com/en_us/research/26/d/weaponizing-trust-claude-code-lures-and-github-release-payloads.html), [Endor Labs](https://www.endorlabs.com/research/ai-code-security-benchmark) の公開研究
- [BVP Securing AI Agents (2026)](https://www.bvp.com/atlas/securing-ai-agents-the-defining-cybersecurity-challenge-of-2026), [Apiiro Code Execution Risks in Agentic AI](https://apiiro.com/blog/code-execution-risks-agentic-ai/) の設計思想

---

*Last reviewed: 2026-05-01 (Phase 1, SPEC-0010 / TASK-0095). Next scheduled review: each minor release or upon material change.*
