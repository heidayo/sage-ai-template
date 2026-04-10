#!/bin/bash
# sage-repair.sh — SAGE File Repair (TASK-0049)
# Reads install-state.yaml, finds MISSING/MISMATCH managed files, repairs them
set -euo pipefail

# --- Refuse root ---
if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR: sage-repair.sh must not be run as root."
  exit 1
fi

# --- Options ---
DRY_RUN=false
AUTO_YES=false
TARGET_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --yes) AUTO_YES=true; shift ;;
    --file) TARGET_FILE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Prereq ---
INSTALL_STATE=".sage/install-state.yaml"
if [ ! -f "$INSTALL_STATE" ]; then
  echo "ERROR: install-state.yaml not found. Run 'bash install.sh' first."
  exit 1
fi

# --- Cross-platform SHA256 ---
sha256_hash() {
  local file="$1"
  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "ERROR: No SHA256 tool found" >&2
    exit 1
  fi
}

# --- Backup ---
backup_file() {
  local file="$1"
  if [ ! -f "$file" ]; then return; fi
  local backup_dir=".sage/backup"
  mkdir -p "$backup_dir"
  local timestamp
  timestamp=$(date +%Y%m%d%H%M%S)
  local backup_path="${backup_dir}/$(basename "$file").${timestamp}.bak"
  cp "$file" "$backup_path"
  echo "  Backed up: $file -> $backup_path"
}

# --- Confirm ---
confirm_action() {
  local message="$1"
  if [ "$AUTO_YES" = true ]; then return 0; fi
  if [ "$DRY_RUN" = true ]; then return 0; fi
  printf "  %s [y/N] " "$message"
  read -r response
  case "$response" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Parse install-state.yaml and find broken files ---
REPAIR_COUNT=0
SKIP_COUNT=0
NEEDS_INSTALL_UPDATE=false

IN_FILES=false
CURRENT_PATH=""
CURRENT_MANAGED=""
CURRENT_SHA256=""

attempt_repair() {
  if [ -z "$CURRENT_PATH" ]; then return; fi
  if [ "$CURRENT_MANAGED" != "true" ]; then return; fi

  # Filter by --file if specified
  if [ -n "$TARGET_FILE" ] && [ "$CURRENT_PATH" != "$TARGET_FILE" ]; then return; fi

  local needs_repair=false
  local reason=""

  if [ ! -f "$CURRENT_PATH" ]; then
    needs_repair=true
    reason="MISSING"
  elif [ -n "$CURRENT_SHA256" ]; then
    local actual_hash
    actual_hash=$(sha256_hash "$CURRENT_PATH")
    if [ "$actual_hash" != "$CURRENT_SHA256" ]; then
      needs_repair=true
      reason="MISMATCH"
    fi
  fi

  if [ "$needs_repair" = false ]; then return; fi

  echo "  $reason: $CURRENT_PATH"

  if [ "$DRY_RUN" = true ]; then
    echo "    [dry-run] Would repair $CURRENT_PATH"
    REPAIR_COUNT=$((REPAIR_COUNT + 1))
    return
  fi

  if confirm_action "Repair $CURRENT_PATH?"; then
    backup_file "$CURRENT_PATH"
    REPAIR_COUNT=$((REPAIR_COUNT + 1))
    NEEDS_INSTALL_UPDATE=true
  else
    echo "    Skipped"
    SKIP_COUNT=$((SKIP_COUNT + 1))
  fi
}

echo "=== SAGE Repair ==="
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "Mode: dry-run (no changes will be made)"
  echo ""
fi

echo "Scanning for files needing repair..."

while IFS= read -r line; do
  if echo "$line" | grep -qE '^files:'; then
    IN_FILES=true
    continue
  fi
  if [ "$IN_FILES" = true ] && echo "$line" | grep -qE '^[^ ]' && [ -n "$line" ]; then
    attempt_repair
    IN_FILES=false
    continue
  fi
  if [ "$IN_FILES" = false ]; then continue; fi

  if echo "$line" | grep -qE '^[[:space:]]*- path:'; then
    attempt_repair
    CURRENT_PATH=$(echo "$line" | sed 's/.*- path:[[:space:]]*//' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//')
    CURRENT_MANAGED=""
    CURRENT_SHA256=""
  elif echo "$line" | grep -qE '^[[:space:]]*managed:'; then
    CURRENT_MANAGED=$(echo "$line" | sed 's/.*managed:[[:space:]]*//' | tr -d ' ')
  elif echo "$line" | grep -qE '^[[:space:]]*sha256:'; then
    CURRENT_SHA256=$(echo "$line" | sed 's/.*sha256:[[:space:]]*//' | tr -d ' "'"'"'')
  fi
done < "$INSTALL_STATE"
# Process last entry
attempt_repair

# Run install.sh --update once if any files need repair
if [ "$NEEDS_INSTALL_UPDATE" = true ] && [ "$DRY_RUN" = false ]; then
  echo ""
  echo "Running install.sh to restore files..."
  if [ -f "install.sh" ]; then
    # Remove version file to force install.sh to run in update mode
    SAVED_VERSION=""
    if [ -f ".sage/version" ]; then
      SAVED_VERSION=$(cat .sage/version)
      rm -f .sage/version
    fi
    bash install.sh --update 2>&1 | grep -E "(CREATE|UPDATE|OK)" || true
    # Restore version
    if [ -n "$SAVED_VERSION" ]; then
      echo "$SAVED_VERSION" > .sage/version
    fi
    echo "  Repair complete."
  else
    echo "  WARN: install.sh not found. Cannot auto-repair. Please re-run installer."
  fi
fi

echo ""
if [ "$DRY_RUN" = true ]; then
  echo "=== Dry Run Complete: $REPAIR_COUNT file(s) would be repaired ==="
else
  echo "=== SAGE Repair: $REPAIR_COUNT repaired, $SKIP_COUNT skipped ==="
fi
