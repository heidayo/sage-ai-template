# SPEC-0016: RUN log SQLite-FTS / 検索基盤

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0016 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |
| 更新日    | 2026-05-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0008 (RUN log validator), SPEC-0012 (security-filter redaction), SPEC-0017 (agent identity runtime field) |
| 権限レベル | platform |
| 予約Phase | Phase 5+ (SPEC-0010/0011/0012 で予約済) |

## 背景・目的

SAGE は `.sage/runs/RUN-*.yaml` で全 agent 実行を記録するが、以下のギャップが残存:

1. **検索基盤不在**: 数百 RUN log を grep / awk / jq で都度集計、incident response 時の効率が低い (例: 「過去 30 日で agent_id=implementation かつ status=fail の RUN を抽出」が手作業)
2. **redaction 後の事後検索が困難**: SPEC-0012 security-filter で `***REDACTED***` 化された RUN log は機械的構造を持つが、検索インデックスがないため本番運用で実質 read-only
3. **drift 集計の効率**: SPEC-0015 audit log + SPEC-0017 inventory drift は JSON-lines だが、RUN log との join 検索 (例: 「drift1 を出した agent_id の RUN log を抽出」) ができない

本 SPEC は **SQLite FTS5** を採用し、RUN log + audit log の検索基盤を構築する。SAGE doctrine §9.2 に従い、**runtime enforcement は提供しない** — 検索 index と CLI 検索コマンドのみ。

## 対象ユーザー

- 数十〜数千 RUN log を運用する team (incident response 速度向上)
- redaction 済 RUN log を SIEM / audit pipeline に流す user
- agent drift の root cause analysis を行う security operator

## スコープ（含む）

- **SQLite FTS5 schema**: `.sage/runs.db` に RUN log + audit event を index、agent_id / task_id / status / drift_type / runtime / timestamp で検索
- **`scripts/sage-runlog-index.sh`**: `.sage/runs/RUN-*.yaml` + `.sage/audit/mcp-allowlist-*.log` + `.sage/audit/agent-inventory-*.log` を indexer で SQLite に入れる
- **`scripts/sage-runlog-search.sh`**: CLI 検索 (FTS5 query syntax + structured filter)
- **doctor 拡張**: `[5/6]` step で index 健全性 (stale / missing entry / size 圧迫) を check
- **incremental update**: full re-index ではなく差分 update (mtime ベース)
- **doc cross-refs**: 5 file (R7 厳守、各 +3 行以内)
- **installer 拡張**: index/search script を embed

## スコープ外（明示的に除外）

- runtime での RUN log 改ざん検出 (audit log 内容の信頼性は別 SPEC)
- Web UI / dashboard (CLI のみ)
- Cross-repo 集計 (1 repo の `.sage/` 内のみ)
- redaction logic 変更 (SPEC-0012 で確定済)
- agent identity inventory の design 変更 (SPEC-0017 で確定済)
- MCP allowlist registry の design 変更 (SPEC-0015 で確定済)
- install.sh 分割 (SPEC-0014)

## 要件

### 機能要件

- **[FR-01] SQLite FTS5 schema** (`.sage/runs.db`):
  - `runs` table: run_id PK / task_id / agent_id / runtime / status / started_at / completed_at / files_changed (JSON) / error_log
  - `audit_events` table: id PK / source (mcp-allowlist / agent-inventory) / drift_type / severity / runtime / server_name / timestamp / details (JSON)
  - `runs_fts` virtual table (FTS5): run_id / task_id / agent_id / status / error_log で全文検索
  - `audit_fts` virtual table (FTS5): drift_type / severity / details_json で全文検索

- **[FR-02] indexer** (`scripts/sage-runlog-index.sh`):
  - 引数なし: 全 `.sage/runs/RUN-*.yaml` + `.sage/audit/*.log` を index
  - `--incremental`: mtime > last_index_at の file のみ re-index
  - `--full`: DB drop + 全 re-index
  - Python stdlib (`sqlite3` + `yaml` + `json`) のみ、外部依存なし
  - graceful: yaml/json parse error は warn + skip (run / event 単位で)

