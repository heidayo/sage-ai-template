#!/usr/bin/env bash
# =============================================================================
# TASK-0123: mcp-allowlist-audit.sh (SPEC-0015)
# Purpose:  SessionStart hook — audit .mcp.json (Claude Code) and
#           repo-local .codex/config.toml (Codex CLI) against
#           .sage/mcp-allowlist.json registry.
# Profile:  none/minimal -> skip; standard -> warn; strict -> block on
#           strict-block enum (drift1/5/6 anonymous/8/transport_mismatch).
# Behavior: detection-only (audit-first / runtime-process-safe).
#           NEVER kills processes — strict exit 1 = SessionStart block.
# Schema:   .sage/audit/mcp-allowlist-YYYYMMDD.log (JSON-lines, NFR-04)
# =============================================================================
set -uo pipefail

# --- Profile gating ---
PROFILE="standard"
if [ -f ".sage/config.yaml" ]; then
  PROFILE=$(grep -A1 'hooks:' .sage/config.yaml 2>/dev/null | grep 'profile:' | awk '{print $2}' | tr -d '"' || echo "standard")
  [ -z "$PROFILE" ] && PROFILE="standard"
fi

if [ "$PROFILE" = "minimal" ] || [ "$PROFILE" = "none" ]; then
  exit 0
fi

# --- Read SessionStart stdin (best-effort, hook does not depend on input) ---
if read -r -t 1 _ 2>/dev/null; then :; fi

# --- Read user-global Codex opt-in (default off, SEC-06) ---
INCLUDE_USER_GLOBAL=false
if [ -f ".sage/config.yaml" ]; then
  if grep -qE '^[[:space:]]*include_user_global_codex:[[:space:]]*true' .sage/config.yaml 2>/dev/null; then
    INCLUDE_USER_GLOBAL=true
  fi
fi

REGISTRY_PATH=".sage/mcp-allowlist.json"
AUDIT_DIR=".sage/audit"
TODAY="$(date -u +%Y%m%d)"
AUDIT_LOG="${AUDIT_DIR}/mcp-allowlist-${TODAY}.log"
BYPASS_LOG="${AUDIT_DIR}/mcp-allowlist-bypass.log"

# --- Graceful degradation: registry absent ---
if [ ! -f "$REGISTRY_PATH" ]; then
  echo "WARN: .sage/mcp-allowlist.json not found. Initial setup recommended (SPEC-0015). Skipping MCP allowlist audit." >&2
  exit 0
fi

# --- Graceful degradation: Python unavailable ---
if ! command -v python3 &>/dev/null; then
  echo "WARN: python3 not available. Skipping MCP allowlist audit." >&2
  exit 0
fi

mkdir -p "$AUDIT_DIR"

# --- Delegate to Python: parse registry + actual config + emit drift events ---
EXIT_CODE_FILE="$(mktemp)"
trap 'rm -f "$EXIT_CODE_FILE"' EXIT

python3 - "$REGISTRY_PATH" "$AUDIT_LOG" "$BYPASS_LOG" "$PROFILE" "$INCLUDE_USER_GLOBAL" "$EXIT_CODE_FILE" <<'PYEOF'
import json
import os
import sys
import datetime
import pathlib

registry_path, audit_log, bypass_log, profile, include_user_global, exit_code_file = sys.argv[1:7]
include_user_global = include_user_global == "true"

# --- Strict-block enum set (SPEC FR-03 + Codex 4th/7th review) ---
STRICT_BLOCK = {
    "drift1_stdio_unknown_server",
    "drift1_http_unknown_server",
    "drift5_npm_integrity_mismatch",
    "drift5_command_path_sha256_mismatch",
    "drift5_tls_pin_sha256_mismatch",
    "drift6_anonymous",
    "drift8_oauth_callback_mismatch",
    "transport_mismatch",
}

# --- Sensitive header canonical list (RFC 9110 §5.1, lowercase normalized) ---
SENSITIVE_HEADERS = {
    "authorization", "cookie", "set-cookie", "proxy-authorization",
    "x-api-key", "x-auth-token", "x-token",
}

