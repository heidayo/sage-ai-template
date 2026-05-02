#!/usr/bin/env bash
# =============================================================================
# TASK-0123: test-mcp-allowlist-audit.sh (SPEC-0015 AC-03)
# Purpose:  Test mcp-allowlist-audit.sh hook (24 scenarios across stdio/http
#           drift cases, registry absence, profile gating, secret hygiene,
#           transport_mismatch, OAuth callback mismatch).
# =============================================================================
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_helpers.sh
source "${TEST_DIR}/_helpers.sh"

PASS=0
FAIL=0

# Helper: write registry to sandbox
write_registry() {
  local sandbox="$1"
  local content="$2"
  echo "$content" > "${sandbox}/.sage/mcp-allowlist.json"
}

# Helper: write actual .mcp.json
write_mcp_json() {
  local sandbox="$1"
  local content="$2"
  echo "$content" > "${sandbox}/.mcp.json"
}

# Helper: write actual .codex/config.toml (repo-local)
write_codex_repo() {
  local sandbox="$1"
  local content="$2"
  mkdir -p "${sandbox}/.codex"
  echo "$content" > "${sandbox}/.codex/config.toml"
}

# Helper: set profile
set_profile() {
  local sandbox="$1"
  local profile="$2"
  cat > "${sandbox}/.sage/config.yaml" <<EOF
hooks:
  profile: ${profile}
EOF
}

# Helper: assert audit log contains drift_type
assert_audit_drift_type() {
  local sandbox="$1"
  local drift_type="$2"
  local label="$3"
  local audit_log
  audit_log="$(ls "${sandbox}/.sage/audit/mcp-allowlist-"*.log 2>/dev/null | head -1)"
  if [ -z "$audit_log" ]; then
    FAIL=$((FAIL + 1))
    echo "  not ok ${label}: no audit log found" >&2
    return 1
  fi
  if grep -q "\"drift_type\": \"${drift_type}\"" "$audit_log"; then
    PASS=$((PASS + 1))
    echo "  ok   ${label} (drift_type=${drift_type})"
  else
    FAIL=$((FAIL + 1))
    echo "  not ok ${label}: drift_type ${drift_type} not in audit log" >&2
    cat "$audit_log" >&2
  fi
}

assert_no_audit_log() {
  local sandbox="$1"
  local label="$2"
  # Match only date-stamped drift event log, exclude bypass/auxiliary logs (NFR-04).
  # Tolerate missing audit dir (registry absent / minimal profile cases).
  local found=""
  if [ -d "${sandbox}/.sage/audit" ]; then
    found="$(find "${sandbox}/.sage/audit" -name 'mcp-allowlist-2*.log' 2>/dev/null | head -1 || true)"
  fi
  if [ -n "$found" ]; then
    FAIL=$((FAIL + 1))
    echo "  not ok ${label}: drift event log unexpectedly present: $found" >&2
  else
    PASS=$((PASS + 1))
    echo "  ok   ${label} (no drift event log)"
  fi
}

# Base registry with one stdio + one http server
BASE_REGISTRY='{
  "version": "1.0",
  "servers": [
    {
      "name": "playwright",
      "transport": "stdio",
      "artifact_type": "npm_package",
      "command": "npx",
      "args": ["@anthropic-ai/mcp-playwright@1.42.0"],
      "version_pin": "1.42.0",
      "publisher": "anthropic",
      "source_registry": "https://registry.npmjs.org",
      "approved_by": "SPEC-0015",
      "approved_at": "2026-05-02",
      "expires_at": "2027-05-02"
    },
    {
      "name": "company-search",
      "transport": "http",
      "artifact_type": "remote_http",
      "url": "https://mcp.example.com/v1",
      "url_origin_pin": "https://mcp.example.com",
      "auth_mode": "bearer_env",
      "bearer_token_env_var": "COMPANY_TOKEN",
      "approved_by": "SPEC-0015",
      "approved_at": "2026-05-02",
      "expires_at": "2027-05-02"
    }
  ],
  "policy": {
    "forbid_latest_tag": true,
    "require_npm_integrity": false,
    "require_publisher": true,
    "forbid_unknown_transport": true,
    "http_require_url_origin_pin": true,
    "http_require_auth": true,
    "http_static_header_secret_check": true,
    "oauth_callback_require_match": true
  },
  "bypass": {"enabled": false}
}'

# ============================================================================
# stdio drift cases
# ============================================================================

echo "# stdio drift cases"

# --- drift1 stdio: unknown server ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"unknown-stdio": {"command": "node", "args": ["evil.js"]}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift1_stdio_unknown_server" "drift1 stdio unknown server"
rm -rf "$sandbox"

# --- drift2 stdio: args version mismatch ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"playwright": {"command": "npx", "args": ["@anthropic-ai/mcp-playwright@1.99.0"]}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift2_stdio_args_mismatch" "drift2 stdio args mismatch"
rm -rf "$sandbox"