- **[FR-03] search CLI** (`scripts/sage-runlog-search.sh`):
  - `--task-id TASK-XXXX`: task で絞り込み
  - `--agent-id NAME`: agent_id で絞り込み
  - `--status pass|fail|skipped`: status で絞り込み
  - `--drift-type ENUM`: SPEC-0015/0017 enum 値で audit event 絞り込み
  - `--since YYYY-MM-DD` / `--until YYYY-MM-DD`: 期間
  - `--fts QUERY`: FTS5 query (例: `"NEAR(redact, error)"`、`"agent_id:implementation AND status:fail"`)
  - 出力: TSV (default) または `--json`

- **[FR-04] doctor 拡張**: `[5/6]` step で:
  - `.sage/runs.db` 存在 (FAIL: missing → WARN、initial setup 案内)
  - DB schema 整合 (FAIL: schema mismatch → FAIL)
  - 最終 index 時刻 (FAIL: 7 日以上未更新 → WARN)
  - DB size (FAIL: > 100 MB → WARN、rotation 推奨)

- **[FR-05] template + documentation**:
  - `.sage/runs.db` は user repo の git ignore 推奨 (sample `.gitignore` 追加)
  - 5 doc cross-refs (R7 厳守、各 +3 行以内): SECURITY.md / sage/governance.md §9.1 / AGENTS.md / CLAUDE.md / docs/codex-security.md

### 非機能要件

- **[NFR-01] パフォーマンス**: 1000 RUN log の full index < 5s (Python stdlib sqlite3、in-memory transaction)
- **[NFR-02] graceful degradation**: SQLite 不在 / Python 不在で index/search が gracefully skip
- **[NFR-03] portability**: macOS / Linux 両対応 (Python stdlib `sqlite3` は標準同梱)
- **[NFR-04] auditability**: search query を `.sage/audit/runlog-search-YYYYMMDD.log` に記録 (誰が何を検索したかの監査)
- **[NFR-05] backward compat**: `.sage/runs.db` 不在で既存 validator / doctor は影響なし
- **[NFR-06] test scenario coverage**: 12 シナリオ (index 4: full / incremental / parse error / empty + search 6: 各 filter + FTS + JSON output + doctor 2: missing / stale)

### セキュリティ要件

- **[SEC-01] redaction 維持**: indexer は元 RUN log / audit log を変更しない (SPEC-0012 redaction を inherit)
- **[SEC-02] DB に secret を新規導入しない**: source file の content をそのまま store (新規 token 抽出禁止)
- **[SEC-03] search query log redaction**: `.sage/audit/runlog-search-*.log` の query 文字列にも secret pattern を redact (SPEC-0012 と同 pattern)
- **[SEC-04] DB file permission**: index script は `.sage/runs.db` を chmod 600 で保護 (other-readable 禁止)

### 運用要件

- **[OPS-01] index frequency**: SessionStart hook で `--incremental` 自動実行 (毎回 1-2 RUN log のみ追加)
- **[OPS-02] rotation**: DB size > 100 MB で WARN、user 判断で rebuild (`--full`)
- **[OPS-03] gitignore**: `.sage/runs.db` を default で gitignore (DB は local cache、共有不要)
- **[OPS-04] 段階採用昇格条件**:

  | 昇格 | 条件 | 検証コマンド |
  |---|---|---|
  | none → indexer 導入 | doctor 0 FAIL 維持、`bash scripts/sage-runlog-index.sh` で `.sage/runs.db` 生成成功 | `test -f .sage/runs.db && bash scripts/sage-doctor.sh` |
  | manual index → SessionStart auto | 7 日 manual 運用 + index 失敗 0 件 | `awk '/index_error/' .sage/audit/runlog-index-*.log \| wc -l` で 0 |
  | search optional → core workflow | 14 日 SessionStart auto + DB size < 50MB | `du -sh .sage/runs.db` で許容範囲 |

## 受け入れ条件 (AC)

