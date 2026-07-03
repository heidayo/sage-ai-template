#!/usr/bin/env bash
# TASK-0207: mock tsc fixture — 3 errors (SPEC-0030 AC-01 baseline source).
printf 'src/a.ts(1,5): error TS2345: Argument of type '\''string'\'' is not assignable.\n'
printf 'src/b.ts(2,7): error TS2322: Type '\''number'\'' is not assignable to type '\''string'\''.\n'
printf 'src/c.ts(9,1): error TS7006: Parameter '\''x'\'' implicitly has an '\''any'\'' type.\n'
exit 2
