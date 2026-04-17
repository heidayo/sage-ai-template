#!/usr/bin/env bash
# =============================================================================
# SPEC-0008 TASK-0070: sage-coverage-parse.sh
# Purpose:  Parse a coverage number from stdin (language-agnostic) and
#           compare it to a threshold. Language-specific formatting is the
#           coverage_command's job; this script only extracts the first float
#           it sees, normalizes to 0.0-1.0, and compares.
# Usage:    echo "80.5%" | bash scripts/sage-coverage-parse.sh <threshold>
#           echo "0.92"  | bash scripts/sage-coverage-parse.sh 0.80
# Input:    - threshold as arg1 (float 0.0-1.0, or 0-100 which we normalize)
#           - coverage value via stdin (any textual form containing a number)
# Exit:     0 when coverage >= threshold
#           1 when coverage <  threshold
#           2 on parse failure / bad usage
# Output:   prints "coverage=X threshold=Y" to stdout; details to stderr on FAIL
# =============================================================================
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <threshold>" >&2
  exit 2
fi

THRESHOLD_RAW="$1"

INPUT=$(cat)
if [ -z "${INPUT// }" ]; then
  echo "ERROR: no coverage input provided on stdin" >&2
  exit 2
fi

# Normalize threshold and coverage to a 0.0-1.0 float.
python3 - <<PY "$INPUT" "$THRESHOLD_RAW"
import re, sys

raw_cov = sys.argv[1]
raw_thr = sys.argv[2]

def extract_float(s):
    # Find the first numeric token (handles percent signs, table output, etc.)
    m = re.search(r'([0-9]+(?:\.[0-9]+)?)', s)
    if not m:
        return None
    return float(m.group(1))

def to_unit(x):
    # Accept either 0..1 or 0..100 — if > 1, treat as percentage.
    if x is None:
        return None
    return x / 100.0 if x > 1.0 else x

cov = to_unit(extract_float(raw_cov))
thr = to_unit(extract_float(raw_thr))

if cov is None:
    print(f"ERROR: could not parse coverage from input: {raw_cov!r}", file=sys.stderr)
    sys.exit(2)
if thr is None:
    print(f"ERROR: could not parse threshold from arg: {raw_thr!r}", file=sys.stderr)
    sys.exit(2)

print(f"coverage={cov:.4f} threshold={thr:.4f}")
if cov + 1e-9 >= thr:
    sys.exit(0)
print(
    f"FAIL: coverage {cov*100:.2f}% below threshold {thr*100:.2f}%",
    file=sys.stderr,
)
sys.exit(1)
PY
