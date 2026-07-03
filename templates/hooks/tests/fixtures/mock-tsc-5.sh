#!/usr/bin/env bash
# TASK-0207: mock tsc fixture — 5 errors (SPEC-0030 AC-02 increase source).
printf 'src/a.ts(1,5): error TS2345: Argument of type '\''string'\'' is not assignable.\n'
printf 'src/b.ts(2,7): error TS2322: Type '\''number'\'' is not assignable to type '\''string'\''.\n'
printf 'src/c.ts(9,1): error TS7006: Parameter '\''x'\'' implicitly has an '\''any'\'' type.\n'
printf 'src/d.ts(4,2): error TS2551: Property '\''foo'\'' does not exist on type '\''Bar'\''.\n'
printf 'src/e.ts(8,3): error TS2769: No overload matches this call.\n'
exit 2