def emit(severity, drift_type, runtime, scope="server", server_name=None, **details_extra):
    """Write JSON-line to audit log per NFR-04 schema."""
    record = {
        "timestamp": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "runtime": runtime,
        "drift_type": drift_type,
        "severity": severity,
        "details": {"scope": scope, "server_name": server_name, **details_extra},
    }
    with open(audit_log, "a") as f:
        f.write(json.dumps(record) + "\n")

def warn_msg(msg):
    print(f"WARN: {msg}", file=sys.stderr)

# --- Load registry (with secret-hygiene check) ---
try:
    with open(registry_path) as f:
        registry = json.load(f)
except json.JSONDecodeError as e:
    warn_msg(f"registry parse failed: {e}; SPEC-0015 EC-01 — see .sage/mcp-allowlist.json")
    pathlib.Path(exit_code_file).write_text("0")
    sys.exit(0)

policy = registry.get("policy", {})
servers = registry.get("servers", [])
oauth_callback = registry.get("oauth_callback", {})
bypass = registry.get("bypass", {})

# --- Bypass: skip all drift, but record bypass event (SEC-04) ---
if bypass.get("enabled") is True:
    with open(bypass_log, "a") as f:
        f.write(json.dumps({
            "timestamp": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
            "reason": bypass.get("reason", ""),
            "expires_at": bypass.get("expires_at", ""),
        }) + "\n")
    pathlib.Path(exit_code_file).write_text("0")
    sys.exit(0)

# --- Registry parse-stage: drift7 sensitive header check (SEC-07, FAIL) ---
if policy.get("http_static_header_secret_check", True):
    for srv in servers:
        if srv.get("transport") != "http":
            continue
        headers = srv.get("http_headers", {})
        for hkey in headers.keys():
            if hkey.lower() in SENSITIVE_HEADERS:
                emit(
                    "fail", "drift7_sensitive_header", "registry-parse",
                    server_name=srv.get("name"), header_name=hkey.lower(),
                )
                warn_msg(
                    f"FAIL: registry server '{srv.get('name')}' has sensitive static header "
                    f"'{hkey}'. Move to env_http_headers / bearer_token_env_var. (SEC-07 / drift7)"
                )

# --- Build registry index (name -> server_dict) ---
reg_by_name = {srv["name"]: srv for srv in servers if "name" in srv}
forbid_latest = policy.get("forbid_latest_tag", True)
require_npm_integrity = policy.get("require_npm_integrity", False)
http_require_auth = policy.get("http_require_auth", True)
http_require_origin_pin = policy.get("http_require_url_origin_pin", True)
oauth_require_match = policy.get("oauth_callback_require_match", True)

# --- Load actual configs ---
def load_mcp_json(path):
    if not os.path.exists(path):
        return None
    try:
        with open(path) as f:
            return json.load(f)
    except json.JSONDecodeError:
        return None

