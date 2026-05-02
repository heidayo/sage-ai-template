# PLAN-0017: agent identity inventory + RUN log runtime field — implementation plan

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0017 |
| SPEC-ID   | SPEC-0017 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |

## TASK 分割 (4 TASK)

| TASK | 責務 | 見積 | 依存 |
|---|---|---|---|
| TASK-0127 | inventory schema + template + RUN log template + config.yaml 拡張 | 30m | - |
| TASK-0128 | sage-runlog-validate.sh 拡張 + 6 test シナリオ | 60m | TASK-0127 |
| TASK-0129 | sage-doctor.sh 拡張 + Python audit script | 45m | TASK-0128 |
| TASK-0130 | doc cross-refs (5 file) + installer regen + v1.2.1→1.3.0 | 30m | TASK-0127..0129 |

合計: 165 min (2.75h、Phase 5 学習で短縮)

## 依存グラフ

```
TASK-0127 (foundation, 30m)
    │
    ▼
TASK-0128 (validator + tests, 60m)
    │
    ▼
TASK-0129 (doctor, 45m)
    │
    ▼
TASK-0130 (docs + installer, 30m)
```

シリアル実行、合計 wall-clock 165min。

## 検証方法

- Unit test: `bash templates/hooks/tests/run-tests.sh` で既存 + 新規 6 シナリオ PASS
- Validator regression: 既存 4 RUN log (.sage/runs/RUN-000[1-4].yaml) で validator PASS
- Doctor regression: `bash scripts/sage-doctor.sh` 0 FAIL
- doc-drift: `bash scripts/sage-doc-drift.sh` PASS

## R1-R10 doctrine 適用

- R5 (redaction): 4 新 field は enum / free-form string、secret 不記録
- R7 (CLAUDE/AGENTS 肥大化禁止): 5 doc each +3 行以内
- R8 (hook tests): 6+ scenario test 必須
- R10 (一次ソース): SPEC-0015 design hints の mapping 表を 1st-party scope として実装

## Cross-model adversarial review

Phase 1-3 / Phase 5 implementation review pattern を踏襲:
- 4 TASK 完了後 PR 作成
- Codex implementation review 1-2 round で収束見込み (SPEC-0015 で同種 finding 既知のため)
- Specify-phase review ループは打ち切り (Phase 5 学習)

## 完了条件

- [ ] SPEC-0017 全 AC (AC-01..AC-12) 達成
- [ ] PR description に SPEC/PLAN/4 TASK link
- [ ] Codex implementation review 0 件 P1/P2
