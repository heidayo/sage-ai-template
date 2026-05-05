# SPEC-0024: Property-based Verify and Review Gate (SPECA-anchored)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0024 |
| ステータス | Draft |
| 作成日    | 2026-05-05 |
| 更新日    | 2026-05-05 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0007 (AI risk mitigation), SPEC-0015 (MCP audit), SPEC-0023 (pairing doctrine) |
| 権限レベル | platform |
| 予約Phase | Phase 6.x (SPEC-0019 / SPEC-0020 と並行) |
| 一次ソース | [NyxFoundation/speca](https://github.com/NyxFoundation/speca/) (Phase 03 Map→Prove→Stress-Test, Phase 04 3-gate FP filter), [arXiv:2604.26495](https://arxiv.org/abs/2604.26495) |

## 背景・目的

SAGE は Phase 1-6.1 で多層の防御を整備してきた:

- **Phase 1-3** (SPEC-0010..0013): hooks (block-dangerous-commands / protect-sage-files / check-file-scope) + Codex security guide
- **Phase 5** (SPEC-0014/0015/0016/0017): installer modularize / MCP allowlist audit / runlog SQLite-FTS / agent identity inventory
- **Phase 6.1** (SPEC-0018/0022/0023): supply chain hardening (Releases + SHA256SUMS) / Codex Delegation Packet / Claude Collaboration Brief + paired-update doctrine

これらにより「危険コマンドの block」「supply chain drift の audit」「commit/agent identity の trace」までは到達した。しかし、以下のギャップが残る:

1. **SPEC 受け入れ条件 (AC) は「コマンド pass/fail」階層しか持たない**: 例えば SPEC-0015 は AC-01..AC-13 で grep / hook test 結果を確認するが、「MCP server 承認の transitive trust」「OAuth callback port の host-wide uniqueness」のような **不変条件 (Invariant)** は declarative に表現されておらず、Verify phase で機械的に証明試行する仕組みがない
2. **Review Agent は finding を出すが、SPECA Phase 04 の 3-gate FP filter (Dead Code / Trust Boundary / Scope Check) を持たない**: AI Review が出す finding の false positive 率が定量化されていない (現状の SPEC-0007 AP-08 Comprehension Debt の認識止まり)
3. **failures.md は失敗の root-cause 分類が一貫していない**: SPECA は FP の 3 大原因 (Trust boundary misunderstanding 50% / Code reading error 37.5% / Specification misinterpretation 12.5%) を実証データで提示。SAGE の `sage/failures.md` には `cause` field がなく、anti-pattern 昇格判定が定性的

[NyxFoundation/speca](https://github.com/NyxFoundation/speca/) は **「コードから怪しい箇所を探す」のではなく「仕様から証明試行する」** という逆方向の audit framework を提示し、KZG batch verification bug のような数学的 Invariant 違反を実証検出している。SAGE は audit framework ではなく開発統制 system だが、SPECA の **Property → Map → Prove → Stress-Test** および **3-gate FP filter** は SAGE の Verify / Review phase に直接適用できる。

本 SPEC はこの 3 ギャップを埋める:

1. SPEC template に **Properties** セクション (Invariant / Pre-condition / Post-condition / Assumption の 4 種別) を導入し、Property → Gate matrix を governance に明記
2. Review skill (`templates/skills/sage-review/SKILL.md`) に **3-gate FP filter** (Dead Code / Trust Boundary / Scope Check) と新 verdict (OUT_OF_TASK_SCOPE / FOLLOW_UP_REQUIRED / DISPUTED_FP / SKIPPED_WITH_APPROVAL_REQUIRED) を追加
3. `sage/failures.md` template に `cause` field (additive、既存 entry retrofit なし) を追加

これらは SPECA 一次ソースに基づく一次採用であり、本 SPEC merge 時点で SAGE は SPECA-anchored development system として位置付けられる。

## 対象ユーザー

- 標準 lane (`feature/*`) で SPEC を起票する Spec Agent (Properties セクション必須)
- Verify phase を回す Implementation / Review Agent (Property → Gate matrix で機械検証)
- 高リスク領域 (auth / RLS / MCP / installer / hooks) を扱う組織 (proof-attempt による Invariant 違反検出)
- Review skill を利用する Review Agent (3-gate FP filter で FP 抑制)
- 失敗ログを集計する maintainer (cause field で root-cause 分類)
- Codex / Claude 並用 team (paired-update doctrine 準拠で両 CLI に Properties guidance 同期)

## スコープ（含む）

### template / governance 変更

- `specs/_template.md` に **「## Properties」セクション** 新設:
  - 4 種別: `[INV-NN]` Invariant / `[PRE-NN]` Pre-condition / `[POST-NN]` Post-condition / `[ASM-NN]` Assumption
  - 各 Property に Gate mapping (Gate 2 / 3 / 4) を必須記入
  - 権限レベル別の下限規定 (下記 FR-09)
- `sage/governance.md` に **新節 §11「Property-based Verify and Review Gate」** 新設:
  - Property → Gate matrix
  - Verdict 体系 (Hard Fail / OUT_OF_TASK_SCOPE / FOLLOW_UP_REQUIRED / DISPUTED_FP / SKIPPED_WITH_APPROVAL_REQUIRED)
  - 3-gate FP filter doctrine (Dead Code / Trust Boundary / Scope Check)
  - Property 不変条件証明試行手順 (Map → Prove → Stress-Test)

### Review skill 強化

- `templates/skills/sage-review/SKILL.md` および `.claude/skills/sage-review/SKILL.md` (同期):
  - 「3-gate FP filter」セクション追加 (Dead Code → Trust Boundary → Scope Check の早期 exit)
  - `verdict` enum 拡張: `PASS` / `FAIL` (既存) + `OUT_OF_TASK_SCOPE` / `FOLLOW_UP_REQUIRED` / `DISPUTED_FP` / `SKIPPED_WITH_APPROVAL_REQUIRED` (新規)
  - 既存 Hard Fail 条件 (File Scope 違反 / Gate 1-4 fail / secrets / 既知脆弱性) は **強化維持** — DISPUTED_FP では覆せない
- `templates/skills/sage-review/references/review-scoring-rubric.md` (存在時): FP filter 適用後の subscore 算出ロジックを追記

### failures.md schema 拡張

- `sage/failures.md` の **エントリフォーマット節** に `cause` field 追加 (additive、新規 entry のみ任意記入推奨):
  - enum: `trust-boundary` / `code-reading` / `spec-misinterpretation` / `not-applicable` / `other`
  - 既存 `FAIL-0001` は **変更しない** (推定 retrofit 禁止、SAGE doctrine: 「cause を後付け推定するのは spec-misinterpretation の温床」)

### pilot retrofit (3 件)

- 高リスク既存 SPEC 3 件に Properties セクションを additive で後付け追加:
  - [SPEC-0011](SPEC-0011-hook-hardening-and-test-infrastructure.md) (hook hardening、5 Properties 以上)
  - [SPEC-0014](SPEC-0014-installer-modularize.md) (installer modularize、5 Properties 以上)
  - [SPEC-0015](SPEC-0015-mcp-allowlist-audit-and-agent-identity.md) (MCP allowlist audit、5 Properties 以上)
  - 既存 AC は変更しない (additive、AC ↔ Property の整合性は実装メモで説明)

### 検証 hook + test

- `templates/hooks/tests/test-property-section.sh` 新規:
  - 新規 SPEC (SPEC-0024 以降) に Properties セクション存在チェック
  - 権限レベル別の下限判定 (system / platform + Security 要件あり = 5 件以上、その他は警告のみ)
  - 異常系 fixture (Property 削除 / Gate mapping 欠落) で FAIL を返す
- `templates/hooks/tests/run-tests.sh` に新 test 統合
- `.claude/skills/sage-review/SKILL.md` に新 verdict が含まれることの sync 検証 (既存 sage-doc-drift.sh 流用)

### paired update (CLAUDE/AGENTS 同期、SPEC-0023 §10 doctrine 準拠)

- `CLAUDE.md` §9 (Quality Gate Checklist) に Property-based Verify reference 追加 (R7 ≤+5 行)
- `AGENTS.md` §9 相当箇所に Property-based Verify reference 追加 (R7 ≤+5 行)
- `templates/claude-md-snippet.md` および `templates/agents-md-snippet.md` に同 reference (新規導入先に propagate)
- `docs/codex-delegation-packet.md` 本文修正は **明示的 out-of-scope** (Codex agent prompt 深部修正は将来 paired follow-up SPEC 候補)
- `docs/claude-collaboration-brief.md` には Property doctrine reference 追加可 (Claude 側 task で扱う)

### installer 伝播

- `scripts/generator/03-rules.sh` に Property template embed 追加 (specs/_template.md 同期)
- `scripts/generator/07-installer-main.sh` に新 hook (test-property-section.sh) 配置追加
- `install.sh` 再生成、`SHA256SUMS` 同期、`.sage-version` 1.7.0 → 1.8.0 (minor bump、新 hook + verdict 追加)

## スコープ外（明示的に除外）

- **sage-harness orchestrator 強化** (resume / circuit-breaker / budget enforcement、SPECA orchestrator parity) → 別 SPEC、本 SPEC は Verify/Review doctrine のみ
- **Tree-sitter MCP 統合** (SPECA Phase 02c の code pre-resolution、token 40-60% 削減) → 別 SPEC、本 SPEC は manual Property mapping のみ
- **既存全 SPEC (SPEC-0001..0023) の Properties retrofit** → pilot 3 件のみ、残りは incremental migration (CI で WARN-only)
- **Property 自動生成** (LLM が SPEC 本文から Property を自動抽出) → 別 SPEC、本 SPEC は手書き Property のみ
- **`docs/codex-delegation-packet.md` 本文拡張** → SPEC-0023 paired-update doctrine 準拠、Codex 専用本文の深部修正は将来 paired SPEC で別途
- **Codex agent prompt 深部修正** (Codex CLI sandbox/permission に踏み込む変更) → SAGE の audit-only 原則維持
- **Gate 1 (lint/format/type) の Property 化** → Property 対象は意味論的性質のみ、構文 check は既存 Gate 1 維持
- **runtime enforcement** (RLS policy verifier 等の自動修復) → SAGE は audit-only doctrine 維持 (SPEC-0015 SEC-01 と同方針)
- **SPECA pipeline 全体の SAGE 移植** (Phase 01a-04 全 phase の Python orchestrator 取込) → 本 SPEC は Phase 03/04 の doctrine のみ採用
- **既存 `sage/failures.md` entry の cause 推定 retrofit** → Codex review 指摘で禁止 (推定書き換えは spec-misinterpretation 温床)

## 要件

### 機能要件

- **[FR-01]** `specs/_template.md` に **「## Properties」セクション** が以下の構造で存在:

  ```markdown
  ## Properties

  SPEC が満たすべき意味論的性質を declarative に列挙。Verify / Review phase で機械的に proof-attempt が行われる。

  権限レベル別の下限:
  - `system` / `platform` + Security 要件あり: 5 件以上必須
  - `platform` (Security 要件なし): 3 件以上推奨
  - `feature` (低リスク): 任意、`Properties: not applicable + 理由` 許容

  ### Invariants
  - [INV-01] (Gate 3) <Property 内容>
  - [INV-02] (Gate 4) <Property 内容>

  ### Pre-conditions
  - [PRE-01] (Gate 2) <Property 内容>

  ### Post-conditions
  - [POST-01] (Gate 2) <Property 内容>

  ### Assumptions
  - [ASM-01] (Gate 横断) <Property 内容>
  ```

- **[FR-02]** `sage/governance.md` §11 「Property-based Verify and Review Gate」が以下を含む:

  ```markdown
  ## §11 Property-based Verify and Review Gate

  ### §11.1 Property → Gate matrix
  | Property 種別 | 主 Gate | 補助 Gate |
  |---|---|---|
  | API 契約 (Pre/Post) | Gate 2 (Functional) | Gate 4 |
  | 認可 / secret / MCP 権限 (Invariant) | Gate 3 (Security) | Gate 4 |
  | layer 境界 / forbidden dep (Invariant) | Gate 4 (Architecture) | - |
  | traceability / SPEC↔実装対応 (Assumption) | 横断 | Gate 1-5 |

  ### §11.2 Verdict 体系
  | Verdict | 意味 | merge 可否 |
  |---|---|---|
  | PASS | Property 全件証明試行成功 | 可 |
  | FAIL | Property 違反 + 反例あり | 不可 (Hard Fail 同等) |
  | OUT_OF_TASK_SCOPE | Finding が TASK 範囲外の既存問題 | 可 (Finding 記録のみ、後続 SPEC で対応) |
  | FOLLOW_UP_REQUIRED | Finding は妥当だが本 TASK で fix しない | 可 (follow-up TASK 起票必須) |
  | DISPUTED_FP | 実装は正しく Finding 自体が誤り (Dead Code / Trust Boundary 誤解) | 可 (audit log に判定根拠記録必須) |
  | SKIPPED_WITH_APPROVAL_REQUIRED | 証明できないが反例も出せない | 不可 (人間 approver の PR body signature 必須) |

  ### §11.3 3-gate FP filter (early-exit)
  Review Agent は finding を出した後、以下の順で FP filter を適用:
  1. **Dead Code gate**: Finding 対象コードが実行されない経路 → DISPUTED_FP
  2. **Trust Boundary gate**: Finding が信頼境界外 (untrusted input が制御不可な場合) → 別 finding に切り分け
  3. **Scope Check gate**: Finding が TASK File Scope 外の既存問題 → OUT_OF_TASK_SCOPE / FOLLOW_UP_REQUIRED
  早期 exit: いずれかの gate で verdict 確定したら後続 gate は skip。

  ### §11.4 Hard Fail との関係
  以下は 3-gate FP filter で覆せない (DISPUTED_FP にできない):
  - 実装が File Scope 外を変更している (= Silent Scope Expansion、SPEC-0007 AP)
  - Gate 1-4 のいずれか fail
  - secret / credentials のハードコード
  - 既知脆弱性を持つ依存の追加
  Hard Fail は SPECA Phase 04 でも recall-safe doctrine として除外不可。

  ### §11.5 SKIPPED_WITH_APPROVAL_REQUIRED の運用
  - 人間 approver の signature を PR body に記述 (`Approved-by: <username> <reason>`)
  - audit log (`.sage/audit/property-skip-YYYYMMDD.log`) に approver / reason / SPEC-ID / Property-ID を記録
  - silent approval 禁止 (空 signature では merge block)
  ```

- **[FR-03]** `templates/skills/sage-review/SKILL.md` および `.claude/skills/sage-review/SKILL.md` に「3-gate FP filter」セクション追加:
  - Dead Code → Trust Boundary → Scope Check の順序明記
  - 早期 exit ロジック (verdict 確定で後続 skip)
  - 各 gate での判定基準と例
  - 既存 verdict (PASS/FAIL) と新 verdict (OUT_OF_TASK_SCOPE / FOLLOW_UP_REQUIRED / DISPUTED_FP / SKIPPED_WITH_APPROVAL_REQUIRED) の使い分け表

- **[FR-04]** `templates/skills/sage-review/SKILL.md` の `review_feedback` YAML schema を拡張:
  - `verdict` enum を 6 値に拡張 (PASS/FAIL/OUT_OF_TASK_SCOPE/FOLLOW_UP_REQUIRED/DISPUTED_FP/SKIPPED_WITH_APPROVAL_REQUIRED)
  - 各 finding に `fp_gate` field 追加 (`dead_code` / `trust_boundary` / `scope_check` / `none`、none = 通常 finding)
  - SKIPPED_WITH_APPROVAL_REQUIRED 時 `approval_required: { approver: null, reason: null, signed_at: null }` block を含む

- **[FR-05]** `sage/failures.md` エントリフォーマット節に `cause` field 追加:
  - additive (既存 entry には追加しない、新規 entry のみ任意記入)
  - enum: `trust-boundary` / `code-reading` / `spec-misinterpretation` / `not-applicable` / `other`
  - field 順序: 「該当アンチパターン」の次

- **[FR-06]** pilot 3 件の SPEC に Properties セクション additive 追加:
  - [SPEC-0011](SPEC-0011-hook-hardening-and-test-infrastructure.md): hook test infrastructure の不変条件 (hook 実行成功 / shellcheck error 0 / R8 doctrine compliance / hooks profile gating / detection-only behavior 等) 5 件以上
  - [SPEC-0014](SPEC-0014-installer-modularize.md): installer 7 module の boundary / byte-identical regen / SHA256SUMS verify / managed_files coverage / .sage-version semver 等 5 件以上
  - [SPEC-0015](SPEC-0015-mcp-allowlist-audit-and-agent-identity.md): MCP allowlist supply-chain pin の不変条件 (transport-aware schema / OAuth callback uniqueness / sensitive header redact / detection-only / audit log JSON validity 等) 5 件以上
  - 既存 AC とは併存 (AC は command-verifiable / Property は declarative)、矛盾発生時は SPEC を更新する手順を governance §11.4 で別途規定

- **[FR-07]** `templates/hooks/tests/test-property-section.sh` 新規 (8+ scenarios):
  1. 新規 SPEC (SPEC-0024 以降) に Properties セクション存在
  2. 4 種別ヘッダ (Invariants/Pre-conditions/Post-conditions/Assumptions) のうち 1 つ以上存在
  3. 各 Property に Gate mapping `(Gate N)` 含む
  4. 権限レベル `system`/`platform` + Security 要件あり SPEC で Property 5 件以上
  5. 権限レベル `feature` で `Properties: not applicable + 理由` 許容 (PASS 扱い)
  6. 異常系: Properties セクション削除 fixture で FAIL
  7. 異常系: Gate mapping 欠落 fixture で FAIL
  8. 既存 SPEC (SPEC-0001..0023、pilot 3 件除く) は WARN-only (FAIL にしない、incremental migration)

- **[FR-08]** `CLAUDE.md` § 9 章末に Property doctrine cross-reference 追加 (R7 ≤+5 行):
  ```
  ### 9.x Property-based Verify (SPEC-0024)

  全 SPEC は権限レベルに応じて Properties セクション (Invariant/Pre/Post/Assumption) を持つ。
  Review Agent は Dead Code / Trust Boundary / Scope Check の 3-gate FP filter を適用。
  詳細: sage/governance.md §11
  ```
  `AGENTS.md` § 9 相当箇所に同じ文言で同期 (CLI 共通 doctrine、SPEC-0023 paired)。

- **[FR-09]** `templates/claude-md-snippet.md` および `templates/agents-md-snippet.md` に Property doctrine bullet 追加 (既存 install 先に伝播、各 ≤+2 行):
  - Properties section is required for new SPECs (system/platform). See sage/governance.md §11.
  - Review uses 3-gate FP filter (Dead Code / Trust Boundary / Scope Check).

- **[FR-10]** installer 伝播:
  - `scripts/generator/03-rules.sh` に `TMPL_PROPERTY_TEMPLATE` (FR-01 形式の Properties セクション template) を embed
  - `scripts/generator/07-installer-main.sh` に `templates/hooks/tests/test-property-section.sh` の配置エントリ追加
  - `install.sh` 再生成 (`bash scripts/generate-installer.sh > install.sh`)
  - `SHA256SUMS` 再生成 (release tag push 時に sage-publish.sh が実行)
  - `.sage-version` を `1.7.0` → `1.8.0` に bump (新 hook + 新 verdict 追加 = minor)

### 非機能要件

- **[NFR-01] backward compat**: 既存 SAGE 利用者の `.sage/config.yaml` / hooks / scripts は触らない。新 hook (test-property-section.sh) は profile `minimal` で skip、`standard`+ で WARN-only (既存 SPEC retrofit 完了まで)、`strict` で初めて新規 SPEC に対し FAIL
- **[NFR-02] R7 厳守**: CLAUDE.md / AGENTS.md / claude-md-snippet.md / agents-md-snippet.md それぞれ ≤+5 行 (governance.md §11 は新節のため例外、ただし簡潔 ≤80 行に維持)
- **[NFR-03] portability**: macOS / Linux 両対応 (BSD awk / GNU awk 差異吸収、bash 4+ 想定)
- **[NFR-04] パフォーマンス**: test-property-section.sh の 5 回測定中央値 < 200ms (templates/hooks/tests/measure-hook-time.py で検証、SPEC-0015 NFR-01 と同基準)
- **[NFR-05] auditability**: SKIPPED_WITH_APPROVAL_REQUIRED の audit log は JSON-lines (timestamp / approver / reason / spec_id / property_id 必須 5 field)、SPEC-0015 NFR-04 と同 schema 方式
- **[NFR-06] graceful degradation**: 既存 SPEC で Properties セクション不在の場合、test は WARN 出力 + skip (FAIL にしない、AC-11 で incremental migration を担保)
- **[NFR-07] paired update doctrine 準拠**: SPEC-0023 §10 で formalized された paired update を本 SPEC が踏襲。CLAUDE.md / AGENTS.md / 両 snippet の同期更新を 1 PR で完結
- **[NFR-08] file scope 厳守**: 各 TASK は File Scope を明示、Properties retrofit (TASK-0167) は pilot 3 件のみで他 SPEC を触らない
- **[NFR-09] code coverage**: not applicable (本 SPEC は `src/` 配下を変更しない、template + governance + hook 追加のみ)。代替指標として hook test scenario coverage を AC-07 で 8+ 件、AC-08 で 195+ (既存 187 + 新規 8) で必須化、`templates/hooks/tests/run-tests.sh` で CI 常時実行

### セキュリティ要件

- **[SEC-01] declarative-only Property 記述**: Properties は markdown bullet 形式の declarative 記述のみ。実行コード (shell / python) を埋め込み禁止 (template injection 回避)
- **[SEC-02] secret 直接埋め込み禁止**: 認可 Property に secret 値を直接書かない (env 名参照のみ、SPEC-0015 SEC-07 doctrine 継承)。例:
  - 禁止: `[INV-01] (Gate 3) API_KEY = "sk-live-xxx" 一致`
  - 推奨: `[INV-01] (Gate 3) リクエスト header の Authorization は ${API_KEY_ENV} の値と一致`
- **[SEC-03] judgment audit log 必須化**: 3-gate FP filter で DISPUTED_FP / OUT_OF_TASK_SCOPE / FOLLOW_UP_REQUIRED と判定した場合、判定根拠 (どの gate で / どの理由で) を audit log に記録。silent suppression 禁止
- **[SEC-04] SKIPPED_WITH_APPROVAL_REQUIRED の signature 検証**: PR body の `Approved-by:` line を CI で grep。空文字列・偽装 (例: `Approved-by: <ai-agent>`) を block
- **[SEC-05] Hard Fail を覆せない**: §11.4 で明示。File Scope 違反 / Gate 1-4 fail / secret / 既知脆弱性は 3-gate FP filter で DISPUTED_FP にできない (recall-safe、SPECA Phase 04 同 doctrine)
- **[SEC-06] template に PII / secret 例値なし**: Properties template の例値は無害な文字列 (`${API_KEY_ENV}` / `<expected_value>`) のみ、gitleaks 通過必須

### 運用要件

- **[OPS-01] profile gating**: `.sage/config.yaml` `hooks.profile`:
  - `none` / `minimal`: test-property-section.sh skip
  - `standard`: 新規 SPEC (SPEC-0024+) に対し WARN、既存 SPEC は skip
  - `strict`: 新規 SPEC (SPEC-0024+) に対し FAIL、既存 SPEC は WARN
- **[OPS-02] incremental migration**: 既存 SPEC (SPEC-0001..0023、pilot 3 件除く) の Properties retrofit は本 SPEC では行わない。各 SPEC の次回更新時に optional 追加、強制しない
- **[OPS-03] Codex review との連携**: 本 SPEC merge 後、Codex 側で Property-aware verification mode の実装提案を受け付ける窓口を `docs/codex-delegation-packet.md` に追記する判断は将来 paired SPEC で検討 (本 SPEC scope 外、Codex review M3 fix と同 pattern)
- **[OPS-04] 段階採用昇格条件**:

  | 昇格 | 条件 | 検証コマンド |
  |---|---|---|
  | none → standard | 本 SPEC merge 完了 + pilot 3 件 retrofit 完了 + 新 hook 7/8 PASS | `bash templates/hooks/tests/test-property-section.sh` |
  | standard → strict | standard で 14 日運用 + 新 SPEC 起票 5 件以上で全件 Properties 含む | `for spec in $(find specs -name 'SPEC-*.md' -newer specs/SPEC-0024-*.md); do grep -l "## Properties" "$spec"; done \| wc -l` で 5+ |

- **[OPS-05] failures.md cause field の運用**: 新規 entry 起票時のみ任意 (添加) 記入推奨。既存 entry の cause を後付け推定する PR は禁止 (rejection、推定 retrofit が spec-misinterpretation の温床のため)

## 受け入れ条件（Acceptance Criteria）

- [ ] **AC-01**: `specs/_template.md` に「## Properties」セクションが存在し、4 種別ヘッダ + 権限レベル別下限 + Gate mapping 例を含む  
  検証: `grep -F "## Properties" specs/_template.md && grep -F "Invariants" specs/_template.md && grep -F "(Gate" specs/_template.md`
- [ ] **AC-02**: pilot 3 SPEC ([0011](SPEC-0011-hook-hardening-and-test-infrastructure.md), [0014](SPEC-0014-installer-modularize.md), [0015](SPEC-0015-mcp-allowlist-audit-and-agent-identity.md)) に Properties セクションが追加され、各 5 件以上の Property を含む  
  検証: `for f in 0011 0014 0015; do n=$(grep -cE "^- \[(INV|PRE|POST|ASM)-[0-9]+\]" specs/SPEC-$f-*.md); [ "$n" -ge 5 ] || exit 1; done`
- [ ] **AC-03**: `templates/skills/sage-review/SKILL.md` に「3-gate FP filter」セクションが存在し、Dead Code / Trust Boundary / Scope Check の 3 gate と早期 exit ロジックを記述  
  検証: `grep -F "Dead Code" templates/skills/sage-review/SKILL.md && grep -F "Trust Boundary" templates/skills/sage-review/SKILL.md && grep -F "Scope Check" templates/skills/sage-review/SKILL.md && grep -F "early" templates/skills/sage-review/SKILL.md`
- [ ] **AC-04**: `templates/skills/sage-review/SKILL.md` の `review_feedback` YAML schema が 6 verdict を含む  
  検証: `for v in PASS FAIL OUT_OF_TASK_SCOPE FOLLOW_UP_REQUIRED DISPUTED_FP SKIPPED_WITH_APPROVAL_REQUIRED; do grep -qF "$v" templates/skills/sage-review/SKILL.md || exit 1; done`
- [ ] **AC-05**: `sage/failures.md` エントリフォーマットに `cause` field (markdown bold `**cause**` 形式、既存 field と整合) と enum 5 値が記述、既存 FAIL-0001 は **未変更**  
  検証: `grep -F '**cause**' sage/failures.md && for c in trust-boundary code-reading spec-misinterpretation not-applicable other; do grep -qF "$c" sage/failures.md || exit 1; done && diff <(git show main:sage/failures.md | awk '/^### FAIL-0001/,/^### FAIL-[0-9]+/{print}') <(awk '/^### FAIL-0001/,/^### FAIL-[0-9]+/{print}' sage/failures.md)` (cause field 存在 + enum 5 値存在 + FAIL-0001 entry 領域 main と本 branch で完全一致 = diff exit 0、不一致なら非ゼロ終了で AC fail)
- [ ] **AC-06**: `sage/governance.md` §11 が新節として存在し、§11.1〜§11.5 の 5 sub-section 以上を含む (本文内では §11 と記すが header は既存 §10 同様 `## 11.` 形式、SPEC-0023 governance §10 と整合)  
  検証: `grep -F "## 11. Property-based Verify and Review Gate" sage/governance.md && for s in 11.1 11.2 11.3 11.4 11.5; do grep -qF "### $s" sage/governance.md || exit 1; done`
- [ ] **AC-07**: `templates/hooks/tests/test-property-section.sh` が PASS、新規 SPEC で Properties 欠落時に FAIL を返す  
  検証: `bash templates/hooks/tests/test-property-section.sh`
- [ ] **AC-08**: `templates/hooks/tests/run-tests.sh` 全 PASS (既存 187 + 新規 8 = 195+)  
  検証: `bash templates/hooks/tests/run-tests.sh`
- [ ] **AC-09**: `bash scripts/sage-validate.sh` PASS、`bash scripts/sage-doctor.sh` 0 FAIL  
  検証: 直接実行
- [ ] **AC-10**: `bash scripts/generate-installer.sh > /tmp/new && diff install.sh /tmp/new` で 0 行 (byte-identical)  
  検証: 直接実行
- [ ] **AC-11**: `install.sh` に `TMPL_PROPERTY_TEMPLATE` および `templates/hooks/tests/test-property-section.sh` 書き込みパスを含む  
  検証: `grep -c "TMPL_PROPERTY_TEMPLATE\|test-property-section" install.sh` で 3+
- [ ] **AC-12**: paired update — `CLAUDE.md` と `AGENTS.md` に Property doctrine cross-reference が同 semantic 内容で存在 (各 ≤+5 行)  
  検証: `grep -F "Property-based Verify" CLAUDE.md && grep -F "Property-based Verify" AGENTS.md && grep -F "SPEC-0024" CLAUDE.md && grep -F "SPEC-0024" AGENTS.md`
- [ ] **AC-13**: `templates/claude-md-snippet.md` および `templates/agents-md-snippet.md` に parallel bullet (各 ≤+2 行) が追加  
  検証: `grep -F "Properties section" templates/claude-md-snippet.md && grep -F "Properties section" templates/agents-md-snippet.md`
- [ ] **AC-14** (異常系): test-property-section.sh で fixture を mutate して Properties セクション削除した時 FAIL を返す  
  検証: test 内 mutation simulate (heredoc fixture)
- [ ] **AC-15** (異常系): Gate mapping 欠落 fixture (`[INV-01] <内容>` のみで `(Gate N)` 不在) で FAIL を返す  
  検証: test 内 mutation simulate
- [ ] **AC-16** (backward compat): 既存 SPEC で Properties 不在のものは WARN-only、FAIL にしない (incremental migration 担保)  
  検証: test scenario 8 で existing SPEC-0001 fixture を読み WARN-only
- [ ] **AC-17** (backward compat): `bash install.sh --update` で既存 `.sage/config.yaml` `installer_url` が書き換わらない  
  検証: 既存 fixture で `bash install.sh --update` 実行後 grep
- [ ] **AC-18**: `.sage-version` が `1.7.0` → `1.8.0` に更新  
  検証: `grep -F "1.8.0" .sage-version`
- [ ] **AC-19**: shellcheck error 0 件 (新規 test + 既存 modified scripts)  
  検証: `shellcheck templates/hooks/tests/test-property-section.sh && shellcheck scripts/generator/03-rules.sh`
- [ ] **AC-20**: SKIPPED_WITH_APPROVAL_REQUIRED の audit log JSON schema が NFR-05 の 5 必須 field を満たす  
  検証: test scenario で SKIPPED 出力を `python3 -c "import json,sys; r=json.loads(sys.stdin.read()); assert all(k in r for k in ['timestamp','approver','reason','spec_id','property_id'])"` で parse

### Quality Gate との対応

| AC | 検証 Gate | 検証コマンド (CI) |
|---|---|---|
| AC-01, AC-02, AC-06, AC-12, AC-13, AC-18 | Gate 1 (Structural: file 存在 + grep pattern) | `grep` / `test -f` 系 |
| AC-03, AC-04, AC-05 | Gate 1 (Structural: schema 完整性) | `grep` / `diff` 系 |
| AC-07, AC-08, AC-14, AC-15, AC-16, AC-20 | Gate 2 (Functional: hook tests + 異常系 fixture) | `bash run-tests.sh` |
| AC-10, AC-11 | Gate 2 (Functional: byte-identical + embed verification) | `diff` / `grep -c` |
| AC-17, AC-19 | Gate 3 (Security: backward compat + shellcheck) | `git diff` + `shellcheck` |
| AC-09 | Gate 4 (Architecture: validate + doctor) | 各 script 直接実行 |
| SEC-01..SEC-06 | Gate 3 (Security: declarative-only / no secret / audit log / signature) | AC-05 / AC-20 の test scenario 内 |

Gate 5 (Release) は本 SPEC 単独では発火しない (release.yml は v1.8.0 tag push で発火、SPEC-0018 別 verification)。

## 異常系

- **EC-01** (Property セクション削除): 新規 SPEC で `## Properties` 見出しが削除される → AC-14 hook test FAIL
- **EC-02** (Gate mapping 欠落): Property 記述に `(Gate N)` が無い → AC-15 hook test FAIL
- **EC-03** (権限レベル違反): SPEC `権限レベル: platform` + Security 要件あり で Property 4 件以下 → hook test FAIL
- **EC-04** (Properties: not applicable に理由欠落): `Properties: not applicable` のみで「理由」記述が無い → hook test WARN
- **EC-05** (paired update doctrine 違反): CLAUDE.md / AGENTS.md の片方のみ Property reference 追加 → SPEC-0023 paired test (test-claude-collaboration-pairing.sh) で FAIL (既存 doctrine 流用)
- **EC-06** (3-gate FP filter 誤判定): Review Agent が真の bug を DISPUTED_FP にした場合 → audit log の判定根拠を後続 Review が検査 (SEC-03)、3 回繰り返したら failures.md に FAIL-PROP-XXXX として記録、anti-patterns 昇格判定
- **EC-07** (SKIPPED_WITH_APPROVAL_REQUIRED 偽装): PR body に `Approved-by: <ai-agent>` 等の偽 signature → CI で grep regex (`^Approved-by: [a-zA-Z0-9_-]+ ` で human username 形式必須) で block (SEC-04)
- **EC-08** (cause 推定 retrofit 試行): 既存 FAIL-0001 等の cause field を後付けで PR が来る → reviewer reject (OPS-05)
- **EC-09** (既存 SPEC migration 強制): incremental migration NFR-06 に反して既存 SPEC 全件 retrofit を要求する PR → 本 SPEC scope 外として split 要求 (Codex review feedback と同 pattern)

## 契約

- API: なし
- DB: なし
- イベント: なし (audit log は file-based、SPEC-0015 と同 pattern)
- schema: `.sage/audit/property-skip-YYYYMMDD.log` JSON-lines (NFR-05 で定義)

## リスク

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | Property 記述が冗長化 → SPEC 作成負荷↑ → SAGE 採用率↓ | (a) 権限レベル別下限で過剰要求回避 (FR-09)、(b) pilot 3 SPEC で実コスト測定、(c) governance §11 に「最小件数のみ規定、上限なし」明示 | pilot 完了後に `wc -l specs/SPEC-0011-*.md specs/SPEC-0014-*.md specs/SPEC-0015-*.md` 増分 ≤ 30% を検証 |
| 2 | 3-gate FP filter が真陽性も DISPUTED_FP にする (recall 喪失) | EC-06 で 3 回繰り返し検出、SEC-03 で audit log 必須、§11.4 で Hard Fail は覆せない | audit log 内 DISPUTED_FP の件数を週次集計、5% 超で警告 |
| 3 | Property と AC の二重管理コスト | governance §11 で「Property は declarative、AC は command-verifiable」と階層化、矛盾発生時は SPEC 更新 (governance §11.4) | pilot 3 SPEC の AC vs Property の対応表を実装メモに記載 |
| 4 | SKIPPED_WITH_APPROVAL_REQUIRED の濫用 (毎回 SKIPPED で merge) | NFR-05 で audit log 必須、OPS-04 で件数集計、5 件超で governance review 起動 | `wc -l .sage/audit/property-skip-*.log` を週次集計 |
| 5 | paired update doctrine 違反で CLAUDE.md のみ更新 | EC-05 で SPEC-0023 既存 paired test 流用、CI で FAIL | 既存 `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` 拡張不要 |
| 6 | install.sh 再生成忘れで配布物が古い | TASK-0169 で明示、SPEC-0018 / SPEC-0023 と同 pattern | `bash scripts/generate-installer.sh > /tmp/new && diff install.sh /tmp/new` 0 行 |
| 7 | governance §11 が長すぎて R7 違反 | NFR-02 で §11 ≤ 80 行、長文は本 SPEC 本文に集約 | `awk '/^## §11/,/^## §12\|^# /' sage/governance.md \| wc -l` ≤ 80 |
| 8 | 既存 SPEC で WARN noise が多発 | NFR-06 で incremental migration、profile gating で `strict` 時のみ FAIL、`standard` は WARN-only | OPS-04 段階採用昇格条件 |
| 9 | Codex review で予期せぬ finding | SPEC-0023 同 pattern (1-2 round 収束)、3 round 超なら SPEC 巻き戻し | `git log --oneline feature/spec-0024 \| grep -c "review fix"` で round 数把握 |
| 10 | pilot 3 件の Property が後の SPEC 更新と矛盾 | OPS-02 で pilot 完了後の incremental migration、矛盾発生時は SPEC を更新 (Property を再生成) | pilot 3 件の SPEC を quarterly review |

## 失敗時の知識蓄積

本 SPEC は Property-based Verify を audit-only doctrine で導入するため、検出された Property 違反 / DISPUTED_FP 誤判定 / SKIPPED_WITH_APPROVAL_REQUIRED 濫用は **知識蓄積パスを介して継続改善** に繋げる。

### 知識蓄積フロー (3 ステップ)

```
Step 1 [検出]
  test-property-section.sh / Review Agent / Codex review が逸脱 event を検出
  ↓
Step 2 [記録]
  同 root cause で 2 回以上発生 → sage/failures.md に FAIL-PROP-XXXX として追記
  (cause field に trust-boundary / code-reading / spec-misinterpretation のいずれかを記入推奨、新規 entry のみ)
  ↓
Step 3 [昇格]
  同 root cause で 3 回以上発生 → sage/anti-patterns.md に PROP-XXXX として追記、governance §11 に doctrine 反映検討
```

### sage/failures.md 連携

- **誰が**:
  - Review Agent (DISPUTED_FP 誤判定 / 3-gate FP filter 誤適用検出時)
  - Spec Agent (Property ↔ AC 整合性違反検出時)
  - CI (test-property-section.sh の異常系 fixture FAIL 検出時)
- **いつ**: 同 root cause + 同 cause enum 値で 2 回以上発生時
- **どの手順で**: SPEC-ID + Property-ID + cause enum + 6 elements (発生日 / 影響 / 検出経路 / 一次原因 / 再発防止 / 関連 SPEC-ID) を含めて `sage/failures.md` に FAIL-PROP-XXXX として追記。既存 entry の cause 後付け retrofit は禁止 (OPS-05)

### sage/anti-patterns.md への昇格

同 root cause の event が 3 回以上 failures.md に記録された場合:
1. `sage/anti-patterns.md` に「PROP-XXXX: <pattern name>」追記 (例: 「PROP-001: DISPUTED_FP without dead-code evidence」)
2. governance §11 に該当 anti-pattern の doctrine 追加検討 (例: §11.3 3-gate FP filter の Dead Code gate 判定基準を厳格化)
3. `templates/skills/sage-review/SKILL.md` / `templates/hooks/tests/test-property-section.sh` の判定ロジック改訂を検討

### Error Resolution 手順

| EC | エラー時メッセージ例 | Resolution |
|---|---|---|
| EC-01 (Property セクション削除) | `not ok specs/SPEC-XXXX missing ## Properties section` | template (`specs/_template.md`) に従って復元、または `Properties: not applicable + 理由` で許容 (権限レベル `feature` のみ) |
| EC-02 (Gate mapping 欠落) | `not ok [INV-NN] missing (Gate N) annotation` | `(Gate N)` を Property 末尾に追記 (N = 2/3/4/横断) |
| EC-03 (権限レベル違反) | `not ok platform + Security 要件あり SPEC has < 5 Properties` | Property を 5 件以上に追加、または権限レベル / Security 要件を見直し |
| EC-04 (理由欠落) | `WARN: Properties: not applicable without reason` | 理由を記述 (例: 「本 SPEC は documentation only のため意味論的性質が無い」) |
| EC-05 (paired update 違反) | `not ok CLAUDE.md / AGENTS.md missing parallel reference` | 対側を同期更新、SPEC-0023 paired test 流用で再検証 |
| EC-06 (DISPUTED_FP 誤判定) | `WARN: DISPUTED_FP without audit log evidence` | audit log (`.sage/audit/`) に判定根拠 (fp_gate / fp_reason) を記録。3 回繰返で FAIL-PROP-XXXX として failures.md に記録 |
| EC-07 (signature 偽装) | `FAIL: Approved-by AI agent signature in PR body` | human approver の signature に置換、または SPEC を更新して Property を再設計 |
| EC-08 (cause 推定 retrofit 試行) | reviewer による reject (OPS-05) | 既存 entry を変更せず close、新規 entry のみ cause 任意記入 |
| EC-09 (既存 SPEC migration 強制) | reviewer による split 要求 | NFR-06 incremental migration、別 SPEC として分離起票 |

## ロールバック手順

本 SPEC の各機能は段階的にロールバック可能:

| レベル | 手順 | 影響範囲 |
|---|---|---|
| 1. 一時 disable (緊急停止) | `.sage/config.yaml` `hooks.profile: none` で全 hook を skip | 全 SAGE hook が skip (本 SPEC 以外も含む) |
| 2. 部分 disable (本 SPEC hook のみ無効化) | `.claude/settings.json` の `hooks.SessionStart` から `test-property-section.sh` 行のみ削除 | 他の SessionStart hook は継続動作、Properties は記述だけ残る (検証なし) |
| 3. governance §11 削除 | `sage/governance.md` §11 を削除 (CLAUDE.md / AGENTS.md cross-ref も同期削除) | Property doctrine 喪失、paired test fail (意図的、警告として機能) |
| 4. review skill 6 verdict revert | `templates/skills/sage-review/SKILL.md` の verdict enum を PASS/FAIL のみに戻す | OUT_OF_TASK_SCOPE / FOLLOW_UP_REQUIRED / DISPUTED_FP / SKIPPED_WITH_APPROVAL_REQUIRED が利用不可、既存 finding は再分類が必要 |
| 5. 完全 revert | 本 SPEC 導入 PR を `git revert` | template / governance §11 / review skill 拡張 / failures schema / pilot 3 SPEC retrofit / installer / version 全て巻き戻り、SPEC-0023 単独状態に戻る |

各ロールバック後の検証:
- `bash scripts/sage-doctor.sh` で 0 FAIL
- `bash templates/hooks/tests/run-tests.sh` で 187/187 (Phase 6.1 base line) PASS
- `bash install.sh --update` で既存 `.sage/config.yaml` `installer_url` 不変
- レベル 5 後: `git log --oneline | grep -cE "TASK-016[1-9]|TASK-0170"` で 0 件、`.sage-version` が `1.7.x` (1.8.0 巻き戻り)

## 実装メモ（Implementation Agent向け）

### Property 記述の例 (SPEC-0015 retrofit プレビュー)

```markdown
## Properties

権限レベル `platform` + Security 要件あり (SEC-01..SEC-07) のため 5 件以上必須。

### Invariants
- [INV-01] (Gate 3) `.sage/mcp-allowlist.json` の全 server entry に `version_pin` (stdio) または `url_origin_pin` (http) が存在する。`@latest` は `policy.forbid_latest_tag: true` の時 registry から拒否される
- [INV-02] (Gate 3) HTTP MCP server の `auth_mode` は `bearer_env` / `oauth` / `none` のいずれか。`policy.http_require_auth: true` 時 `none` は禁止
- [INV-03] (Gate 4) `.sage/audit/mcp-allowlist-YYYYMMDD.log` は drift event 専用、bypass log は別 filename で分離 (NFR-04)
- [INV-04] (Gate 3) `http_headers` (静的) に sensitive header (Authorization / Cookie / X-Api-Key 等、case-insensitive) が含まれない (drift7 で reject)

### Pre-conditions
- [PRE-01] (Gate 2) `.sage/mcp-allowlist.json` は JSON parseable (`python3 -c "import json; json.load(open(...))"` exit 0)
- [PRE-02] (Gate 2) hook 実行環境に Python 3 が存在 (NFR-03 graceful degradation)

### Post-conditions
- [POST-01] (Gate 2) hook 実行後、`.sage/audit/mcp-allowlist-YYYYMMDD.log` に drift event が JSON-lines 形式で append され、各行が独立 parseable

### Assumptions
- [ASM-01] (Gate 横断) Codex CLI / Claude Code MCP の transport は `stdio` / `http` のみ (将来 transport 追加時は SPEC 更新)
```

### 3-gate FP filter の例 (review skill 強化)

```yaml
review_feedback:
  verdict: DISPUTED_FP
  findings:
    - id: "REV-001"
      category: "safety"
      severity: "minor"
      file: "src/auth/handler.go:42"
      expected: "input validation"
      actual: "no validation"
      fp_gate: "dead_code"  # NEW: gate at which DISPUTED_FP determined
      fp_reason: "this branch is unreachable; src/auth/router.go:18 routes only authenticated requests here"
```

### TASK 順序

PLAN-0024 で詳細化。基本は: foundation TASK-0161 → template/governance TASK-0162 → review skill TASK-0165 → failures schema TASK-0166 → snippet TASK-0163/0164 並列 → pilot TASK-0167 → hook test TASK-0168 → installer TASK-0169 → paired-verification + final TASK-0170。

## 関連 Doctrine

- **R3** (Lethal Trifecta warn-only): 3-gate FP filter の DISPUTED_FP は audit log 記録必須 (SEC-03)、SAGE doctrine と整合
- **R4** (no SecPass thresholds): 本 SPEC は threshold 概念なし、verdict + audit log のみ
- **R5** (RUN log redaction): SKIPPED_WITH_APPROVAL_REQUIRED の audit log は env 名のみ、secret 値含めない (SEC-02)
- **R7** (CLAUDE/AGENTS 肥大化禁止): NFR-02 で各 ≤+5 行明示
- **R8** (hook tests required): AC-07 / AC-14 / AC-15 で 8+ scenarios 必須、異常系 fixture 含む
- **R9** (shellcheck required): AC-19 で error 0 件必須
- **R10** (一次ソース引用): SPECA paper [arXiv:2604.26495](https://arxiv.org/abs/2604.26495) と GitHub repo を一次ソース引用

## Phase 6 全体での position

| SPEC | スコープ | 状態 |
|---|---|---|
| SPEC-0018 | Releases + SHA256SUMS + URL pinning (Phase 6.1) | merged (PR #27) |
| SPEC-0022 | Codex Delegation Packet (Phase 6.1) | merged (PR #28) |
| SPEC-0023 | Claude Collaboration Brief + Pairing Doctrine (Phase 6.1) | merged (PR #29) |
| **SPEC-0024** | **Property-based Verify and Review Gate (SPECA-anchored)** ← 本 SPEC | Draft |
| SPEC-0019 | cosign keyless signing (Phase 6.2) | 未起票 |
| SPEC-0020 | SLSA provenance (Phase 6.3) | 未起票 |
| SPEC-XXXX | sage-harness orchestrator parity (resume / circuit-breaker / budget) | 未起票 (Phase 6.x) |
| SPEC-XXXX | Tree-sitter MCP code pre-resolution | 未起票 (Phase 6.x) |
| SPEC-XXXX | Property auto-generation (LLM 自動抽出) | 未起票 (Phase 6.x、本 SPEC の incremental migration 後) |

## Properties

権限レベル `platform` + Security 要件あり (SEC-01..SEC-06) のため 5 件以上必須 (本 SPEC §11.1 自己適用、eat-your-own-dog-food)。

### Invariants
- [INV-01] (Gate 4) `sage/governance.md` §11 が 5 sub-section (§11.1〜§11.5) 以上を含む状態で merge される (AC-06 と対応)
- [INV-02] (Gate 3) Properties template / governance §11 / sage-review SKILL.md の例値に secret / token / API key を含めない (env 名参照のみ、SEC-02 / SEC-06)
- [INV-03] (Gate 4) pilot retrofit (TASK-0167) は SPEC-0011 / SPEC-0014 / SPEC-0015 の既存 AC を変更せず additive 追加のみ (NFR-08 file scope 厳守)
- [INV-04] (Gate 3) paired-update doctrine (governance §10) で CLAUDE.md / AGENTS.md / 両 snippet が semantic identical を維持 (AC-12 / AC-13 と対応)

### Pre-conditions
- [PRE-01] (Gate 2) SAGE base infrastructure (governance §1-§10 / hooks / runlog / installer modular) が存在する (SPEC-0010..0023 完了済)

### Post-conditions
- [POST-01] (Gate 2) `bash templates/hooks/tests/test-property-section.sh` が 8 scenario 全 PASS (AC-07 と対応)

### Assumptions
- [ASM-01] (Gate 横断) SPECA framework (Phase 03/04) の Property doctrine が SAGE の document-level governance に適用可能 (audit framework と development system は orthogonal だが、Property declarative 記述は両方に有効)

## 関連ID

- PLAN-ID: PLAN-0024
- TASK-ID: TASK-0161 (SPEC + PLAN + 10 TASK draft + sage-evaluate) / TASK-0162 (template + governance §11) / TASK-0163 (CLAUDE.md + claude-md-snippet.md) / TASK-0164 (AGENTS.md + agents-md-snippet.md) / TASK-0165 (sage-review skill 3-gate FP filter + verdict 拡張) / TASK-0166 (failures.md cause schema additive) / TASK-0167 (pilot retrofit SPEC-0011/0014/0015) / TASK-0168 (test-property-section.sh + run-tests.sh) / TASK-0169 (generator + install.sh regen + .sage-version bump) / TASK-0170 (paired-verification + RUN log + final verification)
- RUN-ID: RUN-0009 (本 SPEC 実装時に採番予定)
