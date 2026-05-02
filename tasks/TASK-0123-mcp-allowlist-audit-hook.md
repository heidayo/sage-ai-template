# TASK-0123: MCP allowlist audit hook + tests

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0123 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation/Test |
| 並列可否  | Yes (with TASK-0125) |
| 依存TASK  | TASK-0122 (schema 必要) |
| 見積     | 90m |

## 責務

SessionStart hook として動作する `templates/hooks/mcp-allowlist-audit.sh` を新規実装し、実 `.mcp.json` (Claude Code) と `~/.codex/config.toml` (Codex CLI、optional) を `.sage/mcp-allowlist.yaml` registry と照合して drift を検出する。検出結果は profile に応じて warn (standard) / block (strict) する。完全な test harness を伴う。

## 入力

- SPEC-0015 FR-02 (audit hook 詳細仕様)
- SPEC-0015 NFR-01 (200ms 性能要件)
- SPEC-0015 NFR-03 (graceful degradation)
- SPEC-0015 EC-01..EC-04, EC-06 (error cases)
- SPEC-0015 OPS-01 (profile gating)
- TASK-0122 で確定した registry schema
- 既存 hook の base pattern (`templates/hooks/protect-sage-files.sh` 等の `set -uo pipefail` + profile gating)
- 既存 test harness (`templates/hooks/tests/run-tests.sh` の jq -Rsc + bash_input_json パターン)

## 出力

1. `templates/hooks/mcp-allowlist-audit.sh` 新規:
   - `set -uo pipefail` + profile gating (`.sage/config.yaml` の `hooks.profile`)
   - SessionStart hook なので stdin JSON は `{"hook_event_name":"SessionStart", ...}` を期待
   - 比較対象: `.mcp.json` (cwd 直下) と `~/.codex/config.toml` (存在する場合のみ)
   - registry parse: awk ベース (yq 依存しない、200ms 制約)
   - drift 検出 4 case (drift1/2/3 + expired)、各 case に warn 文言 + audit log 出力
   - profile=`none`/`minimal` で完全 skip (exit 0)、`standard` で warn (exit 0)、`strict` で drift1 のみ block (exit 1)
   - audit log 書き先: `.sage/audit/mcp-allowlist-$(date -u +%Y%m%d).log` (ディレクトリ自動作成)
   - registry 不在: 1 回 warn + skip (initial setup 案内)
   - bypass.enabled=true: 全 drift を skip + `.sage/audit/mcp-allowlist-bypass.log` に bypass 事実を記録

2. `templates/hooks/tests/test-mcp-allowlist-audit.sh` 新規:
   - sandbox 作成 + cleanup
   - test cases (最低 7):
     - drift 1 (registry にない server を `.mcp.json` に作る) → warn 確認
     - drift 2 (registry と異なる args version) → warn 確認
     - drift 3 (registry にあるが `.mcp.json` にない) → info レベル確認
     - expired approval (`expires_at` < 今日) → warn 確認
     - registry 不在 → warn + skip 確認 (exit 0)
     - profile=`minimal` → 完全 skip 確認 (exit 0、log なし)
     - profile=`strict` で drift 1 → block 確認 (exit 1)
   - audit log 出力先のファイル存在確認
   - bypass.enabled=true での suppress 確認

## File Scope（変更許可範囲）

- 作成: `templates/hooks/mcp-allowlist-audit.sh`
- 作成: `templates/hooks/tests/test-mcp-allowlist-audit.sh`
- 削除: なし

## 禁止事項

- runtime での MCP server process kill / signal 送信を実装しない (governance §9.2 違反)
- registry を hook 内で書き換えない (read-only)
- yq / jq 等の外部依存を必須化しない (jq は hook stdin parse でのみ optional 使用、awk fallback あり)
- `.sage/audit/` 以外の path に audit log を書かない
- profile=`minimal`/`none` で 1 文字でも stderr 出さない (true silent skip)

## 完了条件

- [ ] `templates/hooks/mcp-allowlist-audit.sh` 存在 + executable bit
- [ ] shellcheck で error 0 件
- [ ] `templates/hooks/tests/test-mcp-allowlist-audit.sh` の test cases 7+ 全 PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` で 109 + 7 = 116+ 全 PASS
- [ ] `time bash templates/hooks/mcp-allowlist-audit.sh < /tmp/empty.json` < 200ms (NFR-01)
- [ ] graceful degradation: registry 不在 / Codex CLI 不在 / `.mcp.json` 不在 のいずれでも exit 0
- [ ] audit log が `.sage/audit/mcp-allowlist-YYYYMMDD.log` に append-only で書かれる
- [ ] commit message に `TASK-0123:` を含む