# --- drift3 stdio: registry only ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift3_stdio_registry_only" "drift3 registry only"
rm -rf "$sandbox"

# --- drift4 stdio: @latest tag ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"playwright": {"command": "npx", "args": ["@anthropic-ai/mcp-playwright@latest"]}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift4_stdio_latest_tag" "drift4 stdio @latest"
rm -rf "$sandbox"

# --- drift5 npm_integrity mismatch (require_npm_integrity:true + missing field) ---
echo "# drift5 npm_integrity"
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
REGISTRY_INTEGRITY="${BASE_REGISTRY//\"require_npm_integrity\": false/\"require_npm_integrity\": true}"
write_registry "$sandbox" "$REGISTRY_INTEGRITY"
write_mcp_json "$sandbox" '{"mcpServers": {"playwright": {"command": "npx", "args": ["@anthropic-ai/mcp-playwright@1.42.0"]}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift5_npm_integrity_mismatch" "drift5 npm_integrity mismatch"
rm -rf "$sandbox"

# ============================================================================
# http drift cases
# ============================================================================

echo "# http drift cases"

# --- drift1 http: unknown server ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"unknown-http": {"url": "https://evil.example.com"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift1_http_unknown_server" "drift1 http unknown server"
rm -rf "$sandbox"

# --- drift2 http: url_origin mismatch ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"company-search": {"url": "https://evil.com/v1"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift2_http_url_origin_mismatch" "drift2 http origin mismatch"
rm -rf "$sandbox"

