# SAGE Settings Templates

このディレクトリには Claude Code の設定 **雛形** が入っています。

> **⚠️ 重要 — SAGE は runtime sandbox を提供しません**
>
> SAGE は templates/governance/anti-pattern を提供する **doctrine 層** です。runtime での filesystem isolation や network allowlist の実 enforcement は **Claude Code 本体** が行います ([sage/governance.md §9.2](../../sage/governance.md))。
>
> このディレクトリの `sandbox.json` は **雛形にすぎません**。SAGE は user の `.claude/settings.json` を自動上書きしません。**user が自分の責任で merge し、自分の環境で valid か確認してください**。

---

## sandbox.json — Claude Code Sandbox 推奨設定 (Phase 2B)

### 含まれるもの

| Section | Purpose | 根拠 |
|---|---|---|
| `permissions.deny` | secret 読み取り / 破壊的コマンド / force push を block | Phase 1 SECURITY.md §3, Anthropic Claude Code Security |
| `permissions.ask` | dependency 追加 / commit / push は人間確認 | OWASP AI Agent Cheat Sheet §6 (human-in-the-loop) |
| `permissions.disableBypassPermissionsMode: "disable"` | `bypassPermissions` モード自体を組織レベルで禁止 | [CVE-2026-33068](https://nvd.nist.gov/vuln/detail/CVE-2026-33068) trust dialog bypass |
| `sandbox.enabled: true` | OS-level filesystem + network 隔離 | [Anthropic Claude Code Sandboxing 公式](https://www.anthropic.com/engineering/claude-code-sandboxing) |
| `sandbox.failIfUnavailable: true` | sandbox が起動できない時に silently 続行しない | Phase 1 SECURITY.md §3 doctrine |
| `sandbox.filesystem.denyRead` | SSH key / AWS credentials / `.env` 等を OS レベルで隔離 | [CVE-2025-59536](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/) (`ANTHROPIC_BASE_URL` exfil 防止), [CVE-2026-25723](https://nvd.nist.gov/vuln/detail/CVE-2026-25723) (file write bypass 防止) |
| `sandbox.network.allowedDomains` | 必要な API endpoint のみ許可、exfiltration vector 制限 | [Lethal Trifecta — Airia](https://airia.com/ai-security-in-2026-prompt-injection-the-lethal-trifecta-and-how-to-defend/) |

### 適用手順

#### Option A: 既存 `.claude/settings.json` がない場合 (新規 project)

```bash
mkdir -p .claude
cp templates/settings/sandbox.json .claude/settings.json
```

#### Option B: 既存設定がある場合 (推奨)

`jq` で merge してから diff を必ず review:

```bash
# 1. 現状 backup
cp .claude/settings.json .claude/settings.json.bak

# 2. merge (sandbox.json の値が優先される deep merge)
jq -s '.[0] * .[1]' .claude/settings.json templates/settings/sandbox.json > .claude/settings.json.merged

# 3. 必ず diff で確認 — 自分の project に必要な permission を消していないか
diff .claude/settings.json.bak .claude/settings.json.merged

# 4. OK なら apply
mv .claude/settings.json.merged .claude/settings.json

# 5. 初回は plan mode で動作確認
# Claude Code を起動し、まず /plan で軽い操作を試す
```

#### Option C: 部分的に取り込む

全部一度に適用せず、`permissions.deny` だけ・`sandbox.network.allowedDomains` だけ等の段階導入も推奨されます。

### カスタマイズの注意

#### `network.allowedDomains` を自分の環境に合わせる

template には Claude API endpoint と公式 docs (`code.claude.com`) を含めていますが、user の project が叩く API は別途追加が必要:

- OpenAI も使う → `api.openai.com` を追加
- Supabase project → `*.supabase.co` 相当を追加 (ただし wildcard は exfil リスク残るので可能なら specific subdomain に絞る)
- 自社 API → 必要 host のみ追加

#### `permissions.ask` を user が許容できる粒度に

`Bash(npm install *)` を全部 `ask` にすると毎回承認が必要で承認疲れします。trusted package は `allow` に移すか、`pnpm` 1 種類に絞る等を検討。

#### `denyRead` を緩めるのは慎重に

`~/.ssh` を allow しないと git over SSH が動かないように見えますが、Claude Code sandbox の git 操作は通常 sandbox 外の git と HTTPS で動くため、SSH key 自体を読ませる必要は普通ありません。ssh-agent / git credential helper 経由で認証してください。

### 何が変わるか (適用後の挙動)

- `.env` を Claude Code に直接読まれない (Read tool deny + sandbox denyRead 二重防御)
- `git push --force` を試みると block される
- `bypassPermissions` モードへの切り替え自体が組織レベルで禁止される
- 不明なドメインへの outbound 通信は sandbox が止める
- 上記が破られた瞬間に Claude Code は失敗する (`failIfUnavailable: true`)

これらは **user が許容するべきトレードオフ** です。承認プロンプトが増える代わりに supply chain / exfiltration / hijack risk を構造的に減らします。

### 関連ドキュメント

- [SECURITY.md §4](../../SECURITY.md) — SAGE の "Out of Scope" — runtime enforcement は Claude Code 側の責務
- [sage/governance.md §9](../../sage/governance.md) — SAGE Scope Boundary
- [AGENTS.md §2.1](../../AGENTS.md) — Codex 利用者は ~/.codex/config.toml で別途 sandbox 構築 (このファイルは Claude Code 専用)

---

*templates/settings/sandbox.json + README.md は SPEC-0012 / TASK-0110 として 2026-05-02 に追加されました。*
