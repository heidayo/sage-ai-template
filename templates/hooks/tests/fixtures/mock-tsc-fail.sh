#!/usr/bin/env bash
# TASK-0207: mock tsc fixture — execution failure (SPEC-0030 boundary case 2).
# Non-zero exit with NO `error TS` pattern in output, like `tsc: command not
# found`. The ratchet must treat this as failure (exit 1), not as 0 errors.
printf 'sh: tsc: command not found\n' >&2
exit 127
