# PLAN-0023: Claude Collaboration Brief + AGENTS/CLAUDE Pairing Doctrine — implementation plan

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0023 |
| SPEC-ID   | SPEC-0023 |
| ステータス | Review |
| 作成日    | 2026-05-03 |

## 変更レイヤ

- [ ] controller / usecase / domain / frontend (該当なし)
- [x] infrastructure (governance / installer / hook test)
- [x] tooling (scripts/generator/03-rules.sh + 07-installer-main.sh)
- [x] docs (CLAUDE.md / AGENTS.md / sage/governance.md / docs/claude-collaboration-brief.md NEW / templates/claude-md-snippet.md)
- [x] test (templates/hooks/tests/test-claude-collaboration-pairing.sh)

## 影響範囲

- **Claude Code 利用者**: CLAUDE.md §2.1 に collaboration brief reference + Codex-specific files boundary が追加され、新 doc を読むよう誘導される。snippet 経由で新規導入先にも propagate
- **両 CLI 並用 team**: AGENTS.md / CLAUDE.md doctrine が「strict alignment」から「shared/CLI-specific 分離」に formalize され、将来 SPEC の起票時に paired SPEC-ID が要求される
- **新規 SAGE 導入リポジトリ**: install.sh が docs/claude-collaboration-brief.md を生成、template-trust callout 経由で利用者が brief を読める
- **既存利用者**: NFR-01 backward compat により .sage/config.yaml / hooks / scripts は不変、`bash install.sh --update` で brief doc が新規生成 (managed update)
- **CI**: 新 hook test が run-tests.sh に追加され、paired update / doctrine drift / brief 必須セクションを検証
- **maintainer**: 将来 SPEC 起票時に paired SPEC-ID 明示が doctrine 化、漏れは CI test FAIL で検出

## 実装方針

### CLI-specific divergence の formalize

SPEC-0022 が AGENTS.md にのみ Codex-only guidance を追加した時点で、CLAUDE.md L26 の「semantic alignment」doctrine と矛盾が発生した。本 SPEC ではこの矛盾を解消する 2 アプローチを併用:

1. **doctrine 緩和**: §2 文言を「shared rules は alignment 必須、CLI-specific は divergence 可」に更新
2. **paired-update 強制**: governance.md §10 に「CLI-specific 追加は paired SPEC-ID 必須」を新設、CI test で検証

これにより、将来 Codex 側 / Claude 側どちらかに CLI-specific guidance を追加する SPEC が起票された場合、対側 SPEC を必ず paired で起票する手続が形式化される。

### Claude Collaboration Brief の設計思想

Codex の Delegation Packet は「明確な input をもらわないと迷走する」Codex の特性に対応した structured input。一方 Claude Code は collaborative で質問する性質。よって Claude 側 Brief は packet ほど厳密な構造を求めず、以下を中心に:

- Plan Mode / Skill / auto memory の使い分け guide
- Codex に handoff する判断基準 (well-scoped task → packet 化 → 委任)
- 役割分担の semantic mirror (docs/codex-delegation-packet.md と相互参照)

template は markdown blockquote (Codex packet と同形式) で提供するが、入力欄は packet より少なく (Goal / Open Questions / Decision Points / Plan Mode trigger / Codex Handoff trigger / Memory Hooks の 6 セクション)。

### installer 伝播

`scripts/generator/03-rules.sh` の `TMPL_CODEX_DELEGATION_PACKET` (SPEC-0022) 隣接行に `TMPL_CLAUDE_COLLABORATION_BRIEF` を追加し、対称配置を維持。`scripts/generator/07-installer-main.sh` では同 doc を managed_files に追加 (write_file_if_new + update_file)、SPEC-0022 と同 pattern。

### test 設計

7 シナリオ:
1. brief doc 必須セクション (FR-01 の 7 セクション grep)
2. CLAUDE.md collaboration brief reference 存在
3. CLAUDE.md Codex-specific files boundary 存在
4. claude-md-snippet.md parallel 2 bullets 存在
5. CLAUDE.md ↔ AGENTS.md doctrine semantic alignment (両者「may diverge」を含む)
6. governance.md §10「AI Agent Doc Pairing Doctrine」存在
7. install.sh に TMPL_CLAUDE_COLLABORATION_BRIEF + 書き込みパス

異常系 (AC-16/17) は test 内で fixture mutation して FAIL を確認。

## TASK 分割 (5 TASK)

