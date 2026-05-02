# TASK-0131: SQLite-FTS schema + indexer + 4 シナリオ test

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0131 |
| SPEC-ID   | SPEC-0016 |
| PLAN-ID   | PLAN-0016 |
| ステータス | Pending |
| 並列可否  | No (foundation) |
| 依存TASK  | none |
| 見積     | 75m |

## 責務

`.sage/runs.db` SQLite FTS5 schema 定義 + `scripts/sage-runlog-index.sh` indexer (incremental + full mode) + 4 シナリオ test。

## 出力

1. `scripts/sage-runlog-index.sh` (Python-delegated):
   - 引数なし: 全 file index
   - `--incremental`: mtime > last_index_at の file のみ
   - `--full`: DB drop + 全 re-index
   - schema 4 table (runs / audit_events / runs_fts / audit_fts)
   - `.sage/runs.db` chmod 600

2. `templates/hooks/tests/test-runlog-index.sh` (4 シナリオ):
   - full index で 4 RUN log + audit log を入れる
   - incremental で 1 RUN log 追加 → 5 件に
   - parse error file は warn + skip
   - empty `.sage/runs/` で graceful exit 0

## File Scope

- 作成: `scripts/sage-runlog-index.sh`
- 作成: `templates/hooks/tests/test-runlog-index.sh`

## 禁止事項

- 既存 RUN log / audit log の **元 file を変更しない** (read-only、SEC-01)
- redaction logic を indexer で再実装しない (SPEC-0012 を inherit)
- DB に元 file にない field を新規追加しない (透明性、SEC-02)
- `.sage/runs.db` を group/other readable にしない (chmod 600 強制、SEC-04)
- yq / jq 等の外部依存を必須化しない (Python stdlib のみ)
- 実行中に `kill / pkill` を呼ばない (governance §9.2)
- index error で indexer を crash させない (graceful warn + skip)

## 完了条件

- [ ] schema 4 table 定義済 (sqlite3 ".schema" で確認)
- [ ] full / incremental / parse error / empty の 4 シナリオ全 PASS
- [ ] DB permission 600
- [ ] shellcheck error 0 件
- [ ] `bash scripts/sage-runlog-index.sh --full && time ...` で 1000 RUN log < 5s 想定
- [ ] commit message に `TASK-0131:` 含む