- [ ] AC-01: `.sage/runs.db` schema (runs / audit_events / runs_fts / audit_fts 4 table) 定義
- [ ] AC-02: `scripts/sage-runlog-index.sh` 存在、`--incremental` / `--full` flag 動作
- [ ] AC-03: `scripts/sage-runlog-search.sh` 存在、`--task-id` / `--agent-id` / `--status` / `--drift-type` / `--fts` filter 動作
- [ ] AC-04: `templates/hooks/tests/test-runlog-search.sh` 12 シナリオ全 PASS
- [ ] AC-05: `scripts/sage-doctor.sh` `[5/6]` step 追加、`.sage/runs.db` 健全性 check
- [ ] AC-06: 5 doc files に cross-ref 追加 (各 +3 行以内、R7 厳守)
- [ ] AC-07: `bash scripts/sage-validate.sh` PASS
- [ ] AC-08: `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] AC-09: `bash scripts/sage-doc-drift.sh` PASS
- [ ] AC-10: `bash templates/hooks/tests/run-tests.sh` 全 PASS (既存 145 + 新規 12 = 157+)
- [ ] AC-11: 1000 RUN log full index `time bash scripts/sage-runlog-index.sh --full` < 5s (NFR-01)
- [ ] AC-12: `.sage/runs.db` permission が 600 (NFR-04 / SEC-04)

### Quality Gate との対応

| AC | 検証 Gate | 検証コマンド (CI) |
|---|---|---|
| AC-01, AC-02, AC-03 | Gate 1 (Structural: shellcheck + schema validity) | `shellcheck scripts/sage-runlog-index.sh scripts/sage-runlog-search.sh && bash scripts/sage-runlog-index.sh --full && sqlite3 .sage/runs.db ".schema"` |
| AC-04, AC-10, AC-11 | Gate 2 (Functional: tests + perf) | `bash templates/hooks/tests/run-tests.sh && time bash scripts/sage-runlog-index.sh --full` |
| SEC-01..SEC-04 | Gate 3 (Security: redaction維持 / no secret / search log redact / file permission) | `stat -f %Op .sage/runs.db | tail -c 4` で 600、`grep -rE "sk-[A-Za-z0-9]{32,}" .sage/runs.db` で 0 件 |
| AC-05, AC-07, AC-08, AC-09, AC-12 | Gate 4 (Architecture: traceability + doctor + doc-drift) | `bash scripts/sage-validate.sh && bash scripts/sage-doctor.sh && bash scripts/sage-doc-drift.sh` |
| AC-06 | Gate 4 (Architecture: doctrine alignment、R7 厳守) | `wc -l SECURITY.md sage/governance.md AGENTS.md CLAUDE.md docs/codex-security.md` で各 +3 行以内 |

Gate 5 (Release) は本 SPEC 単独では発火しない。

## エラーケース

- **EC-01** (YAML parse error in RUN log): warn + skip 該当 file、他は continue
- **EC-02** (JSON parse error in audit log): 同上
- **EC-03** (SQLite DB lock 競合): retry 3 回 + warn (SessionStart の auto index と manual 衝突)
- **EC-04** (DB schema mismatch on indexer run): doctor で FAIL、user に `--full` re-index 案内
- **EC-05** (Python sqlite3 / yaml 不在): index/search が graceful skip + warn

## 依存関係 / リスク

### 依存
- 既存 RUN log validator (Phase 2A TASK-0074、SPEC-0008)
- SPEC-0012 security-filter (redaction logic)
- SPEC-0015 audit log JSON schema (drift_type enum)
- SPEC-0017 agent inventory inventory schema
- Python 3 stdlib (`sqlite3` + `yaml` + `json`、PyYAML)

### リスク

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | DB size 圧迫 (1000+ RUN log で数十 MB) | OPS-02 rotation + doctor WARN @ 100MB | `du -sh .sage/runs.db` 週次 |
| 2 | indexer の concurrent run で DB lock | EC-03 retry + atomic transaction | `lsof .sage/runs.db` で複数 PID 検出時 alert |
| 3 | redaction 抜けによる secret 二次保管 | SEC-01 で元 file content そのまま、indexer は redact しない | `grep -rE "sk-[A-Za-z0-9]{32,}" .sage/runs.db` で 0 件 |
| 4 | FTS5 query syntax の user 学習コスト | search CLI に `--simple` mode (substring match) 提供 + 公式 SQLite docs link | docs/codex-security.md のような simple example 提供 |
| 5 | Python sqlite3 module 不在 (rare) | NFR-02 graceful skip + warn | install.sh で python3 version check 強化 |
| 6 | search log の secret 漏洩 | SEC-03 で SPEC-0012 redact pattern 適用 | `grep -E "sk-\|ghp_" .sage/audit/runlog-search-*.log` で 0 件 |

## 失敗時の知識蓄積

本 SPEC は indexer + searcher のため、index error / search query 失敗が知識蓄積対象。

### 知識蓄積フロー (3 ステップ)

```
Step 1 [検出]
  indexer / searcher が error を `.sage/audit/runlog-{index,search}-YYYYMMDD.log` に記録
  ↓
