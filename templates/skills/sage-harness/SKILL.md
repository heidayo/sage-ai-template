---
name: sage-harness
description: "SAGEハーネス: Specify→Plan→Execute→Verifyの全ライフサイクルを自律実行。Agent toolで各フェーズを独立コンテキストで実行し、Verify失敗時は構造化フィードバック付きで自動ループ。MANDATORY TRIGGERS: harness, ハーネス実行, sage-harness, 自律開発, フルサイクル, 自動開発"
---

# SAGE ハーネス — 自律開発オーケストレーター

SAGE の 7フェーズライフサイクル（Specify → Plan → Slice → Execute → Verify → Merge → Observe）のうち、Specify〜Verify を自律的に実行するオーケストレータースキル。

## 設計原則

1. **コンテキスト分離**: 各フェーズを Agent tool で独立コンテキストとして実行する。メインコンテキストにはフェーズ間の引き継ぎ情報のみ保持する。
2. **ファイル経由の引き継ぎ**: エージェント間のデータ受け渡しはファイル経由で行う（specs/, plans/, tasks/, docs/feedback/）。プロンプト内に大量のコンテキストを詰め込まない。
3. **機械的な判定**: Pass/Fail はスコア閾値・テスト結果で機械的に判定する。主観的な「良さそう」は判定基準にしない。
4. **二重防御**: プロンプトベースの制限 + 事後検証（git diff チェック等）で安全性を担保する。
5. **役割分離**: 採点エージェント（Evaluator / Review Agent）は Read-Only。修正は常に Creator Agent / Implementation Agent / Test Agent が行う。同一エージェントが実装+最終承認を兼務しない。

---

## 前提条件

- `.sage/config.yaml` の `harness` セクションが設定されていること
- `scripts/sage-id-gen.sh` が実行可能であること
- `sage/anti-patterns.md` が存在すること（既知パターン参照用）

---

## ハーネス起動時の前処理（anti-patterns 注入）

START前に以下を実行:

1. `sage/anti-patterns.md` を読み込む
2. 関連する AP-XXX を以下のエージェントのシステムプロンプトに注入:
   - **Spec Agent**: SPECに禁止パターンを含める指示
   - **Planning Agent**: TASK の禁止事項に含める指示（既存）
   - **Implementation Agent**: 実装時の禁止事項として注入
   - **Review Agent**: findings生成時に既知APとの照合を行う指示
3. **Evaluator** にも既知パターンリストを渡し、findings と AP の重複を検出させる

---

## YAML 出力バリデーション

Evaluator / Review Agent の YAML 出力を受け取った後、オーケストレーターは以下を検証:

1. **構文チェック**: YAML としてパース可能か
2. **必須フィールドの存在チェック**:
   - eval_feedback: `verdict`, `total_score`, `findings`, `fix_instructions`
   - review_feedback: `verdict`, `review_score`, `gate_results`, `findings`, `fix_scope`
3. **値域チェック**: verdict が `PASS | FAIL` のいずれか、スコアが 0-100 の範囲内

### バリデーション失敗時
- **1回目**: 同一エージェントに「出力が YAML スキーマに準拠していません。以下のスキーマに従って再出力してください」とリトライ
- **2回目失敗**: `abort_reason = "yaml_schema_error"` で abort

---

## フロー