def load_codex_toml(path):
    """TOML reader for Codex config — uses tomllib (Python 3.11+).

    Falls back to a documented-limitation minimal reader for older Python:
    only top-level scalars and [mcp_servers.<name>] direct scalar fields.
    Codex review P2 #1 reflected: avoid array/nested-table false positives.
    """
    if not os.path.exists(path):
        return None
    # Try tomllib (Python 3.11+) — handles arrays + nested tables correctly
    try:
        import tomllib  # type: ignore[import-not-found]
        try:
            with open(path, "rb") as f:
                data = tomllib.load(f)
        except (tomllib.TOMLDecodeError, OSError):
            return None
        servers_out = {}
        for name, conf in data.get("mcp_servers", {}).items():
            # Skip nested tables (e.g. [mcp_servers.foo.http_headers]) — those
            # are subkeys of the server, not separate servers
            if isinstance(conf, dict):
                # Strip nested-table values to keep simple comparison logic;
                # leave scalar / list values intact (args is a list).
                flat = {k: v for k, v in conf.items() if not isinstance(v, dict)}
                servers_out[name] = flat
        top_level = {k: v for k, v in data.items() if k != "mcp_servers" and not isinstance(v, dict)}
        return {"servers": servers_out, "top_level": top_level}
    except ImportError:
        # Pre-3.11 fallback: minimal scalar-only reader, with explicit warning
        print(
            "WARN: Python <3.11 detected; tomllib unavailable. "
            "Codex TOML parse limited to scalar fields only. "
            "Upgrade to Python 3.11+ for full TOML support.",
            file=sys.stderr,
        )
        servers_out = {}
        top_level = {}
        current = None
        try:
            with open(path) as f:
                for raw_line in f:
                    line = raw_line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if line.startswith("[mcp_servers."):
                        # Reject nested table sections to avoid false-positive servers
                        section = line.split("[mcp_servers.")[1].rstrip("]").strip()
                        if "." in section:
                            current = None  # e.g. [mcp_servers.foo.http_headers]
                            continue
                        current = section
                        servers_out.setdefault(current, {})
                    elif line.startswith("[") and not line.startswith("[mcp_servers"):
                        current = None
                    elif "=" in line:
                        k, _, v = line.partition("=")
                        k = k.strip()
                        v = v.strip()
                        # Skip lists/arrays (start with [) — fallback can't safely parse them
                        if v.startswith("["):
                            continue
                        v = v.strip('"').strip("'")
                        if current is None:
                            top_level[k] = v
                        else:
                            servers_out[current][k] = v
        except OSError:
            return None
        return {"servers": servers_out, "top_level": top_level}

mcp_json = load_mcp_json(".mcp.json")
codex_repo = load_codex_toml(".codex/config.toml")
codex_user = load_codex_toml(os.path.expanduser("~/.codex/config.toml")) if include_user_global else None

# --- Build "actual" server map (from runtime configs) ---
actual_servers = {}  # name -> {"transport": "stdio"|"http", "raw": {...}, "runtime": "..."}

if mcp_json and "mcpServers" in mcp_json:
    for name, conf in mcp_json["mcpServers"].items():
        # Heuristic: presence of "url" => HTTP, else STDIO
        transport = "http" if "url" in conf else "stdio"
        actual_servers[name] = {"transport": transport, "raw": conf, "runtime": "claude-code"}

for runtime_label, codex_data in (("codex-cli-repo-local", codex_repo), ("codex-cli-user-global", codex_user)):
    if not codex_data:
        continue
    for name, conf in codex_data.get("servers", {}).items():
        if name in actual_servers:
            continue  # First-write-wins to avoid duplicates between runtimes
        transport = "http" if "url" in conf else "stdio"
        actual_servers[name] = {"transport": transport, "raw": conf, "runtime": runtime_label}

# --- Drift detection ---
fail_count = 0  # drift7 (FAIL)
strict_block_count = 0

