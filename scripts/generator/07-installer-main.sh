# shellcheck shell=bash
# --- メインロジックを埋め込む ---
cat <<'MAIN_LOGIC'
# === Main Logic ===

SAGE_START_MARKER="<!-- === SAGE Development System (auto-injected) === -->"
SAGE_END_MARKER="<!-- === End SAGE === -->"

show_version() {
  echo "SAGE Development System v${SAGE_VERSION}"
}

check_installed_version() {
  if [ -f ".sage/version" ]; then
    cat ".sage/version"
  else
    echo ""
  fi
}

# --- SPEC-0025: local overlay exclusion ---
# Directories the installer never creates, overwrites, deletes, or
# checksum-verifies. Declared in .sage/install-state.yaml as
# unmanaged_paths — the declaration is informational only and is NOT
# interpreted as a write allowlist (SEC-02).
UNMANAGED_PATHS=".claude/rules/local .codex/rules/local"

# Single source of truth for overlay exclusion (INV-03). All installer
# code paths reference this function instead of duplicating the check.
is_unmanaged_path() {
  local target="${1#./}"
  local p
  for p in $UNMANAGED_PATHS; do
    case "$target" in
      "$p"|"$p"/*) return 0 ;;
    esac
  done
  return 1
}

# PRE-02: if an overlay path exists as a non-directory or symlink,
# warn and leave it untouched (never an error — AC-08).
warn_unmanaged_anomalies() {
  local p
  for p in $UNMANAGED_PATHS; do
    if [ -L "$p" ]; then
      echo "  WARN: $p is a symlink; installer will not follow or touch it (SPEC-0025)"
    elif [ -e "$p" ] && [ ! -d "$p" ]; then
      echo "  WARN: $p exists but is not a directory; installer will not touch it (SPEC-0025)"
    fi
  done
}

# --- SPEC-0010 / TASK-0097: provenance and integrity verification ---
_sha256_cmd() {
  if command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum"
  elif command -v shasum >/dev/null 2>&1; then
    echo "shasum -a 256"
  else
    echo ""
  fi
}

do_print_provenance() {
  local sha_cmd
  sha_cmd=$(_sha256_cmd)
  local sha
  if [ -n "$sha_cmd" ]; then
    sha=$($sha_cmd "$0" 2>/dev/null | awk '{print $1}')
  else
    sha="unavailable (no sha256sum/shasum)"
  fi
  # TASK-0112 (Codex review bonus): compute size dynamically from $0
  # rather than hardcoding ~213KB. The installer keeps growing across
  # phases (Phase 1: 213KB, Phase 2A: 235KB, Phase 2B: 262KB) and a
  # stale label undermines provenance trust.
  local size_bytes size_kb
  size_bytes=$(wc -c < "$0" 2>/dev/null | tr -d ' ' || echo 0)
  size_kb=$(( size_bytes / 1024 ))
  cat <<EOF
SAGE Development System — Installer Provenance
==============================================
SAGE_VERSION:     ${SAGE_VERSION}
Installer SHA256: ${sha}
Installer size:   ${size_bytes} bytes (~${size_kb}KB)
Source:           https://github.com/heidayo/sage-ai-template
License:          Apache-2.0 (see LICENSE)
Generated:        $(date -u '+%Y-%m-%dT%H:%M:%SZ')

This installer is a self-contained shell script.
It writes templates, hooks, scripts, and CI workflows under the
current directory. Run with --dry-run to preview without writing.
Run with --verify-checksum after install to detect drift against
.sage/install-state.yaml.

Template-trust note: cloned project files (.claude/settings.json,
.mcp.json, AGENTS.md, CLAUDE.md, templates/hooks/) influence AI
agent behavior. See SECURITY.md and sage/governance.md §9 (Scope
Boundary) before adoption.
EOF
}

do_verify_checksum() {
  local state_file=".sage/install-state.yaml"
  if [ ! -f "$state_file" ]; then
    echo "ERROR: state file not found at $state_file."
    echo "       Cannot verify integrity. Either:"
    echo "         (a) Run 'bash $0' to install (and generate state), then re-run --verify-checksum, or"
    echo "         (b) You are running --verify-checksum from a directory where SAGE is not installed."
    echo "       Treating absence as verification failure (rc=2) per SPEC-0010 / TASK-0100 (Codex review P2 #3)."
    return 2
  fi
  local sha_cmd
  sha_cmd=$(_sha256_cmd)
  if [ -z "$sha_cmd" ]; then
    echo "ERROR: sha256sum/shasum not found, cannot verify."
    return 1
  fi
  local drift=0 missing=0 checked=0 invalid=0
  local current_path="" current_sha=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*path:[[:space:]]*\"(.*)\"[[:space:]]*$ ]]; then
      current_path="${BASH_REMATCH[1]}"
      # Reject suspicious paths early (P3 #5: option-like / absolute / parent-traversal).
      case "$current_path" in
        -*|/*|*..*)
          echo "INVALID-PATH: $current_path (rejected by allowlist)"
          invalid=$((invalid + 1))
          current_path=""
          continue
          ;;
      esac
      # SPEC-0025 FR-03: overlay paths are outside checksum verification scope.
      if is_unmanaged_path "$current_path"; then
        current_path=""
        continue
      fi
    elif [[ "$line" =~ ^[[:space:]]*sha256:[[:space:]]*\"(.*)\"[[:space:]]*$ ]]; then
      current_sha="${BASH_REMATCH[1]}"
      if [ -n "$current_path" ] && [ -f "$current_path" ]; then
        # Use -- to terminate options so paths cannot be misinterpreted (P3 #5).
        local actual
        actual=$($sha_cmd -- "$current_path" 2>/dev/null | awk '{print $1}')
        checked=$((checked + 1))
        if [ "$actual" != "$current_sha" ]; then
          echo "DRIFT:   $current_path"
          echo "  recorded: $current_sha"
          echo "  actual:   $actual"
          drift=$((drift + 1))
        fi
      elif [ -n "$current_path" ]; then
        echo "MISSING: $current_path"
        missing=$((missing + 1))
      fi
      current_path=""; current_sha=""
    fi
  done < "$state_file"
  echo ""
  echo "Verified: ${checked} files. Drift: ${drift}. Missing: ${missing}. Invalid-path: ${invalid}."
  if [ "$drift" -gt 0 ] || [ "$missing" -gt 0 ] || [ "$invalid" -gt 0 ]; then
    return 1
  fi
  return 0
}

# SPEC-0018 FR-05: --verify-checksum --remote
# Compare the local installer's SHA256 against the release-published SHA256SUMS.
# Network unavailable => warn + return 0 (graceful, EC-04).
# SHA256SUMS format invalid or mismatch => return 1.
do_verify_checksum_remote() {
  local sha_cmd
  sha_cmd=$(_sha256_cmd)
  if [ -z "$sha_cmd" ]; then
    echo "ERROR: sha256sum/shasum not found, cannot verify."
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl not found, cannot fetch remote SHA256SUMS."
    return 1
  fi

  local installer_path="${0}"
  if [ ! -f "$installer_path" ]; then
    echo "ERROR: cannot locate installer at $installer_path (run via 'bash install.sh' from a saved file, not piped via curl)."
    return 1
  fi

  local remote_url="https://github.com/heidayo/sage-ai-template/releases/latest/download/SHA256SUMS"
  local remote_sums
  if ! remote_sums=$(curl -fsSL --max-time 10 "$remote_url" 2>/dev/null); then
    echo "WARN: remote SHA256SUMS fetch failed; verification skipped (offline or release unavailable)" >&2
    echo "      URL: $remote_url" >&2
    return 0
  fi
  if [ -z "$remote_sums" ]; then
    echo "WARN: remote SHA256SUMS fetched empty content; verification skipped" >&2
    return 0
  fi

  # FR-02 + EC-05: validate format. Each line must be '<64-hex-sha256>  <filename>'.
  if ! printf '%s\n' "$remote_sums" | grep -Eq '^[0-9a-f]{64}  install\.sh$'; then
    echo "FAIL: SHA256SUMS line format invalid (expected '<sha256>  install.sh')"
    echo "  fetched content (first 5 lines):"
    printf '%s\n' "$remote_sums" | head -5 | sed 's/^/    /'
    return 1
  fi

  local expected_sha
  expected_sha=$(printf '%s\n' "$remote_sums" | awk '$2=="install.sh" {print $1; exit}')
  local actual_sha
  actual_sha=$($sha_cmd -- "$installer_path" 2>/dev/null | awk '{print $1}')

  if [ "$expected_sha" = "$actual_sha" ]; then
    echo "OK: install.sh matches release SHA256SUMS"
    echo "  sha256: $actual_sha"
    echo "  source: $remote_url"
    return 0
  else
    echo "FAIL: remote SHA256 mismatch"
    echo "  expected (from release): $expected_sha"
    echo "  actual   (local file):   $actual_sha"
    echo "  source:                  $remote_url"
    return 1
  fi
}

# --- SPEC-0026: pre-write backup (backup_before_write) ---
# INV-04: backup judgment + execution live in this single function; every
# write path that can change an existing file must call it before writing.
BACKUP_ROOT=".sage/backup"
BACKUP_GEN_DIR=""

# FR-02 / SEC-01: keep the newest 3 generations. Only directories whose
# name matches ^[0-9]{8}-[0-9]{6}(-[0-9]+)?$ are rotation candidates;
# anything else under .sage/backup/ is preserved (AC-11).
_backup_rotate_generations() {
  local dirs count oldest
  dirs=$(ls -1 "$BACKUP_ROOT" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}(-[0-9]+)?$' | sort || true)
  count=$(printf '%s' "$dirs" | grep -c . || true)
  while [ "$count" -gt 3 ]; do
    oldest=$(printf '%s\n' "$dirs" | head -1)
    [ -n "$oldest" ] || break
    rm -rf "${BACKUP_ROOT:?}/${oldest:?}"
    echo "  BACKUP-ROTATE: removed oldest generation $BACKUP_ROOT/$oldest"
    dirs=$(printf '%s\n' "$dirs" | tail -n +2)
    count=$((count - 1))
  done
}

# FR-01: create the generation directory lazily — only when the first
# actual UPDATE backup happens (no empty generations). On timestamp
# collision, append -N instead of reusing an existing generation (AC-12).
_backup_ensure_gen_dir() {
  if [ -n "$BACKUP_GEN_DIR" ]; then
    return 0
  fi
  local ts candidate n
  ts=$(date -u +%Y%m%d-%H%M%S)
  candidate="$ts"
  n=0
  while [ -e "$BACKUP_ROOT/$candidate" ]; do
    n=$((n + 1))
    candidate="$ts-$n"
  done
  if ! mkdir -p "$BACKUP_ROOT/$candidate" 2>/dev/null; then
    return 1
  fi
  BACKUP_GEN_DIR="$BACKUP_ROOT/$candidate"
  _backup_rotate_generations
  return 0
}

# backup_before_write <path> [<new_content>]
# PRE-01: back up only when the file exists AND the content will change
# (when <new_content> is given; without it, the caller has already
# determined the file will change). SEC-03: print paths only, never
# file contents. AC-09 fail-safe: if the backup cannot be written,
# abort the installer (non-zero exit) without touching the target file.
backup_before_write() {
  local path="$1"
  if [ "${DRY_RUN:-false}" = "true" ]; then
    return 0
  fi
  if [ ! -f "$path" ]; then
    return 0  # CREATE, not UPDATE — nothing to back up
  fi
  if is_unmanaged_path "$path"; then
    return 0  # SPEC-0025: overlay paths are never written, never backed up
  fi
  if [ "$#" -ge 2 ] && [ "$(cat "$path")" = "$2" ]; then
    return 0  # content unchanged — not an UPDATE
  fi
  if ! _backup_ensure_gen_dir; then
    echo "ERROR: cannot create backup directory under $BACKUP_ROOT — aborting without overwriting $path (fail-safe, SPEC-0026)" >&2
    exit 1
  fi
  local dest="$BACKUP_GEN_DIR/$path"
  if ! mkdir -p "$(dirname "$dest")" 2>/dev/null || ! cp "$path" "$dest" 2>/dev/null; then
    echo "ERROR: backup of $path to $dest failed — aborting without overwriting (fail-safe, SPEC-0026)" >&2
    exit 1
  fi
  echo "  BACKUP: $dest"
}

write_file_if_new() {
  local path="$1"
  local content="$2"
  local dir
  dir=$(dirname "$path")
  # SPEC-0025 FR-01 / PRE-01: never write under overlay paths.
  if is_unmanaged_path "$path"; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      echo "  WOULD-SKIP:   $path (unmanaged overlay path, SPEC-0025)"
    else
      echo "  SKIP: $path (unmanaged overlay path, SPEC-0025)"
    fi
    return 0
  fi
  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ -f "$path" ]; then
      echo "  WOULD-SKIP:   $path (already exists)"
    else
      echo "  WOULD-CREATE: $path"
    fi
    return 0
  fi
  mkdir -p "$dir"

  if [ -f "$path" ]; then
    echo "  SKIP: $path (already exists)"
    return 0
  else
    echo "$content" > "$path"
    echo "  CREATE: $path"
    return 0
  fi
}

update_file() {
  local path="$1"
  local content="$2"
  local dir
  dir=$(dirname "$path")
  # SPEC-0025 FR-01 / PRE-01: never write under overlay paths.
  if is_unmanaged_path "$path"; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      echo "  WOULD-SKIP:   $path (unmanaged overlay path, SPEC-0025)"
    else
      echo "  SKIP: $path (unmanaged overlay path, SPEC-0025)"
    fi
    return 0
  fi
  # SPEC-0026 FR-03: in diff mode show the unified diff for UPDATE targets
  # (existing file whose content would change) and write nothing.
  if [ "${DIFF_MODE:-false}" = "true" ]; then
    if [ -f "$path" ] && [ "$(cat "$path")" != "$content" ]; then
      echo "  DIFF: $path"
      printf '%s\n' "$content" | diff -u -L "$path (current)" -L "$path (new)" "$path" - || true
    fi
    return 0
  fi
  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo "  WOULD-UPDATE: $path"
    return 0
  fi
  mkdir -p "$dir"
  # SPEC-0026 INV-02: never overwrite an existing file without a backup.
  backup_before_write "$path" "$content"
  echo "$content" > "$path"
  echo "  UPDATE: $path"
}

upsert_sage_section() {
  local file="$1"
  local snippet="$2"

  # SPEC-0026 FR-05 / PRE-03: check marker consistency before any edit.
  # A file with only one of the two markers is treated as damaged: editing
  # it (replace or append) risks destroying user content, so skip it
  # entirely (no change, no append), WARN, and keep the installer going.
  local has_start=false has_end=false
  if [ -f "$file" ]; then
    grep -qF "$SAGE_START_MARKER" "$file" 2>/dev/null && has_start=true
    grep -qF "$SAGE_END_MARKER" "$file" 2>/dev/null && has_end=true
  fi
  if [ "$has_start" != "$has_end" ]; then
    echo "  WARN: $file has only one SAGE marker (start: $has_start / end: $has_end) — skipped without changes to avoid losing customizations (SPEC-0026)." >&2
    echo "        Repair the markers manually, then re-run: see docs/installer-preservation.md" >&2
    return 0
  fi

  if [ "${DRY_RUN:-false}" = "true" ] && [ "${DIFF_MODE:-false}" != "true" ]; then
    if [ ! -f "$file" ]; then
      echo "  WOULD-CREATE: $file"
    elif [ "$has_start" = "true" ]; then
      echo "  WOULD-UPDATE: $file (SAGE section)"
    else
      echo "  WOULD-APPEND: $file (SAGE section)"
    fi
    return 0
  fi

  if [ ! -f "$file" ]; then
    if [ "${DIFF_MODE:-false}" = "true" ]; then
      echo "  WOULD-CREATE: $file"
      return 0
    fi
    echo "$snippet" > "$file"
    echo "  CREATE: $file"
    return
  fi

  # Build the expected post-upsert content in a temp file. It is used for
  # the real write (mv), the pre-write backup comparison (TASK-0178) and
  # the --diff preview (SPEC-0026 FR-04: the diff is taken against this
  # expected content, so any change outside the markers shows up too).
  local tmp_result=$(mktemp)
  if [ "$has_start" = "true" ]; then
    # SAGEセクションが既にある → マーカー間を置換
    local tmp_before=$(mktemp)
    local tmp_after=$(mktemp)

    # マーカーの行番号を取得
    local start_line=$(grep -nF "$SAGE_START_MARKER" "$file" | head -1 | cut -d: -f1)
    local end_line=$(grep -nF "$SAGE_END_MARKER" "$file" | tail -1 | cut -d: -f1)

    # マーカー前の部分
    if [ "$start_line" -gt 1 ]; then
      sed -n "1,$((start_line - 1))p" "$file" > "$tmp_before"
    else
      : > "$tmp_before"
    fi

    # マーカー後の部分
    local total_lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$end_line" -lt "$total_lines" ]; then
      sed -n "$((end_line + 1)),\$p" "$file" > "$tmp_after"
    else
      : > "$tmp_after"
    fi

    # 結合: before + new snippet + after
    cat "$tmp_before" > "$tmp_result"
    echo "$snippet" >> "$tmp_result"
    cat "$tmp_after" >> "$tmp_result"
    rm -f "$tmp_before" "$tmp_after"
  else
    # マーカーなし → 末尾 append (既存行は不変)
    cat "$file" > "$tmp_result"
    echo "" >> "$tmp_result"
    echo "$snippet" >> "$tmp_result"
  fi

  if [ "${DIFF_MODE:-false}" = "true" ]; then
    if ! cmp -s "$file" "$tmp_result"; then
      echo "  DIFF: $file"
      diff -u -L "$file (current)" -L "$file (new)" "$file" "$tmp_result" || true
    fi
    rm -f "$tmp_result"
    return 0
  fi

  if [ "$has_start" = "true" ]; then
    # SPEC-0026 INV-02: back up before replacing the SAGE section
    # (skipped inside backup_before_write when content is unchanged).
    backup_before_write "$file" "$(cat "$tmp_result")"
    mv "$tmp_result" "$file"
    echo "  UPDATE: $file (SAGE section replaced)"
  else
    # SPEC-0026 INV-02: appending changes the file — back it up first.
    backup_before_write "$file"
    mv "$tmp_result" "$file"
    echo "  APPEND: $file (SAGE section added)"
  fi
}

setup_commit_hook() {
  if [ ! -d .git ]; then
    echo "  SKIP: not a git repository"
    return
  fi

  local hook_dir=".git/hooks"
  if [ -d .husky ]; then
    hook_dir=".husky"
  fi

  local hook_file="$hook_dir/commit-msg"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ -f "$hook_file" ] && grep -qF "SAGE" "$hook_file" 2>/dev/null; then
      echo "  WOULD-SKIP:   $hook_file (SAGE hook already present)"
    elif [ -f "$hook_file" ]; then
      echo "  WOULD-APPEND: $hook_file"
    else
      echo "  WOULD-CREATE: $hook_file"
    fi
    return
  fi

  if [ -f "$hook_file" ] && grep -qF "SAGE" "$hook_file"; then
    echo "  SKIP: $hook_file (SAGE hook already present)"
  elif [ -f "$hook_file" ]; then
    # SPEC-0026 INV-02: appending changes the file — back it up first.
    backup_before_write "$hook_file"
    echo "" >> "$hook_file"
    echo "# --- SAGE: TASK-ID check ---" >> "$hook_file"
    echo "$TMPL_COMMIT_HOOK" >> "$hook_file"
    echo "  APPEND: $hook_file"
  else
    mkdir -p "$hook_dir"
    echo "$TMPL_COMMIT_HOOK" > "$hook_file"
    chmod +x "$hook_file"
    echo "  CREATE: $hook_file"
  fi
}

audit_existing_claude_md() {
  local file="$1"
  local report=".sage/adoption-audit.md"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo "  WOULD-WRITE: $report (adoption audit for existing CLAUDE.md)"
    return
  fi

  # SPEC-0026 INV-02: back up a previous audit report before regenerating.
  backup_before_write "$report"
  echo "# SAGE Adoption Audit" > "$report"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$report"
  echo "" >> "$report"

  local rules=$(grep -E "^[\t ]*[-*]" "$file" | grep -v "^#" | grep -v '^\s*$')

  echo "## Analysis" >> "$report"
  echo "" >> "$report"

  echo "### SAFE_AUTO_APPLY" >> "$report"
  echo "These rules do not conflict with SAGE. No action needed." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && ! echo "$line" | grep -qiE "commit|task|spec|todo|fixme|test|scope|review"; then
      echo "- $line" >> "$report"
    fi
  done
  echo "" >> "$report"

  echo "### NEEDS_REVIEW" >> "$report"
  echo "These rules may overlap with SAGE. Review recommended." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && echo "$line" | grep -qiE "spec|scope|review|test|coverage"; then
      if ! echo "$line" | grep -qiE "commit.*id|task.*id|no commit|skip test"; then
        echo "- $line" >> "$report"
      fi
    fi
  done
  echo "" >> "$report"

  echo "### CONFLICT" >> "$report"
  echo "These rules may conflict with SAGE. Do NOT auto-merge." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && echo "$line" | grep -qiE "commit.*message|commit.*format|task.*id|ticket.*id|todo.*ok|fixme.*allow|skip.*test"; then
      echo "- $line (conflicts with SAGE commit/test rules)" >> "$report"
    fi
  done
  echo "" >> "$report"

  echo "## Recommendation" >> "$report"
  echo "- SAFE_AUTO_APPLY items: no action needed" >> "$report"
  echo "- NEEDS_REVIEW items: check if your project rules and SAGE rules overlap. Remove duplicates." >> "$report"
  echo "- CONFLICT items: resolve manually before relying on SAGE enforcement." >> "$report"

  echo "  AUDIT: Report written to $report"
}

setup_gitignore() {
  # Note: .sage/runs/ is intentionally NOT added to .gitignore — RUN logs
  # are SAGE's audit trail and must be tracked. Only .sage/metrics/ (raw
  # numeric counters) is ignored. See TASK-0100 / Codex review P1 #1.
  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ ! -f .gitignore ]; then
      echo "  WOULD-CREATE: .gitignore (with .sage/metrics/ and .sage/backup/)"
    else
      grep -qxF '.sage/metrics/' .gitignore 2>/dev/null || echo "  WOULD-APPEND: .gitignore += .sage/metrics/"
      grep -qxF '.sage/backup/' .gitignore 2>/dev/null || echo "  WOULD-APPEND: .gitignore += .sage/backup/"
    fi
    return
  fi
  if [ ! -f .gitignore ]; then
    printf '%s\n' '.sage/metrics/' '.sage/backup/' > .gitignore
  else
    if ! grep -qxF '.sage/metrics/' .gitignore 2>/dev/null; then
      # SPEC-0026 INV-02: appending changes an existing file — back it up first.
      backup_before_write .gitignore
      echo '.sage/metrics/' >> .gitignore
    fi
    # SPEC-0026 FR-09: keep backup snapshots out of the destination repo's history.
    if ! grep -qxF '.sage/backup/' .gitignore 2>/dev/null; then
      backup_before_write .gitignore
      echo '.sage/backup/' >> .gitignore
    fi
  fi
  echo "  OK"
}

# --- Parse arguments ---
MODE="install"
DRY_RUN=false
# SPEC-0026 FR-03: --diff shows unified diffs of UPDATE targets, writes nothing.
DIFF_MODE=false
# SPEC-0018: --remote modifier for --verify-checksum (pre-scan to allow flag in any order)
REMOTE_VERIFY=false
for arg in "$@"; do
  if [ "$arg" = "--remote" ]; then REMOTE_VERIFY=true; fi
done
# SPEC-0028: --stack <name> takes a value, so it is pre-scanned (the main case
# loop below iterates single args). The value is only ever compared against the
# allowlist — it is never used as a path or command (SEC-01/INV-03).
STACK_FLAG=false
STACK_OPT=""
_stack_expect=false
for arg in "$@"; do
  if [ "$_stack_expect" = "true" ]; then
    STACK_OPT="$arg"
    _stack_expect=false
    continue
  fi
  if [ "$arg" = "--stack" ]; then
    STACK_FLAG=true
    _stack_expect=true
  fi
done
for arg in "$@"; do
  case "$arg" in
    --update) MODE="update" ;;
    --version) show_version; exit 0 ;;
    --print-provenance) do_print_provenance; exit 0 ;;
    --verify-checksum)
      if [ "$REMOTE_VERIFY" = "true" ]; then
        do_verify_checksum_remote; exit $?
      else
        do_verify_checksum; exit $?
      fi
      ;;
    --remote) ;;  # SPEC-0018: pre-scanned above, no-op here
    --stack) ;;   # SPEC-0028: pre-scanned above (value validated after this loop)
    --dry-run) DRY_RUN=true ;;
    --diff) DIFF_MODE=true ;;
    --help)
      cat <<HELP_EOF
Usage: bash install.sh [OPTIONS]

  (no args)              First-time installation (auto-updates if installed)
  --update               Force update mode
  --version              Show SAGE version
  --dry-run              Preview without writing any files (SPEC-0010)
  --stack <name>         Apply a project_checks stack preset on NEW install only
                         (go | ts-pnpm | node-npm | python). Existing
                         .sage/config.yaml is never modified (SPEC-0028)
  --diff                 Show unified diffs of files that would be updated,
                         without writing any files (SPEC-0026)
  --verify-checksum      Verify installed files against .sage/install-state.yaml
  --verify-checksum --remote
                         Verify the local installer against the GitHub Release
                         SHA256SUMS (SPEC-0018). Network unavailable => warn + exit 0.
  --print-provenance     Print installer SHA256, version, and license info
  --help                 Show this help

License: Apache-2.0 (see LICENSE)
Source:  https://github.com/heidayo/sage-ai-template
Trust:   See SECURITY.md and sage/governance.md §9 (Scope Boundary)
HELP_EOF
      exit 0
      ;;
  esac
done

# SPEC-0028 FR-03/SEC-01: --stack accepts allowlist values only, by exact
# string comparison. Unknown values fail before any file is written (AC-07).
if [ "$STACK_FLAG" = "true" ]; then
  case "$STACK_OPT" in
    go|ts-pnpm|node-npm|python) ;;
    *)
      {
        echo "ERROR: unknown --stack value: '${STACK_OPT}'"
        echo ""
        echo "Usage: bash $0 [--stack go|ts-pnpm|node-npm|python] [--dry-run] [OPTIONS]"
        echo "  Allowed stacks: go, ts-pnpm, node-npm, python (SPEC-0028)"
        echo "  See 'bash $0 --help' for all options."
      } >&2
      exit 1
      ;;
  esac
fi

# SPEC-0026 PRE-02: --diff piggybacks on the dry-run write suppression so
# no code path can create, modify, or delete files (POST-02). Backups are
# not taken either (nothing is written).
if [ "$DIFF_MODE" = "true" ]; then
  DRY_RUN=true
  echo "========================================="
  echo "  SAGE v${SAGE_VERSION} — DIFF PREVIEW (no writes will occur)"
  echo "========================================="
  echo ""
  chmod() { return 0; }
# Announce dry-run mode prominently
elif [ "$DRY_RUN" = "true" ]; then
  echo "========================================="
  echo "  SAGE v${SAGE_VERSION} — DRY RUN (no writes will occur)"
  echo "========================================="
  echo ""
  # Override chmod as no-op so chained "write_file_if_new && chmod +x" stays safe
  # (the file is not created in dry-run, so chmod would fail under set -e).
  chmod() { return 0; }
fi

INSTALLED_VERSION=$(check_installed_version)

# SPEC-0025 PRE-02 / AC-08: report anomalous overlay paths before any write
# and before the "already at version" early exit, so the WARN is emitted on
# every invocation regardless of install/update/no-op mode.
warn_unmanaged_anomalies

# Auto-detect: if already installed, switch to update mode
if [ -n "$INSTALLED_VERSION" ] && [ "$MODE" = "install" ]; then
  echo "SAGE v${INSTALLED_VERSION} is already installed."
  echo "Updating to v${SAGE_VERSION}..."
  echo ""
  MODE="update"
fi

# SPEC-0026 FR-03: --diff always evaluates the diff, even at the same
# version — local drift against the templates is exactly what it must show.
if [ "$MODE" = "update" ] && [ "$INSTALLED_VERSION" = "$SAGE_VERSION" ] && [ "$DIFF_MODE" != "true" ]; then
  echo "Already at v${SAGE_VERSION}. No update needed."
  exit 0
fi

# --- SPEC-0028: stack preset resolution ---
# A preset is selected only while .sage/config.yaml does not exist (FR-02/FR-06
# preserve-if-exists). Auto-detection checks marker file existence only — file
# contents are never read or copied into config.yaml (PRE-02/SEC-02). The
# selected body is one of the embedded static preset strings (INV-04).
STACK_NAME=""
STACK_PRESET_BODY=""
if [ -f ".sage/config.yaml" ]; then
  if [ "$STACK_FLAG" = "true" ]; then
    echo "INFO: existing .sage/config.yaml found — --stack ${STACK_OPT} is not applied (preserve-if-exists, SPEC-0028)"
  fi
else
  if [ "$STACK_FLAG" = "true" ]; then
    STACK_NAME="$STACK_OPT"
    echo "INFO: stack preset '${STACK_NAME}' selected via --stack (SPEC-0028)"
  else
    detected_markers=""
    [ -f "go.mod" ] && detected_markers="${detected_markers} go.mod"
    [ -f "pnpm-workspace.yaml" ] && detected_markers="${detected_markers} pnpm-workspace.yaml"
    [ -f "pnpm-lock.yaml" ] && detected_markers="${detected_markers} pnpm-lock.yaml"
    [ -f "package.json" ] && detected_markers="${detected_markers} package.json"
    [ -f "pyproject.toml" ] && detected_markers="${detected_markers} pyproject.toml"
    if [ -n "$detected_markers" ]; then
      # Priority: go > ts-pnpm > node-npm > python (FR-04). pnpm markers are
      # more specific than package.json, so ts-pnpm wins over node-npm.
      if [ -f "go.mod" ]; then
        STACK_NAME="go"
      elif [ -f "pnpm-workspace.yaml" ] || [ -f "pnpm-lock.yaml" ]; then
        STACK_NAME="ts-pnpm"
      elif [ -f "package.json" ]; then
        STACK_NAME="node-npm"
      else
        STACK_NAME="python"
      fi
      echo "INFO: detected stack markers:${detected_markers} (SPEC-0028)"
      echo "INFO: applying stack preset '${STACK_NAME}' to project_checks (priority: go > ts-pnpm > node-npm > python; override with --stack <name>)"
    fi
    # No marker detected: keep the unset template — output and generated
    # files stay byte-identical to the pre-SPEC-0028 installer (FR-05/INV-02).
  fi
  case "$STACK_NAME" in
    go) STACK_PRESET_BODY="$TMPL_STACK_GO" ;;
    ts-pnpm) STACK_PRESET_BODY="$TMPL_STACK_TS_PNPM" ;;
    node-npm) STACK_PRESET_BODY="$TMPL_STACK_NODE_NPM" ;;
    python) STACK_PRESET_BODY="$TMPL_STACK_PYTHON" ;;
  esac
fi

echo "========================================="
if [ "$MODE" = "install" ]; then
  echo "  SAGE v${SAGE_VERSION} — New Installation"
else
  echo "  SAGE v${INSTALLED_VERSION:-?} → v${SAGE_VERSION} — Update"
fi
echo "========================================="
echo ""

# --- [1/9] Directories ---
echo "[1/9] ディレクトリ..."
if [ "${DRY_RUN:-false}" = "true" ]; then
  echo "  WOULD-MKDIR: specs plans tasks sage .sage/runs .sage/metrics docs scripts .claude/rules .claude/skills/{sage-spec,sage-plan,sage-review,sage-review/references,sage-evaluate/references,sage-harness,sage-promote}"
else
  mkdir -p specs plans tasks sage .sage/runs .sage/metrics docs scripts .claude/rules .claude/skills/sage-spec .claude/skills/sage-plan .claude/skills/sage-review .claude/skills/sage-review/references .claude/skills/sage-evaluate/references .claude/skills/sage-harness .claude/skills/sage-promote
fi
echo "  OK"

# --- [2/9] Templates & governance ---
echo ""
echo "[2/9] テンプレート & ガバナンス文書..."
if [ "$MODE" = "install" ]; then
  write_file_if_new "specs/_template.md" "$TMPL_SPEC"
  write_file_if_new "plans/_template.md" "$TMPL_PLAN"
  write_file_if_new "tasks/_template.md" "$TMPL_TASK"
  write_file_if_new "sage/charter.md" "$TMPL_CHARTER"
  write_file_if_new "sage/governance.md" "$TMPL_GOVERNANCE"
  write_file_if_new "sage/failures.md" "$TMPL_FAILURES"
  write_file_if_new "sage/anti-patterns.md" "$TMPL_ANTIPATTERNS"
  write_file_if_new "sage/quality-gates.md" "$TMPL_QUALITY_GATES"
  write_file_if_new "sage/adoption-phases.md" "$TMPL_ADOPTION"
  write_file_if_new "sage/traceability.md" "$TMPL_TRACEABILITY"
  # SPEC-0028 PRE-01/POST-01: apply the selected stack preset immediately
  # before the write, and only while .sage/config.yaml is still absent.
  # write_file_if_new keeps its preserve-if-exists behavior either way (INV-01).
  if [ -n "$STACK_PRESET_BODY" ] && [ ! -f ".sage/config.yaml" ]; then
    TMPL_CONFIG=$(replace_project_checks_section "$TMPL_CONFIG" "$STACK_PRESET_BODY")
  fi
  write_file_if_new ".sage/config.yaml" "$TMPL_CONFIG"
  # SPEC-0027: id-patterns.json is preserve-if-exists (AC-12) — never overwritten
  write_file_if_new ".sage/id-patterns.json" "$TMPL_ID_PATTERNS"
  write_file_if_new "scripts/sage-id-pattern.sh" "$TMPL_ID_PATTERN_LOADER"
  write_file_if_new "scripts/sage-validate.sh" "$TMPL_VALIDATE" && chmod +x "scripts/sage-validate.sh"
  write_file_if_new "scripts/sage-id-gen.sh" "$TMPL_ID_GEN" && chmod +x "scripts/sage-id-gen.sh"
  write_file_if_new "scripts/sage-trace-check.sh" "$TMPL_TRACE_CHECK" && chmod +x "scripts/sage-trace-check.sh"
  write_file_if_new "scripts/sage-update-check.sh" "$TMPL_UPDATE_CHECK" && chmod +x "scripts/sage-update-check.sh"
  write_file_if_new "scripts/sage-promote.sh" "$TMPL_PROMOTE" && chmod +x "scripts/sage-promote.sh"
  write_file_if_new "scripts/sage-retro-spec.sh" "$TMPL_RETRO_SPEC" && chmod +x "scripts/sage-retro-spec.sh"
  write_file_if_new "docs/codex-delegation-packet.md" "$TMPL_CODEX_DELEGATION_PACKET"
  write_file_if_new "docs/claude-collaboration-brief.md" "$TMPL_CLAUDE_COLLABORATION_BRIEF"
else
  # Update mode: テンプレートとガバナンスはSAGE管理なので上書き
  update_file "specs/_template.md" "$TMPL_SPEC"
  update_file "plans/_template.md" "$TMPL_PLAN"
  update_file "tasks/_template.md" "$TMPL_TASK"
  update_file "sage/charter.md" "$TMPL_CHARTER"
  update_file "sage/governance.md" "$TMPL_GOVERNANCE"
  update_file "sage/anti-patterns.md" "$TMPL_ANTIPATTERNS"
  update_file "sage/quality-gates.md" "$TMPL_QUALITY_GATES"
  update_file "sage/adoption-phases.md" "$TMPL_ADOPTION"
  update_file "sage/traceability.md" "$TMPL_TRACEABILITY"
  # SPEC-0027: loader is SAGE-managed (updated); id-patterns.json is
  # project-customizable — installed only when missing (preserve-if-exists)
  update_file "scripts/sage-id-pattern.sh" "$TMPL_ID_PATTERN_LOADER"
  write_file_if_new ".sage/id-patterns.json" "$TMPL_ID_PATTERNS"
  update_file "scripts/sage-validate.sh" "$TMPL_VALIDATE" && chmod +x "scripts/sage-validate.sh"
  update_file "scripts/sage-id-gen.sh" "$TMPL_ID_GEN" && chmod +x "scripts/sage-id-gen.sh"
  update_file "scripts/sage-trace-check.sh" "$TMPL_TRACE_CHECK" && chmod +x "scripts/sage-trace-check.sh"
  update_file "scripts/sage-update-check.sh" "$TMPL_UPDATE_CHECK" && chmod +x "scripts/sage-update-check.sh"
  update_file "scripts/sage-promote.sh" "$TMPL_PROMOTE" && chmod +x "scripts/sage-promote.sh"
  update_file "scripts/sage-retro-spec.sh" "$TMPL_RETRO_SPEC" && chmod +x "scripts/sage-retro-spec.sh"
  update_file "docs/codex-delegation-packet.md" "$TMPL_CODEX_DELEGATION_PACKET"
  update_file "docs/claude-collaboration-brief.md" "$TMPL_CLAUDE_COLLABORATION_BRIEF"
  # failures.md, config.yaml はプロジェクト固有データが入るので更新しない
  echo "  KEEP: sage/failures.md (project data)"
  echo "  KEEP: .sage/config.yaml (project settings)"
fi

# --- [3/9] .claude/rules/ ---
echo ""
echo "[3/9] .claude/rules/..."
# SPEC-0025: write_rules_file (module 03) references is_unmanaged_path so
# rules generation can never reach into */rules/local/**.
write_rules_file ".claude/rules/specs-rules.md" "$TMPL_RULES_SPECS"
write_rules_file ".claude/rules/plans-rules.md" "$TMPL_RULES_PLANS"
write_rules_file ".claude/rules/tasks-rules.md" "$TMPL_RULES_TASKS"
write_rules_file ".claude/rules/src-rules.md" "$TMPL_RULES_SRC"
write_rules_file ".claude/rules/sage-governance-rules.md" "$TMPL_RULES_GOVERNANCE"

# --- [4/9] .claude/skills/ ---
echo ""
echo "[4/9] .claude/skills/..."
if [ "$MODE" = "install" ]; then
  write_file_if_new ".claude/skills/sage-spec/SKILL.md" "$TMPL_SKILL_SPEC"
  write_file_if_new ".claude/skills/sage-plan/SKILL.md" "$TMPL_SKILL_PLAN"
  write_file_if_new ".claude/skills/sage-review/SKILL.md" "$TMPL_SKILL_REVIEW"
  write_file_if_new ".claude/skills/sage-review/references/review-scoring-rubric.md" "$TMPL_SKILL_REVIEW_RUBRIC"
  write_file_if_new ".claude/skills/sage-harness/SKILL.md" "$TMPL_SKILL_HARNESS"
  write_file_if_new ".claude/skills/sage-evaluate/SKILL.md" "$TMPL_SKILL_EVALUATE"
  write_file_if_new ".claude/skills/sage-evaluate/references/scoring-rubric.md" "$TMPL_SKILL_EVALUATE_RUBRIC"
  write_file_if_new ".claude/skills/sage-evaluate/references/knowledge-base.md" "$TMPL_SKILL_EVALUATE_KB"
  write_file_if_new ".claude/skills/sage-promote/SKILL.md" "$TMPL_SKILL_PROMOTE"
else
  update_file ".claude/skills/sage-spec/SKILL.md" "$TMPL_SKILL_SPEC"
  update_file ".claude/skills/sage-plan/SKILL.md" "$TMPL_SKILL_PLAN"
  update_file ".claude/skills/sage-review/SKILL.md" "$TMPL_SKILL_REVIEW"
  update_file ".claude/skills/sage-review/references/review-scoring-rubric.md" "$TMPL_SKILL_REVIEW_RUBRIC"
  update_file ".claude/skills/sage-harness/SKILL.md" "$TMPL_SKILL_HARNESS"
  update_file ".claude/skills/sage-evaluate/SKILL.md" "$TMPL_SKILL_EVALUATE"
  update_file ".claude/skills/sage-evaluate/references/scoring-rubric.md" "$TMPL_SKILL_EVALUATE_RUBRIC"
  update_file ".claude/skills/sage-evaluate/references/knowledge-base.md" "$TMPL_SKILL_EVALUATE_KB"
  update_file ".claude/skills/sage-promote/SKILL.md" "$TMPL_SKILL_PROMOTE"
fi

# --- [5/9] CLAUDE.md ---
echo ""
echo "[5/9] CLAUDE.md..."
# Audit existing CLAUDE.md before first SAGE injection
AUDIT_GENERATED=""
if [ -f CLAUDE.md ] && [ -s CLAUDE.md ] && ! grep -qF "$SAGE_START_MARKER" CLAUDE.md; then
  audit_existing_claude_md CLAUDE.md
  AUDIT_GENERATED="true"
fi
upsert_sage_section "CLAUDE.md" "$TMPL_CLAUDE_SNIPPET"

# --- [6/9] AGENTS.md ---
echo ""
echo "[6/9] AGENTS.md (Codex)..."
upsert_sage_section "AGENTS.md" "$TMPL_AGENTS_SNIPPET"

# --- [7/9] Hooks ---
echo ""
echo "[7/9] Claude Code hooks..."
if [ "${DRY_RUN:-false}" != "true" ]; then
  mkdir -p templates/hooks
fi
if [ "$MODE" = "install" ]; then
  write_file_if_new "templates/hooks/block-dangerous-commands.sh" "$TMPL_HOOK_BLOCK_DANGEROUS" && chmod +x "templates/hooks/block-dangerous-commands.sh"
  write_file_if_new "templates/hooks/protect-sage-files.sh" "$TMPL_HOOK_PROTECT_SAGE" && chmod +x "templates/hooks/protect-sage-files.sh"
  write_file_if_new "templates/hooks/check-file-scope.sh" "$TMPL_HOOK_CHECK_SCOPE" && chmod +x "templates/hooks/check-file-scope.sh"
  write_file_if_new "templates/hooks/session-start.sh" "$TMPL_HOOK_SESSION_START" && chmod +x "templates/hooks/session-start.sh"
  write_file_if_new "templates/hooks/session-stop.sh" "$TMPL_HOOK_SESSION_STOP" && chmod +x "templates/hooks/session-stop.sh"
  write_file_if_new "templates/hooks/lethal-trifecta-detect.sh" "$TMPL_HOOK_LETHAL_TRIFECTA" && chmod +x "templates/hooks/lethal-trifecta-detect.sh"
  write_file_if_new "templates/hooks/secret-read-multi-layer.sh" "$TMPL_HOOK_SECRET_READ" && chmod +x "templates/hooks/secret-read-multi-layer.sh"
  write_file_if_new "templates/hooks/security-filter.sh" "$TMPL_HOOK_SECURITY_FILTER" && chmod +x "templates/hooks/security-filter.sh"
  write_file_if_new "templates/hooks/mcp-allowlist-audit.sh" "$TMPL_HOOK_MCP_ALLOWLIST_AUDIT" && chmod +x "templates/hooks/mcp-allowlist-audit.sh"
  mkdir -p templates/sage
  write_file_if_new "templates/sage/mcp-allowlist-template.json" "$TMPL_SAGE_MCP_ALLOWLIST_TEMPLATE"
  write_file_if_new "templates/sage/README.md" "$TMPL_SAGE_README"
  mkdir -p templates/hooks/tests
  write_file_if_new "templates/hooks/tests/test-mcp-allowlist-audit.sh" "$TMPL_TEST_MCP_ALLOWLIST" && chmod +x "templates/hooks/tests/test-mcp-allowlist-audit.sh"
  write_file_if_new "templates/hooks/tests/test-detection-only-behavior.sh" "$TMPL_TEST_DETECTION_ONLY" && chmod +x "templates/hooks/tests/test-detection-only-behavior.sh"
  write_file_if_new "templates/hooks/tests/measure-hook-time.py" "$TMPL_MEASURE_HOOK_TIME" && chmod +x "templates/hooks/tests/measure-hook-time.py"
  write_file_if_new "scripts/sage-mcp-allowlist-audit.sh" "$TMPL_SCRIPT_MCP_ALLOWLIST_AUDIT" && chmod +x "scripts/sage-mcp-allowlist-audit.sh"
  write_file_if_new "templates/sage/agent-inventory-template.yaml" "$TMPL_SAGE_AGENT_INVENTORY"
  write_file_if_new "templates/hooks/tests/test-agent-inventory-validator.sh" "$TMPL_TEST_AGENT_INVENTORY" && chmod +x "templates/hooks/tests/test-agent-inventory-validator.sh"
  write_file_if_new "scripts/sage-agent-inventory-audit.sh" "$TMPL_SCRIPT_AGENT_INVENTORY" && chmod +x "scripts/sage-agent-inventory-audit.sh"
  write_file_if_new "scripts/sage-runlog-index.sh" "$TMPL_SCRIPT_RUNLOG_INDEX" && chmod +x "scripts/sage-runlog-index.sh"
  write_file_if_new "scripts/sage-runlog-search.sh" "$TMPL_SCRIPT_RUNLOG_SEARCH" && chmod +x "scripts/sage-runlog-search.sh"
  write_file_if_new "scripts/sage-runlog-db-audit.sh" "$TMPL_SCRIPT_RUNLOG_DB_AUDIT" && chmod +x "scripts/sage-runlog-db-audit.sh"
  write_file_if_new "templates/hooks/tests/test-runlog-index.sh" "$TMPL_TEST_RUNLOG_INDEX" && chmod +x "templates/hooks/tests/test-runlog-index.sh"
  write_file_if_new "templates/hooks/tests/test-runlog-search.sh" "$TMPL_TEST_RUNLOG_SEARCH" && chmod +x "templates/hooks/tests/test-runlog-search.sh"
  write_file_if_new "templates/hooks/tests/test-runlog-db-doctor.sh" "$TMPL_TEST_RUNLOG_DB_DOCTOR" && chmod +x "templates/hooks/tests/test-runlog-db-doctor.sh"
  write_file_if_new "templates/hooks/tests/test-property-section.sh" "$TMPL_TEST_PROPERTY_SECTION" && chmod +x "templates/hooks/tests/test-property-section.sh"
  write_file_if_new "templates/settings/sandbox.json" "$TMPL_SETTINGS_SANDBOX"
  write_file_if_new "templates/settings/README.md" "$TMPL_SETTINGS_README"
else
  update_file "templates/hooks/block-dangerous-commands.sh" "$TMPL_HOOK_BLOCK_DANGEROUS" && chmod +x "templates/hooks/block-dangerous-commands.sh"
  update_file "templates/hooks/protect-sage-files.sh" "$TMPL_HOOK_PROTECT_SAGE" && chmod +x "templates/hooks/protect-sage-files.sh"
  update_file "templates/hooks/check-file-scope.sh" "$TMPL_HOOK_CHECK_SCOPE" && chmod +x "templates/hooks/check-file-scope.sh"
  update_file "templates/hooks/session-start.sh" "$TMPL_HOOK_SESSION_START" && chmod +x "templates/hooks/session-start.sh"
  update_file "templates/hooks/session-stop.sh" "$TMPL_HOOK_SESSION_STOP" && chmod +x "templates/hooks/session-stop.sh"
  update_file "templates/hooks/lethal-trifecta-detect.sh" "$TMPL_HOOK_LETHAL_TRIFECTA" && chmod +x "templates/hooks/lethal-trifecta-detect.sh"
  update_file "templates/hooks/secret-read-multi-layer.sh" "$TMPL_HOOK_SECRET_READ" && chmod +x "templates/hooks/secret-read-multi-layer.sh"
  update_file "templates/hooks/security-filter.sh" "$TMPL_HOOK_SECURITY_FILTER" && chmod +x "templates/hooks/security-filter.sh"
  update_file "templates/hooks/mcp-allowlist-audit.sh" "$TMPL_HOOK_MCP_ALLOWLIST_AUDIT" && chmod +x "templates/hooks/mcp-allowlist-audit.sh"
  mkdir -p templates/sage
  update_file "templates/sage/mcp-allowlist-template.json" "$TMPL_SAGE_MCP_ALLOWLIST_TEMPLATE"
  update_file "templates/sage/README.md" "$TMPL_SAGE_README"
  mkdir -p templates/hooks/tests
  update_file "templates/hooks/tests/test-mcp-allowlist-audit.sh" "$TMPL_TEST_MCP_ALLOWLIST" && chmod +x "templates/hooks/tests/test-mcp-allowlist-audit.sh"
  update_file "templates/hooks/tests/test-detection-only-behavior.sh" "$TMPL_TEST_DETECTION_ONLY" && chmod +x "templates/hooks/tests/test-detection-only-behavior.sh"
  update_file "templates/hooks/tests/measure-hook-time.py" "$TMPL_MEASURE_HOOK_TIME" && chmod +x "templates/hooks/tests/measure-hook-time.py"
  update_file "scripts/sage-mcp-allowlist-audit.sh" "$TMPL_SCRIPT_MCP_ALLOWLIST_AUDIT" && chmod +x "scripts/sage-mcp-allowlist-audit.sh"
  update_file "templates/sage/agent-inventory-template.yaml" "$TMPL_SAGE_AGENT_INVENTORY"
  update_file "templates/hooks/tests/test-agent-inventory-validator.sh" "$TMPL_TEST_AGENT_INVENTORY" && chmod +x "templates/hooks/tests/test-agent-inventory-validator.sh"
  update_file "scripts/sage-agent-inventory-audit.sh" "$TMPL_SCRIPT_AGENT_INVENTORY" && chmod +x "scripts/sage-agent-inventory-audit.sh"
  update_file "scripts/sage-runlog-index.sh" "$TMPL_SCRIPT_RUNLOG_INDEX" && chmod +x "scripts/sage-runlog-index.sh"
  update_file "scripts/sage-runlog-search.sh" "$TMPL_SCRIPT_RUNLOG_SEARCH" && chmod +x "scripts/sage-runlog-search.sh"
  update_file "scripts/sage-runlog-db-audit.sh" "$TMPL_SCRIPT_RUNLOG_DB_AUDIT" && chmod +x "scripts/sage-runlog-db-audit.sh"
  update_file "templates/hooks/tests/test-runlog-index.sh" "$TMPL_TEST_RUNLOG_INDEX" && chmod +x "templates/hooks/tests/test-runlog-index.sh"
  update_file "templates/hooks/tests/test-runlog-search.sh" "$TMPL_TEST_RUNLOG_SEARCH" && chmod +x "templates/hooks/tests/test-runlog-search.sh"
  update_file "templates/hooks/tests/test-runlog-db-doctor.sh" "$TMPL_TEST_RUNLOG_DB_DOCTOR" && chmod +x "templates/hooks/tests/test-runlog-db-doctor.sh"
  update_file "templates/hooks/tests/test-property-section.sh" "$TMPL_TEST_PROPERTY_SECTION" && chmod +x "templates/hooks/tests/test-property-section.sh"
  update_file "templates/settings/sandbox.json" "$TMPL_SETTINGS_SANDBOX"
  update_file "templates/settings/README.md" "$TMPL_SETTINGS_README"
fi
# Deploy settings.json with hook definitions
if [ "${DRY_RUN:-false}" = "true" ]; then
  if [ ! -f ".claude/settings.json" ] || ! grep -qF "block-dangerous-commands" ".claude/settings.json" 2>/dev/null; then
    echo "  WOULD-CREATE: .claude/settings.json (with hooks)"
  else
    echo "  WOULD-SKIP:   .claude/settings.json (hooks already configured)"
  fi
elif [ ! -f ".claude/settings.json" ] || ! grep -qF "block-dangerous-commands" ".claude/settings.json" 2>/dev/null; then
  mkdir -p .claude
  # SPEC-0026 INV-02: an existing settings.json without hooks gets replaced — back it up.
  backup_before_write ".claude/settings.json" "$TMPL_SETTINGS_JSON"
  echo "$TMPL_SETTINGS_JSON" > ".claude/settings.json"
  echo "  CREATE: .claude/settings.json (with hooks)"
else
  echo "  SKIP: .claude/settings.json (hooks already configured)"
fi

# --- [8/9] Commit hook ---
echo ""
echo "[8/9] Pre-commit hook..."
setup_commit_hook

# --- [9/9] .gitignore ---
echo ""
echo "[9/9] .gitignore..."
setup_gitignore

# --- Save installed version ---
if [ "${DRY_RUN:-false}" = "true" ]; then
  echo "  WOULD-WRITE: .sage/version (${SAGE_VERSION})"
else
  # SPEC-0026 INV-02 (no-op when the version is unchanged).
  backup_before_write ".sage/version" "$SAGE_VERSION"
  echo "$SAGE_VERSION" > .sage/version
fi

# --- Generate install-state.yaml (SPEC-0004) ---
echo ""
echo "Generating install-state.yaml..."
generate_install_state() {
  local state_file=".sage/install-state.yaml"
  local sha_cmd=""

  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo "  WOULD-WRITE: $state_file"
    return
  fi

  # Cross-platform SHA256
  if command -v sha256sum &>/dev/null; then
    sha_cmd="sha256sum"
  elif command -v shasum &>/dev/null; then
    sha_cmd="shasum -a 256"
  else
    echo "  WARN: No sha256 command found. Skipping install-state generation."
    return
  fi

  # SPEC-0026 INV-02: back up the previous install-state before regenerating.
  backup_before_write "$state_file"
  cat > "$state_file" <<STATEHEADER
version: "${SAGE_VERSION}"
installed_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
files:
STATEHEADER

  # SAGE-managed files (update_file targets — overwritten on update)
  local managed_files=(
    # Templates
    "specs/_template.md"
    "plans/_template.md"
    "tasks/_template.md"
    # Governance
    "sage/charter.md"
    "sage/governance.md"
    "sage/anti-patterns.md"
    "sage/quality-gates.md"
    "sage/adoption-phases.md"
    "sage/traceability.md"
    # Scripts
    "scripts/sage-id-pattern.sh"
    "scripts/sage-validate.sh"
    "scripts/sage-id-gen.sh"
    "scripts/sage-trace-check.sh"
    "scripts/sage-update-check.sh"
    "scripts/sage-promote.sh"
    "scripts/sage-retro-spec.sh"
    # Docs
    "docs/codex-delegation-packet.md"
    "docs/claude-collaboration-brief.md"
    # Claude Code rules and skills
    ".claude/rules/specs-rules.md"
    ".claude/rules/plans-rules.md"
    ".claude/rules/tasks-rules.md"
    ".claude/rules/src-rules.md"
    ".claude/rules/sage-governance-rules.md"
    ".claude/skills/sage-spec/SKILL.md"
    ".claude/skills/sage-plan/SKILL.md"
    ".claude/skills/sage-review/SKILL.md"
    ".claude/skills/sage-review/references/review-scoring-rubric.md"
    ".claude/skills/sage-harness/SKILL.md"
    ".claude/skills/sage-evaluate/SKILL.md"
    ".claude/skills/sage-evaluate/references/scoring-rubric.md"
    ".claude/skills/sage-evaluate/references/knowledge-base.md"
    ".claude/skills/sage-promote/SKILL.md"
    "templates/hooks/block-dangerous-commands.sh"
    "templates/hooks/protect-sage-files.sh"
    "templates/hooks/check-file-scope.sh"
    "templates/hooks/session-start.sh"
    "templates/hooks/session-stop.sh"
  )

  # User-customizable files (write_file_if_new targets — NOT overwritten)
  local user_files=(
    "CLAUDE.md"
    "AGENTS.md"
    ".sage/config.yaml"
    ".sage/id-patterns.json"
    "sage/failures.md"
    ".claude/settings.json"
  )

  for f in "${managed_files[@]}"; do
    if [ -f "$f" ]; then
      local hash=$($sha_cmd "$f" | awk '{print $1}')
      echo "  - path: \"$f\"" >> "$state_file"
      echo "    sha256: \"$hash\"" >> "$state_file"
      echo "    source: \"embedded\"" >> "$state_file"
      echo "    managed: true" >> "$state_file"
    fi
  done

  for f in "${user_files[@]}"; do
    if [ -f "$f" ]; then
      local hash=$($sha_cmd "$f" | awk '{print $1}')
      echo "  - path: \"$f\"" >> "$state_file"
      echo "    sha256: \"$hash\"" >> "$state_file"
      echo "    source: \"embedded\"" >> "$state_file"
      echo "    managed: false" >> "$state_file"
    fi
  done

  # SPEC-0025 FR-02: declare overlay directories the installer never touches
  # or verifies. Informational only — not a write allowlist (SEC-02).
  cat >> "$state_file" <<'STATEUNMANAGED'
unmanaged_paths:
  - ".claude/rules/local/"
  - ".codex/rules/local/"
STATEUNMANAGED

  echo "  OK: .sage/install-state.yaml"
}
generate_install_state

echo ""
echo "========================================="
echo "  SAGE v${SAGE_VERSION} — Complete"
echo "========================================="
echo ""
if [ "$MODE" = "install" ]; then
  echo "AI エージェントは次のセッションから自動的にSAGEに従います。"
  echo ""
  echo "次のステップ:"
  if [ "$AUDIT_GENERATED" = "true" ]; then
    echo "  ⚠ 既存の CLAUDE.md にルールが検出されました。"
    echo "    まず監査レポートを確認してください："
    echo "      cat .sage/adoption-audit.md"
    echo ""
    echo "    - SAFE_AUTO_APPLY → 対応不要"
    echo "    - NEEDS_REVIEW    → SAGEと重複していないか確認、重複は削除"
    echo "    - CONFLICT        → 手動で解決してからSAGEを利用"
    echo ""
  fi
  echo "  1. 次の機能開発で SPEC を書いてみる"
  echo "     bash scripts/sage-id-gen.sh spec"
  echo ""
  echo "カスタマイズ:"
  echo "  CLAUDE.md     → SAGEマーカーの上に自由に追記OK"
  echo "  .claude/rules/ → 自分用ルールは別名で追加（例: my-api-rules.md）"
  echo "                   ※ SAGE管理ファイル（specs-rules.md 等）は更新時に上書きされます"
else
  echo "更新内容:"
  echo "  - テンプレート・ガバナンス文書を v${SAGE_VERSION} に更新"
  echo "  - CLAUDE.md / AGENTS.md の SAGE セクションを更新"
  echo "  - プロジェクト固有の設定 (config.yaml, failures.md) はそのまま"
fi
echo ""
MAIN_LOGIC
