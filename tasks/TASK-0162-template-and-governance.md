# TASK-0162: specs/_template.md Properties section + sage/governance.md §11 (5 sub-section)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0162 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Pending |
| 担当Agent | Spec Agent (governance 専属) |
| 並列可否  | No (governance 確定が後続前提) |
| 依存TASK  | TASK-0161 |
| 見積     | 60m |

## 責務

SPEC template と governance §11 の 2 ファイルに Property doctrine を追加。後続 TASK の前提となる shared-core 変更。

## 入力

- SPEC-0024 FR-01 (Properties セクション schema)
- SPEC-0024 FR-02 (governance §11 5 sub-section)
- 既存 specs/_template.md (Property セクション不在)
- 既存 sage/governance.md (§1〜§10 までは既存、§11 新設)

## 出力

### specs/_template.md (FR-01)

「## 関連ID」の直前に「## Properties」セクション追加:

```markdown
## Properties

SPEC が満たすべき意味論的性質を declarative に列挙。Verify / Review phase で機械的に proof-attempt が行われる。

権限レベル別の下限:
- `system` / `platform` + Security 要件あり: 5 件以上必須
- `platform` (Security 要件なし): 3 件以上推奨
- `feature` (低リスク): 任意、`Properties: not applicable + 理由` 許容

各 Property に Gate mapping `(Gate N)` 必須 (N = 2: Functional / 3: Security / 4: Architecture / 横断)。

### Invariants
- [INV-01] (Gate N) <常に成立すべき不変条件>

### Pre-conditions
- [PRE-01] (Gate N) <関数/API 入口の前提>

### Post-conditions
- [POST-01] (Gate N) <関数/API 出口の保証>

### Assumptions
- [ASM-01] (Gate 横断) <仕様外の前提 (環境/ツール)>
```

### sage/governance.md (FR-02)

§10 の直後に §11 として 5 sub-section 新設 (≤ 80 行):

```markdown
## §11 Property-based Verify and Review Gate (SPEC-0024)

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
| FAIL | Property 違反 + 反例あり | 不可 |
| OUT_OF_TASK_SCOPE | Finding が TASK 範囲外既存問題 | 可 |
| FOLLOW_UP_REQUIRED | Finding 妥当だが本 TASK で fix しない | 可 (follow-up 起票必須) |
| DISPUTED_FP | 実装正しく Finding が誤り | 可 (audit log 必須) |
| SKIPPED_WITH_APPROVAL_REQUIRED | 証明できないが反例も無い | 不可 (人間承認 signature 必須) |

### §11.3 3-gate FP filter (early-exit)
1. Dead Code gate: 実行されない経路 → DISPUTED_FP
2. Trust Boundary gate: untrusted input が制御不可 → 別 finding に切り分け
3. Scope Check gate: TASK File Scope 外既存問題 → OUT_OF_TASK_SCOPE / FOLLOW_UP_REQUIRED
早期 exit: いずれかの gate で verdict 確定したら後続 skip。

### §11.4 Hard Fail との関係
File Scope 違反 / Gate 1-4 fail / secret hardcode / 既知脆弱性は 3-gate FP filter で覆せない (recall-safe doctrine、SPECA Phase 04 と整合)。

### §11.5 SKIPPED_WITH_APPROVAL_REQUIRED の運用
- 人間 approver の signature を PR body に記述 (`Approved-by: <username> <reason>`)
- audit log (`.sage/audit/property-skip-YYYYMMDD.log`) に approver / reason / SPEC-ID / Property-ID を記録
- silent approval 禁止 (空 signature では merge block)
- AI agent 名 (`<ai-agent>` 等) は signature として無効
```

## File Scope（変更許可範囲）

- 変更: `specs/_template.md` (「## Properties」セクション 1 追加のみ)
- 変更: `sage/governance.md` (§11 新節追加のみ、既存 §1〜§10 不変)

## 禁止事項

- specs/_template.md の既存セクション (背景・目的 / 対象ユーザー / スコープ等) を変更しない
- sage/governance.md の §1〜§10 の本文を変更しない (本 TASK は §11 追加のみ)
- governance §11 を 80 行超で記述しない (R7 厳守、長文は SPEC-0024 本文に集約)
- Property 例値に secret 値を直接書かない (env 名参照のみ、SEC-02)
- 実行可能 code (shell / python) を Property 内に embed しない (SEC-01)

## 完了条件

- [ ] `grep -F "## Properties" specs/_template.md` で 1 件 hit
- [ ] `grep -E "^### (Invariants|Pre-conditions|Post-conditions|Assumptions)" specs/_template.md` で 4 件
- [ ] `grep -F "## §11 Property-based Verify and Review Gate" sage/governance.md` で 1 件 hit
- [ ] `grep -E "^### §11\.[1-5]" sage/governance.md` で 5 件
- [ ] `awk '/^## §11/,/^## §12|^# /' sage/governance.md | wc -l` で 80 行以下
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] commit message に `TASK-0162:` 含む