for name, actual in actual_servers.items():
    runtime = actual["runtime"]
    raw = actual["raw"]
    transport = actual["transport"]

    if name not in reg_by_name:
        # drift1 — unknown server
        if transport == "stdio":
            emit("warn", "drift1_stdio_unknown_server", runtime,
                 server_name=name, actual_command=raw.get("command", ""))
            warn_msg(f"drift1: unknown stdio server '{name}' (not in allowlist).")
            strict_block_count += 1
        else:
            emit("warn", "drift1_http_unknown_server", runtime,
                 server_name=name, actual_url=raw.get("url", ""))
            warn_msg(f"drift1: unknown http server '{name}' (not in allowlist).")
            strict_block_count += 1
        continue

    reg_srv = reg_by_name[name]
    reg_transport = reg_srv.get("transport", "stdio")

    if reg_transport != transport:
        # transport mismatch (independent enum, Codex 7th review)
        emit("warn", "transport_mismatch", runtime,
             server_name=name,
             expected_transport=reg_transport,
             actual_transport=transport)
        warn_msg(f"transport_mismatch: '{name}' expected {reg_transport}, got {transport}.")
        strict_block_count += 1
        continue

    if transport == "stdio":
        # drift2: args version mismatch
        # Codex review P1 #1 (CWE-532): NEVER log raw actual_args — they may
        # contain tokens / API keys. Log only argv-shape (count + length sketch)
        # plus the full registry-approved args (those are reviewed in PRs).
        reg_args = reg_srv.get("args", [])
        actual_args = raw.get("args", [])
        if reg_args != actual_args:
            emit("warn", "drift2_stdio_args_mismatch", runtime,
                 server_name=name,
                 expected_args=reg_args,
                 actual_args="[REDACTED]",
                 actual_args_count=len(actual_args) if isinstance(actual_args, list) else None)
            warn_msg(f"drift2: '{name}' args mismatch (registry vs actual; actual REDACTED).")
        # drift4: @latest tag check (scan actual_args without logging them)
        if forbid_latest:
            for arg in actual_args:
                if "@latest" in str(arg):
                    emit("warn", "drift4_stdio_latest_tag", runtime,
                         server_name=name, actual_command=raw.get("command", ""))
                    warn_msg(f"drift4: '{name}' uses @latest (forbidden by policy).")
                    break
        # drift5: artifact integrity (npm_package only, optional check)
        if require_npm_integrity and reg_srv.get("artifact_type") == "npm_package":
            if not reg_srv.get("npm_integrity"):
                emit("warn", "drift5_npm_integrity_mismatch", runtime,
                     server_name=name,
                     expected_integrity="(missing in registry)",
                     actual_integrity="(not checked)")
                warn_msg(f"drift5: '{name}' npm_integrity required but missing in registry.")
                strict_block_count += 1
    else:  # http
        # drift2 http: url_origin mismatch
        # Codex review P1 #2 (WHATWG URL origin): use urlsplit + exact tuple
        # comparison. startswith() lets `https://mcp.example.com.evil.test`
        # pass a pin of `https://mcp.example.com`.
        reg_origin = reg_srv.get("url_origin_pin", "")
        actual_url = raw.get("url", "")
        if reg_origin:
            from urllib.parse import urlsplit
            try:
                a = urlsplit(actual_url)
                r = urlsplit(reg_origin)
                # Effective port: explicit port if set, else scheme default
                def _effective_port(parts):
                    if parts.port:
                        return parts.port
                    return {"https": 443, "http": 80}.get(parts.scheme, None)
                origin_match = (
                    a.scheme == r.scheme
                    and a.scheme in ("https", "http")
                    and a.hostname is not None
                    and r.hostname is not None
                    and a.hostname == r.hostname
                    and _effective_port(a) == _effective_port(r)
                )
            except (ValueError, AttributeError):
                origin_match = False  # fail closed
            if not origin_match:
                emit("warn", "drift2_http_url_origin_mismatch", runtime,
                     server_name=name, expected_url=reg_origin, actual_url=actual_url)
                warn_msg(f"drift2 http: '{name}' url_origin mismatch.")
        # drift6: anonymous auth
        # Codex review P1 #3: infer ACTUAL auth_mode from actual config fields,
        # not from registry. If actual config lacks auth, must report as
        # anonymous regardless of what registry declares.
        reg_auth_mode = reg_srv.get("auth_mode", "none")
        # Heuristic: actual config has bearer if it has Authorization-style
        # env reference, oauth if it has oauth_provider, else none.
        actual_has_bearer = bool(raw.get("bearer_token_env_var")) or any(
            k.lower() == "authorization" for k in (raw.get("env_http_headers") or {}).keys()
        )
        actual_has_oauth = bool(raw.get("oauth_provider"))
        if actual_has_oauth:
            actual_auth_mode = "oauth"
        elif actual_has_bearer:
            actual_auth_mode = "bearer_env"
        else:
            actual_auth_mode = "none"

        if http_require_auth and actual_auth_mode == "none":
            emit("warn", "drift6_anonymous", runtime,
                 server_name=name,
                 expected_auth_mode=reg_auth_mode,
                 actual_auth_mode=actual_auth_mode)
            warn_msg(f"drift6: '{name}' anonymous (actual auth_mode: none) — strict will block.")
            strict_block_count += 1
        elif reg_auth_mode != actual_auth_mode:
            # Auth-mode drift (registry expects X, actual is Y) — block in strict
            emit("warn", "drift6_anonymous", runtime,
                 server_name=name,
                 expected_auth_mode=reg_auth_mode,
                 actual_auth_mode=actual_auth_mode)
            warn_msg(f"drift6: '{name}' auth_mode mismatch (registry={reg_auth_mode} vs actual={actual_auth_mode}).")
            strict_block_count += 1
        elif actual_auth_mode == "oauth":
            emit("info", "drift6_oauth_approve", runtime,
                 server_name=name, actual_auth_mode=actual_auth_mode)
        elif actual_auth_mode == "bearer_env":
            emit("info", "drift6_bearer_approve", runtime,
                 server_name=name, actual_auth_mode=actual_auth_mode)

