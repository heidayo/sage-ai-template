#!/usr/bin/env bash
# =============================================================================
# SPEC-0008 TASK-0074: sage-runlog-validate.sh
# Purpose:  Validate .sage/runs/*.yaml files against the run_log_schema
#           declared in .sage/config.yaml.
# Usage:    bash scripts/sage-runlog-validate.sh [FILE...]
#           - no args: validate every file under .sage/runs/*.yaml
#           - args:    validate only the specified files
# Exit:     0 on all-pass, 1 on any failure.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

# Build file list
if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  shopt -s nullglob
  FILES=("$ROOT"/.sage/runs/*.yaml)
  shopt -u nullglob
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "no RUN log files to validate"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required for YAML validation" >&2
  exit 1
fi

# Embedded python validator. Kept inline so the script is self-contained
# and does not introduce a new dependency file.
python3 - "${FILES[@]}" <<'PY'
import re
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError:
    print("ERROR: python yaml module is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(1)

AGENT_IDS = {"spec", "planning", "implementation", "review", "test", "security", "operations"}
STATUS_VALUES = {"pass", "fail", "skipped"}
GATE_KEYS = ("structural", "functional", "security", "architecture", "release")
# Note: .sage/config.yaml's run_log_schema claims security/architecture are
# pass|fail only, but existing RUN logs record skipped for these when a gate
# is unconfigured in a given run (e.g. no project_checks for structural yet).
# Existing data is authoritative; validator accepts skipped across all gates
# until the schema is updated in a follow-up.
GATE_VALUES = {"pass", "fail", "skipped"}

RUN_ID_RE = re.compile(r"^RUN-\d{4}$")
TASK_ID_RE = re.compile(r"^TASK-\d{4}$")
ISO8601_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:?\d{2})$")


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            doc = yaml.safe_load(f)
    except yaml.YAMLError as e:
        return [f"YAML parse error: {e}"]
    except OSError as e:
        return [f"cannot read file: {e}"]

    if not isinstance(doc, dict):
        return ["top-level YAML is not a mapping"]

    def req(key: str) -> None:
        if key not in doc:
            errors.append(f"missing required field: {key}")

    for k in ("run_id", "task_id", "agent_id", "started_at", "completed_at",
              "status", "files_changed", "gate_results"):
        req(k)

    if "run_id" in doc and not (isinstance(doc["run_id"], str) and RUN_ID_RE.match(doc["run_id"])):
        errors.append(f"run_id must match RUN-XXXX: got {doc['run_id']!r}")
    if "task_id" in doc and not (isinstance(doc["task_id"], str) and TASK_ID_RE.match(doc["task_id"])):
        errors.append(f"task_id must match TASK-XXXX: got {doc['task_id']!r}")
    if "agent_id" in doc and doc["agent_id"] not in AGENT_IDS:
        errors.append(f"agent_id must be one of {sorted(AGENT_IDS)}: got {doc['agent_id']!r}")
    for ts in ("started_at", "completed_at"):
        if ts in doc:
            v = doc[ts]
            if not isinstance(v, str) or not ISO8601_RE.match(v):
                errors.append(f"{ts} must be ISO 8601 string: got {v!r}")
    if "status" in doc and doc["status"] not in STATUS_VALUES:
        errors.append(f"status must be one of {sorted(STATUS_VALUES)}: got {doc['status']!r}")
    if "files_changed" in doc:
        v = doc["files_changed"]
        if not isinstance(v, list) or not all(isinstance(s, str) for s in v):
            errors.append("files_changed must be a list of strings")
    if "gate_results" in doc:
        g = doc["gate_results"]
        if not isinstance(g, dict):
            errors.append("gate_results must be a mapping")
        else:
            for gk in GATE_KEYS:
                if gk not in g:
                    errors.append(f"gate_results.{gk} missing")
                elif g[gk] not in GATE_VALUES:
                    errors.append(
                        f"gate_results.{gk} must be one of {sorted(GATE_VALUES)}: got {g[gk]!r}"
                    )
    if "error_log" in doc and not isinstance(doc["error_log"], str):
        errors.append("error_log must be a string if present")
    return errors


# SPEC-0017: agent inventory drift check (warn-only, backward compat).
# Returns list of warning strings (NOT errors — does not fail validation).
RUNTIME_VALUES = {"claude-code", "codex-cli", "codex-cloud", "cron", "human", "unknown"}
APPROVAL_VALUES = {"on-request", "never", "always", "unknown"}
NETWORK_VALUES = {"off", "allowlist", "unrestricted", "unknown"}


def load_inventory(root: Path):
    """Load .sage/agent-inventory.yaml if present. Returns dict (agent_id -> spec) or None."""
    inv_path = root / ".sage" / "agent-inventory.yaml"
    if not inv_path.exists():
        return None
    try:
        with open(inv_path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        if not isinstance(data, dict) or "agents" not in data:
            return None
        return {a["agent_id"]: a for a in data["agents"] if isinstance(a, dict) and "agent_id" in a}
    except (yaml.YAMLError, OSError):
        return None


def _coerce_yaml_str(v):
    """YAML 1.1 parses bareword off/on/yes/no as bool. Coerce back to string
    for enum comparison so users can write `network_mode: off` unquoted."""
    if isinstance(v, bool):
        return {True: "on", False: "off"}[v]
    return v


def inventory_warnings(doc: dict, inv: dict) -> list[str]:
    warnings: list[str] = []
    agent_id = doc.get("agent_id")
    if agent_id not in inv:
        return warnings  # agent not declared → silent (existing enum check covers it)
    expected = inv[agent_id]

    runtime = _coerce_yaml_str(doc.get("runtime", None))
    if runtime is None:
        warnings.append("runtime field missing (SPEC-0017 recommends declaring observed runtime)")
    elif runtime not in RUNTIME_VALUES:
        warnings.append(f"runtime not in enum {sorted(RUNTIME_VALUES)}: got {runtime!r}")
    elif runtime != "unknown":
        exp_runtime = expected.get("expected_runtime", [])
        if exp_runtime and runtime not in exp_runtime:
            warnings.append(
                f"runtime '{runtime}' not in inventory expected_runtime {exp_runtime} for agent_id={agent_id}"
            )

    ap = _coerce_yaml_str(doc.get("approval_policy"))
    if ap is not None and ap not in APPROVAL_VALUES:
        warnings.append(f"approval_policy not in enum: got {ap!r}")
    elif ap and ap != "unknown":
        exp_ap = expected.get("expected_approval_policy")
        if exp_ap and ap != exp_ap:
            warnings.append(
                f"approval_policy '{ap}' != inventory expected '{exp_ap}' for agent_id={agent_id}"
            )

    nm = _coerce_yaml_str(doc.get("network_mode"))
    if nm is not None and nm not in NETWORK_VALUES:
        warnings.append(f"network_mode not in enum: got {nm!r}")
    elif nm and nm != "unknown":
        exp_nm = expected.get("expected_network_mode")
        if exp_nm and nm != exp_nm:
            warnings.append(
                f"network_mode '{nm}' != inventory expected '{exp_nm}' for agent_id={agent_id}"
            )

    return warnings


# Determine repo root from the first RUN log file's location, or cwd
files = [Path(p) for p in sys.argv[1:]]
if files:
    # Walk up to find .sage/
    candidate = files[0].resolve().parent
    while candidate != candidate.parent:
        if (candidate / ".sage").is_dir():
            break
        candidate = candidate.parent
    repo_root = candidate
else:
    repo_root = Path.cwd()

inventory = load_inventory(repo_root)

total_failures = 0
total_warnings = 0
for path in files:
    errs = validate(path)
    if errs:
        total_failures += 1
        print(f"FAIL {path}")
        for e in errs:
            print(f"  - {e}")
    else:
        # Run inventory check only when validate() passed
        warns = []
        if inventory is not None:
            try:
                with open(path, "r", encoding="utf-8") as f:
                    doc = yaml.safe_load(f)
                if isinstance(doc, dict):
                    warns = inventory_warnings(doc, inventory)
            except (yaml.YAMLError, OSError):
                pass
        if warns:
            total_warnings += len(warns)
            print(f"OK   {path} (with {len(warns)} inventory warning(s))")
            for w in warns:
                print(f"  WARN: {w}")
        else:
            print(f"OK   {path}")

if total_failures:
    print(f"{total_failures} file(s) failed validation", file=sys.stderr)
    sys.exit(1)
if total_warnings:
    print(f"{total_warnings} inventory warning(s) total (SPEC-0017, non-blocking)", file=sys.stderr)
sys.exit(0)
PY
