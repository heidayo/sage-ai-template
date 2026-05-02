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
| 見積     | 120m (Codex review P2 反映で perf helper + parser robustness 改善追加 +30m) |

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
   - test cases (最低 13、NFR-06 シナリオ網羅性):
     - **drift 1**: registry にない server を `.mcp.json` に作る → warn
     - **drift 2**: args version mismatch → warn
     - **drift 3**: registry にあるが `.mcp.json` にない → info
     - **drift 4**: `.mcp.json` に `@latest` (`policy.forbid_latest_tag: true` 時) → warn
     - **drift 5**: sha256 mismatch (`policy.require_sha256: true` 時) → warn (重大)
     - expired approval → warn
     - registry 不在 → warn + skip (exit 0)
     - profile=`minimal` → 完全 skip (exit 0、log なし)
     - profile=`strict` で drift 1 → block (exit 1)
     - profile=`strict` で drift 5 → block (exit 1)
     - audit log で args が **redact** されている (raw command line 不在を grep で検証)
     - **default で user-global `~/.codex/config.toml` を読まない** (Codex review P2-3 反映の test)
     - opt-in 設定時のみ user-global を読む (`.sage/config.yaml` で `mcp_audit.include_user_global_codex: true` 明示時)
   - bypass.enabled=true での suppress 確認

3. `templates/hooks/tests/measure-hook-time.sh` 新規 (Codex review P2-5 反映):
   - 引数: hook script path
   - 5 回実行、各実行時間を `time` で計測 (`/usr/bin/time -f "%e"` で wall-clock 時間取得)
   - 中央値 (median) を bash で算出
   - 環境変数 `SAGE_HOOK_TIME_THRESHOLD_MS` (default 200) と比較
   - 中央値 < 閾値 → exit 0 + 結果を stdout
   - 超過 → exit 1 + 結果を stderr
   - `time` 単発の flakiness を回避

## File Scope（変更許可範囲）

- 作成: `templates/hooks/mcp-allowlist-audit.sh`
- 作成: `templates/hooks/tests/test-mcp-allowlist-audit.sh`
- 作成: `templates/hooks/tests/measure-hook-time.sh`
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
- [ ] `! grep -nE "\\b(kill\|pkill\|killall)\\b" templates/hooks/mcp-allowlist-audit.sh` で 0 件 (SEC-01 自動検証、TASK-0124 で再確認)
- [ ] `templates/hooks/tests/test-mcp-allowlist-audit.sh` の 13 シナリオ全 PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` で 109 + 13 = 122+ 全 PASS
- [ ] `templates/hooks/tests/measure-hook-time.sh templates/hooks/mcp-allowlist-audit.sh` で 5 回中央値 < 200ms (機械判定 exit code)
- [ ] graceful degradation: registry 不在 / Codex CLI 不在 / `.mcp.json` 不在 / Python 不在 のいずれでも exit 0
- [ ] audit log が `.sage/audit/mcp-allowlist-YYYYMMDD.log` に append-only で書かれる
- [ ] audit log に raw command line 不在 (args redact 検証 grep で 0 件)
- [ ] default で user-global config を読まない (test で検証)
- [ ] opt-in 設定時のみ user-global を読む (test で検証)
- [ ] commit message に `TASK-0123:` を含む