# --- drift3: registry has server not in any actual config ---
for name, reg_srv in reg_by_name.items():
    if name not in actual_servers:
        emit("info", "drift3_stdio_registry_only", "registry-parse",
             server_name=name)

# --- drift8: OAuth callback mismatch (top-level) ---
# Codex review P2 #2: emit drift8 whenever oauth_callback_require_match is true
# AND either side declares values that don't EXACTLY match the other side
# (including missing/undeclared on one side).
if oauth_require_match:
    reg_port = str(oauth_callback.get("mcp_oauth_callback_port", "")) if oauth_callback else ""
    reg_url = oauth_callback.get("mcp_oauth_callback_url", "") if oauth_callback else ""
    for runtime_label, codex_data in (("codex-cli-repo-local", codex_repo), ("codex-cli-user-global", codex_user)):
        if not codex_data:
            continue
        actual_port = str(codex_data["top_level"].get("mcp_oauth_callback_port", ""))
        actual_url = codex_data["top_level"].get("mcp_oauth_callback_url", "")
        # Mismatch = exact-match fails on either field where at least one side is non-empty
        port_mismatch = (reg_port or actual_port) and reg_port != actual_port
        url_mismatch = (reg_url or actual_url) and reg_url != actual_url
        if port_mismatch or url_mismatch:
            emit("warn", "drift8_oauth_callback_mismatch", runtime_label,
                 scope="top_level", server_name=None,
                 expected_port=reg_port, actual_port=actual_port,
                 expected_url=reg_url, actual_url=actual_url,
                 mismatch_kind=("port" if port_mismatch else "url"))
            warn_msg(f"drift8: OAuth callback mismatch (port: '{reg_port}' vs '{actual_port}', url: '{reg_url}' vs '{actual_url}').")
            strict_block_count += 1

# --- expired approvals ---
today = datetime.date.today().isoformat()
for srv in servers:
    expires_at = srv.get("expires_at", "")
    if expires_at and expires_at < today:
        emit("warn", "expired_approval", "registry-parse",
             server_name=srv.get("name"), expires_at=expires_at)
        warn_msg(f"expired: '{srv.get('name')}' approval expired ({expires_at}).")

# --- Strict profile: block (exit 1) on any strict-block drift OR drift7 FAIL ---
fail_count_total = 0
# Re-scan today's audit log for fail severity (drift7 emits fail above)
if os.path.exists(audit_log):
    with open(audit_log) as f:
        for line in f:
            try:
                rec = json.loads(line)
                # Only count today's fails (this run's emissions)
                if rec.get("severity") == "fail" and rec.get("timestamp", "").startswith(datetime.datetime.utcnow().strftime("%Y-%m-%d")):
                    fail_count_total += 1
            except json.JSONDecodeError:
                pass

if profile == "strict" and (strict_block_count > 0 or fail_count_total > 0):
    pathlib.Path(exit_code_file).write_text("1")
else:
    pathlib.Path(exit_code_file).write_text("0")

sys.exit(0)
PYEOF

EXIT_CODE="$(cat "$EXIT_CODE_FILE" 2>/dev/null || echo 0)"
exit "$EXIT_CODE"
