#!/usr/bin/env bash
# =============================================================================
# TASK-0101: run-tests.sh
# Purpose:  Discover and execute SAGE hook tests (templates/hooks/tests/test-*.sh).
# Exit:     0 if all tests pass, 1 if any test fails.
# =============================================================================
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_TESTS=()

shopt -s nullglob
test_files=( "${TEST_DIR}"/test-*.sh )
shopt -u nullglob

if [ "${#test_files[@]}" -eq 0 ]; then
  echo "ERROR: no test-*.sh files found in ${TEST_DIR}" >&2
  exit 1
fi

echo "Running ${#test_files[@]} hook test file(s) from ${TEST_DIR}..."
echo ""

for test_file in "${test_files[@]}"; do
  name="$(basename "${test_file}" .sh)"
  echo "# ${name}"

  # Each test file must end with a `summary_line` printout that the runner can
  # parse. Run in a subshell so set -e in test files does not abort the runner.
  output="$(bash "${test_file}" 2>&1 || true)"
  echo "${output}"

  # Parse "SUMMARY pass=N fail=M" line.
  summary_line=$(echo "${output}" | grep -E '^SUMMARY pass=[0-9]+ fail=[0-9]+' | tail -1)
  if [ -z "${summary_line}" ]; then
    echo "  ERROR: ${name} did not emit summary_line — counted as 1 fail" >&2
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    FAILED_TESTS+=( "${name}" )
    echo ""
    continue
  fi

  pass_n=$(echo "${summary_line}" | sed -E 's/.*pass=([0-9]+).*/\1/')
  fail_n=$(echo "${summary_line}" | sed -E 's/.*fail=([0-9]+).*/\1/')
  TOTAL_PASS=$((TOTAL_PASS + pass_n))
  TOTAL_FAIL=$((TOTAL_FAIL + fail_n))
  if [ "${fail_n}" -gt 0 ]; then
    FAILED_TESTS+=( "${name}" )
  fi
  echo ""
done

TOTAL=$((TOTAL_PASS + TOTAL_FAIL))
echo "================================================="
echo "  PASS: ${TOTAL_PASS} / FAIL: ${TOTAL_FAIL} / TOTAL: ${TOTAL}"
echo "================================================="

if [ "${TOTAL_FAIL}" -gt 0 ]; then
  echo "Failed tests:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "  - ${t}"
  done
  exit 1
fi

exit 0