```
┌───────────────────────────────────────────────────────┐
│  Phase 1: Specify                                     │
│  ┌─────────────────────────────────────────────┐      │
│  │ Agent → Spec Agent                          │      │
│  │   入力: ユーザー要求 + anti-patterns        │      │
│  │   出力: specs/SPEC-XXXX-*.md                │      │
│  └─────────────────────────────────────────────┘      │
│  ┌─────────────────────────────────────────────┐      │
│  │ WHILE iteration < spec_eval_max_iterations: │      │
│  │   Evaluator（Read-Only）→ eval_feedback     │      │
│  │   score >= 100 → 次Phase                    │      │
│  │   score < 100 → Spec Agent に修正させる      │      │
│  │   上限到達 → abort "spec_eval_max"           │      │
│  └─────────────────────────────────────────────┘      │
├───────────────────────────────────────────────────────┤
│  Phase 2: Plan + Slice                                │
│  ┌─────────────────────────────────────────────┐      │
│  │ Agent → Planning Agent                      │      │
│  │   入力: SPEC + anti-patterns                │      │
│  │   出力: plans/, tasks/, done-def            │      │
│  └─────────────────────────────────────────────┘      │
│  ┌─────────────────────────────────────────────┐      │
│  │ WHILE iteration < plan_eval_max_iterations: │      │
│  │   Evaluator（Read-Only）→ eval_feedback     │      │
│  │   score >= 100 → 次Phase                    │      │
│  │   score < 100 → Planning Agent に修正させる  │      │
│  │   上限到達 → abort "plan_eval_max"           │      │
│  └─────────────────────────────────────────────┘      │
├───────────────────────────────────────────────────────┤
│  Phase 3-4: Execute + Verify ループ                   │
│  ┌─────────────────────────────────────────────┐      │
│  │ WHILE iteration < max_iterations:           │      │
│  │                                             │      │
│  │   Step 1: Implementation Agent              │      │
│  │     Write: src/（TASK File Scope内のみ）     │      │
│  │     Forbidden: tests/, specs/, plans/       │      │
│  │                                             │      │
│  │   Step 2: Test Agent                        │      │
│  │     Write: tests/（テストファイルのみ）       │      │
│  │     Read: src/, specs/, plans/              │      │
│  │     Forbidden: src/ の修正                  │      │
│  │                                             │      │
│  │   Step 3: Review Agent（Read-Only）          │      │
│  │     Write: NONE                             │      │
│  │     Bash: テスト実行・lint・カバレッジのみ    │      │
│  │     出力: review_feedback YAML              │      │
│  │                                             │      │
│  │   review_score >= 100 AND 全Gate pass → 完了│      │
│  │   FAIL → fix_scope ルーティングで再実行      │      │
│  │   same_fail_count >= 3 → abort              │      │
│  └─────────────────────────────────────────────┘      │
├───────────────────────────────────────────────────────┤
│  Phase 5: ログ記録                                    │
│  → .sage/runs/RUN-XXXX.yaml に全結果を記録            │
│  → Fail パターンを sage/failures.md に自動追記         │
│  → 3回以上のパターンを sage/anti-patterns.md に昇格    │
└───────────────────────────────────────────────────────┘
```

---

## Phase 1: Specify

### Spec Agent 呼び出し

Agent tool で以下のプロンプトを渡す:

```
あなたは Spec Agent です。
.claude/prompts/spec-agent.md を読み、その役割定義に従ってください。

【タスク】
以下の要求に基づいて SPEC を作成してください:
{user_request}

【手順】
1. bash scripts/sage-id-gen.sh spec で SPEC-ID を生成する
2. specs/_template.md をコピーして specs/SPEC-{ID}-{short-name}.md を作成する
3. 全セクションを埋める（TBD/TODO 禁止）
4. 以下の exit criteria を全て満たすこと:
   - SPEC-ID が割り当てられている
   - 背景・目的が1文以上
   - スコープ（含む）がバレットリスト
   - スコープ外が明示（"なし" は不可）
   - 受け入れ条件が3件以上（各コマンドで検証可能）
   - 異常系が1件以上
   - セキュリティ要件が記載

【既知パターンの注入】
{anti_patterns_content}
上記の既知アンチパターンに該当する問題がある場合、SPEC のスコープ外・禁止事項に含めてください。

【出力】
作成した SPEC ファイルのパスと SPEC-ID を報告してください。
```

### Evaluator 呼び出し（SPEC採点 — Read-Only）

Agent tool で以下のプロンプトを渡す:

```
あなたは Evaluator です。
templates/skills/sage-evaluate/SKILL.md を読み、その役割定義に従ってください。
templates/skills/sage-evaluate/references/scoring-rubric.md を読み、
6軸・100点満点で以下の SPEC を採点してください:

対象ファイル: {spec_file_path}

【重要: Read-Only 制約】
- Write/Edit ツールの使用は絶対に禁止する
- ドキュメントの修正は一切行わない
- 問題を発見した場合は findings + fix_instructions として報告する

【既知パターン】
{anti_patterns_content}
findings 生成時に上記の既知パターンとの重複を検出してください。

【出力形式】
以下の eval_feedback YAML 形式で厳密に出力してください:

eval_feedback:
  target_file: "{spec_file_path}"
  target_type: SPEC
  verdict: PASS | FAIL
  total_score: N
  grade: "S++ | S+ | S | A- | B | C"
  subscores:
    codified_rules: N/20
    atomic_decomposition: N/20
    spec_driven_development: N/20
    observable_development: N/20
    knowledge_management: N/15
    gradual_adoption: N/5
  findings:
    - id: "EVAL-001"
      axis: "..."
      severity: "critical | major | minor"
      location: "..."
      problem: "..."
      expected: "..."
      actual: "..."
  fix_instructions:
    - finding_id: "EVAL-001"
      target_file: "..."
      section: "..."
      action: "..."
      example: "..."

【File Scope】
- Read: specs/, plans/, tasks/, sage/, .sage/config.yaml
- Write: NONE（絶対に書き込み禁止）
```

### Spec Agent 修正呼び出し（score < 100 の場合）

```
あなたは Spec Agent です。
.claude/prompts/spec-agent.md を読み、その役割定義に従ってください。

【タスク】
以下の Evaluator フィードバックに基づいて SPEC を修正してください:

対象ファイル: {spec_file_path}

【修正指示（fix_instructions）】
{eval_feedback.fix_instructions を展開}

【ルール】
- fix_instructions に記載された修正のみを行う
- 指示にない変更は加えない
- 修正完了後、変更内容の概要を報告する

【File Scope】
- Write: specs/（対象 SPEC ファイルのみ）
```

### Phase 1 ループ制御

```
iteration = 0
WHILE iteration < spec_eval_max_iterations:
  1. Evaluator（Read-Only）を呼び出し → eval_feedback YAML を受け取る
  2. YAML バリデーション実行（上記「YAML 出力バリデーション」参照）
  3. eval_feedback.verdict == "PASS" (score >= 100) → Phase 2 へ進む
  4. eval_feedback.verdict == "FAIL" → Spec Agent 修正呼び出し
  5. iteration += 1

上限到達（spec_eval_max_iterations）:
  → status = "aborted"
  → abort_reason = "spec_eval_max"
  → ユーザーに報告し判断を委ねる
```

---

## Phase 2: Plan + Slice

### Planning Agent 呼び出し

Agent tool で以下のプロンプトを渡す:

```
あなたは Planning Agent です。
.claude/prompts/planning-agent.md を読み、その役割定義に従ってください。

【タスク】
以下の SPEC に基づいて PLAN と TASK を作成してください:
SPEC: {spec_file_path}（SPEC-ID: {spec_id}）

【手順】
1. bash scripts/sage-id-gen.sh plan で PLAN-ID を生成
2. plans/_template.md をコピーして plans/PLAN-{ID}-{short-name}.md を作成
3. SPEC の受け入れ条件を TASK に分解する:
   a. 各 TASK に bash scripts/sage-id-gen.sh task で TASK-ID を割り当て
   b. tasks/_template.md をコピーして tasks/TASK-{ID}-{short-name}.md を作成
   c. 各 TASK に単一責務・File Scope・完了条件を定義
4. Done Definition を作成する:
   a. templates/done-definition-template.md をコピーして
      tasks/done-def-{spec_id}-round-1.md を作成
   b. テスト対象URL、起動コマンド、Pass/Fail判定基準を埋める
      （実装前なので仮値可、Implementation Agent が具体化する）

【既知パターンの注入】
sage/anti-patterns.md の「ハーネス検出パターン」セクションを読み、
該当するパターンがあれば TASK の禁止事項に含めてください。
{anti_patterns_content}

【出力】
PLAN-ID、全 TASK-ID のリスト、Done Definition ファイルパスを報告してください。
```