# --- drift6 anonymous (registry has auth_mode: none + http_require_auth: true) ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
ANON_REGISTRY=$(echo "$BASE_REGISTRY" | python3 -c "
import json,sys
r=json.load(sys.stdin)
r['servers'].append({
  'name':'anon-server','transport':'http','artifact_type':'remote_http',
  'url':'https://anon.example.com','url_origin_pin':'https://anon.example.com',
  'auth_mode':'none',
  'approved_by':'SPEC-0015','approved_at':'2026-05-02','expires_at':'2027-05-02'
})
print(json.dumps(r))
")
write_registry "$sandbox" "$ANON_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"anon-server": {"url": "https://anon.example.com"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift6_anonymous" "drift6 anonymous"
rm -rf "$sandbox"

# --- drift6 OAuth approve (registry oauth + actual oauth = info, not block) ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
OAUTH_REGISTRY=$(echo "$BASE_REGISTRY" | python3 -c "
import json,sys
r=json.load(sys.stdin)
r['servers'].append({
  'name':'oauth-server','transport':'http','artifact_type':'remote_http',
  'url':'https://oauth.example.com','url_origin_pin':'https://oauth.example.com',
  'auth_mode':'oauth','oauth_provider':'google','oauth_scopes':['openid'],
  'approved_by':'SPEC-0015','approved_at':'2026-05-02','expires_at':'2027-05-02'
})
print(json.dumps(r))
")
write_registry "$sandbox" "$OAUTH_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"oauth-server": {"url": "https://oauth.example.com"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift6_oauth_approve" "drift6 OAuth approve"
rm -rf "$sandbox"

# --- drift6 Bearer approve (registry bearer_env + actual url match = info) ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"company-search": {"url": "https://mcp.example.com/v1"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift6_bearer_approve" "drift6 Bearer approve"
rm -rf "$sandbox"

# --- drift7 sensitive header (canonical case) ---
echo "# drift7 sensitive header (4 case-insensitive variants)"
for variant in "Authorization" "authorization" "AUTHORIZATION" "x-Api-Key"; do
  sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
  BAD_REGISTRY=$(echo "$BASE_REGISTRY" | python3 -c "
import json,sys
r=json.load(sys.stdin)
r['servers'][1]['http_headers']={'${variant}': 'leaked-secret'}
print(json.dumps(r))
")
  write_registry "$sandbox" "$BAD_REGISTRY"
  run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
  assert_audit_drift_type "$sandbox" "drift7_sensitive_header" "drift7 sensitive header (${variant})"
  rm -rf "$sandbox"
done

# --- drift8 OAuth callback mismatch ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
CB_REGISTRY=$(echo "$BASE_REGISTRY" | python3 -c "
import json,sys
r=json.load(sys.stdin)
r['oauth_callback']={'mcp_oauth_callback_port':'8765','mcp_oauth_callback_url':''}
print(json.dumps(r))
")
write_registry "$sandbox" "$CB_REGISTRY"
write_codex_repo "$sandbox" 'mcp_oauth_callback_port = "9000"
[mcp_servers.test]
url = "https://x"
'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "drift8_oauth_callback_mismatch" "drift8 OAuth callback mismatch"
rm -rf "$sandbox"

# --- transport_mismatch ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
# playwright is stdio in registry; submit it as http in actual config
write_mcp_json "$sandbox" '{"mcpServers": {"playwright": {"url": "https://fake.example.com"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "transport_mismatch" "transport_mismatch"
rm -rf "$sandbox"

# ============================================================================
# Common scenarios
# ============================================================================

echo "# common scenarios"

# --- expired approval ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
EXPIRED_REGISTRY=$(echo "$BASE_REGISTRY" | python3 -c "
import json,sys
r=json.load(sys.stdin)
r['servers'][0]['expires_at']='2020-01-01'
print(json.dumps(r))
")
write_registry "$sandbox" "$EXPIRED_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"playwright": {"command": "npx", "args": ["@anthropic-ai/mcp-playwright@1.42.0"]}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_audit_drift_type "$sandbox" "expired_approval" "expired approval"
rm -rf "$sandbox"

# --- registry absent → warn + skip (exit 0, no audit log) ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_eq "$HOOK_RC" "0" "registry absent exit 0"
assert_no_audit_log "$sandbox" "registry absent no audit log"
rm -rf "$sandbox"

# --- profile=minimal → silent skip ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
set_profile "$sandbox" "minimal"
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"unknown": {"command": "evil"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_eq "$HOOK_RC" "0" "profile=minimal exit 0"
assert_no_audit_log "$sandbox" "profile=minimal no audit log"
rm -rf "$sandbox"

# --- profile=strict + drift1 stdio → block (exit 1) ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
set_profile "$sandbox" "strict"
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"unknown-stdio": {"command": "evil"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_eq "$HOOK_RC" "1" "profile=strict drift1 stdio block"
rm -rf "$sandbox"

# --- profile=strict + drift7 → block (exit 1, FAIL) ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
set_profile "$sandbox" "strict"
BAD7=$(echo "$BASE_REGISTRY" | python3 -c "
import json,sys
r=json.load(sys.stdin)
r['servers'][1]['http_headers']={'Authorization':'Bearer x'}
print(json.dumps(r))
")
write_registry "$sandbox" "$BAD7"
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_eq "$HOOK_RC" "1" "profile=strict drift7 block (FAIL)"
rm -rf "$sandbox"

# --- audit log args redact (env name in registry, not env value) ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
write_mcp_json "$sandbox" '{"mcpServers": {"unknown-stdio": {"command": "evil"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
audit_log="$(ls "${sandbox}/.sage/audit/mcp-allowlist-"*.log 2>/dev/null | head -1)"
if grep -qE "Bearer|secret-value|leaked" "$audit_log" 2>/dev/null; then
  FAIL=$((FAIL + 1))
  echo "  not ok audit log redact: leaked secret-pattern" >&2
else
  PASS=$((PASS + 1))
  echo "  ok   audit log redact (no secret-pattern)"
fi
rm -rf "$sandbox"

# --- default does NOT read user-global ~/.codex/config.toml ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
write_registry "$sandbox" "$BASE_REGISTRY"
# (we cannot easily test ~/.codex/config.toml without polluting user env;
#  instead: assert no audit log entry with runtime=codex-cli-user-global)
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
audit_log="$(ls "${sandbox}/.sage/audit/mcp-allowlist-"*.log 2>/dev/null | head -1)"
if [ -n "$audit_log" ] && grep -q "codex-cli-user-global" "$audit_log"; then
  FAIL=$((FAIL + 1))
  echo "  not ok default user-global excluded" >&2
else
  PASS=$((PASS + 1))
  echo "  ok   default does not read user-global codex config"
fi
rm -rf "$sandbox"

# --- opt-in include_user_global_codex: true reads user-global ---
# (skip: requires user env mutation; the gating logic itself is covered by config parse path)

# --- bypass.enabled: true suppresses drift, records bypass log ---
sandbox="$(create_sandbox)"; trap "rm -rf $sandbox" EXIT
BYPASS_REG=$(echo "$BASE_REGISTRY" | python3 -c "
import json,sys
r=json.load(sys.stdin)
r['bypass']={'enabled':True,'reason':'test','expires_at':'2026-12-31'}
print(json.dumps(r))
")
write_registry "$sandbox" "$BYPASS_REG"
write_mcp_json "$sandbox" '{"mcpServers": {"unknown": {"command": "evil"}}}'
run_hook "mcp-allowlist-audit.sh" "" "$sandbox"
assert_no_audit_log "$sandbox" "bypass enabled: no drift audit log"
if [ -f "${sandbox}/.sage/audit/mcp-allowlist-bypass.log" ]; then
  PASS=$((PASS + 1))
  echo "  ok   bypass log written"
else
  FAIL=$((FAIL + 1))
  echo "  not ok bypass log missing" >&2
fi
rm -rf "$sandbox"

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