| TASK | 責務 | 見積 | 依存 | 並列可否 |
|---|---|---|---|---|
| TASK-0151 | SPEC + PLAN + 5 TASK draft + sage-evaluate 100/100 PASS | 60m | none | No (foundation) |
| TASK-0152 | `docs/claude-collaboration-brief.md` 新規作成 (FR-01 の 7 セクション) | 75m | TASK-0151 | Yes (TASK-0153 と並列可) |
| TASK-0153 | `CLAUDE.md` §2 doctrine 更新 + §2.1 parallel guidance + `AGENTS.md` §2 doctrine sync + `templates/claude-md-snippet.md` parallel | 45m | TASK-0151 | Yes (TASK-0152 と並列可) |
| TASK-0154 | `sage/governance.md` §10 新設 + `scripts/generator/03-rules.sh` embed + `scripts/generator/07-installer-main.sh` write/update/managed + install.sh 再生成 + .sage-version 1.6.0→1.7.0 + SHA256SUMS sync | 75m | TASK-0152, TASK-0153 | No |
| TASK-0155 | `templates/hooks/tests/test-claude-collaboration-pairing.sh` 9 scenarios + RUN-0008 + final verification (run-tests / sage-doctor / sage-doc-drift / sage-validate) | 60m | TASK-0152, TASK-0153, TASK-0154 | No |
| TASK-0156 | SPEC-0022 test (test-codex-delegation-packet.sh) branch-aware 化 + install --update propagation 取り込み | 30m | TASK-0155 | No |
| TASK-0157 | (Codex review B1) RUN-ID collision fix: RUN-0007 restore + RUN-0008 NEW + TASK-0155 参照更新 | 15m | TASK-0156 | No |
| TASK-0158 | (Codex review M1) test-codex-delegation-packet.sh detached HEAD fallback (`GITHUB_HEAD_REF` / `GITHUB_REF_NAME` 優先) | 20m | TASK-0157 | No |
| TASK-0159 | (Codex review M2/M3/M4) SPEC/PLAN scope expansion + governance §10.5 wording + test scenario 5 強化 | 45m | TASK-0158 | No |
| TASK-0160 | (Codex review m1/m2/m3/n1) status 更新 + 72% claim qualify + count drift 修正 + AGENTS.md §2 文言整合 + install.sh 再生成 | 45m | TASK-0159 | No |

合計: 315 min (initial 5 TASK) + 155 min (Codex review fix 5 TASK) = 470 min (7.8h、wall-clock 240min + 130min = 370min)

## 依存グラフ

```
TASK-0151 (SPEC/PLAN/TASK draft, 60m)
    │
    ├──────────────────────────┐
    ▼                          ▼
TASK-0152 (brief doc, 75m)   TASK-0153 (CLAUDE/AGENTS/snippet, 45m)
    │                          │
    └──────────────┬───────────┘
                   ▼
        TASK-0154 (governance + installer + version, 75m)
                   │
                   ▼
        TASK-0155 (test + RUN-0008 + verification, 60m)
                   │
                   ▼
        TASK-0156 (SPEC-0022 test branch-aware fix, 30m)
                   │
                   ▼
   ── Codex review feedback received (Blocker B1 + Major M1-M4 + Minor + Nit) ──
                   │
                   ▼
        TASK-0157 (RUN-ID collision fix, 15m)
                   │
                   ▼
        TASK-0158 (detached HEAD fallback, 20m)
                   │
                   ▼
        TASK-0159 (SPEC/PLAN scope + governance §10.5 + Scenario 5, 45m)
                   │
                   ▼
        TASK-0160 (status update + qualifications + final regen, 45m)
```

TASK-0152 と TASK-0153 は依存なし (異なる File Scope) で並列可。TASK-0156..0160 は Codex review feedback を受けた sequential fix。

## 検証方法

- **Unit test**: `bash templates/hooks/tests/run-tests.sh` で既存 180 + 新規 7 scenario PASS (合計 187+)
- **Integration test**: `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` 単体で 7/7 PASS、異常系 fixture (AC-16/17) も test 内で simulate
- **Byte-identical regression**: `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` 0 行
- **Backward compat**: 既存 `.sage/config.yaml` (Gist URL fixture) で `bash install.sh --update` exit 0、installer_url 不変
- **Validate / Doctor / Doc-drift**: 既存 3 script で 0 FAIL / PASS

## リスク

