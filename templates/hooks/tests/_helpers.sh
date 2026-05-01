#!/usr/bin/env bash
# =============================================================================
# TASK-0101: test-helpers.sh
# Purpose:  Shared helpers for SAGE hook tests (pure bash, no external deps).
# Sourced by test-*.sh files.
# =============================================================================
set -euo pipefail

# Resolve repository root from this file's location.
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "${TEST_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${HOOKS_DIR}/../.." && pwd)"

# Per-test counters (the test runner aggregates).
HELPER_PASS=0
HELPER_FAIL=0
HELPER_FAIL_LOG=""

# create_sandbox: create a tmpdir + .sage/config.yaml so hooks see profile=standard.
# Echos the tmpdir path. Caller should `trap "rm -rf $dir" EXIT`.
create_sandbox() {
  local dir
  dir="$(mktemp -d -t sage-hook-test-XXXXXX)"
  mkdir -p "${dir}/.sage"
  cat > "${dir}/.sage/config.yaml" <<EOF
hooks:
  profile: standard
EOF
  echo "${dir}"
}

# run_hook: invoke a hook script with given JSON stdin from a sandbox cwd.
# Sets globals: HOOK_RC, HOOK_STDOUT, HOOK_STDERR.
run_hook() {
  local hook_name="$1"
  local stdin_json="$2"
  local cwd="${3:-$(pwd)}"

  local hook_path="${HOOKS_DIR}/${hook_name}"
  if [ ! -f "${hook_path}" ]; then
    HOOK_RC=127
    HOOK_STDOUT=""
    HOOK_STDERR="hook not found: ${hook_path}"
    return 0
  fi

  local out_file err_file
  out_file="$(mktemp)"
  err_file="$(mktemp)"

  # NOTE: append newline so the hook's `read -r INPUT` captures the JSON.
  # Without the trailing \n, `read` returns non-zero before the body is
  # consumed and the hook degrades to its empty-stdin allow-path.
  set +e
  ( cd "${cwd}" && printf '%s\n' "${stdin_json}" | bash "${hook_path}" >"${out_file}" 2>"${err_file}" )
  HOOK_RC=$?
  set -e

  HOOK_STDOUT="$(cat "${out_file}")"
  HOOK_STDERR="$(cat "${err_file}")"
  rm -f "${out_file}" "${err_file}"
}

# assert_eq: numeric equality assertion.
assert_eq() {
  local actual="$1"
  local expected="$2"
  local label="${3:-assertion}"
  if [ "${actual}" = "${expected}" ]; then
    HELPER_PASS=$((HELPER_PASS + 1))
    echo "  ok   ${label} (= ${expected})"
  else
    HELPER_FAIL=$((HELPER_FAIL + 1))
    HELPER_FAIL_LOG="${HELPER_FAIL_LOG}\n  not ok ${label}: expected '${expected}' got '${actual}'"
    echo "  not ok ${label}: expected '${expected}' got '${actual}'" >&2
  fi
}

# assert_contains: substring match in a haystack.
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="${3:-assertion}"
  if echo "${haystack}" | grep -qF -- "${needle}"; then
    HELPER_PASS=$((HELPER_PASS + 1))
    echo "  ok   ${label} (contains '${needle}')"
  else
    HELPER_FAIL=$((HELPER_FAIL + 1))
    HELPER_FAIL_LOG="${HELPER_FAIL_LOG}\n  not ok ${label}: substring '${needle}' not found"
    echo "  not ok ${label}: substring '${needle}' not found" >&2
    echo "  haystack: ${haystack}" >&2
  fi
}

# assert_not_contains: substring absence check.
assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="${3:-assertion}"
  if echo "${haystack}" | grep -qF -- "${needle}"; then
    HELPER_FAIL=$((HELPER_FAIL + 1))
    HELPER_FAIL_LOG="${HELPER_FAIL_LOG}\n  not ok ${label}: unexpected substring '${needle}' present"
    echo "  not ok ${label}: unexpected substring '${needle}' present" >&2
  else
    HELPER_PASS=$((HELPER_PASS + 1))
    echo "  ok   ${label} (does not contain '${needle}')"
  fi
}

# Emit a one-line summary the runner can parse.
summary_line() {
  echo "SUMMARY pass=${HELPER_PASS} fail=${HELPER_FAIL}"
}