### Evaluator 呼び出し（PLAN採点 — Read-Only）

SPEC と同じ要領で、PLAN + TASK を6軸採点。
- Evaluator は Read-Only（Write/Edit ツール使用禁止）
- eval_feedback YAML 形式で出力
- score < 100 → Planning Agent に fix_instructions を渡して修正させる

### Planning Agent 修正呼び出し（score < 100 の場合）

```
あなたは Planning Agent です。
.claude/prompts/planning-agent.md を読み、その役割定義に従ってください。

【タスク】
以下の Evaluator フィードバックに基づいて PLAN / TASK を修正してください:

対象ファイル: {eval_feedback.fix_instructions で指定されたファイル}

【修正指示（fix_instructions）】
{eval_feedback.fix_instructions を展開}

【ルール】
- fix_instructions に記載された修正のみを行う
- 指示にない変更は加えない
- 修正完了後、変更内容の概要を報告する

【File Scope】
- Write: plans/, tasks/（対象ファイルのみ）
```

### Phase 2 ループ制御

Phase 1 と同一パターン。上限: `plan_eval_max_iterations` 回。
上限到達 → `abort_reason = "plan_eval_max"`

---

## Phase 3-4: Execute + Verify ループ

### ループ初期化

```
iteration = 0
previous_review_feedback = null
fail_history = {}  # REV-ID → 連続失敗回数
```

### Step 1: Implementation Agent 呼び出し

Agent tool で以下のプロンプトを渡す:

```
あなたは Implementation Agent です。
.claude/prompts/implementation-agent.md を読み、その役割定義に従ってください。

【タスク】
以下の TASK を実装してください:
{task_file_paths のリスト}

【参照ドキュメント】
- SPEC: {spec_file_path}
- PLAN: {plan_file_path}
- Done Definition: {done_def_file_path}

【既知パターンの注入】
以下のアンチパターンに該当する実装を行わないでください:
{anti_patterns_content}

{IF previous_review_feedback AND fix_scope.implementation is not empty:}
【前回の Review フィードバック（iteration {N-1}）】
以下の問題を優先的に修正してください:

findings（implementation向け）:
{previous_review_feedback.findings のうち fix_scope.implementation に該当するもの}

修正指示:
{previous_review_feedback.instruction のうち target: "implementation" のもの}
{ENDIF}

【ルール】
- TASK の File Scope 内の src/ ファイルのみ変更する
- tests/ の変更は禁止（Test Agent の責務）
- specs/, plans/ の変更は禁止
- コミットメッセージに TASK-ID を含める（例: feat: add auth handler [TASK-0001]）
- TODO/FIXME をコミットに残さない
- Done Definition の起動コマンド・テスト対象URL を具体値で更新する

【出力】
実装した内容の概要、変更ファイルリスト、Done Definition の更新内容を報告してください。
```

### Step 1 後の git diff チェック（二重防御）

```bash
# Implementation Agent が tests/ や specs/ を変更していないか確認
impl_diff = bash("git diff --name-only")
forbidden_changes = impl_diff のうち tests/ または specs/ または plans/ にマッチするもの
if forbidden_changes is not empty:
  bash("git checkout -- {forbidden_changes}")
  log_warning("Implementation Agent attempted forbidden file modification — reverted: {forbidden_changes}")
```

### Step 2: Test Agent 呼び出し

Agent tool で以下のプロンプトを渡す:

```
あなたは Test Agent です。
.claude/prompts/test-agent.md を読み、その役割定義に従ってください。

【タスク】
以下の SPEC と Done Definition に基づいてテストを作成・更新してください:

【参照ドキュメント】
- SPEC: {spec_file_path}
- Done Definition: {done_def_file_path}
- TASK ファイル: {task_file_paths}

{IF previous_review_feedback AND fix_scope.test is not empty:}
【前回の Review フィードバック（iteration {N-1}）】
以下のテスト問題を優先的に修正してください:

findings（test向け）:
{previous_review_feedback.findings のうち fix_scope.test に該当するもの}

修正指示:
{previous_review_feedback.instruction のうち target: "test" のもの}
{ENDIF}

【ルール】
- tests/ 内のテストファイルのみ変更する
- src/ の変更は禁止（Implementation Agent の責務）
- specs/, plans/ の変更は禁止
- 正常系・境界値・異常系を網羅する
- カバレッジ閾値（.sage/config.yaml の unit_test_coverage）を達成する

【出力】
作成・更新したテストファイルリスト、テスト実行結果、カバレッジ情報を報告してください。
```

### Step 2 後の git diff チェック（二重防御）

```bash
# Test Agent が src/ を変更していないか確認
test_diff = bash("git diff --name-only")
forbidden_changes = test_diff のうち src/ にマッチするもの
if forbidden_changes is not empty:
  bash("git checkout -- {forbidden_changes}")
  log_warning("Test Agent attempted src/ modification — reverted: {forbidden_changes}")
```

### Step 3: Review Agent 呼び出し（Read-Only）

Agent tool で以下のプロンプトを渡す:

```
あなたは Review Agent です。
.claude/prompts/review-agent.md を読み、その役割定義に従ってください。
特に「Harness Mode」セクションと「Scoring Rubric」セクションを厳守してください。

【ツール使用制限（絶対）】
- Read: 使用可（全ファイル読み取り可）
- Bash: 使用可（テスト実行・lint・カバレッジ計測のみ）
- Write/Edit: 使用禁止（コードの修正は一切行わない）
- Agent: 使用禁止

コードに問題を発見した場合、修正するのではなく、
review_feedback YAML 形式で報告してください。
修正は Implementation Agent / Test Agent の責務です。

【検証対象】
- SPEC: {spec_file_path}
- Done Definition: {done_def_file_path}
- TASK ファイル: {task_file_paths}

【既知パターンの照合】
{anti_patterns_content}
findings 生成時に上記の既知パターンとの照合を行い、該当する場合はその旨を記載してください。

【実行する検証】
1. Gate 1 (Structural): lint, format, type check を実行
2. Gate 2 (Functional): テスト実行、カバレッジ確認 (>= 80%)
3. Gate 3 (Security): secret scan, dependency check を実行
4. Gate 4 (Architecture): File Scope 遵守確認、TASK-ID in commits 確認
5. Done Definition の受け入れ条件を1件ずつ検証
6. ブラウザ検証（.mcp.json が存在する場合のみ）
7. Scoring Rubric（6軸100点）で採点

【出力形式】
以下の review_feedback YAML 形式で厳密に出力してください:

review_feedback:
  round: {round_number}
  iteration: {iteration_number}
  verdict: PASS | FAIL
  review_score: N
  subscores:
    spec_alignment: N/25
    scope_compliance: N/20
    responsibility_alignment: N/15
    complexity: N/10
    test_adequacy: N/15
    safety: N/15
  gate_results:
    structural: pass | fail
    functional: pass | fail
    security: pass | fail
    architecture: pass | fail
  findings:
    - id: "REV-001"
      category: "spec_alignment | scope_compliance | responsibility | complexity | test | safety"
      severity: "critical | major | minor"
      file: "path/to/file"
      expected: "期待される状態"
      actual: "現在の状態"
  fix_scope:
    implementation: [{ file: "path", reason: "理由" }]
    test: [{ file: "path", reason: "理由" }]
  instruction:
    - target: "implementation"
      action: "Implementation Agentへの具体的修正指示"
    - target: "test"
      action: "Test Agentへの具体的修正指示"
  retry_allowed: true | false
  same_fail_count: N

【Hard Fail条件】
以下に該当する場合、review_score に関係なく verdict: FAIL + retry_allowed: false:
- File Scope違反
- Gate 1-4のいずれかFail
- secrets/credentialsのハードコード
- 既知脆弱性を持つ依存の追加
```

