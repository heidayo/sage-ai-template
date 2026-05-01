# TASK-0109: security-filter.sh (SessionStop secret mask) + tests

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0109 |
| SPEC-ID   | SPEC-0012 |
| PLAN-ID   | PLAN-0012 |
| ステータス | Pending |
| 担当Agent | Implementation/Test |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 75m |

## 責務

SessionStop hook で `.sage/runs/RUN-*.yaml` の最新 file を scan し、API key / token / JWT パターンを `***REDACTED***` に置換する。Phase 2A Cluster I subagent 報告 (security-filter.sh 提案) と Codex review R5 (RUN log SQLite/FTS は redaction 先行) の両方への対応。

## 入力

- SPEC-0012 FR-03, SEC-01, NFR-05, リスク2
- Codex review R5 (SPEC-0010 follow-up: RUN log 索引化前に redaction)
- Cluster I subagent (Make Culture security-scan skill) の `hooks/security-filter.sh` 提案
- Phase 2A test harness

## 出力

1. `templates/hooks/security-filter.sh` 新規:
   - `set -euo pipefail` + profile gating
   - SessionStop hook なので stdin JSON は `{"hook_event_name":"SessionStop", ...}` を期待
   - **Target**: `.sage/runs/RUN-*.yaml` の最新 (mtime 最新) 1 file のみ scan
   - **Redaction patterns** (sed -i または awk で in-place 置換、atomic write):
     - `sk-[A-Za-z0-9]{32,}` (OpenAI/Anthropic style)
     - `ghp_[A-Za-z0-9]{36}`, `gho_[A-Za-z0-9]{36}` (GitHub PAT)
     - `xox[abp]-[A-Za-z0-9-]+` (Slack)
     - `AKIA[0-9A-Z]{16}` (AWS Access Key)
     - `eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}` (JWT 3-part base64)
     - YAML field where key matches `(api[_-]?key|token|secret|password|jwt)` (case-insensitive) and value is non-empty 20+ char alphanumeric → 値全体を `***REDACTED***`
   - **Atomic write**: `mktemp` → `sed/awk` → `mv` で in-place、失敗時 trap で original 保持
   - **Idempotency** (NFR-05): 既に `***REDACTED***` 化された entry は再 redact しない
   - profile=minimal/none で skip
   - exit 0 を必ず返す (SessionStop hook なので block しない)

2. `templates/hooks/tests/test-security-filter.sh`:
   - Setup: sandbox に `.sage/runs/RUN-9999.yaml` を作成、test patterns 含む内容
   - Run hook → file 内容 verify
   - Idempotency: 同 hook 2 回実行で同じ file 内容
   - Atomic: 失敗 inject (write 中断) で original file 保持
   - Patterns: sk-/ghp_/xox/AKIA/JWT すべて redact 確認
   - YAML field: `api_key: "abcdefghijklmnopqrst"` → `api_key: "***REDACTED***"`
   - Negative: 通常テキスト (`note: hello world`) は変更されない

## File Scope（変更許可範囲）

- 作成: `templates/hooks/security-filter.sh`
- 作成: `templates/hooks/tests/test-security-filter.sh`
- 削除: なし

## 禁止事項

- 既存 RUN log structure (YAML schema) を破壊しない (key/value 構造維持、value のみ置換)
- `.sage/runs/` 全 file scan 禁止 (最新 1 file のみ、performance リスク)
- non-atomic write 禁止 (partial failure で破損)
- redaction が 1 回 file pattern だけで合致したら全行置換のような broad match 禁止
- minimal profile で実行されないこと (test で確認)

## 完了条件

- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS
- [ ] `sk-abcdef0123456789abcdef0123456789abcd` を含む YAML field が `***REDACTED***` に置換
- [ ] `ghp_abcd...36chars` 同上
- [ ] `api_key: "20+char"` → `api_key: "***REDACTED***"`
- [ ] 通常テキスト (`note: hello`) は unchanged
- [ ] 同 hook 2 回実行で file 内容同一 (idempotent)
- [ ] write failure inject で original 保持 (atomic)
- [ ] profile=minimal で全 skip + file unchanged
- [ ] exit 0 必ず返す
- [ ] commit message に `TASK-0109:` を含む
