#!/usr/bin/env bash
# =============================================================================
# TASK-0124: test-detection-only-behavior.sh (SPEC-0015 SEC-01 / NFR-09)
# Purpose:  Verify mcp-allowlist-audit.sh NEVER invokes kill family.
#           Uses fake wrapper method (PATH manipulation), not grep —
#           grep would false-positive on comments / strings, ps aux
#           false-positives on the test's own grep process.
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HOOK="${REPO_ROOT}/templates/hooks/mcp-allowlist-audit.sh"

echo "# detection-only behavior (fake wrapper)"

tempdir="$(mktemp -d -t sage-detection-XXXXXX)"
trap "rm -rf $tempdir" EXIT
INVOCATION_LOG="$tempdir/invocations.log"

# Create fake kill / pkill / killall wrappers — record invocations
for cmd in kill pkill killall; do
  cat > "$tempdir/$cmd" <<WRAPPER
#!/bin/sh
echo "\$0 called with: \$*" >> "$INVOCATION_LOG"
WRAPPER
  chmod +x "$tempdir/$cmd"
done

# Create a minimal sandbox so the hook runs (registry absent → exit 0 silently)
sandbox="$(mktemp -d -t sage-detection-sandbox-XXXXXX)"
mkdir -p "${sandbox}/.sage"
cat > "${sandbox}/.sage/config.yaml" <<EOF
hooks:
  profile: standard
EOF

# Run hook with fake wrappers in PATH
export PATH="$tempdir:$PATH"
( cd "$sandbox" && bash "$HOOK" < /dev/null ) >/dev/null 2>&1 || true

if [ -s "$INVOCATION_LOG" ]; then
  FAIL=$((FAIL + 1))
  echo "  not ok detection-only violation: kill family invoked" >&2
  cat "$INVOCATION_LOG" >&2
else
  PASS=$((PASS + 1))
  echo "  ok   no kill / pkill / killall invocation"
fi

# Also test with a registry present + drift1 inject
cat > "${sandbox}/.sage/mcp-allowlist.json" <<JSON
{
  "version": "1.0",
  "servers": [
    {"name":"playwright","transport":"stdio","artifact_type":"npm_package",
     "command":"npx","args":["@anthropic-ai/mcp-playwright@1.42.0"],
     "version_pin":"1.42.0","publisher":"anthropic",
     "source_registry":"https://registry.npmjs.org",
     "approved_by":"SPEC-0015","approved_at":"2026-05-02","expires_at":"2027-05-02"}
  ],
  "policy": {"forbid_latest_tag":true,"http_require_auth":true,"http_static_header_secret_check":true},
  "bypass": {"enabled": false}
}
JSON
cat > "${sandbox}/.mcp.json" <<JSON
{"mcpServers": {"playwright": {"command": "npx", "args": ["@anthropic-ai/mcp-playwright@1.42.0"]}, "unknown-stdio": {"command": "node"}}}
JSON

: > "$INVOCATION_LOG"
( cd "$sandbox" && bash "$HOOK" < /dev/null ) >/dev/null 2>&1 || true

if [ -s "$INVOCATION_LOG" ]; then
  FAIL=$((FAIL + 1))
  echo "  not ok detection-only violation (with drift): kill family invoked" >&2
  cat "$INVOCATION_LOG" >&2
else
  PASS=$((PASS + 1))
  echo "  ok   no kill family invocation (with drift detection active)"
fi

rm -rf "$sandbox"

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
