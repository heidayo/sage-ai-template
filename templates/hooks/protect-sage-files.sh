#!/usr/bin/env bash
# =============================================================================
# TASK-0037: protect-sage-files.sh
# Purpose:  PreToolUse hook (Edit|Write matcher) — protect SAGE-managed files
# Profile:  standard+ (skipped if profile is "minimal" or "none")
# Behavior: Reads JSON from stdin with tool_name and tool_input.file_path.
#           Protected: CLAUDE.md, sage/*, .sage/config.yaml, .claude/settings.json
#           If a TASK with sage-managed: true AND status In Progress / 実行中 exists, allow.
#           Otherwise block (exit 2).
#           On empty stdin or parse error: exit 0
# =============================================================================
set -euo pipefail

# --- Profile gating ---
PROFILE="standard"
if [ -f ".sage/config.yaml" ]; then
  PROFILE=$(grep -A1 'hooks:' .sage/config.yaml 2>/dev/null | grep 'profile:' | awk '{print $2}' | tr -d '"' || echo "standard")
  [ -z "$PROFILE" ] && PROFILE="standard"
fi

if [ "$PROFILE" = "minimal" ] || [ "$PROFILE" = "none" ]; then
  exit 0
fi

task_status() {
  awk -F'|' '/^\|[[:space:]]*ステータス[[:space:]]*\|/ {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3; exit}' "$1" 2>/dev/null || true
}

task_is_active() {
  local status
  status="$(task_status "$1")"
  case "$status" in
    "In Progress"|"実行中")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# --- Read stdin (JSON) ---
INPUT=""
if ! read -r -t 1 INPUT; then
  exit 0
fi

if [ -z "$INPUT" ]; then
  exit 0
fi

# --- Parse file_path and content from JSON ---
FILE_PATH=""
CONTENT=""
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
  # TASK-0104: also parse the write content for downstream hijack-pattern
  # detection. Falls back to empty when jq is unavailable; the path-only
  # check still runs in that case.
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)
else
  FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- TASK-0104 (SPEC-0011) FR-05: hijack-pattern content check ---
# These checks run BEFORE the existing path/active-task gate so the hijack
# patterns are blocked even when an active sage-managed TASK exists.
# Background: cloned-repo trust attacks (Check Point CVE-2025-59536,
# CVE-2025-61260, NVD CVE-2026-33068) inject dangerous keys into config
# files that Claude Code / Codex CLI subsequently honor at trust time.

NORM_PATH_FOR_CONTENT="${FILE_PATH#./}"

content_contains() {
  # POSIX-grep regex against the parsed CONTENT.
  [ -n "$CONTENT" ] && echo "$CONTENT" | grep -qE "$1"
}

