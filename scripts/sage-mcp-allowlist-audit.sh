#!/usr/bin/env bash
# =============================================================================
# TASK-0124: sage-mcp-allowlist-audit.sh (SPEC-0015)
# Purpose:  CLI wrapper for MCP allowlist drift detection (Python-based).
#           Used by sage-doctor.sh as a separate process to avoid bash
#           heredoc + $(...) command-substitution parsing issues.
# Input:    $1 = registry path (.sage/mcp-allowlist.json)
# Output:   TSV lines: <level>\t<check>\t<message>
#           level: OK / WARN / FAIL
# Exit:     0 always (FAIL is reported via output, not exit code)
# =============================================================================
set -uo pipefail

REGISTRY_PATH="${1:-.sage/mcp-allowlist.json}"

if ! command -v python3 &>/dev/null; then
  echo "WARN	mcp_allowlist_python	python3 not in PATH"
  exit 0
fi

if [ ! -f "$REGISTRY_PATH" ]; then
  echo "WARN	mcp_allowlist_registry	Registry $REGISTRY_PATH not present"
  exit 0
fi

python3 - "$REGISTRY_PATH" <<'PYEOF'
import json
import sys
import os
import datetime

registry_path = sys.argv[1]

SENSITIVE_HEADERS = {
    "authorization", "cookie", "set-cookie", "proxy-authorization",
    "x-api-key", "x-auth-token", "x-token",
}

# (b) registry validity + secret hygiene
try:
    with open(registry_path) as f:
        reg = json.load(f)
except json.JSONDecodeError as e:
    print(f"FAIL\tregistry_validity\tJSON parse failed: {e}")
    sys.exit(0)

fail7 = []
if reg.get("policy", {}).get("http_static_header_secret_check", True):
    for srv in reg.get("servers", []):
        if srv.get("transport") != "http":
            continue
        for hkey in srv.get("http_headers", {}).keys():
            if hkey.lower() in SENSITIVE_HEADERS:
                fail7.append((srv.get("name"), hkey))

if fail7:
    for name, hkey in fail7:
        print(f"FAIL\tmcp_secret_hygiene\tdrift7 sensitive header in registry: server '{name}' has '{hkey}' (SEC-07)")
else:
    print("OK\tregistry_validity\tRegistry parses + secret hygiene clean")

# (c) strict-block drift count from today's audit log
today = datetime.date.today().strftime('%Y%m%d')
log_path = f".sage/audit/mcp-allowlist-{today}.log"
strict_types = {
    "drift1_stdio_unknown_server", "drift1_http_unknown_server",
    "drift5_npm_integrity_mismatch", "drift5_command_path_sha256_mismatch",
    "drift5_tls_pin_sha256_mismatch", "drift6_anonymous",
    "drift8_oauth_callback_mismatch", "transport_mismatch",
}
strict_n = 0
if os.path.exists(log_path):
    for line in open(log_path):
        try:
            rec = json.loads(line)
            if rec.get("drift_type") in strict_types:
                strict_n += 1
        except json.JSONDecodeError:
            pass

if strict_n > 0:
    print(f"WARN\tmcp_strict_block_drift\t{strict_n} strict-block drift event(s) in today's audit log — strict promotion blocked")
else:
    print("OK\tmcp_strict_block_drift\t0 strict-block drift events today")

# (d) other warn-only drift count (INFO)
other_types = {
    "drift2_stdio_args_mismatch", "drift2_http_url_origin_mismatch",
    "drift3_stdio_registry_only", "drift4_stdio_latest_tag",
    "drift6_oauth_approve", "drift6_bearer_approve",
}
other_n = 0
if os.path.exists(log_path):
    for line in open(log_path):
        try:
            rec = json.loads(line)
            if rec.get("drift_type") in other_types:
                other_n += 1
        except json.JSONDecodeError:
            pass
print(f"OK\tmcp_other_drift\t{other_n} warn-only drift event(s) (INFO)")

# (e) expired approvals
today_iso = datetime.date.today().isoformat()
expired = [
    s.get("name") for s in reg.get("servers", [])
    if s.get("expires_at", "") and s.get("expires_at", "") < today_iso
]
if expired:
    print(f"WARN\tmcp_expired_approval\t{len(expired)} expired approval(s): {', '.join(expired)}")
else:
    print("OK\tmcp_expired_approval\tNo expired approvals")
PYEOF
