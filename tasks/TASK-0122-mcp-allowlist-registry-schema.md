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
- SPEC-0015 FR-02 (policy enforcement: forbid_latest_tag / require_npm_integrity / require_publisher / forbid_unknown_transport / http_require_url_origin_pin / http_require_auth / http_static_header_secret_check)
- SPEC-0015 SEC-02 (positive list + supply-chain pin 原則)
- 既存 `templates/mcp-json-template.json` の構造 (参考のみ)
- Codex CLI `~/.codex/config.toml` の `[mcp_servers]` 構造 (参考のみ)
- Codex review P1 finding (PR #21 review): "version 固定、sha256 または package lock provenance、publisher/source registry、@latest 禁止または明示 risk acceptance を schema と test に入れてください"

## 出力

1. `templates/sage/mcp-allowlist-template.json` 新規 (**transport-aware**, Codex review P1 反映):

   - **stdio transport 必須 field**: `name`, `transport: "stdio"`, `artifact_type` (npm_package / local_binary), `command`, `args`, `version_pin`, `publisher`, `source_registry`, `approved_by`, `approved_at`, `expires_at`
   - **stdio 推奨 field**: `npm_integrity` (npm_package 用、`policy.require_npm_integrity: true` で必須化可能)、`enabled_tools` / `disabled_tools`
   - **http transport 必須 field** (Codex 3rd review P2 #1 反映で auth_mode 導入): `name`, `transport: "http"`, `artifact_type: "remote_http"`, `url`, `url_origin_pin`, `auth_mode` (`bearer_env` / `oauth` / `none`), `approved_by`, `approved_at`, `expires_at`
     - `auth_mode: "bearer_env"` の追加必須: `bearer_token_env_var` (env name only)
     - `auth_mode: "oauth"` の追加必須: `oauth_provider` / `oauth_scopes` (list) / `oauth_callback_url`
     - `auth_mode: "none"` は anonymous (`policy.http_require_auth: true` で禁止可能)
   - **http 推奨 field**: `http_headers` (**non-sensitive のみ、機密 header 名禁止**)、`env_http_headers` (機密値はこちらに env 名参照)、`tls_pin_sha256`, `enabled_tools` / `disabled_tools`
   - **共通 optional**: `notes`, `startup_timeout_sec`, `tool_timeout_sec`, `enabled`, `required`
   - top-level: `version: "1.0"` + `policy: { forbid_latest_tag: true, require_npm_integrity: false, require_publisher: true, forbid_unknown_transport: true, http_require_url_origin_pin: true, http_require_auth: true, http_static_header_secret_check: true }` + `bypass: { enabled: false }`
   - 例として **4 server entry** (Codex 3rd review P2 #1 で auth_mode oauth 例を追加):
     - `playwright` (transport: stdio, artifact_type: npm_package)
     - `filesystem-local` (transport: stdio, artifact_type: local_binary、command_path_sha256 例)
     - `company-search` (transport: http, artifact_type: remote_http, auth_mode: bearer_env)
     - `external-oauth-mcp` (transport: http, artifact_type: remote_http, auth_mode: oauth, oauth_provider: google)
   - inline コメント (JSON `_comment` field) で「positive list」「`@latest` 禁止」「server 追加時 SPEC-ID 記入」「HTTP MCP は anonymous 禁止 (auth_mode は bearer_env / oauth どちらか必須)」「`http_headers` に Authorization / Cookie / X-Api-Key 等の機密 header 静的値 禁止 (env_http_headers 経由)」を案内

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
- [ ] `servers` に 4+ example entry (stdio/npm_package, stdio/local_binary, http/remote_http with bearer_env, http/remote_http with oauth の 4 transport-artifact-auth 組合せ)
- [ ] 各 entry に必須 field 全揃い (transport + auth_mode ごとの schema validation 可能)
- [ ] policy.forbid_latest_tag = true (default)
- [ ] policy.require_publisher = true (default、stdio 用)
- [ ] policy.require_npm_integrity = false (default、user opt-in)
- [ ] policy.forbid_unknown_transport = true (default)
- [ ] policy.http_require_url_origin_pin = true (default)
- [ ] policy.http_require_auth = true (default、HTTP MCP の anonymous 禁止、OAuth / Bearer どちらでも可)
- [ ] policy.http_static_header_secret_check = true (default、機密 header 静的値を registry に書かせない)
- [ ] `_comment` 形式で positive list / SPEC-ID 記入 / `@latest` 禁止 / HTTP MCP の auth 必須 / sensitive header 静的値禁止 を案内
- [ ] JSON parse で error 0 件 (`python3 -c "import json; json.load(open('templates/sage/mcp-allowlist-template.json'))"`)
- [ ] commit message に `TASK-0122:` を含む
