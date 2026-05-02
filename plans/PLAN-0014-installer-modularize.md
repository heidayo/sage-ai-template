# PLAN-0014: installer modularize — implementation plan

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0014 |
| SPEC-ID   | SPEC-0014 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |

## TASK 分割 (3 TASK)

| TASK | 責務 | 見積 | 依存 |
|---|---|---|---|
| TASK-0135 | scripts/generator/ 7 module 抽出 + generate-installer.sh re-write + byte-identical 確認 | 90m | - |
| TASK-0136 | test-installer-modularize.sh (6 シナリオ) + scripts/generator/README.md | 45m | TASK-0135 |
| TASK-0137 | doc cross-refs (5 file R7) + 既存 install.sh 不変確認 (再生成して diff 0) | 30m | TASK-0135..0136 |

合計: 165 min (2.75h)

## 依存グラフ

```
TASK-0135 (extract + rewrite + byte-identical, 90m)
    │
    ▼
TASK-0136 (test + README, 45m)
    │
    ▼
TASK-0137 (docs, 30m)
```

シリアル実行、合計 wall-clock 165min。

## 検証方法

| 検証 | 方法 |
|---|---|
| Byte-identical | `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh \| wc -l` で 0 |
| Module syntax | `for m in scripts/generator/*.sh; do bash -n "$m" \|\| exit 1; done` |
| Unit test | `bash templates/hooks/tests/run-tests.sh` で 159 + 6 = 165+ PASS |
| Doctor regression | `bash scripts/sage-doctor.sh` 0 FAIL |
| Performance | `time bash scripts/generate-installer.sh > install.sh` < 2s (NFR-01) |
| doc-drift | `bash scripts/sage-doc-drift.sh` PASS |

## リスク

PLAN レベル risk:

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | 分割で install.sh が変わる (functional change 混入) | TASK-0135 で byte-identical CI 必須 | `diff install.sh /tmp/new.sh \| wc -l` で 0 |
| 2 | source 順序ミスで embed file 順序が変わる | numeric prefix (01-07) glob sort 保証 | module 命名規則を README で明示 |
| 3 | embed_file 関数の signature 変更で全 module 破壊 | 関数定義は generate-installer.sh のみで、本 SPEC で signature 不変 | git diff で関数定義行が変更されていないこと |
| 4 | doc cross-ref 各 +3 行超過 | TASK-0137 「禁止事項」で R7 厳守明示 | `wc -l` diff |
| 5 | Codex implementation review で予期せぬ finding | Phase 5+ pattern で 1-2 round 収束見込み | review 履歴 |

## R1-R10 doctrine 適用

| Doctrine | 本 SPEC での適用 |
|---|---|
| **R1** (no branch protection auto-config) | 本 SPEC で branch protection / Ruleset を触らない |
| **R2** (sandbox_mode template only, runtime change なし) | 本 SPEC は generator refactor、runtime / install logic 不変 |
| **R3** (Lethal Trifecta warn-only) | 本 SPEC で error 検出 logic を変更しない |
| **R4** (no SecPass thresholds) | 本 SPEC で硬い閾値を設定しない |
| **R5** (RUN log redaction) | 本 SPEC は generator のみ、redaction logic に触らない |
| **R6** (license vs security 分離) | 本 SPEC は maintainability 専念 |
| **R7** (CLAUDE/AGENTS 肥大化禁止) | TASK-0137 で 5 doc each +3 行以内 |
| **R8** (hook tests required) | TASK-0136 で 6 シナリオ test 必須 |
| **R9** (shellcheck required) | scripts/generator/*.sh に shellcheck error 0 件必須 |
| **R10** (一次ソース引用) | bash 公式 docs (source / set -e) |

## Cross-model adversarial review

Phase 1-3 / Phase 5+ implementation review pattern を踏襲:

### Review プロセス

1. **Specify phase**: SPEC + PLAN + 3 TASK draft → sage-evaluate 100 点 → user 承認
2. **Implementation phase**: TASK-0135 → 0136 → 0137
3. **Codex implementation review**: 実装完了後、Phase 5+ 同 format (byte-identical 確認 + module quality)
4. **Multi-round 収束**: 1-2 round 見込み (refactor only、新規 logic 不在)

### Exit criteria

- [ ] **P1 0 件**
- [ ] **P2 0 件**
- [ ] **P3 は明示 accept**
- [ ] **Byte-identical** install.sh 検証 PASS
- [ ] **R7 regression なし** — 5 doc 合計増分 ≤ +15 行
- [ ] **R10 regression なし** — claim に primary source 紐付き

### 失敗時のエスカレーション

byte-identical fail が CI で連続発生する場合、SPEC を draft に戻し、Spec Agent で module 分割境界を再設計。`sage/failures.md` に「FAIL-SPEC-0014-DESIGN-ITERATION」として記録。

## 完了条件

- [ ] SPEC-0014 全 AC (AC-01..AC-12) 達成
- [ ] PR description に SPEC/PLAN/3 TASK link
- [ ] Codex implementation review 0 件 P1/P2
- [ ] **Byte-identical install.sh** 検証 PASS
