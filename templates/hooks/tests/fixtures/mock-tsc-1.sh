#!/usr/bin/env bash
# TASK-0207: mock tsc fixture — 1 error. Emits 1 `error TS` line and exits
# non-zero, like tsc when type errors exist (SPEC-0030 boundary case 2: exit
# code alone must not be treated as execution failure).
printf 'src/a.ts(1,5): error TS2345: Argument of type '\''string'\'' is not assignable.\n'
exit 2
