# 失敗ログ (fixture: GATE-FP 複数件・欠番あり)

TASK-0210 test fixture: failures.md with two GATE-FP entries and a gap in the
number sequence (the second number is intentionally missing — gaps must NOT
be reused), plus one FAIL entry (number spaces are independent, 境界ケース3).
NOTE: the numbering scan is grep-based and counts every ID-shaped string in
this file (SPEC-0031 境界ケース2), so this prose must not contain concrete
FAIL/GATE-FP numbers beyond the entries below.

## FAIL-0001: fixture failure entry

- 発生日: 2026-01-01
- 内容: fixture entry for numbering

## GATE-FP-0001: fixture gate false positive entry

- 発生日: 2026-02-01
- 誤検知した Gate: Gate 2 / unit test fixture
- 再発回数: 1

## GATE-FP-0003: fixture gate false positive entry (gap before this)

- 発生日: 2026-02-03
- 誤検知した Gate: Gate 3 / secret scan fixture
- 再発回数: 1
