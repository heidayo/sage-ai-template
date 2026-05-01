# SAGE Hook Tests

Pure-bash test harness for `templates/hooks/*.sh`. No external dependencies (no BATS, no node, no python). Phase 2A SPEC-0011 / TASK-0101.

## Run

```bash
bash templates/hooks/tests/run-tests.sh
```

Exits 0 if all tests pass, 1 if any fail. Per-test PASS/FAIL counters are printed under each `# test-name` heading and aggregated in the final `PASS / FAIL / TOTAL` line.

## Why a custom harness

- **Self-contained** — matches SAGE's "no external runtime dependencies" doctrine (same reason `install.sh` is a single bash script).
- **Mirrors hook reality** — the hook is invoked by Claude Code with a JSON payload on stdin. Tests use the same contract (`run_hook` helper writes JSON to stdin and captures rc + stdout + stderr).
- **CI parity** — `run-tests.sh` is callable from `.github/workflows/sage-structural-gate.yml` (TASK-0102) and from `make test-hooks` locally.

## Anatomy of a test file

Each test file is `templates/hooks/tests/test-<hook-name>.sh` with this shape:

```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

SANDBOX="$(create_sandbox)"
trap 'rm -rf "${SANDBOX}"' EXIT

# Allow case
run_hook "block-dangerous-commands.sh" '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: npm test"

# Block case
run_hook "block-dangerous-commands.sh" '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: rm -rf /"
assert_contains "${HOOK_STDERR}" "BLOCKED" "block: stderr has BLOCKED prefix"

summary_line   # <- mandatory final line
```

## Helpers (from `_helpers.sh`)

| Helper | Purpose |
|---|---|
| `create_sandbox` | echoes a `mktemp -d` path with `.sage/config.yaml` (profile=standard) so hooks pass profile-gating |
| `run_hook <hook.sh> <stdin-json> [<cwd>]` | invokes hook, sets globals `HOOK_RC` / `HOOK_STDOUT` / `HOOK_STDERR` |
| `assert_eq <actual> <expected> <label>` | numeric/string equality |
| `assert_contains <haystack> <needle> <label>` | substring check |
| `assert_not_contains <haystack> <needle> <label>` | negative substring check |
| `summary_line` | prints `SUMMARY pass=N fail=M` for the runner to parse |

## Adding a new hook test

1. Add `test-<your-hook>.sh` next to existing tests.
2. Source `test-helpers.sh`.
3. Always `create_sandbox` and `trap` cleanup.
4. End with `summary_line`.
5. Run `bash templates/hooks/tests/run-tests.sh` — your test is auto-discovered.

## Limits

- This harness validates **hook contract** (rc, stderr text, side effects). It does NOT validate that the hook is actually reachable from a real Claude Code session — that is integration-level and out of scope for unit tests.
- `set -e` is intentionally not used in test files (`set -uo pipefail` only) so that a single failed assertion does not abort the rest of the suite. `assert_*` helpers track `HELPER_FAIL`.
- Hooks are pattern-matching defenses. The tests are smoke-level proof of behavior, not adversarial coverage. See [SECURITY.md §5 Known Risks](../../../SECURITY.md) for the doctrine.
