# PLAN-0024: Property-based Verify and Review Gate (SPECA-anchored) — implementation plan

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0024 |
| SPEC-ID   | SPEC-0024 |
| ステータス | Review |
| 作成日    | 2026-05-05 |

## 変更レイヤ

- [ ] controller / usecase / domain / frontend (該当なし、本 SPEC は documentation + tooling)
- [x] infrastructure (governance §11 / installer / hook test)
- [x] tooling (`scripts/generator/06-hooks-phase5.sh` + `scripts/generator/07-installer-main.sh`)
- [x] docs (`CLAUDE.md` / `AGENTS.md` / `sage/governance.md` / `sage/failures.md` / `templates/claude-md-snippet.md` / `templates/agents-md-snippet.md` / `specs/_template.md`)
- [x] skills (`templates/skills/sage-review/SKILL.md` + `.claude/skills/sage-review/SKILL.md`)
- [x] specs retrofit (pilot 3 件: SPEC-0011 / SPEC-0014 / SPEC-0015)
- [x] test (`templates/hooks/tests/test-property-section.sh`)

## 影響範囲

- **新規 SPEC 起票者 (Spec Agent)**: SPEC-0024 merge 以降、`specs/_template.md` の Properties セクションに権限レベル別の下限で記入が要求される (system/platform + Security 要件あり = 5 件以上必須、その他は推奨/任意)
- **Verify phase の Implementation/Review Agent**: Property → Gate matrix で機械的 proof-attempt が可能になる。Map → Prove → Stress-Test の手順は governance §11 で明記
- **Review skill 利用者**: 3-gate FP filter (Dead Code / Trust Boundary / Scope Check) で finding 自動分類、新 verdict (OUT_OF_TASK_SCOPE / FOLLOW_UP_REQUIRED / DISPUTED_FP / SKIPPED_WITH_APPROVAL_REQUIRED) で粒度向上
- **既存 SPEC 利用者**: NFR-01 backward compat により既存 23 SPEC は触らない、incremental migration (OPS-02)。pilot 3 件 (SPEC-0011/0014/0015) のみ Properties additive 追加
- **新規 SAGE 導入リポジトリ**: install.sh が Property template を配置、新規 SPEC はセクション込みで生成
- **CI**: 新 hook (test-property-section.sh) が run-tests.sh に追加 (9 scenarios)、SPEC-0023 paired test (test-claude-collaboration-pairing.sh) を流用して CLAUDE/AGENTS 同期検証
- **Codex 並用 team**: paired-update doctrine 準拠 (SPEC-0023 §10) で AGENTS.md / agents-md-snippet.md にも parallel reference 追加 (Codex 専用本文は scope 外)
- **maintainer**: failures.md に cause field (additive) で root-cause 集計が可能になる、anti-pattern 昇格判定が定量化

## 実装方針

### Property doctrine の採用根拠

