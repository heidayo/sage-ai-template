# `templates/sage/`

SAGE 内部 declarative registry / inventory のテンプレート配布元。`installer.sh` で `.sage/` 配下にコピーされる雛形。

## ファイル一覧

| ファイル | 配置先 | 目的 | 関連 SPEC |
|---|---|---|---|
| `mcp-allowlist-template.json` | `.sage/mcp-allowlist.json` | MCP allowlist registry (transport-aware、supply-chain pinned、audit-only) | [SPEC-0015](../../specs/SPEC-0015-mcp-allowlist-audit-and-agent-identity.md) |

## 使い方

1. `installer.sh` を実行すると、各 template が `.sage/` 配下に配置される
2. user が template をプロジェクトに合わせて編集
3. SAGE の hook / doctor が config を read-only で audit (drift / 期限切れ等を検出)

## doctrine

- **declarative + audit-only**: SAGE は registry を読んで warn / FAIL を出すのみ。runtime での MCP 起動 block 等は本体機能 (Claude Code / Codex) の責任 (governance §9.2)
- **positive list**: registry に明示列挙された entry のみ承認、新規追加は SPEC-ID または PR URL の audit trail 必須
- **secret hygiene**: 機密値 (token / API key) を registry に直接書かない、env 変数名参照のみ
