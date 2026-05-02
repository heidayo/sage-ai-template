# TASK-0132: search CLI + 6 シナリオ test

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0132 |
| SPEC-ID   | SPEC-0016 |
| PLAN-ID   | PLAN-0016 |
| ステータス | Pending |
| 並列可否  | No |
| 依存TASK  | TASK-0131 |
| 見積     | 60m |

## 責務

`scripts/sage-runlog-search.sh` CLI 検索 + 6 シナリオ test。

## 出力

1. `scripts/sage-runlog-search.sh`:
   - filter: `--task-id` / `--agent-id` / `--status` / `--drift-type` / `--since` / `--until`
   - FTS: `--fts QUERY` (SQLite FTS5 syntax)
   - output: TSV (default) または `--json`
   - search query を `.sage/audit/runlog-search-YYYYMMDD.log` に記録 (NFR-04、SEC-03 で redact)

2. `templates/hooks/tests/test-runlog-search.sh` (6 シナリオ):
   - `--task-id TASK-0001` で 1 件抽出
   - `--agent-id implementation` で複数件
   - `--status fail` で error_log 含む RUN log 抽出
   - `--drift-type drift1_stdio_unknown_server` で audit event 抽出
   - `--fts "redact"` で error_log 全文検索
   - `--json` 形式 output が valid JSON

## File Scope

- 作成: `scripts/sage-runlog-search.sh`
- 作成: `templates/hooks/tests/test-runlog-search.sh`

## 禁止事項

- DB を search で **書き込み変更しない** (read-only)
- search query log に raw secret を書かない (SEC-03 で SPEC-0012 redact pattern 適用)
- FTS5 の `MATCH` operator 以外の dynamic SQL を組まない (SQL injection 防止)
- `--task-id` / `--agent-id` 等 user input を SQL に直挿ししない (parameterized query 必須)
- 実行中に `kill / pkill` 呼ばない
- search で 1 万件以上の結果を返したら自動 truncate + warn (誤操作防止)

## 完了条件

- [ ] 6 シナリオ全 PASS
- [ ] `--json` output が valid JSON (Python `json.loads` で parse 成功)
- [ ] search query log に redact pattern 適用 (SEC-03)
- [ ] shellcheck error 0 件
- [ ] commit message に `TASK-0132:` 含む