PLAN レベル risk (SPEC レベル risk は SPEC-0023 §「依存関係 / リスク」参照):

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | 5 TASK serial 実行で wall-clock 315min 超過 | TASK-0152/0153 並列化、各 TASK 単独完結性で中断・再開可 | `git log --oneline TASK-0151..0155` で 5 commit 順序確認 |
| 2 | brief doc が packet と semantic drift | TASK-0152 で「役割分担」節を packet と相互参照、test scenario 5 で検証 | `diff <(grep "^- " docs/codex-delegation-packet.md) <(grep "^- " docs/claude-collaboration-brief.md)` で対称セクション確認 |
| 3 | CLAUDE.md / AGENTS.md doctrine 文言が片方更新で残る | TASK-0153 で両方を同 commit で更新、test scenario 5 で検証 | `git diff --name-only TASK-0153 -- CLAUDE.md AGENTS.md` で両方含む確認 |
| 4 | install.sh 再生成忘れで配布物が古い (TASK-0154 漏れ) | Phase 5+ / SPEC-0018 教訓、TASK-0154 で明示 | `grep -c "TMPL_CLAUDE_COLLABORATION_BRIEF\|claude-collaboration-brief" install.sh` で 5+ 検出 |
| 5 | governance §10 が長すぎて R7 違反 | NFR-02 で governance §10 は新設のため例外、ただし簡潔 (≤30 行) を維持 | `wc -l sage/governance.md` で増分確認 |
| 6 | snippet 追記で新規 install 後の挙動 regression | NFR-01 backward compat、新規 install のみ snippet 追加分受け取り | 既存 .sage/config.yaml + `bash install.sh --update` で installer_url 不変 |
| 7 | test fixture mutation が flaky | AC-16/17 で git working tree を mutate せず in-memory で simulate (heredoc + grep) | test を 5 回連続実行で全 PASS |
| 8 | Codex review で予期せぬ finding | SPEC-0022 の review pattern (Major 2 件で収束) を参考、1-2 round 想定 | review 履歴で converge 確認 |

## R1-R10 doctrine 適用

| Doctrine | 本 SPEC での適用 |
|---|---|
| **R1** (no branch protection auto-config) | 本 SPEC で branch protection / Ruleset を触らない |
| **R2** (sandbox_mode template only, runtime change なし) | doctrine + doc + test のみ、Claude Code runtime 設定不変 |
| **R3** (Lethal Trifecta warn-only) | EC-06 (Codex side files への意図せぬ編集) は WARN-only、FAIL までは行わない |
| **R4** (no SecPass thresholds) | threshold 概念なし、文書 + test のみ |
| **R5** (RUN log redaction) | 新 doc に secret 例値なし、test fixture は無害な文字列のみ |
| **R6** (license vs security 分離) | 本 SPEC は documentation + governance、license に触らない |
| **R7** (CLAUDE/AGENTS 肥大化禁止) | NFR-02 で各 ≤+5 行明示、長文は docs/claude-collaboration-brief.md に集約 |
| **R8** (hook tests required) | TASK-0155 で 7+ scenario test 必須、AC-16/17 異常系 fixture 含む |
| **R9** (shellcheck required) | AC-20 で test + 既存 modified scripts に shellcheck error 0 件必須 |
| **R10** (一次ソース引用) | docs/claude-collaboration-brief.md は Anthropic Claude Code 公式 docs を一次ソース引用 |

## Cross-model adversarial review

Phase 6.1 / SPEC-0022 implementation review pattern を踏襲:

### Review プロセス

1. **Specify phase**: SPEC + PLAN + 5 TASK draft → sage-evaluate 100 点 PASS → user 承認
2. **Implementation phase**: TASK-0152/0153 並列 → 0154 → 0155 の順で実装
3. **Codex implementation review**: 実装完了後、Codex 側に review を依頼 (本 PR は Claude 側成果なので Codex がレビューする逆方向)
4. **Multi-round 収束**: 1-2 round で converge 見込み (SPEC-0022 で同種 finding 既知)

### Exit criteria

- [ ] **P1 (critical) 0 件**
- [ ] **P2 (should fix) 0 件**
- [ ] **P3 (nit) は明示 accept**
- [ ] **R7 regression なし** — `wc -l` で CLAUDE/AGENTS/snippet 各 ≤+5 行、合計 ≤+15 行
- [ ] **paired update doctrine が実証** — SPEC-0023 自体が SPEC-0022 の paired として起票されている記録 (governance §10 の最初の例)

### 失敗時のエスカレーション

3 round 経過しても新 P2 以上の finding が出続ける場合、SPEC を draft に戻し、Spec Agent で再設計。`sage/failures.md` に「FAIL-SPEC-0023-DESIGN-ITERATION」として記録、user に方針相談。

## 必要な検証

- [x] unit test (`bash templates/hooks/tests/run-tests.sh`)
- [x] integration test (`bash templates/hooks/tests/test-claude-collaboration-pairing.sh`)
- [x] security scan (`bash scripts/sage-validate.sh` + `gitleaks detect`)
- [ ] e2e test (本 SPEC では Claude Code 実セッションで brief 利用は対象外、Phase 2 で別 SPEC)
- [x] architecture boundary check (`bash scripts/sage-doctor.sh` + `bash scripts/sage-doc-drift.sh`)

## 完了条件

- [ ] SPEC-0023 全 AC (AC-01..AC-20) 達成
- [ ] PR description に SPEC-0023 / PLAN-0023 / 5 TASK link + paired with SPEC-0022 明記
- [ ] Codex implementation review 0 件 P1/P2 (本 PR は Claude 側成果のため Codex がレビュー)
- [ ] `.sage-version` 1.6.0 → 1.7.0 (minor bump、新機能追加のため)
- [ ] CHANGELOG entry (該当 file 不在のため、PR description で代用)