### Step 3 後の git diff チェック（二重防御）

```
review_diff = bash("git diff --name-only")
if review_diff is not empty:
  bash("git checkout -- .")
  log_warning("Review Agent attempted file modification — reverted")
```

### fix_scope ルーティング規則

review_feedback の `fix_scope` に基づき、オーケストレーターが再実行するエージェントを機械的に決定する:

| fix_scope.implementation | fix_scope.test | 再実行対象 |
|--------------------------|----------------|-----------|
| 空でない | 空でない | Implementation Agent → Test Agent の順で再実行 |
| 空でない | 空 | Implementation Agent のみ再実行 |
| 空 | 空でない | Test Agent のみ再実行 |
| 空 | 空 | abort（verdict: FAIL だが fix_scope 空はスキーマ不整合） |

### ループ判定

```
IF review_result.verdict == "PASS" AND review_result.review_score >= review_score_threshold (100):
  → ループ終了、Phase 5 へ

IF review_result.retry_allowed == false:
  → abort_reason = "human_escalation"
  → ユーザーに報告

# 同一失敗チェック
FOR each finding in review_result.findings:
  fail_history[finding.id] += 1
  IF fail_history[finding.id] >= same_fail_abort_threshold (3):
    → abort_reason = "same_fail_3x"
    → 該当パターンを sage/failures.md に追記
    → ユーザーに報告

IF iteration >= max_iterations:
  → abort_reason = "max_iterations"
  → ユーザーに報告

ELSE:
  → previous_review_feedback = review_result
  → fix_scope ルーティング規則に従い、該当エージェントのみ再実行
  → 次のイテレーションへ
```

---

## Phase 5: ログ記録

### Run Log 作成

```bash
bash scripts/sage-id-gen.sh run
```

で RUN-ID を生成し、`.sage/runs/RUN-XXXX.yaml` に以下を書き出す:

```yaml
run_id: RUN-XXXX
type: harness
spec_id: SPEC-XXXX
plan_id: PLAN-XXXX
task_ids: [TASK-XXXX, TASK-XXXY]
started_at: "2026-04-10T10:00:00+09:00"
completed_at: "2026-04-10T10:45:00+09:00"
status: pass  # pass | fail | aborted
abort_reason: ""  # max_iterations | same_fail_3x | spec_eval_max | plan_eval_max | human_escalation | yaml_schema_error
iterations: 2
phases:
  specify:
    status: pass
    score: 100
    eval_iterations: 3
    duration_seconds: 120
  plan:
    status: pass
    score: 100
    eval_iterations: 2
    duration_seconds: 180
  execute_verify:
    - iteration: 1
      implementation_status: completed
      test_status: completed
      review_status: fail
      review_score: 72
      review_feedback:
        findings:
          - id: "REV-001"
            category: test
            expected: "テストカバレッジ >= 80%"
            actual: "65%"
        fix_scope:
          implementation: []
          test: [{ file: "tests/auth/login.test.ts", reason: "カバレッジ不足" }]
        instruction:
          - target: "test"
            action: "401応答テストを追加"
    - iteration: 2
      implementation_status: skipped  # fix_scope.implementation が空のためスキップ
      test_status: completed
      review_status: pass
      review_score: 100
gate_results:
  structural: pass
  functional: pass
  security: pass
  architecture: pass
```

### Failure 自動蓄積

