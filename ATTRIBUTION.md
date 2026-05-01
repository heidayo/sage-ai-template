# Attribution

SAGE Development System is an original work by heidayo.

SAGE integrates **ideas and design philosophies** from the following sources.
No source code was copied from any of these projects.

---

## Inspiration Sources

### 1. go-boilerplate
- **Author**: Tomy-ch
- **URL**: https://github.com/Tomy-ch/go-boilerplate
- **License**: MIT
- **What SAGE adopted**: The philosophy of "structural integrity prevents deviation" — designing codebases that are hard to break even when AI modifies them.

### 2. ai-development-patterns
- **Author**: Paul Duvall
- **URL**: https://github.com/PaulDuvall/ai-development-patterns
- **License**: MIT
- **What SAGE adopted**: The concept of codifying AI development success/failure into named, detectable patterns and anti-patterns.

### 3. auto-dev
- **Author**: phodal
- **URL**: https://github.com/phodal/auto-dev
- **License**: MPL-2.0 (Mozilla Public License 2.0)
- **What SAGE adopted**: The philosophy of distributing SDLC responsibilities across multiple specialized agents rather than relying on a single AI.
- **Note**: No MPL-licensed code was used. Only the design philosophy of role separation was referenced.

### 4. awesome-AI-driven-development
- **URL**: https://github.com/AIDrivenDevelopment/awesome-AI-driven-development
- **License**: Not specified (no LICENSE file found as of 2026)
- **What SAGE adopted**: The concept of organizing tools by functional role slots rather than by specific products.
- **Note**: No content (lists, descriptions, etc.) was copied. Only the organizational philosophy was referenced.

### 5. Spec-Driven Development (SoftwareSeni)
- **URL**: https://www.softwareseni.com/spec-driven-development-in-2025-the-complete-guide-to-using-ai-to-write-production-code/
- **Type**: Blog article (not open-source software)
- **What SAGE adopted**: The philosophy that specifications should be the single source of truth, and AI quality depends on instruction clarity rather than model capability.
- **Note**: No article text was reproduced. Only the underlying concept was referenced.

---

## Clarification

SAGE is a synthesis of **ideas and design philosophies**, not a combination of source code.
All implementation (scripts, templates, configurations, workflows, documentation) is original work.

---

## External Knowledge Integration Sources (Phase 1, 2026-05)

SAGE v2 改修にあたり、以下の **公開一次ソース** からセキュリティ・運用設計の知見を統合しました。
コードや文章のコピーはなく、知見の引用と doctrine 化のみを行っています。

### Standards / Frameworks

- **OWASP AI Agent Security Cheat Sheet** — https://cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html
- **OWASP Agentic Skills Top 10 (AST01-AST10)** — https://owasp.org/www-project-agentic-skills-top-10/
- **OWASP GenAI Exploit Round-up Q1 2026** — https://genai.owasp.org/2026/04/14/owasp-genai-exploit-round-up-report-q1-2026/

### Vendor Documentation (Anthropic)

- **Claude Code Security** — https://code.claude.com/docs/en/security
- **Claude Code Sandboxing (Anthropic Engineering)** — https://www.anthropic.com/engineering/claude-code-sandboxing
- **Claude Code Auto Mode** — https://www.anthropic.com/engineering/claude-code-auto-mode
- **Anthropic Trust Center** — https://trust.anthropic.com

### Vendor Documentation (OpenAI)

- **Codex Sandboxing** — https://developers.openai.com/codex/concepts/sandboxing
- **Codex Cloud Internet Access** — https://developers.openai.com/codex/cloud/internet-access
- **codex-action Security** — https://github.com/openai/codex-action/security
- **Codex Security (research preview)** — https://openai.com/index/codex-security-now-in-research-preview/

### Vulnerability Disclosures (NVD / Researchers)

- **CVE-2026-25723** (Claude Code file write bypass via piped sed, fixed in 2.0.55) — https://nvd.nist.gov/vuln/detail/CVE-2026-25723
- **CVE-2026-33068** (Claude Code trust dialog bypass via repo-controlled `.claude/settings.json`, 8.8 HIGH, fixed in 2.1.53) — https://nvd.nist.gov/vuln/detail/CVE-2026-33068
- **Check Point Research: Claude Code Project Files RCE & API Token Exfiltration (CVE-2025-59536)** — https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/
- **Check Point Research: Codex CLI Command Injection (CVE-2025-61260)** — https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/
- **BeyondTrust: OpenAI Codex Branch Name Injection → GitHub Token compromise** — https://www.beyondtrust.com/blog/entry/openai-codex-command-injection-vulnerability-github-token
- **Adversa AI: Claude Code deny rule bypass via 50+ subcommand chains** — https://adversa.ai/blog/claude-code-security-bypass-deny-rules-disabled/
- **Trend Micro: Claude Code Source Leak Lures & GitHub Releases Abuse** — https://www.trendmicro.com/en_us/research/26/d/weaponizing-trust-claude-code-lures-and-github-release-payloads.html
- **Trend Micro: AI Package Hallucination & Code Integrity** — https://www.trendmicro.com/vinfo/us/security/news/vulnerabilities-and-exploits/the-mirage-of-ai-programming-hallucinations-and-code-integrity

### Industry Analysis & Benchmarks

- **VentureBeat: Six exploits broke AI coding agents (credential, not model)** — https://venturebeat.com/security/six-exploits-broke-ai-coding-agents-iam-never-saw-them
- **Bessemer Venture Partners: Securing AI Agents (2026 cybersecurity challenge)** — https://www.bvp.com/atlas/securing-ai-agents-the-defining-cybersecurity-challenge-of-2026
- **Apiiro: Top Code Execution Risks in Agentic AI Systems** — https://apiiro.com/blog/code-execution-risks-agentic-ai/
- **ProjectDiscovery 2026 AI Coding Impact Report** — https://www.prnewswire.com/news-releases/projectdiscoverys-2026-ai-coding-impact-report-reveals-ai-generated-code-is-outpacing-security-teams-ability-to-keep-up-302749706.html
- **Endor Labs: AI Code Security Benchmark (Func vs Sec correctness)** — https://www.endorlabs.com/research/ai-code-security-benchmark
- **Airia: Lethal Trifecta in Agentic AI** — https://airia.com/ai-security-in-2026-prompt-injection-the-lethal-trifecta-and-how-to-defend/

### Academic / Research

- **SoK: Hallucinations and Security Risks in AI-Assisted Software Development** — https://arxiv.org/html/2502.18468v1
- **CR-Bench: Evaluating Real-World Utility of AI Code Review Agents** — https://arxiv.org/html/2603.11078v1
- **Dive into Claude Code: Agent System Design Space** — https://arxiv.org/pdf/2604.14228
- **Surge AI: When Coding Agents Spiral Into 693 Lines of Hallucinations** — https://surgehq.ai/blog/when-coding-agents-spiral-into-693-lines-of-hallucinations

### Web Framework Security (Application-side guidance)

- **Next.js Security (server components & actions)** — https://nextjs.org/blog/security-nextjs-server-components-actions
- **Next.js Data Security guide** — https://nextjs.org/docs/app/guides/data-security

---

## Note on Phase 1 Synthesis

These sources informed SAGE v2's **doctrine and threat model** (governance §9 Scope Boundary, SECURITY.md threat model). No copyrighted text was reproduced — references are URL-only, with summaries paraphrased in original wording. The integration was cross-validated by an independent Codex review (cross-model adversarial review per SAGE-v2 Tier 2.5 pattern) before adoption.
