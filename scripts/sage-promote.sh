#!/bin/bash
# sage-promote.sh — Promote a vibe/* branch to a managed promote/* branch
# SPEC-0006: Vibe Coding Lanes & Promotion Protocol
#
# Usage: bash scripts/sage-promote.sh vibe/my-feature
#
# This script:
# 1. Validates the source branch is a vibe/* branch
# 2. Creates a promote/{feature-name} branch
# 3. Generates a Retro-SPEC draft via sage-retro-spec.sh
# 4. Generates a TASK-ID for the promotion work
# 5. Prints next steps for the developer

set -euo pipefail

# --- Argument validation ---
if [ $# -lt 1 ]; then
  echo ""
  echo "  Usage: bash scripts/sage-promote.sh <vibe-branch>"
  echo "  Example: bash scripts/sage-promote.sh vibe/my-feature"
  echo ""
  exit 1
fi

SOURCE_BRANCH="$1"

# Validate source is a vibe/* branch
if [[ "$SOURCE_BRANCH" != vibe/* ]]; then
  echo ""
  echo "  ERROR: Source branch must be a vibe/* branch"
  echo "  Got: $SOURCE_BRANCH"
  echo ""
  exit 1
fi

# Extract feature name
FEATURE_NAME="${SOURCE_BRANCH#vibe/}"
PROMOTE_BRANCH="promote/$FEATURE_NAME"

echo "=== SAGE Promotion Protocol ==="
echo ""
echo "  Source:  $SOURCE_BRANCH (explore lane)"
echo "  Target:  $PROMOTE_BRANCH (promotion lane)"
echo ""

# --- Check source branch exists ---
if ! git rev-parse --verify "$SOURCE_BRANCH" > /dev/null 2>&1; then
  echo "  ERROR: Branch '$SOURCE_BRANCH' does not exist"
  exit 1
fi

SOURCE_SHA=$(git rev-parse "$SOURCE_BRANCH")

# --- Check commit count for accuracy warning ---
COMMIT_COUNT=$(git rev-list --count main.."$SOURCE_BRANCH" 2>/dev/null || echo "0")
echo "  Commits to promote: $COMMIT_COUNT"

# Read threshold from config (default 50)
MAX_COMMITS=50
if [ -f .sage/config.yaml ]; then
  CONFIG_MAX=$(grep "promotion_max_commits:" .sage/config.yaml 2>/dev/null | awk '{print $2}' || echo "")
  if [ -n "$CONFIG_MAX" ]; then
    MAX_COMMITS="$CONFIG_MAX"
  fi
fi

if [ "$COMMIT_COUNT" -gt "$MAX_COMMITS" ]; then
  echo ""
  echo "  WARNING: $COMMIT_COUNT commits exceeds threshold ($MAX_COMMITS)"
  echo "  Retro-SPEC accuracy may be low. Consider writing SPEC manually."
  echo ""
  # Non-interactive mode (e.g., Claude Code desktop/browser): continue with warning
  # Interactive mode (terminal): prompt for confirmation
  if [ -t 0 ]; then
    read -p "  Continue anyway? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "  Aborted."
      exit 0
    fi
  else
    echo "  Non-interactive mode: continuing with warning."
    echo "  Review the generated Retro-SPEC carefully for accuracy."
  fi
fi

# --- Create promote branch ---
echo ""
echo "[1/4] Creating promote branch..."
if git rev-parse --verify "$PROMOTE_BRANCH" > /dev/null 2>&1; then
  echo "  Branch '$PROMOTE_BRANCH' already exists. Checking it out."
  git checkout "$PROMOTE_BRANCH"
else
  git checkout -b "$PROMOTE_BRANCH" "$SOURCE_BRANCH"
  echo "  Created: $PROMOTE_BRANCH"
fi

# --- Generate Retro-SPEC ---
echo ""
echo "[2/4] Generating Retro-SPEC draft..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/sage-retro-spec.sh" ]; then
  SAGE_PROMOTION_SOURCE_BRANCH="$SOURCE_BRANCH" \
  SAGE_PROMOTION_SOURCE_SHA="$SOURCE_SHA" \
    bash "$SCRIPT_DIR/sage-retro-spec.sh" "$PROMOTE_BRANCH"
else
  echo "  WARNING: sage-retro-spec.sh not found. Skipping Retro-SPEC generation."
  echo "  Please create a SPEC manually in specs/"
fi

# --- Generate TASK-ID ---
echo ""
echo "[3/4] Generating TASK-ID..."
if [ -f "$SCRIPT_DIR/sage-id-gen.sh" ]; then
  TASK_ID=$(bash "$SCRIPT_DIR/sage-id-gen.sh" task 2>/dev/null || echo "TASK-XXXX")
  echo "  Assigned: $TASK_ID"
else
  TASK_ID="TASK-XXXX"
  echo "  WARNING: sage-id-gen.sh not found. Please assign TASK-ID manually."
fi

# --- Print next steps ---
echo ""
echo "[4/4] Promotion setup complete!"
echo ""
echo "=== Next Steps ==="
echo ""
echo "  1. Review the Retro-SPEC draft in specs/"
echo "     - Fill in any TBD sections"
echo "     - Verify acceptance criteria are testable"
echo "     - Get human approval"
echo ""
echo "  2. Add tests for the promoted code"
echo ""
echo "  3. Commit with TASK-ID: $TASK_ID"
echo "     Example: git commit -m \"$TASK_ID: promote $FEATURE_NAME with Retro-SPEC\""
echo ""
echo "  4. Run quality gates:"
echo "     bash scripts/sage-validate.sh"
echo ""
echo "  5. Create PR from $PROMOTE_BRANCH → main"
echo "     Include SPEC-ID, PLAN-ID, $TASK_ID in PR body"
echo ""
echo "=== End Promotion Protocol ==="
