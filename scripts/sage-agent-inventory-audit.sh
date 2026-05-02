#!/usr/bin/env bash
# =============================================================================
# TASK-0129: sage-agent-inventory-audit.sh (SPEC-0017)
# Purpose:  CLI wrapper for agent inventory drift summary (used by sage-doctor.sh).
# Input:    none — reads .sage/agent-inventory.yaml + .sage/runs/RUN-*.yaml
# Output:   TSV lines: <level>\t<check>\t<message>
# Exit:     0 always
# =============================================================================
set -uo pipefail

INVENTORY_PATH=".sage/agent-inventory.yaml"
RUNS_DIR=".sage/runs"
RECENT_N="${SAGE_INVENTORY_RECENT_N:-10}"

if ! command -v python3 &>/dev/null; then
  echo "WARN	agent_inventory_python	python3 not in PATH"
  exit 0
fi

if [ ! -f "$INVENTORY_PATH" ]; then
  echo "WARN	agent_inventory_present	$INVENTORY_PATH not found (SPEC-0017 inventory recommended)"
  exit 0
fi

if [ ! -d "$RUNS_DIR" ]; then
  echo "OK	agent_inventory_runs	No RUN logs to audit"
  exit 0
fi

python3 - "$INVENTORY_PATH" "$RUNS_DIR" "$RECENT_N" <<'PYEOF'
import os
import sys
import glob

try:
    import yaml
except ImportError:
    print("WARN\tagent_inventory_python_yaml\tpython yaml module unavailable")
    sys.exit(0)

inventory_path, runs_dir, recent_n = sys.argv[1], sys.argv[2], int(sys.argv[3])

try:
    with open(inventory_path) as f:
        inv_data = yaml.safe_load(f)
except (yaml.YAMLError, OSError) as e:
    print(f"FAIL\tagent_inventory_validity\t{e}")
    sys.exit(0)

if not isinstance(inv_data, dict) or "agents" not in inv_data:
    print("FAIL\tagent_inventory_validity\tinvalid schema")
    sys.exit(0)

inv = {a["agent_id"]: a for a in inv_data["agents"] if isinstance(a, dict) and "agent_id" in a}

# Collect recent N RUN logs
files = sorted(glob.glob(f"{runs_dir}/RUN-*.yaml"))[-recent_n:]
if not files:
    print("OK\tagent_inventory_runs\tNo RUN logs in directory")
    sys.exit(0)

def coerce(v):
    if isinstance(v, bool):
        return {True: "on", False: "off"}[v]
    return v

missing_runtime = 0
mismatch_count = 0
total = 0
for f in files:
    try:
        with open(f) as fh:
            doc = yaml.safe_load(fh)
    except (yaml.YAMLError, OSError):
        continue
    if not isinstance(doc, dict):
        continue
    agent_id = doc.get("agent_id")
    if agent_id not in inv:
        continue
    total += 1
    runtime = coerce(doc.get("runtime"))
    if runtime is None:
        missing_runtime += 1
        continue
    expected = inv[agent_id].get("expected_runtime", [])
    if runtime != "unknown" and expected and runtime not in expected:
        mismatch_count += 1

if total == 0:
    print("OK\tagent_inventory_runs\tNo declared agent_id RUN logs in window")
else:
    if missing_runtime > 0:
        print(f"OK\tagent_inventory_missing_runtime\t{missing_runtime}/{total} RUN log(s) lack runtime field (SPEC-0017 optional, INFO)")
    else:
        print(f"OK\tagent_inventory_runtime_field\tAll {total} declared RUN log(s) have runtime field")
    if mismatch_count > 0:
        print(f"WARN\tagent_inventory_drift\t{mismatch_count}/{total} RUN log(s) have runtime not in expected list")
    else:
        print(f"OK\tagent_inventory_drift\t0 declared-vs-observed mismatches in last {recent_n} runs")

print(f"OK\tagent_inventory_summary\tinventory contains {len(inv)} declared agent_id(s)")
PYEOF
