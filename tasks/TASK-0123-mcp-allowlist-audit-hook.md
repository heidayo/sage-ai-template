# TASK-0123: MCP allowlist audit hook + tests + performance test helper

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0123 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation/Test |
| 並列可否  | No |
| 依存TASK  | TASK-0122 (JSON schema 必要) |
| 見積     | 165m (Codex 2nd review +30m for transport-aware + Python helper / fake wrapper、Codex 3rd review +0m for auth_mode + secret hygiene、Codex 4th-5th review +15m for OAuth top-level + drift6 strict + case-insensitive + audit log JSON schema) |

## 責務

SessionStart hook として動作する `templates/hooks/mcp-allowlist-audit.sh` を新規実装。**default は repo-local config のみ** (`.mcp.json` cwd + `.codex/config.toml` cwd)、user-global `~/.codex/config.toml` は **`.sage/config.yaml` で明示 opt-in した場合のみ** (Codex review P2-3 反映)。registry parse は **Python stdlib `json`** で安定実行 (Codex review P2-4 反映)。Performance 測定 helper も同 TASK で作成。

## 入力

- SPEC-0015 FR-03 (audit hook 詳細仕様、repo-local default)
- SPEC-0015 FR-05 (Performance test helper)
- SPEC-0015 NFR-01 (200ms median)
- SPEC-0015 NFR-03 (graceful degradation)
- SPEC-0015 NFR-07 (parser robustness、Python stdlib `json`)
- SPEC-0015 EC-01..EC-05 (error cases)
- SPEC-0015 OPS-01 (profile gating)
- SPEC-0015 SEC-01 (detection-only / runtime-process-safe、kill 等の実コマンド禁止)
- SPEC-0015 SEC-06 (user-global default exclusion)
- TASK-0122 で確定した JSON registry schema
- 既存 hook の base pattern (`templates/hooks/protect-sage-files.sh` 等)
- Codex review P2-3 / P2-4 / P2-5 (PR #21)

## 出力

1. `templates/hooks/mcp-allowlist-audit.sh` 新規:
   - `set -uo pipefail` + profile gating
   - SessionStart hook、stdin JSON は `{"hook_event_name":"SessionStart", ...}`
   - **default 比較対象**:
     - `.mcp.json` (cwd 直下)
     - `./.codex/config.toml` (repo-local Codex config、存在時のみ)
   - **opt-in 比較対象**: `.sage/config.yaml` の `mcp_audit.include_user_global_codex: true` を明示時のみ `~/.codex/config.toml` も対象
   - registry parse: **Python stdlib `json`** (`python3 -c "import json,sys; ..."`、awk 不採用)
   - Python 不在時: `command -v python3` 失敗で warn + skip (graceful degradation NFR-03)
   - drift 検出 8+ case (Codex 4th review 反映で transport + auth-aware に拡張):
     - **stdio**: drift1 (registry にない server) / drift2 (args version mismatch) / drift3 (registry only) / drift4 (`@latest`) / drift5 (artifact integrity mismatch — npm_integrity / command_path_sha256 / tls_pin_sha256)
     - **http**: drift1 http / drift2 http (url_origin mismatch) / drift6 anonymous (auth_mode: "none") / drift6 OAuth approve / drift6 Bearer approve / drift7 sensitive header (case-insensitive 4 variant) / drift8 OAuth callback mismatch
     - **共通**: transport mismatch (drift1 として判定) / expired approval
     - 各 case に warn 文言 + audit log 出力
   - profile=`none`/`minimal` で完全 skip (true silent)、`standard` で warn (exit 0)、**`strict` で drift1 / drift5 / drift6 anonymous / drift8 OAuth callback mismatch の 4 cases を block (exit 1)** (Codex 4th review P2 #4 反映で http_require_auth policy 名と挙動の整合)
   - audit log 書き先: `.sage/audit/mcp-allowlist-$(date -u +%Y%m%d).log` (ディレクトリ自動作成)
   - **args redact**: log には raw command line でなく `<command> <package-name>@<version>` 形式に正規化 (Codex review P2 反映)
   - registry 不在: 1 回 warn + skip
   - bypass.enabled=true: 全 drift skip + `.sage/audit/mcp-allowlist-bypass.log` に bypass 事実を記録
   - **`kill / pkill / killall / kill -*` 等の実コマンド使用禁止** (SEC-01、TASK-0124 で behavior test 検証)

2. `templates/hooks/tests/test-mcp-allowlist-audit.sh` 新規:
   - sandbox 作成 + cleanup
   - test cases (最低 24、NFR-06 シナリオ網羅性、transport + auth-aware):
     - **stdio drift**:
       - drift 1 stdio: registry にない stdio server を `.mcp.json` に作る → warn
       - drift 2 stdio: args version mismatch → warn
       - drift 3 stdio: registry にあるが `.mcp.json` にない → info
       - drift 4 stdio: `@latest` (`policy.forbid_latest_tag: true` 時) → warn
       - drift 5 stdio: npm_integrity mismatch (`policy.require_npm_integrity: true` 時) → warn (重大)
     - **http drift** (Codex 1st-4th review 反映):
       - drift 1 http: registry にない HTTP MCP server を `.mcp.json` に作る → warn (重大)
       - drift 2 http: url_origin mismatch → warn
       - drift 6 anonymous: HTTP MCP の `auth_mode: "none"` または auth_mode 不在 + `policy.http_require_auth: true` → warn (standard) / **block (strict)** (Codex 4th review P2 #4 反映)
       - drift 6 OAuth approve: HTTP MCP の `auth_mode: "oauth"` (provider / scopes 整合) → 通常承認
       - drift 6 Bearer approve: HTTP MCP の `auth_mode: "bearer_env"` (env var 一致) → 通常承認
       - **drift 7 sensitive header (case-insensitive、Codex 4th review P2 #2 反映)**: 4 variant 全て FAIL (registry parse reject):
         - canonical: `http_headers: { "Authorization": "..." }`
         - lowercase: `http_headers: { "authorization": "..." }`
         - uppercase: `http_headers: { "AUTHORIZATION": "..." }`
         - mixed: `http_headers: { "x-Api-Key": "..." }`
         - 実装: header name を `header.lower()` で正規化後 canonical list `[authorization, cookie, set-cookie, proxy-authorization, x-api-key, x-auth-token, x-token]` と比較 (Bearer は header 名でなく value pattern のため list に含めない)
       - **drift 8 OAuth callback mismatch** (Codex 4th review P2 #3 反映): registry top-level `oauth_callback.mcp_oauth_callback_port: 8765` だが実 Codex config top-level `mcp_oauth_callback_port: 9000` → warn (standard) / **block (strict)**
       - transport mismatch: 実 config STDIO ↔ registry HTTP (or 逆) → drift 1 として warn
     - **共通**:
       - expired approval → warn
       - registry 不在 → warn + skip (exit 0)
       - profile=`minimal` → 完全 skip (exit 0、log なし)
       - **profile=`strict` で以下 4 類が block (exit 1)** (Codex 4th review P2 #4 反映):
         - drift 1 (stdio / http 両方)
         - drift 5 (artifact integrity mismatch)
         - drift 6 anonymous (HTTP MCP auth_mode: "none")
         - drift 8 (OAuth callback mismatch)
       - audit log で args / bearer_token_env_var の値が **redact** (env name のみ記録、env value は記録しない)
       - default で user-global `~/.codex/config.toml` を読まない (Codex review P2 反映)
       - opt-in 設定時のみ user-global を読む (`.sage/config.yaml` で `mcp_audit.include_user_global_codex: true` 明示時)
   - bypass.enabled=true での suppress 確認

3. `templates/hooks/tests/measure-hook-time.py` 新規 (Codex review P2-3 反映、macOS / Linux 完全互換のため Python ベース):
   - Python 3 stdlib のみ (`time.perf_counter()` + `subprocess` + `statistics` + `argparse`)
   - 引数: hook script path (positional)、`--runs 5` (default)、`--threshold-ms 200` (default、env `SAGE_HOOK_TIME_THRESHOLD_MS` で override 可)
   - 各 run で `subprocess.run(...)` 前後の `time.perf_counter()` 差分を ms 単位で記録
   - `statistics.median()` で中央値算出
   - 中央値 < 閾値 → exit 0 + 結果を stdout (median / min / max / 全 runs)
   - 超過 → exit 1 + 結果を stderr
   - macOS の `/usr/bin/time -f` 非互換問題を完全回避
   - shebang `#!/usr/bin/env python3`、Python 3 不在環境では shell wrapper で graceful skip (NFR-03)

## File Scope（変更許可範囲）

- 作成: `templates/hooks/mcp-allowlist-audit.sh`
- 作成: `templates/hooks/tests/test-mcp-allowlist-audit.sh`
- 作成: `templates/hooks/tests/measure-hook-time.py` (Codex review P2-3 反映で Python ベースに変更、shell ベースの `.sh` は不採用)
- 削除: なし

## 禁止事項

- runtime での MCP server process kill / signal を実装しない (governance §9.2 / SEC-01 違反)
- `kill / pkill / killall / kill -*` 等の実コマンドをスクリプト内に書かない (TASK-0124 の behavior test で検証される)
- registry を hook 内で書き換えない (read-only)
- yq / jq 等の YAML/JSON 外部依存を必須化しない (jq は hook stdin parse でのみ optional 使用可、`json.loads()` は Python stdlib)
- `.sage/audit/` 以外の path に audit log を書かない
- profile=`minimal`/`none` で 1 文字でも stderr 出さない (true silent skip)
- audit log に raw command line / API key / token を書かない (args redact 必須)
- default で user-global `~/.codex/config.toml` を読まない (opt-in 必須)

## 完了条件

- [ ] `templates/hooks/mcp-allowlist-audit.sh` 存在 + executable bit
- [ ] shellcheck で error 0 件
- [ ] **detection-only behavior は TASK-0124 の `test-detection-only-behavior.sh` で検証** (fake wrapper 方式、grep 不採用、Codex review P2-2 反映)
- [ ] `templates/hooks/tests/test-mcp-allowlist-audit.sh` の 24 シナリオ全 PASS (Codex 4th review P2 #2/#3/#4 反映で +4: drift7 case-insensitive 4 variant + drift8 OAuth callback mismatch + drift6 anonymous strict block test)
- [ ] `bash templates/hooks/tests/run-tests.sh` で 109 + 24 = 133+ 全 PASS
- [ ] `python3 templates/hooks/tests/measure-hook-time.py templates/hooks/mcp-allowlist-audit.sh` で 5 回中央値 < 200ms (Python `time.perf_counter()` で macOS / Linux 互換、機械判定 exit code)
- [ ] graceful degradation: registry 不在 / Codex CLI 不在 / `.mcp.json` 不在 / Python 不在 のいずれでも exit 0
- [ ] audit log が `.sage/audit/mcp-allowlist-YYYYMMDD.log` に append-only で書かれる
- [ ] **audit log は JSON-lines 形式** (Codex 6th review P2 #2 反映、NFR-04 schema 準拠): 各行が独立 JSON object、必須 5 field (`timestamp` ISO 8601 UTC / `runtime` / `drift_type` enum / `severity` / `details`)
- [ ] **`drift_type` enum 完全一致**: 人間向け文字列ではなく schema 定義の enum 値 (`drift1_stdio_unknown_server` / `drift5_npm_integrity_mismatch` / `drift6_anonymous` / `drift7_sensitive_header` / `drift8_oauth_callback_mismatch` 等) を出力
- [ ] audit log に raw command line 不在 (args redact 検証 grep で 0 件)
- [ ] default で user-global config を読まない (test で検証)
- [ ] opt-in 設定時のみ user-global を読む (test で検証)
- [ ] commit message に `TASK-0123:` を含む
