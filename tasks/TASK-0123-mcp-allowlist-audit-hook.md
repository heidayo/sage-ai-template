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
| 見積     | 150m (Codex 2nd review P1 transport-aware + P2 Python helper / fake wrapper で +30m、Codex 3rd review P2 で auth_mode + secret hygiene 拡張で +0m 維持) |

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
   - drift 検出 5 case (drift1..drift5 + expired)、各 case に warn 文言 + audit log 出力
   - profile=`none`/`minimal` で完全 skip (true silent)、`standard` で warn (exit 0)、`strict` で drift1 / drift5 を block (exit 1)
   - audit log 書き先: `.sage/audit/mcp-allowlist-$(date -u +%Y%m%d).log` (ディレクトリ自動作成)
   - **args redact**: log には raw command line でなく `<command> <package-name>@<version>` 形式に正規化 (Codex review P2 反映)
   - registry 不在: 1 回 warn + skip
   - bypass.enabled=true: 全 drift skip + `.sage/audit/mcp-allowlist-bypass.log` に bypass 事実を記録
   - **`kill / pkill / killall / kill -*` 等の実コマンド使用禁止** (SEC-01、TASK-0124 で behavior test 検証)

2. `templates/hooks/tests/test-mcp-allowlist-audit.sh` 新規:
   - sandbox 作成 + cleanup
   - test cases (最低 17、NFR-06 シナリオ網羅性、transport-aware):
     - **stdio drift**:
       - drift 1 stdio: registry にない stdio server を `.mcp.json` に作る → warn
       - drift 2 stdio: args version mismatch → warn
       - drift 3 stdio: registry にあるが `.mcp.json` にない → info
       - drift 4 stdio: `@latest` (`policy.forbid_latest_tag: true` 時) → warn
       - drift 5 stdio: npm_integrity mismatch (`policy.require_npm_integrity: true` 時) → warn (重大)
     - **http drift** (Codex 1st-3rd review 反映):
       - drift 1 http: registry にない HTTP MCP server を `.mcp.json` に作る → warn (重大)
       - drift 2 http: url_origin mismatch (登録 origin と異なる url) → warn
       - drift 6 anonymous: HTTP MCP の `auth_mode: "none"` または auth_mode 不在 + `policy.http_require_auth: true` → warn
       - drift 6 OAuth approve: HTTP MCP の `auth_mode: "oauth"` (oauth_provider / scopes / callback 整合) → 通常承認、anonymous 扱いしない
       - drift 6 Bearer approve: HTTP MCP の `auth_mode: "bearer_env"` (bearer_token_env_var 一致) → 通常承認
       - drift 7 sensitive header: registry の `http_headers` に `Authorization` 等の機密 header 静的値 → **FAIL** (parse 段階 reject)
       - transport mismatch: 実 config が STDIO server だが registry が `transport: "http"` (またはその逆) → drift 1 として warn
     - **共通**:
       - expired approval → warn
       - registry 不在 → warn + skip (exit 0)
       - profile=`minimal` → 完全 skip (exit 0、log なし)
       - profile=`strict` で drift 1 (stdio / http 両方) → block (exit 1)
       - profile=`strict` で drift 5 (artifact integrity mismatch) → block (exit 1)
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
- [ ] `templates/hooks/tests/test-mcp-allowlist-audit.sh` の 20 シナリオ全 PASS (Codex 3rd review P2 で http drift +3 拡張: drift6 OAuth/Bearer 通常承認 + drift7 sensitive header FAIL)
- [ ] `bash templates/hooks/tests/run-tests.sh` で 109 + 20 = 129+ 全 PASS
- [ ] `python3 templates/hooks/tests/measure-hook-time.py templates/hooks/mcp-allowlist-audit.sh` で 5 回中央値 < 200ms (Python `time.perf_counter()` で macOS / Linux 互換、機械判定 exit code)
- [ ] graceful degradation: registry 不在 / Codex CLI 不在 / `.mcp.json` 不在 / Python 不在 のいずれでも exit 0
- [ ] audit log が `.sage/audit/mcp-allowlist-YYYYMMDD.log` に append-only で書かれる
- [ ] audit log に raw command line 不在 (args redact 検証 grep で 0 件)
- [ ] default で user-global config を読まない (test で検証)
- [ ] opt-in 設定時のみ user-global を読む (test で検証)
- [ ] commit message に `TASK-0123:` を含む
