# TASK-0124: sage-doctor.sh に MCP allowlist check 追加 + detection-only behavior test

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0124 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0123 (audit logic re-use + behavior test 対象) |
| 見積     | 60m (Codex review P2 反映で behavior test 追加 +15m) |

## 責務

`scripts/sage-doctor.sh` に MCP allowlist の health check ステップを新規追加。TASK-0123 の audit hook と同 logic を CLI から呼べる形に factor out し、doctor から reuse。**Detection-only behavior test** を追加し、`kill / pkill / killall` 等の実コマンドが hook script に含まれていないことを grep ベースではなく **挙動 test** で検証 (Codex review P2-5 反映)。

## 入力

- SPEC-0015 FR-04 (doctor 拡張仕様)
- SPEC-0015 SEC-01 (detection-only / runtime-process-safe behavior test)
- SPEC-0015 AC-04, AC-09 (doctor が OK/WARN/FAIL 返す + 0 FAIL)
- TASK-0123 で実装した audit hook の drift 検出ロジック
- 既存 `scripts/sage-doctor.sh` の structure (各 step の出力 format / FAIL 集計)
- Codex review P2-5 (verification command flakiness)

## 出力

1. `scripts/sage-doctor.sh` 拡張:
   - 新 step「MCP allowlist check」を既存 step 群の後に追加 (出力 format 統一)
   - 5 観点の check (Codex 5th-6th review 反映で strict-block drift + registry secret hygiene を doctor に反映):
     - **(a) registry 存在**: `.sage/mcp-allowlist.json` 存在しなければ WARN
     - **(b) registry validity + secret hygiene**: JSON parse 不能 → FAIL。**`drift7_sensitive_header` 検出 → FAIL** (Codex 6th review P2 #1 反映: registry secret hygiene 違反は registry-level failure として扱う、INFO ではなく FAIL)
     - **(c) strict-block drift count**: TASK-0123 hook の drift 検出 logic を reuse、`.sage/audit/mcp-allowlist-*.log` を Python `json.loads()` で parse して `drift_type` enum 完全一致で判定。**strict 時 block 対象 8 enum (`drift1_stdio_unknown_server` / `drift1_http_unknown_server` / `drift5_npm_integrity_mismatch` / `drift5_command_path_sha256_mismatch` / `drift5_tls_pin_sha256_mismatch` / `drift6_anonymous` / `drift8_oauth_callback_mismatch` / `transport_mismatch`) のいずれか 1 件 > 0 で WARN** (Codex 5th-7th review 反映: transport_mismatch を drift1 と semantic 同等として strict-block enum に追加)
     - **(d) other warn-only drift count** (INFO レベル): `drift2_*_mismatch` / `drift3_*_registry_only` / `drift4_*_latest_tag` / `drift6_oauth_approve` / `drift6_bearer_approve` の件数を INFO で報告 (drift7 は (b) で FAIL 扱い、transport_mismatch は (c) で strict-block 扱いのため本 bucket から除外)
     - **(e) expired approvals 集計**: `expires_at` < 今日の server 数を WARN
   - 出力 format: `[N/M] MCP allowlist check...` + 各 sub-check で `OK: ...` / `WARN: ...` / `FAIL: ...`
   - 既存 summary line (`OK: X  WARN: Y  FAIL: Z`) に集計反映

2. `scripts/sage-mcp-allowlist-audit.sh` 新規 (TASK-0123 の audit logic を CLI から呼べる shell script として共通化):
   - hook (`templates/hooks/mcp-allowlist-audit.sh`) と doctor 両方が source または call で reuse
   - hook 側 logic が十分 modular なら本 script は wrapper のみ

3. `templates/hooks/tests/test-detection-only-behavior.sh` 新規 (**fake wrapper 方式**、Codex review P2-2 反映):
   - **setup**: tempdir に fake `kill` / `pkill` / `killall` 実行可能 wrapper を作成、各 wrapper は呼び出し時に `$INVOCATION_LOG` に追記
   - **PATH manipulation**: `PATH="$tempdir:$PATH"` で fake wrapper を先頭に置く
   - **execute**: `templates/hooks/mcp-allowlist-audit.sh` を subprocess として実行 (sample stdin 付き)
   - **assertion**: `[ ! -s "$INVOCATION_LOG" ]` (= log file が空) を確認、非空なら FAIL
   - **cleanup**: tempdir 削除
   - `ps aux | grep` 方式は採用しない (test 自身の grep プロセス / SPEC コメント記述が false fail を起こすため、Codex review P2-2 で却下)
   - 副次効果: hook 内で `kill` を文字列として `echo` する場合は wrapper が呼ばれないので false fail にならない (= 真の behavior 検証)

   ```bash
   # 概念実装イメージ:
   tempdir=$(mktemp -d)
   trap "rm -rf $tempdir" EXIT
   INVOCATION_LOG="$tempdir/invocations.log"
   for cmd in kill pkill killall; do
     cat > "$tempdir/$cmd" <<'WRAPPER'
   #!/bin/sh
   echo "$0 called with: $*" >> "$INVOCATION_LOG"
   WRAPPER
     chmod +x "$tempdir/$cmd"
   done
   PATH="$tempdir:$PATH" bash templates/hooks/mcp-allowlist-audit.sh < /dev/null
   if [ -s "$INVOCATION_LOG" ]; then
     echo "FAIL: detection-only violation, kill family invoked:"
     cat "$INVOCATION_LOG"
     exit 1
   fi
   echo "PASS: no kill family invocation"
   ```

## File Scope（変更許可範囲）

- 変更: `scripts/sage-doctor.sh`
- 作成: `scripts/sage-mcp-allowlist-audit.sh`
- 作成: `templates/hooks/tests/test-detection-only-behavior.sh`
- 削除: なし

## 禁止事項

- 既存 doctor step を削除 / 順序変更しない
- doctor から MCP server を kill / restart しない (audit-only)
- `.sage/audit/*.log` の内容を改変 / rotate しない (本 TASK は read-only)
- Phase 1-3 の test 109/109 を破壊しない (regression)
- behavior test を grep / `ps aux` ベースで実装しない (Codex review P2-2 反映、test 自身の grep プロセス混入で false fail、または SPEC/PLAN コメント記述で false positive、**fake wrapper 方式必須**)

## 完了条件

- [ ] `scripts/sage-doctor.sh` に「MCP allowlist check」step が追加され、既存 step 数 + 1 に
- [ ] registry 不在で WARN 出る (実機テスト: registry を一時削除して doctor 実行)
- [ ] registry valid + drift なし で OK 出る
- [ ] **strict-block drift WARN tests** (Codex 6th-8th review 反映、**5 logical cases / 8 enum 全部 inject**):
  - drift1 inject (registry にない server: `drift1_stdio_unknown_server` / `drift1_http_unknown_server`) で WARN 出る
  - drift5 inject (artifact integrity mismatch: `drift5_npm_integrity_mismatch` / `drift5_command_path_sha256_mismatch` / `drift5_tls_pin_sha256_mismatch`) で WARN 出る
  - drift6 anonymous inject (HTTP MCP `auth_mode: "none"` + `policy.http_require_auth: true`、drift_type: `drift6_anonymous`) で WARN 出る
  - drift8 OAuth callback mismatch inject (registry top-level `oauth_callback.mcp_oauth_callback_port: 8765` vs 実 Codex config `9000`、drift_type: `drift8_oauth_callback_mismatch`) で WARN 出る
  - transport_mismatch inject (実 config STDIO server だが registry が `transport: "http"` または逆、drift_type: `transport_mismatch`) で WARN 出る (Codex 7th review P2 #1 反映で strict-block 5th case)
- [ ] **registry secret hygiene FAIL test** (Codex 6th review P2 #1 反映): drift7 inject (registry に `http_headers: { "Authorization": "..." }` 等の sensitive header 静的値、drift_type: `drift7_sensitive_header`) で **FAIL** 出る (INFO ではない、registry-level failure として扱う)
- [ ] expired approval inject で WARN 出る
- [ ] `bash scripts/sage-doctor.sh` 全体で 0 FAIL 維持 (本 TASK 完了直後の repo state で)
- [ ] `templates/hooks/tests/test-detection-only-behavior.sh` PASS (kill 系 process 起動 0 件を behavior 検証)
- [ ] commit message に `TASK-0124:` を含む
