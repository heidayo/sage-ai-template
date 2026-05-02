# PLAN-0016: RUN log SQLite-FTS — implementation plan

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0016 |
| SPEC-ID   | SPEC-0016 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |

## TASK 分割 (4 TASK)

| TASK | 責務 | 見積 | 依存 |
|---|---|---|---|
| TASK-0131 | SQLite schema + indexer (`sage-runlog-index.sh`) + 4 シナリオ test | 75m | - |
| TASK-0132 | search CLI (`sage-runlog-search.sh`) + 6 シナリオ test | 60m | TASK-0131 |
| TASK-0133 | doctor [5/6] step + audit script + 2 シナリオ test | 45m | TASK-0132 |
| TASK-0134 | doc cross-refs (5 file) + installer regen + v1.3.0 → 1.4.0 | 30m | TASK-0131..0133 |

合計: 210 min (3.5h)

## 依存グラフ

```
TASK-0131 (foundation, 75m)
    │
    ▼
TASK-0132 (search CLI, 60m)
    │
    ▼
TASK-0133 (doctor [5/6], 45m)
    │
    ▼
TASK-0134 (docs + installer, 30m)
```

シリアル実行、合計 wall-clock 210min。

## 検証方法

| 検証 | 方法 |
|---|---|
| Unit test | `bash templates/hooks/tests/run-tests.sh` で 145 + 12 = 157+ PASS |
| Indexer perf | `time bash scripts/sage-runlog-index.sh --full` (1000 RUN log) < 5s |
| Search functional | filter 6 種 + FTS query 全動作 |
| Doctor regression | `bash scripts/sage-doctor.sh` 0 FAIL |
| doc-drift | `bash scripts/sage-doc-drift.sh` PASS |
| DB permission | `stat .sage/runs.db` で 600 |

## リスク

PLAN レベル risk:

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | indexer の wall-clock 75min が超過 | Python sqlite3 in-memory transaction で最適化 | `time` 計測 |
| 2 | install.sh 再生成忘れ | TASK-0134 「禁止事項」で明示 (Phase 3 教訓) | `grep -c "TMPL_SCRIPT_RUNLOG_INDEX" install.sh` で >= 4 |
| 3 | CLAUDE/AGENTS doc cross-ref +3 行超過 | TASK-0134 「禁止事項」で R7 厳守明示 | `wc -l` diff |
| 4 | SQLite FTS5 syntax の test flaky | search test に予期 query / 不正 query 両方 inject | test シナリオ 6 で網羅 |
| 5 | Codex implementation review で予期せぬ finding | Phase 1-3 / Phase 5 と同 pattern で 1-2 round 収束見込み | review 履歴 |

## R1-R10 doctrine 適用

| Doctrine | 本 SPEC での適用 |
|---|---|
| **R1** (no branch protection auto-config) | 本 SPEC で branch protection / Ruleset を触らない |
| **R2** (sandbox_mode template only, runtime change なし) | indexer + searcher は read-only から source、SAGE doctrine §9.2 維持 |
| **R3** (Lethal Trifecta warn-only) | indexer error は warn-only、validator 全体は PASS |
| **R4** (no SecPass thresholds) | 本 SPEC で硬い閾値を設定しない、運用 doctrine のみ |
| **R5** (RUN log redaction) | SEC-01 で SPEC-0012 redaction を維持、indexer は redact しない (元 file をそのまま store) |
| **R6** (license vs security 分離) | 本 SPEC は operations 専念 |
| **R7** (CLAUDE/AGENTS 肥大化禁止) | TASK-0134 で 5 doc each +3 行以内 |
| **R8** (hook tests required) | TASK-0131..0133 で計 12 シナリオ test 必須 |
| **R9** (shellcheck required) | sage-runlog-index.sh / sage-runlog-search.sh に shellcheck error 0 件必須 |
| **R10** (一次ソース引用) | SQLite FTS5 公式 docs を一次ソースとして引用 |

## Cross-model adversarial review

Phase 1-3 / Phase 5 implementation review pattern を踏襲:

### Review プロセス

1. **Specify phase**: SPEC + PLAN + 4 TASK draft → sage-evaluate 100 点 PASS → user 承認
2. **Implementation phase**: TASK-0131 → 0132 → 0133 → 0134 の順で実装
3. **Codex implementation review**: 実装完了後、Phase 5 同 format
4. **Multi-round 収束**: 1-2 round 見込み (Phase 5 で同 pattern 既習)

### Exit criteria

- [ ] **P1 0 件**
- [ ] **P2 0 件**
- [ ] **P3 は明示 accept**
- [ ] **R7 regression なし** — 5 doc 合計増分 ≤ +15 行
- [ ] **R10 regression なし** — claim に primary source 紐付き

### 失敗時のエスカレーション

3 round 経過しても新 P2 以上の finding が出続ける場合、SPEC を draft に戻し、Spec Agent で再設計。`sage/failures.md` に「FAIL-SPEC-0016-DESIGN-ITERATION」として記録。

## 完了条件

- [ ] SPEC-0016 全 AC (AC-01..AC-12) 達成
- [ ] PR description に SPEC/PLAN/4 TASK link
- [ ] Codex implementation review 0 件 P1/P2
