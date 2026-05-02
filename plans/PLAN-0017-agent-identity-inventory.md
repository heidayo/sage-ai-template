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

## リスク

PLAN レベル risk (SPEC レベル risk は SPEC-0017 §「依存関係 / リスク」参照):

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | 4 TASK serial 実行で wall-clock 165min が超過 | 並列化なしで明示シリアル、各 TASK 単独完結性で中断・再開可 | `git log --oneline TASK-0127..0130` で 4 commit 順序確認 |
| 2 | install.sh 再生成忘れで template が古い版で配布 | TASK-0130 に install.sh 再生成 + `bash install.sh --update` を明示、Phase 3 の TASK-0117/0119 教訓 | `grep -c "TMPL_SAGE_AGENT_INVENTORY" install.sh` で 4 (declare + write + update + variant) |
| 3 | CLAUDE/AGENTS doc cross-ref が +3 行超過 | TASK-0130 「禁止事項」で R7 厳守明示 | `git diff HEAD~4 HEAD --stat -- AGENTS.md CLAUDE.md SECURITY.md sage/governance.md docs/codex-security.md` |
| 4 | YAML 1.1 bool parse で test flaky | _coerce_yaml_str 共通化 (validator + audit script 両方) | test シナリオ 4 で `network_mode: "off"` quoted 形式と unquoted の両方を確認 |
| 5 | Codex implementation review で予期せぬ finding | Phase 1-3 / Phase 5 と同 pattern で 1-2 round 収束見込み、3+ round になれば SPEC へ巻き戻し | review 履歴で converge 確認 |

## R1-R10 doctrine 適用

| Doctrine | 本 SPEC での適用 |
|---|---|
| **R1** (no branch protection auto-config) | 本 SPEC で branch protection / Ruleset を触らない |
| **R2** (sandbox_mode template only, runtime change なし) | inventory は declarative-only、runtime での agent 認証は SAGE 範囲外 (governance §9.2) |
| **R3** (Lethal Trifecta warn-only) | 本 SPEC の drift detection は warn-only、SPEC-0015 の strict block と異なり inventory drift は FAIL にしない |
| **R4** (no SecPass thresholds) | 本 SPEC で硬い閾値を設定しない、運用 doctrine のみ |
| **R5** (RUN log redaction) | 4 新 field は enum + free-form string のみ、secret 値は記録しない (SPEC-0017 SEC-02 で明示) |
| **R6** (license vs security 分離) | 本 SPEC は security 専念 |
| **R7** (CLAUDE/AGENTS 肥大化禁止) | TASK-0130 で 5 doc each +3 行以内、長文は SPEC-0017 + docs/codex-security.md (§2 末尾 1 行) に集約 |
| **R8** (hook tests required) | TASK-0128 で 6+ scenario test 必須 (実際は 7 シナリオ実装) |
| **R9** (shellcheck required) | sage-runlog-validate.sh / sage-agent-inventory-audit.sh に shellcheck error 0 件必須 |
| **R10** (一次ソース引用) | SPEC-0015 design hints の mapping 表を 1st-party scope として実装、Codex MCP docs / RFC 9110 等の一次ソース継承 |

## Cross-model adversarial review

Phase 1-3 / Phase 5 implementation review pattern を踏襲:

### Review プロセス

1. **Specify phase**: SPEC + PLAN + 4 TASK draft → sage-evaluate 100 点 PASS → user 承認
2. **Implementation phase**: TASK-0127 → 0128 → 0129 → 0130 の順で実装
3. **Codex implementation review**: 実装完了後、Phase 5 と同 format で Codex に依頼
4. **Multi-round 収束**: 1-2 round で converge 見込み (SPEC-0015 で同種 finding 既知のため)

### Exit criteria (収束件数予測ではなく明示判定基準)

実装 PR の Codex review が収束したと判定する基準:

- [ ] **P1 (critical) 0 件**
- [ ] **P2 (should fix) 0 件**
- [ ] **P3 (nit) は明示 accept**
- [ ] **R7 regression なし** — `wc -l` で 5 文書合計増分 ≤ +15 行
- [ ] **R10 regression なし** — 全 claim に primary source URL 紐付き

### 失敗時のエスカレーション

3 round 経過しても新 P2 以上の finding が出続ける場合、SPEC を draft に戻し、Spec Agent で再設計。`sage/failures.md` に「FAIL-SPEC-0017-DESIGN-ITERATION」として記録、user に方針相談。

## 完了条件

- [ ] SPEC-0017 全 AC (AC-01..AC-12) 達成
- [ ] PR description に SPEC/PLAN/4 TASK link
- [ ] Codex implementation review 0 件 P1/P2
