# TASK-0122: MCP allowlist registry schema (JSON, supply-chain pinned) + template

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0122 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (基盤) |
| 依存TASK  | none |
| 見積     | 30m |

## 責務

`.sage/mcp-allowlist.json` の **JSON schema** を確定し (Codex review P2 反映で YAML → JSON 変更、Python stdlib `json` で安定 parse)、`templates/sage/mcp-allowlist-template.json` として user 配布可能な雛形を作成する。supply-chain pin field (sha256 / version_pin / publisher / source_registry) を必須として組み込む (Codex review P1 反映)。

## 入力

- SPEC-0015 FR-01 (registry schema、JSON 形式、supply-chain pin field 必須)
- SPEC-0015 FR-02 (policy enforcement: forbid_latest_tag / require_sha256 / require_publisher)
- SPEC-0015 SEC-02 (positive list + supply-chain pin 原則)
- 既存 `templates/mcp-json-template.json` の構造 (参考のみ)
- Codex CLI `~/.codex/config.toml` の `[mcp_servers]` 構造 (参考のみ)
- Codex review P1 finding (PR #21 review): "version 固定、sha256 または package lock provenance、publisher/source registry、@latest 禁止または明示 risk acceptance を schema と test に入れてください"

## 出力

1. `templates/sage/mcp-allowlist-template.json` 新規 (**transport-aware**, Codex review P1 反映):

   - **stdio transport 必須 field**: `name`, `transport: "stdio"`, `artifact_type` (npm_package / local_binary), `command`, `args`, `version_pin`, `publisher`, `source_registry`, `approved_by`, `approved_at`, `expires_at`
   - **stdio 推奨 field**: `npm_integrity` (npm_package 用、`policy.require_npm_integrity: true` で必須化可能)、`enabled_tools` / `disabled_tools`
   - **http transport 必須 field**: `name`, `transport: "http"`, `artifact_type: "remote_http"`, `url`, `url_origin_pin`, `bearer_token_env_var`, `approved_by`, `approved_at`, `expires_at`
   - **http 推奨 field**: `http_headers`, `env_http_headers`, `tls_pin_sha256`, `enabled_tools` / `disabled_tools`
   - **共通 optional**: `notes`, `startup_timeout_sec`, `tool_timeout_sec`, `enabled`, `required`
   - top-level: `version: "1.0"` + `policy: { forbid_latest_tag: true, require_npm_integrity: false, require_publisher: true, forbid_unknown_transport: true, http_require_url_origin_pin: true, http_require_bearer_token_env: true }` + `bypass: { enabled: false }`
   - 例として **3 server entry**:
     - `playwright` (transport: stdio, artifact_type: npm_package、SPEC 例の主要)
     - `filesystem-local` (transport: stdio, artifact_type: local_binary、command_path_sha256 例)
     - `company-search` (transport: http, artifact_type: remote_http、url_origin_pin + bearer_token_env_var 例)
   - inline コメント (JSON `_comment` field) で「positive list」「`@latest` 禁止」「server 追加時 SPEC-ID 記入」「HTTP MCP は anonymous 禁止 (bearer_token_env_var 必須)」を案内

2. `templates/sage/README.md` 新規 (もし不在なら):
   - `templates/sage/` ディレクトリの位置づけ (registry / inventory 雛形配布元)
   - mcp-allowlist-template.json の目的と使用方法 1 行
   - SPEC-0015 へのリンク

## File Scope（変更許可範囲）

- 作成: `templates/sage/mcp-allowlist-template.json`
- 作成: `templates/sage/README.md` (既存しない場合)
- 削除: なし

## 禁止事項

- `.sage/mcp-allowlist.json` (実 user データ) を作成しない (本 TASK は template のみ)
- schema に runtime enforcement を示唆する field (`block_on_drift`, `kill_process` 等) を含めない (SAGE doctrine §9.2 違反)
- YAML 形式で template を作らない (Codex review P2: parser robustness の理由で JSON 統一)
- example で `@latest` 使用禁止 (`policy.forbid_latest_tag: true` と一貫させる)
- sha256 を fake 値で書かない (例の sha256 は計算済の実値 or `"<compute-with-shasum>"` placeholder)

## 完了条件

- [ ] `templates/sage/mcp-allowlist-template.json` 存在
- [ ] `version`, `servers`, `policy`, `bypass` の 4 top-level key 存在
- [ ] `servers` に 3+ example entry (stdio/npm_package, stdio/local_binary, http/remote_http の 3 transport-artifact 組合せ)
- [ ] 各 entry に必須 field 全揃い (transport ごとの schema validation 可能)
- [ ] policy.forbid_latest_tag = true (default)
- [ ] policy.require_publisher = true (default、stdio 用)
- [ ] policy.require_npm_integrity = false (default、user opt-in)
- [ ] policy.forbid_unknown_transport = true (default)
- [ ] policy.http_require_url_origin_pin = true (default)
- [ ] policy.http_require_bearer_token_env = true (default、HTTP MCP の anonymous 禁止)
- [ ] `_comment` 形式で positive list 原則 / SPEC-ID 記入ルール / `@latest` 禁止 / HTTP MCP の auth 必須を案内
- [ ] JSON parse で error 0 件 (`python3 -c "import json; json.load(open('templates/sage/mcp-allowlist-template.json'))"`)
- [ ] commit message に `TASK-0122:` を含む