`auto_append_failures: true` の場合、abort されたパターンを `sage/failures.md` に自動追記:

```markdown
### FAIL-XXXX: {abort_reason} at Phase {phase}
- **日時**: {timestamp}
- **RUN-ID**: RUN-XXXX
- **Phase**: {specify | plan | execute_verify}
- **Iteration**: {iteration}/{max}
- **最終スコア**: {last_score}
- **最終findings**: {last_findingsの要約}
- **abort_reason**: {max_iterations | same_fail_3x | spec_eval_max | plan_eval_max | human_escalation | yaml_schema_error}
- **再発回数**: N
- **対策**: [未解決]
```

### Anti-Pattern 昇格

`failure_pattern_escalation` 回数（3回）に達したパターンは `sage/anti-patterns.md` に以下の形式で昇格:

```markdown
## AP-XXX: {パターン名}
- **初回発生**: {日時}
- **発生回数**: N
- **abort_reason**: {reason}
- **共通findings**: {繰り返されたfindingsのパターン}
- **推奨対策**: [未解決 | 対策内容]
- **関連FAIL**: [FAIL-001, FAIL-002, ...]
```

---

## 設定値（.sage/config.yaml）

```yaml
harness:
  max_iterations: 5               # Execute-Verify ループ上限
  spec_score_threshold: 100        # Phase 1 通過に必要な Evaluator スコア
  plan_score_threshold: 100        # Phase 2 通過に必要な Evaluator スコア
  review_score_threshold: 100      # Phase 3-4: Review Agent score to pass
  spec_eval_max_iterations: 10     # Phase 1 Evaluator ループ上限
  plan_eval_max_iterations: 10     # Phase 2 Evaluator ループ上限
  verify_pass_required: true       # 全ゲート通過必須
  enable_browser_verify: false     # Playwright MCP によるブラウザ検証
  auto_append_failures: true       # sage/failures.md への自動追記
  same_fail_abort_threshold: 3     # 同一 REV-ID 連続失敗での abort
  failure_pattern_escalation: 3    # anti-patterns.md への昇格閾値
```

---

## 呼び出し方

```
/sage-harness
```

プロンプトで要求を記述する。例:

```
/sage-harness
ユーザー認証機能を追加してください。
メールアドレスとパスワードによるログイン、JWTトークン発行、
認証ミドルウェアが必要です。
```

### オプション引数

- `--spec SPEC-XXXX`: 既存 SPEC から再開（Phase 2 から開始）
- `--plan PLAN-XXXX`: 既存 PLAN から再開（Phase 3 から開始）
- `--max-iterations N`: ループ上限の一時変更

---

## File Scope

| 操作 | 対象 |
|------|------|
| Read | 全ファイル（オーケストレーター自身は全ファイル参照可） |
| Write | `.sage/runs/`（Run Log のみ、append only） |
| Delegate | specs/, plans/, tasks/ は Spec/Planning Agent 経由で変更 |
| Delegate | src/ は Implementation Agent 経由で変更 |
| Delegate | tests/ は Test Agent 経由で変更 |
| Forbidden | `CLAUDE.md`, `AGENTS.md`, `sage/`（governance系）の直接変更 |

---

## Abort 時の対応

ハーネスが abort した場合、以下をユーザーに報告する:

1. **abort_reason** と最終スコア
2. **最後の構造化フィードバック**（失敗項目・修正指示）
3. **Run Log のパス**（`.sage/runs/RUN-XXXX.yaml`）
4. **推奨アクション**:
   - `same_fail_3x`: 該当パターンの根本原因を人間が調査
   - `max_iterations`: SPEC の受け入れ条件を見直し、再実行
   - `spec_eval_max` / `plan_eval_max`: SPEC/PLAN の品質を人間がレビュー
   - `human_escalation`: Review Agent が `retry_allowed: false` と判断した問題を確認
   - `yaml_schema_error`: エージェントの YAML 出力が2回連続でスキーマ不適合
