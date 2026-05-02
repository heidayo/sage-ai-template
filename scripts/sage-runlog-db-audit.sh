#!/usr/bin/env bash
# =============================================================================
# TASK-0133: sage-runlog-db-audit.sh (SPEC-0016)
# Purpose:  CLI wrapper for .sage/runs.db health check (used by sage-doctor.sh).
# Output:   TSV: <level>\t<check>\t<message>
# Exit:     0 always
# =============================================================================
set -uo pipefail

DB_PATH=".sage/runs.db"
STALE_DAYS="${SAGE_DB_STALE_DAYS:-7}"
SIZE_WARN_MB="${SAGE_DB_SIZE_WARN_MB:-100}"

if ! command -v python3 &>/dev/null; then
  echo "WARN	runlog_db_python	python3 not in PATH"
  exit 0
fi

if [ ! -f "$DB_PATH" ]; then
  echo "WARN	runlog_db_present	$DB_PATH not found (SPEC-0016: run 'bash scripts/sage-runlog-index.sh --full' to initialize)"
  exit 0
fi

python3 - "$DB_PATH" "$STALE_DAYS" "$SIZE_WARN_MB" <<'PYEOF'
import sys, sqlite3, os, time

db_path, stale_days, size_warn_mb = sys.argv[1:4]
stale_days = int(stale_days)
size_warn_mb = int(size_warn_mb)

# (b) schema validity
expected_tables = {"runs", "audit_events", "runs_fts", "audit_fts", "index_meta"}
try:
    conn = sqlite3.connect(db_path, timeout=5.0)
    cur = conn.execute("SELECT name FROM sqlite_master WHERE type IN ('table')")
    actual = {row[0] for row in cur.fetchall()}
    missing = expected_tables - actual
    if missing:
        print(f"FAIL\trunlog_db_schema\tDB schema missing tables: {sorted(missing)} (run --full to rebuild)")
        sys.exit(0)
    else:
        print("OK\trunlog_db_schema\tDB schema valid (5 expected tables present)")
except sqlite3.Error as e:
    print(f"FAIL\trunlog_db_schema\tDB error: {e}")
    sys.exit(0)

# (c) last index time
try:
    cur = conn.execute("SELECT value FROM index_meta WHERE key = 'last_index_at'")
    row = cur.fetchone()
    if row:
        last_index_at = float(row[0])
        age_days = (time.time() - last_index_at) / 86400
        if age_days > stale_days:
            print(f"WARN\trunlog_db_freshness\tLast index {age_days:.1f} days ago (> {stale_days} days threshold)")
        else:
            print(f"OK\trunlog_db_freshness\tLast index {age_days:.1f} days ago")
    else:
        print("WARN\trunlog_db_freshness\tlast_index_at meta missing")
except sqlite3.Error as e:
    print(f"WARN\trunlog_db_freshness\t{e}")

# (d) DB size
size_bytes = os.path.getsize(db_path)
size_mb = size_bytes / (1024 * 1024)
if size_mb > size_warn_mb:
    print(f"WARN\trunlog_db_size\tDB size {size_mb:.1f} MB (> {size_warn_mb} MB threshold; rotation recommended)")
else:
    print(f"OK\trunlog_db_size\tDB size {size_mb:.1f} MB")

# (e) row counts (informational)
try:
    runs_n = conn.execute("SELECT COUNT(*) FROM runs").fetchone()[0]
    audit_n = conn.execute("SELECT COUNT(*) FROM audit_events").fetchone()[0]
    print(f"OK\trunlog_db_rows\t{runs_n} RUN log(s), {audit_n} audit event(s) indexed")
except sqlite3.Error:
    pass

conn.close()
PYEOF
