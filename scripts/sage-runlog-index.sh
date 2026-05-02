#!/usr/bin/env bash
# =============================================================================
# TASK-0131: sage-runlog-index.sh (SPEC-0016)
# Purpose:  Index .sage/runs/RUN-*.yaml + .sage/audit/*.log into
#           .sage/runs.db (SQLite FTS5).
# Usage:    bash scripts/sage-runlog-index.sh [--full|--incremental]
# Default:  --incremental (mtime > last_index_at)
# Exit:     0 always (parse errors are warned + skipped)
# =============================================================================
set -uo pipefail

MODE="${1:-}"
case "$MODE" in
  --full|--incremental|"") ;;
  *) echo "ERROR: unknown mode: $MODE (use --full or --incremental)" >&2; exit 1 ;;
esac
[ -z "$MODE" ] && MODE="--incremental"

DB_PATH=".sage/runs.db"
RUNS_DIR=".sage/runs"
AUDIT_DIR=".sage/audit"

if ! command -v python3 &>/dev/null; then
  echo "WARN: python3 not available; skipping RUN log indexing." >&2
  exit 0
fi

mkdir -p .sage

python3 - "$DB_PATH" "$RUNS_DIR" "$AUDIT_DIR" "$MODE" <<'PYEOF'
import os
import sys
import sqlite3
import json
import glob
import re

try:
    import yaml
except ImportError:
    print("WARN: python yaml module unavailable; skipping indexing.", file=sys.stderr)
    sys.exit(0)

db_path, runs_dir, audit_dir, mode = sys.argv[1:5]

SCHEMA = """
CREATE TABLE IF NOT EXISTS runs (
    run_id TEXT PRIMARY KEY,
    task_id TEXT,
    agent_id TEXT,
    runtime TEXT,
    status TEXT,
    started_at TEXT,
    completed_at TEXT,
    files_changed TEXT,
    error_log TEXT,
    indexed_at TEXT,
    source_mtime REAL
);
CREATE INDEX IF NOT EXISTS idx_runs_task_id ON runs(task_id);
CREATE INDEX IF NOT EXISTS idx_runs_agent_id ON runs(agent_id);
CREATE INDEX IF NOT EXISTS idx_runs_status ON runs(status);
CREATE INDEX IF NOT EXISTS idx_runs_started_at ON runs(started_at);

CREATE TABLE IF NOT EXISTS audit_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source TEXT,
    drift_type TEXT,
    severity TEXT,
    runtime TEXT,
    server_name TEXT,
    timestamp TEXT,
    details TEXT,
    source_file TEXT,
    indexed_at TEXT,
    UNIQUE(source_file, timestamp, drift_type, server_name)
);
CREATE INDEX IF NOT EXISTS idx_audit_drift_type ON audit_events(drift_type);
CREATE INDEX IF NOT EXISTS idx_audit_severity ON audit_events(severity);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_events(timestamp);

CREATE VIRTUAL TABLE IF NOT EXISTS runs_fts USING fts5(
    run_id, task_id, agent_id, status, error_log,
    content='runs', content_rowid='rowid'
);

CREATE VIRTUAL TABLE IF NOT EXISTS audit_fts USING fts5(
    drift_type, severity, details,
    content='audit_events', content_rowid='id'
);

CREATE TABLE IF NOT EXISTS index_meta (
    key TEXT PRIMARY KEY,
    value TEXT
);
"""

def coerce_yaml_str(v):
    if isinstance(v, bool):
        return {True: "on", False: "off"}[v]
    return v

def get_last_index_at(conn):
    cur = conn.execute("SELECT value FROM index_meta WHERE key = 'last_index_at'")
    row = cur.fetchone()
    return float(row[0]) if row else 0.0

def set_last_index_at(conn, ts):
    conn.execute("INSERT OR REPLACE INTO index_meta (key, value) VALUES ('last_index_at', ?)", (str(ts),))