[NyxFoundation/speca](https://github.com/NyxFoundation/speca/) は「コードから怪しい箇所を探す」のではなく「仕様から証明試行する」逆方向の audit framework。SAGE は audit framework ではなく開発統制 system だが、SPECA の Phase 03 (Map → Prove → Stress-Test) と Phase 04 (3-gate FP filter) は Verify / Review phase に直接適用可能。

ただし、wholesale 採用ではなく以下の選択的取込:

1. **取り込む**: Property declarative 記述 / Map-Prove-Stress 手順 / 3-gate FP filter / FP cause 分類
2. **取り込まない**: SPECA Phase 01a (URL crawl) / STRIDE+CWE Top 25 (protocol/crypto 偏向) / Python orchestrator (sage-harness は別 SPEC) / Tree-sitter pre-resolution (別 SPEC)

### 4 種別 Property の責務分離

| 種別 | 用途 | 主 Gate | 例 |
|---|---|---|---|
| Invariant | 常に成立すべき不変条件 | Gate 3 / Gate 4 | RLS policy / OAuth callback uniqueness |
| Pre-condition | 関数/API 入口の前提 | Gate 2 | 入力 schema validity |
| Post-condition | 関数/API 出口の保証 | Gate 2 | 出力 schema validity / state transition |
| Assumption | 仕様外の前提 (環境/ツール) | 横断 | Python 3 存在 / transport が stdio/http |

権限レベル別の下限 (FR-09 / OPS-04):

| 権限レベル | Property 件数 | Properties: not applicable 許容 |
|---|---|---|
| `system` / `platform` + Security 要件あり | 5 件以上必須 | 不可 |
| `platform` (Security 要件なし) | 3 件以上推奨 | 不可 |
| `feature` (低リスク) | 任意 | 可 (理由必須) |

### Verdict 体系の設計

SPECA Phase 04 の verdict (CONFIRMED_VULNERABILITY / DISPUTED_FP / DOWNGRADED / NEEDS_MANUAL_REVIEW / PASS_THROUGH) を SAGE 用に再設計。SPECA は audit framework なので「bug を見つけて confirmed か否か」が主だが、SAGE は実装 review なので「実装が SPEC と整合か否か」が主。よって以下のマッピング:

| SAGE verdict | SPECA 対応 | SAGE 用途 |
|---|---|---|
| PASS | PASS_THROUGH | Property 全件証明試行成功 |
| FAIL | CONFIRMED_VULNERABILITY | Property 違反 + 反例あり |
| OUT_OF_TASK_SCOPE | (新規) | Finding が TASK 範囲外既存問題 |
| FOLLOW_UP_REQUIRED | (新規) | Finding 妥当だが本 TASK で fix しない |
| DISPUTED_FP | DISPUTED_FP | 実装正しく Finding が誤り |
| SKIPPED_WITH_APPROVAL_REQUIRED | NEEDS_MANUAL_REVIEW | 証明できないが反例も無い、人間承認待ち |

Hard Fail (File Scope 違反 / Gate 1-4 fail / secret / 既知脆弱性) は 3-gate FP filter で覆せない (§11.4)、SPECA の recall-safe doctrine と整合。

### 3-gate FP filter の早期 exit

```
finding raised
    │
    ▼
[Gate 1: Dead Code]
    ├── 実行されない経路 → DISPUTED_FP (audit log: dead_code reason)
    │   exit
    └── 実行される経路 → next gate
    │
    ▼
[Gate 2: Trust Boundary]
    ├── untrusted input が制御不可 → 別 finding に切り分け
    │   continue (新 finding raise)
    └── trust boundary 内 → next gate
    │
    ▼
[Gate 3: Scope Check]
    ├── TASK File Scope 外既存問題 → OUT_OF_TASK_SCOPE
    │   exit (Finding 記録のみ、merge 可)
    ├── 本 TASK で fix しない判断 → FOLLOW_UP_REQUIRED
    │   exit (follow-up TASK 起票必須)
    └── TASK 範囲内 + 妥当 → finding 維持 (verdict: FAIL or PASS)
```

### paired update doctrine の踏襲

SPEC-0023 §10 で formalized された paired update doctrine を本 SPEC が踏襲する 2 つ目の事例。

- **shared-core (TASK-0162)**: `specs/_template.md` + `sage/governance.md` §11 (両 CLI 共通 doctrine)
- **Claude-facing (TASK-0163)**: `CLAUDE.md` + `templates/claude-md-snippet.md`
- **Codex-facing (TASK-0164)**: `AGENTS.md` + `templates/agents-md-snippet.md`
- **paired-verification (TASK-0170)**: 既存 `templates/hooks/tests/test-claude-collaboration-pairing.sh` を流用 (新 hook 不要、grep 範囲拡張のみ)

### installer 伝播

`specs/_template.md` の Properties セクションは既存 `scripts/generator/01-templates.sh` の `TMPL_SPEC` embed で伝播。`scripts/generator/06-hooks-phase5.sh` に `TMPL_TEST_PROPERTY_SECTION` embed を追加し、`scripts/generator/07-installer-main.sh` に `templates/hooks/tests/test-property-section.sh` の write/update エントリ追加 (SPEC-0023 同 pattern)。`install.sh` 再生成、`.sage-version` 1.7.1 → 1.8.0 (minor bump、新 hook + 新 verdict 追加)。

## TASK 分割 (10 TASK)

| TASK | 責務 | 担当境界 | 見積 | 依存 | 並列可否 |
|---|---|---|---|---|---|
| TASK-0161 | SPEC + PLAN + 10 TASK draft + sage-evaluate 100/100 PASS | shared-core | 75m | none | No (foundation) |
| TASK-0162 | `specs/_template.md` Properties セクション + `sage/governance.md` §11 (5 sub-section) 新設 | shared-core | 60m | TASK-0161 | No (governance 確定が後続前提) |
| TASK-0163 | `CLAUDE.md` §9 cross-ref (≤+5 行) + `templates/claude-md-snippet.md` parallel bullets (≤+2 行) | Claude-facing | 30m | TASK-0162 | Yes (TASK-0164 と並列) |
| TASK-0164 | `AGENTS.md` §9 cross-ref (≤+5 行) + `templates/agents-md-snippet.md` parallel bullets (≤+2 行) | Codex-facing | 30m | TASK-0162 | Yes (TASK-0163 と並列) |
| TASK-0165 | `templates/skills/sage-review/SKILL.md` 3-gate FP filter + 6 verdict 拡張 + `.claude/skills/sage-review/SKILL.md` 同期 | shared-core | 60m | TASK-0162 | Yes (TASK-0166 と並列) |
| TASK-0166 | `sage/failures.md` cause field additive (template only、既存 entry 不変) | shared-core | 20m | TASK-0162 | Yes (TASK-0165 と並列) |
| TASK-0167 | pilot retrofit: SPEC-0011 / SPEC-0014 / SPEC-0015 に Properties セクション additive (各 5 件以上) | pilot | 90m | TASK-0162 | Yes (上記 4 TASK と並列、別 File Scope) |
| TASK-0168 | `templates/hooks/tests/test-property-section.sh` 新規 (9 scenarios) + `templates/hooks/tests/run-tests.sh` 統合 | shared-core | 60m | TASK-0162, TASK-0167 | No (pilot 完了が test fixture 前提) |
| TASK-0169 | `scripts/generator/06-hooks-phase5.sh` embed + `scripts/generator/07-installer-main.sh` write entry + `install.sh` 再生成 + `.sage-version` 1.7.1→1.8.0 + `SHA256SUMS` 同期 (PR 内) | shared-core | 75m | TASK-0163, TASK-0164, TASK-0165, TASK-0166, TASK-0167, TASK-0168 | No |
| TASK-0170 | paired-verification (test-claude-collaboration-pairing.sh 流用 grep 拡張) + RUN-0009 + final verification (run-tests / sage-doctor / sage-doc-drift / sage-validate) | paired-verification | 45m | TASK-0169 | No |

合計: 545 min (9.1h、wall-clock 並列実行で約 360min = 6h)

## 依存グラフ

```
TASK-0161 (foundation: SPEC + PLAN + TASK draft + evaluate, 75m)
    │
    ▼
TASK-0162 (template + governance §11, 60m)
    │
    ├──────────┬──────────┬──────────┬──────────┐
    ▼          ▼          ▼          ▼          ▼
TASK-0163  TASK-0164  TASK-0165  TASK-0166  TASK-0167
(CLAUDE,   (AGENTS,   (review    (failures  (pilot
30m)       30m)       skill,     schema,    retrofit,
                      60m)       20m)       90m)
    │          │          │          │          │
    └──────────┴──────────┴──────────┴──────────┤
                                                ▼
                              TASK-0168 (test-property-section + integration, 60m)
                                                │
                                                ▼
                              TASK-0169 (generator + install.sh + version, 75m)
                                                │
                                                ▼
                              TASK-0170 (paired-verification + RUN + final, 45m)
                                                │
                                                ▼
                              ── Codex implementation review ──
```

並列実行: TASK-0163 / 0164 / 0165 / 0166 / 0167 は TASK-0162 完了後すべて File Scope が異なるため並列可能 (4 stream で wall-clock 短縮)。TASK-0168 は pilot fixture 利用で 0167 完了後、TASK-0169 は全 doctrine 確定後、TASK-0170 は最終 verification として sequential。

## 検証方法

- **Unit test**: `bash templates/hooks/tests/run-tests.sh` で既存 189 + 新規 9 scenario PASS (合計 198+)
- **Integration test**: `bash templates/hooks/tests/test-property-section.sh` 単体で 9/9 PASS、異常系 fixture (AC-14/15) と AC-20 audit schema を test 内で simulate
- **Byte-identical regression**: `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` 0 行
- **Backward compat**: 既存 `.sage/config.yaml` (Gist URL fixture) で `bash install.sh --update` exit 0、`installer_url` 不変、既存 SPEC は WARN-only
- **Validate / Doctor / Doc-drift**: 既存 3 script で 0 FAIL / PASS
- **Paired update**: `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` PASS (CLAUDE/AGENTS 同期検証で SPEC-0024 reference 確認)
- **Pilot Property 件数**: `for f in 0011 0014 0015; do n=$(grep -cE "^- \[(INV|PRE|POST|ASM)-[0-9]+\]" specs/SPEC-$f-*.md); [ "$n" -ge 5 ] || exit 1; done` 全件 5+
- **Existing FAIL-0001 unchanged**: `git diff main HEAD -- sage/failures.md` で FAIL-0001 entry の本文に変化なし (cause field 追加のみ template 節)

## リスク

PLAN レベル risk (SPEC レベル risk は SPEC-0024 §「リスク」参照):

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | 10 TASK 並列 4 stream 実行で wall-clock 360min 超過 | TASK-0163/0164/0165/0166/0167 は File Scope 異なるため並列可、各 TASK 単独完結 | `git log --oneline TASK-0161..0170` で 10 commit 順序確認、wall-clock 集計 |
| 2 | pilot 3 件 Property が AC と矛盾 | 実装メモで AC ↔ Property 対応表を SPEC 内に併記、矛盾発生時は SPEC 更新手続を governance §11.4 で規定 | pilot 完了時に対応表 review |
| 3 | governance §11 が長すぎて R7 違反 | NFR-02 で §11 ≤ 80 行明示、長文は SPEC-0024 本文に集約 | `awk '/^## §11/,/^## §12\|^# /' sage/governance.md \| wc -l` ≤ 80 |
| 4 | install.sh 再生成忘れ | TASK-0169 で明示、SPEC-0023 / SPEC-0018 教訓 | `bash scripts/generate-installer.sh > /tmp/new && diff install.sh /tmp/new` 0 行 |
| 5 | 3-gate FP filter test で flaky fixture | TASK-0168 で fixture を heredoc + grep simulate、git working tree 不変 | test を 5 回連続実行で全 PASS |
| 6 | Codex review で予期せぬ finding | SPEC-0023 同 pattern (1-2 round 収束想定)、3 round 超なら SPEC 巻き戻し | review 履歴で converge 確認 |
| 7 | 既存 SPEC で Property WARN noise が多発 | NFR-06 で incremental migration、profile gating で `strict` 時のみ FAIL、`standard` は WARN-only | OPS-04 で 14 日運用後判定 |
| 8 | SKIPPED_WITH_APPROVAL_REQUIRED の濫用 | NFR-05 audit log 必須、OPS-04 件数集計、5 件超で governance review 起動 | `wc -l .sage/audit/property-skip-*.log` 週次 |
| 9 | paired update doctrine 違反 | SPEC-0023 既存 paired test 流用 (TASK-0170)、CI で FAIL | `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` |
| 10 | Property 記述の冗長化 → SPEC 起票負荷↑ | 権限レベル別下限 (FR-09)、最小件数のみ規定で上限なし | pilot 完了後 wc -l 増分 ≤ 30% |

## R1-R10 doctrine 適用

| Doctrine | 本 SPEC での適用 |
|---|---|
| **R1** (no branch protection auto-config) | 本 SPEC で branch protection / Ruleset を触らない |
| **R2** (sandbox_mode template only) | doctrine + doc + test のみ、Claude Code / Codex runtime 設定不変 |
| **R3** (Lethal Trifecta warn-only) | 3-gate FP filter の DISPUTED_FP は audit log 記録必須 (SEC-03) |
| **R4** (no SecPass thresholds) | threshold 概念なし、verdict + audit log のみ |
| **R5** (RUN log redaction) | SKIPPED_WITH_APPROVAL_REQUIRED の audit log は env 名のみ (SEC-02) |
| **R6** (license vs security 分離) | 本 SPEC は documentation + governance、license に触らない |
| **R7** (CLAUDE/AGENTS 肥大化禁止) | NFR-02 で各 ≤+5 行明示、長文は SPEC-0024 + governance §11 に集約 |
| **R8** (hook tests required) | TASK-0168 で 9 scenario test 必須、AC-14/15 異常系 fixture + AC-20 audit schema 含む |
| **R9** (shellcheck required) | AC-19 で test + 既存 modified scripts に shellcheck error 0 件必須 |
| **R10** (一次ソース引用) | SPECA paper [arXiv:2604.26495](https://arxiv.org/abs/2604.26495) と [GitHub repo](https://github.com/NyxFoundation/speca/) を一次ソース引用 |

## Cross-model adversarial review

Phase 6.1 / SPEC-0022 / SPEC-0023 implementation review pattern を踏襲。

### Review プロセス

1. **Specify phase**: SPEC + PLAN + 10 TASK draft → sage-evaluate 100 点 PASS → user 承認 (現在ここ)
2. **Implementation phase**: TASK-0162 (foundation) → TASK-0163/0164/0165/0166/0167 並列 → TASK-0168 → TASK-0169 → TASK-0170 の順
3. **Codex implementation review**: 実装完了後、Codex 側に review を依頼 (本 PR は Claude 側成果なので Codex がレビューする逆方向)
4. **Multi-round 収束**: 1-2 round で converge 見込み (SPEC-0023 同 pattern、Codex feedback 6 点既反映済)

### Exit criteria

- [ ] **P1 (critical) 0 件**
- [ ] **P2 (should fix) 0 件**
- [ ] **P3 (nit) は明示 accept**
- [ ] **R7 regression なし** — `wc -l` で CLAUDE/AGENTS/snippet 各 ≤+5 行、合計 ≤+15 行
- [ ] **paired update doctrine が 2 回目の実証** — SPEC-0024 が SPEC-0023 の paired-update doctrine を踏襲、governance §10 の 2 例目として記録
- [ ] **pilot Property 5 件以上** — SPEC-0011/0014/0015 各 5 件以上 (AC-02)

### 失敗時のエスカレーション

3 round 経過しても新 P2 以上の finding が出続ける場合、SPEC を draft に戻し Spec Agent で再設計。`sage/failures.md` に「FAIL-PROP-DESIGN-ITERATION」として記録、user に方針相談。

## 必要な検証 (Required verification — 実装完了時に check)

- [ ] unit test (`bash templates/hooks/tests/run-tests.sh`)
- [ ] integration test (`bash templates/hooks/tests/test-property-section.sh`)
- [ ] security scan (`bash scripts/sage-validate.sh` + `gitleaks detect`)
- [ ] paired update test (`bash templates/hooks/tests/test-claude-collaboration-pairing.sh`)
- [ ] e2e test (本 SPEC では Claude Code 実セッションで Property doctrine 利用は対象外、別 SPEC で運用 phase 評価) — N/A
- [ ] architecture boundary check (`bash scripts/sage-doctor.sh` + `bash scripts/sage-doc-drift.sh`)

## 完了条件

- [ ] SPEC-0024 全 AC (AC-01..AC-20) 達成
- [ ] PR description に SPEC-0024 / PLAN-0024 / 10 TASK link + paired with SPEC-0023 doctrine の 2 例目である旨明記
- [ ] Codex implementation review 0 件 P1/P2 (本 PR は Claude 側成果のため Codex がレビュー)
- [ ] `.sage-version` 1.7.1 → 1.8.0 (minor bump、新 hook + 新 verdict 追加)
- [ ] CHANGELOG entry (該当 file 不在のため、PR description で代用)