Step 2 [記録]
  同 root cause で 2 回以上発生 → `sage/failures.md` に FAIL-RUNDB-XXXX として追記
  ↓
Step 3 [昇格]
  同 root cause で 3 回以上発生 → `sage/anti-patterns.md` に追記、indexer logic 見直し検討
```

### sage/failures.md 連携

- **誰が**: indexer error を運用上問題と判断した repo owner
- **いつ**: 同 root cause (例: yaml schema mismatch / sqlite lock 衝突) で 2 回以上発生時
- **どの手順で**: error log entry を抽出 → `sage/failures.md` に FAIL-RUNDB-XXXX として 6 elements で追記

### sage/anti-patterns.md への昇格

3 回以上発生で `sage/anti-patterns.md` に「RUNDB-XXXX」追記、indexer/searcher の logic 見直しを Phase 6 で SPEC 起票。

### Error Resolution 手順

| EC | エラー時メッセージ例 | Resolution |
|---|---|---|
| EC-01/02 (parse error) | `WARN: skip RUN-9999.yaml; YAML parse error at line N` | 該当 file 修正 → re-index |
| EC-03 (DB lock) | `WARN: SQLite DB locked; retrying (attempt 1/3)` | concurrent indexer 停止 |
| EC-04 (schema mismatch) | `FAIL: DB schema vN != current vM; run --full to rebuild` | `bash scripts/sage-runlog-index.sh --full` |
| EC-05 (Python module 不在) | `WARN: python3 sqlite3/yaml unavailable; skip indexing` | `pip install pyyaml` 案内 |

## ロールバック手順

本 SPEC の indexer + searcher は **opt-in / 別 file** なので、ロールバックは段階的:

| レベル | 手順 | 影響範囲 |
|---|---|---|
| 1. indexer 一時 disable | SessionStart hook から auto-index 行を削除 | manual index のみ動作、search 既存 DB で継続 |
| 2. DB 削除 + 再構築 | `rm .sage/runs.db && bash scripts/sage-runlog-index.sh --full` | 一時的に search 不可、再 index 完了で復旧 |
| 3. validator 拡張 revert | doctor [5/6] step を `if false; then ... fi` で stub | doctor で DB 関連 check skip |
| 4. 完全 revert | 本 SPEC 導入 PR を `git revert` | indexer / searcher / DB schema 全て元に戻る |

各ロールバック後の検証:
- `bash scripts/sage-doctor.sh` 0 FAIL
- `bash templates/hooks/tests/run-tests.sh` 145/145 (Phase 5+ base line) PASS
- 既存 .sage/runs/RUN-*.yaml で `bash scripts/sage-runlog-validate.sh` PASS

## 関連 Doctrine

- **R5 (RUN log redaction)**: SPEC-0012 redaction を維持、indexer は元 file content をそのまま store
- **R7 (CLAUDE/AGENTS 肥大化禁止)**: 5 doc each +3 行以内
- **R8 (hook tests)**: 12 scenario test 必須
- **R10 (一次ソース)**: SQLite FTS5 公式 docs (https://sqlite.org/fts5.html) を一次ソースとして引用

## Phase 5+ 全体の position

| SPEC | スコープ | 状態 |
|---|---|---|
| SPEC-0014 | install.sh 分割 (264KB → modules) | 予約 |
| SPEC-0015 | MCP allowlist audit | merged (PR #21) |
| SPEC-0016 | **RUN log SQLite-FTS** ← 本 SPEC | Draft |
| SPEC-0017 | Agent identity inventory | merged (PR #23) |
