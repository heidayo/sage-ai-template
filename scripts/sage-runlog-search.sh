#!/usr/bin/env bash
# =============================================================================
# TASK-0132: sage-runlog-search.sh (SPEC-0016)
# Purpose:  Search .sage/runs.db (SQLite FTS5) by filter / FTS query.
# Usage:    bash scripts/sage-runlog-search.sh [OPTIONS]
# Filters:  --task-id ID / --agent-id NAME / --status STATUS /
#           --drift-type ENUM / --since DATE / --until DATE / --fts QUERY
# Output:   TSV (default) or --json
# Exit:     0 on success, 1 on DB missing / SQL error
# =============================================================================
set -uo pipefail

DB_PATH=".sage/runs.db"
AUDIT_DIR=".sage/audit"

TASK_ID=""
AGENT_ID=""
STATUS=""
DRIFT_TYPE=""
SINCE=""
UNTIL=""
FTS=""
JSON_OUT=false
LIMIT="${SAGE_SEARCH_LIMIT:-1000}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id) TASK_ID="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --drift-type) DRIFT_TYPE="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --until) UNTIL="$2"; shift 2 ;;
    --fts) FTS="$2"; shift 2 ;;
    --json) JSON_OUT=true; shift ;;
    --help|-h)
      cat <<'EOF'
Usage: sage-runlog-search.sh [OPTIONS]
  --task-id ID         filter by TASK-ID (e.g. TASK-0001)
  --agent-id NAME      filter by agent_id (e.g. implementation)
  --status STATUS      pass | fail | skipped
  --drift-type ENUM    filter audit events (e.g. drift1_stdio_unknown_server)
  --since YYYY-MM-DD   started_at >= date
  --until YYYY-MM-DD   started_at <= date
  --fts QUERY          SQLite FTS5 MATCH query (runs_fts)
  --json               output as JSON instead of TSV
EOF
      exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ ! -f "$DB_PATH" ]; then
  echo "ERROR: $DB_PATH not found. Run 'bash scripts/sage-runlog-index.sh --full' first." >&2
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 not available." >&2
  exit 1
fi

mkdir -p "$AUDIT_DIR"
SEARCH_LOG="${AUDIT_DIR}/runlog-search-$(date -u +%Y%m%d).log"

# SEC-03: redact secret patterns from search query before logging
redact_query() {
  echo "$1" | python3 -c "
import sys, re
q = sys.stdin.read()
patterns = [
    r'sk-[A-Za-z0-9_-]{20,}',
    r'ghp_[A-Za-z0-9]{20,}',
    r'AKIA[0-9A-Z]{16}',
    r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',
]
for p in patterns:
    q = re.sub(p, '***REDACTED***', q)
print(q.rstrip(), end='')
"
}

REDACTED_QUERY=$(redact_query "task_id=${TASK_ID} agent_id=${AGENT_ID} status=${STATUS} drift_type=${DRIFT_TYPE} since=${SINCE} until=${UNTIL} fts=${FTS}")
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)	${REDACTED_QUERY}" >> "$SEARCH_LOG"

python3 - "$DB_PATH" "$TASK_ID" "$AGENT_ID" "$STATUS" "$DRIFT_TYPE" "$SINCE" "$UNTIL" "$FTS" "$JSON_OUT" "$LIMIT" <<'PYEOF'
import sys, sqlite3, json

db, task_id, agent_id, status, drift_type, since, until, fts, json_out, limit = sys.argv[1:11]
json_out = (json_out == "true")
limit = int(limit)

conn = sqlite3.connect(db, timeout=30.0)
conn.row_factory = sqlite3.Row

rows = []

# audit events search (drift_type filter routes here)
if drift_type:
    q = "SELECT 'audit' AS table_name, source, drift_type, severity, runtime, server_name, timestamp, details FROM audit_events WHERE drift_type = ?"
    params = [drift_type]
    if since:
        q += " AND timestamp >= ?"; params.append(since)
    if until:
        q += " AND timestamp <= ?"; params.append(until)
    q += f" ORDER BY timestamp DESC LIMIT {limit + 1}"
    for row in conn.execute(q, params):
        rows.append(dict(row))
else:
    # runs search
    q = "SELECT 'run' AS table_name, run_id, task_id, agent_id, runtime, status, started_at, completed_at, error_log FROM runs WHERE 1=1"
    params = []
    if task_id:
        q += " AND task_id = ?"; params.append(task_id)
    if agent_id:
        q += " AND agent_id = ?"; params.append(agent_id)
    if status:
        q += " AND status = ?"; params.append(status)
    if since:
        q += " AND started_at >= ?"; params.append(since)
    if until:
        q += " AND started_at <= ?"; params.append(until)
    if fts:
        # Restrict by FTS match (run_id from runs_fts)
        q += " AND rowid IN (SELECT rowid FROM runs_fts WHERE runs_fts MATCH ?)"
        params.append(fts)
    q += f" ORDER BY started_at DESC LIMIT {limit + 1}"
    try:
        for row in conn.execute(q, params):
            rows.append(dict(row))
    except sqlite3.OperationalError as e:
        print(f"ERROR: SQL: {e}", file=sys.stderr)
        sys.exit(1)

truncated = len(rows) > limit
if truncated:
    rows = rows[:limit]

if json_out:
    print(json.dumps({"rows": rows, "count": len(rows), "truncated": truncated}))
else:
    if not rows:
        print("(no results)")
    else:
        # TSV header from first row keys
        cols = list(rows[0].keys())
        print("\t".join(cols))
        for r in rows:
            print("\t".join(str(r.get(c, "")) for c in cols))
        if truncated:
            print(f"# WARN: truncated to first {limit} results", file=sys.stderr)

conn.close()
PYEOF