case "$NORM_PATH_FOR_CONTENT" in
  *.claude/settings.json|.claude/settings.json)
    if content_contains '"defaultMode"[[:space:]]*:[[:space:]]*"bypassPermissions"'; then
      echo "BLOCKED: '.claude/settings.json' write contains defaultMode=bypassPermissions." >&2
      echo "Reference: NVD CVE-2026-33068 (Claude Code trust dialog bypass)" >&2
      echo "  https://nvd.nist.gov/vuln/detail/CVE-2026-33068" >&2
      exit 2
    fi
    if content_contains '"enableAllProjectMcpServers"[[:space:]]*:[[:space:]]*true'; then
      echo "BLOCKED: '.claude/settings.json' write enables enableAllProjectMcpServers=true." >&2
      echo "Reference: Backslash Security Claude Code Best Practices (auto-trust of project MCP is high risk)" >&2
      exit 2
    fi
    ;;
  *.env|.env|*.env.local|.env.local|*.env.production|.env.production)
    if content_contains '^[[:space:]]*CODEX_HOME[[:space:]]*='; then
      echo "BLOCKED: '$NORM_PATH_FOR_CONTENT' write sets CODEX_HOME, which redirects Codex CLI config search." >&2
      echo "Reference: CVE-2025-61260 (Codex CLI project-local config RCE, fixed in 0.23.0)" >&2
      echo "  https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/" >&2
      exit 2
    fi
    if content_contains '^[[:space:]]*ANTHROPIC_BASE_URL[[:space:]]*='; then
      echo "BLOCKED: '$NORM_PATH_FOR_CONTENT' write sets ANTHROPIC_BASE_URL, which redirects Claude Code API traffic." >&2
      echo "Reference: CVE-2025-59536 (Claude Code project files RCE / API token exfil)" >&2
      echo "  https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/" >&2
      exit 2
    fi
    ;;
  *.codex/config.toml|.codex/config.toml)
    if content_contains '^[[:space:]]*\[?mcp_servers\.|^[[:space:]]*mcp_servers[[:space:]]*='; then
      echo "BLOCKED: '.codex/config.toml' write defines mcp_servers — supply-chain risk per OWASP AST01-10." >&2
      echo "Reference: CVE-2025-61260 (project-local Codex config can launch unaudited MCP servers)" >&2
      echo "  https://research.checkpoint.com/2025/openai-codex-cli-command-injection-vulnerability/" >&2
      exit 2
    fi
    ;;
  *.mcp.json|.mcp.json)
    if content_contains '"mcpServers"[[:space:]]*:[[:space:]]*\{'; then
      echo "BLOCKED: '.mcp.json' write defines mcpServers — supply-chain risk per OWASP AST01-10." >&2
      echo "Reference: OWASP Agentic Skills Top 10 (AST01 Malicious Skills, AST02 Supply Chain)" >&2
      echo "  https://owasp.org/www-project-agentic-skills-top-10/" >&2
      exit 2
    fi
    ;;
esac

# --- Check if file is protected ---
IS_PROTECTED=false

# Normalize: strip leading ./ if present
NORM_PATH="${FILE_PATH#./}"

case "$NORM_PATH" in
  CLAUDE.md)
    IS_PROTECTED=true
    ;;
  sage/*)
    IS_PROTECTED=true
    ;;
  .sage/config.yaml)
    IS_PROTECTED=true
    ;;
  .claude/settings.json)
    IS_PROTECTED=true
    ;;
esac

# Also check if the path ends with these (for absolute paths)
if [ "$IS_PROTECTED" = false ]; then
  case "$FILE_PATH" in
    */CLAUDE.md)
      IS_PROTECTED=true
      ;;
    */sage/*)
      IS_PROTECTED=true
      ;;
    */.sage/config.yaml)
      IS_PROTECTED=true
      ;;
    */.claude/settings.json)
      IS_PROTECTED=true
      ;;
  esac
fi

if [ "$IS_PROTECTED" = false ]; then
  # Not a protected file — allow
  exit 0
fi

# --- Check for active sage-managed TASK ---
if [ -d "tasks" ]; then
  for task_file in tasks/*.md; do
    [ -f "$task_file" ] || continue

    # Check if task has sage-managed: true AND active status
    HAS_SAGE_MANAGED=false
    HAS_ACTIVE_STATUS=false

    if grep -q 'sage-managed:[[:space:]]*true' "$task_file" 2>/dev/null; then
      HAS_SAGE_MANAGED=true
    fi

    if task_is_active "$task_file"; then
      HAS_ACTIVE_STATUS=true
    fi

    if [ "$HAS_SAGE_MANAGED" = true ] && [ "$HAS_ACTIVE_STATUS" = true ]; then
      # Active sage-managed task found — allow edit
      exit 0
    fi
  done
fi

# --- Block: no active sage-managed task ---
echo "BLOCKED: '$NORM_PATH' is a SAGE-protected file." >&2
echo "Protected files: CLAUDE.md, sage/*, .sage/config.yaml, .claude/settings.json" >&2
echo "To modify, ensure a TASK in tasks/ has 'sage-managed: true' and status 'In Progress' (or '実行中')." >&2
exit 2