def index_run_log(conn, path, indexed_at):
    try:
        with open(path, "r", encoding="utf-8") as f:
            doc = yaml.safe_load(f)
    except (yaml.YAMLError, OSError) as e:
        print(f"WARN: skip {path}: {e}", file=sys.stderr)
        return False
    if not isinstance(doc, dict):
        print(f"WARN: skip {path}: not a mapping", file=sys.stderr)
        return False
    mtime = os.path.getmtime(path)
    files_changed = doc.get("files_changed", [])
    if not isinstance(files_changed, list):
        files_changed = []
    conn.execute(
        "INSERT OR REPLACE INTO runs "
        "(run_id, task_id, agent_id, runtime, status, started_at, completed_at, "
        " files_changed, error_log, indexed_at, source_mtime) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (
            doc.get("run_id"),
            doc.get("task_id"),
            doc.get("agent_id"),
            coerce_yaml_str(doc.get("runtime")),
            doc.get("status"),
            doc.get("started_at"),
            doc.get("completed_at"),
            json.dumps(files_changed),
            doc.get("error_log", ""),
            indexed_at,
            mtime,
        ),
    )
    return True

def index_audit_log(conn, path, indexed_at, source):
    """Index a JSON-lines audit log file."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except OSError as e:
        print(f"WARN: skip {path}: {e}", file=sys.stderr)
        return 0
    n = 0
    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        details = rec.get("details", {}) if isinstance(rec.get("details"), dict) else {}
        try:
            conn.execute(
                "INSERT OR IGNORE INTO audit_events "
                "(source, drift_type, severity, runtime, server_name, timestamp, "
                " details, source_file, indexed_at) "
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    source,
                    rec.get("drift_type"),
                    rec.get("severity"),
                    rec.get("runtime"),
                    details.get("server_name"),
                    rec.get("timestamp"),
                    json.dumps(details),
                    path,
                    indexed_at,
                ),
            )
            n += 1
        except sqlite3.IntegrityError:
            pass  # duplicate per UNIQUE constraint
    return n

def main():
    full = (mode == "--full")

    # Open DB
    conn = sqlite3.connect(db_path, timeout=30.0)
    try:
        if full and os.path.exists(db_path):
            conn.executescript("DROP TABLE IF EXISTS runs; DROP TABLE IF EXISTS audit_events; "
                               "DROP TABLE IF EXISTS runs_fts; DROP TABLE IF EXISTS audit_fts; "
                               "DROP TABLE IF EXISTS index_meta;")

        conn.executescript(SCHEMA)
        last_index_at = 0.0 if full else get_last_index_at(conn)
        import time
        now = time.time()
        indexed_at_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now))

        run_count = 0
        run_skip = 0
        if os.path.isdir(runs_dir):
            for path in sorted(glob.glob(f"{runs_dir}/RUN-*.yaml")):
                if not full and os.path.getmtime(path) <= last_index_at:
                    continue
                if index_run_log(conn, path, indexed_at_iso):
                    run_count += 1
                else:
                    run_skip += 1

        audit_count = 0
        if os.path.isdir(audit_dir):
            for source_glob, source_label in (
                (f"{audit_dir}/mcp-allowlist-2*.log", "mcp-allowlist"),
                (f"{audit_dir}/agent-inventory-2*.log", "agent-inventory"),
            ):
                for path in sorted(glob.glob(source_glob)):
                    if not full and os.path.getmtime(path) <= last_index_at:
                        continue
                    audit_count += index_audit_log(conn, path, indexed_at_iso, source_label)

        # Rebuild FTS to keep in sync (FTS5 external content table requires manual sync)
        conn.executescript(
            "INSERT INTO runs_fts(runs_fts) VALUES('rebuild'); "
            "INSERT INTO audit_fts(audit_fts) VALUES('rebuild');"
        )

        set_last_index_at(conn, now)
        conn.commit()
        print(f"OK: indexed {run_count} RUN log(s), {audit_count} audit event(s) "
              f"({run_skip} skipped, mode={mode})")
    finally:
        conn.close()

    # SEC-04: chmod 600
    try:
        os.chmod(db_path, 0o600)
    except OSError as e:
        print(f"WARN: chmod 600 on {db_path} failed: {e}", file=sys.stderr)

main()
PYEOF
