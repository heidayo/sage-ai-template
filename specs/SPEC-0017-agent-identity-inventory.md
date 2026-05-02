# SPEC-0017: Agent identity inventory + RUN log runtime field

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0017 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |
| 更新日    | 2026-05-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0008 (RUN log validator), SPEC-0015 (audit log schema doctrine) |
| 権限レベル | platform |
| 予約Phase | Phase 5 (SPEC-0015 から分離、design hints 既存) |

## 背景・目的

SAGE は traceability の核として `agent_id` enum (spec/planning/implementation/review/test/security/operations) を RUN log で記録するが、以下のギャップが残存:

1. **agent identity inventory 不在**: どの agent_id が **どの runtime context (claude-code / codex-cli / codex-cloud / cron / human)** で expected か宣言できない。新 agent role 追加時の運用統制なし
2. **RUN log に observed runtime field なし**: 現状 RUN log schema は agent_id を記録するが、その RUN が **実際にどの runtime で実行されたか** の field がない。「宣言値 vs 実測値」の差分検出不可
3. **SPEC-0015 design hints**: SPEC-0015 で「inventory のみは anti-pattern、RUN log schema 拡張で実測値を記録」「validator が宣言と実測の差分を warn」を 1st-party scope として SPEC-0017 で設計するよう先行記録済

本 SPEC は SPEC-0015 design hints に従い、agent identity inventory + RUN log runtime field 拡張 + validator 差分検出を実装する。

## 対象ユーザー

- 複数 runtime (claude-code + codex-cli + cron 等) で SAGE を運用する team
- agent role 追加時に統制 PR を要求したい組織
- RUN log を SIEM / audit pipeline に流す user

## スコープ（含む）

- **`.sage/agent-inventory.yaml` schema**: agent_id 別に expected runtime / approval_policy / network_mode を declarative に宣言
- **RUN log schema 拡張**: `runtime` / `tool_runtime` / `approval_policy` / `network_mode` を 4 新 field として追加 (NFR-04 の machine-readable enum)
- **RUN log validator 拡張**: `scripts/sage-runlog-validate.sh` に declared vs observed の差分検出を追加 (warn-only、existing RUN log は backward compat)
- **`templates/sage/agent-inventory-template.yaml`**: 7 agent_id 全 default declare
- **doctor 拡張**: `scripts/sage-doctor.sh` に「agent inventory drift」step 追加
- **doctrine documentation**: 5 doc cross-refs (R7 厳守、各 +3 行以内)

## スコープ外（明示的に除外）

- runtime 認証 / SSO / OAuth: 本 SPEC は declarative inventory only
- 既存 RUN log の retroactive migration: 4 新 field は optional、既存 RUN log は warn なし
- MCP allowlist 関連 (SPEC-0015 で完了)
- install.sh 分割 (SPEC-0014)
- RUN log 検索基盤 (SPEC-0016)

## 要件

### 機能要件

- **[FR-01] agent inventory schema** (`.sage/agent-inventory.yaml`):
  ```yaml
  version: "1.0"
  agents:
    - agent_id: implementation
      expected_runtime: ["claude-code", "codex-cli"]
      expected_tool_runtime_pattern: "(claude-code-2|codex-cli-0)\\."
      expected_approval_policy: "on-request"
      expected_network_mode: "off"
      restricted_to_branches: ["feature/*", "fix/*"]
      notes: "Implementation agent"
  ```
  必須 field: `agent_id` / `expected_runtime` / `expected_approval_policy` / `expected_network_mode`
  推奨 field: `expected_tool_runtime_pattern` / `restricted_to_branches`
  optional: `notes`

- **[FR-02] RUN log schema 4 新 field** (NFR-04 machine-readable enum):
  - `runtime` (enum): `claude-code` / `codex-cli` / `codex-cloud` / `cron` / `human` / `unknown`
  - `tool_runtime` (string): 例 `claude-code-2.1.x`, `codex-cli-0.23.x`, free-form
  - `approval_policy` (enum): `on-request` / `never` / `always` / `unknown`
  - `network_mode` (enum): `off` / `allowlist` / `unrestricted` / `unknown`
  - 全 field optional (backward compat)、`unknown` で unset 表現

- **[FR-03] validator 差分検出** (`scripts/sage-runlog-validate.sh` 拡張):
  - inventory 不在: 既存 logic のみ実行 (graceful)
  - inventory 存在 + RUN log の `runtime` field 不在: warn (新 field 推奨)
  - inventory 存在 + RUN log `runtime` ∉ `inventory.agents[agent_id].expected_runtime`: warn (declared vs observed mismatch)
  - inventory 存在 + RUN log `approval_policy` ≠ `expected_approval_policy`: warn
  - inventory 存在 + RUN log `network_mode` ≠ `expected_network_mode`: warn
  - validator 全体は PASS (warn 止まり、FAIL にしない、backward compat 維持)

- **[FR-04] doctor 拡張**: `scripts/sage-doctor.sh` に新 sub-check 追加 (sage-mcp-allowlist-audit.sh と同パターン):
  - inventory 存在チェック (WARN if missing)
  - 最近 N (default 10) RUN log を集計、declared vs observed mismatch 件数を WARN
  - missing runtime field の RUN log 件数を INFO

- **[FR-05] template + documentation**:
  - `templates/sage/agent-inventory-template.yaml` (7 agent_id 全 default declare)
  - `templates/run-log-template.yaml` を 4 新 field 付きに更新 (commented optional)
  - `.sage/config.yaml` の `run_log_schema.fields` を 4 新 field で拡張
  - 5 doc cross-refs (sage/governance.md §9.1, AGENTS.md / CLAUDE.md / SECURITY.md / docs/codex-security.md、各 +3 行以内、R7 厳守)

### 非機能要件

- **[NFR-01] backward compat**: 既存 RUN log (4 新 field なし) は validator PASS のまま (warn のみ)
- **[NFR-02] graceful degradation**: inventory 不在で validator 既存 logic のみ実行
- **[NFR-03] portability**: macOS / Linux 両対応 (Python 3 stdlib 使用)
- **[NFR-04] auditability**: validator warn は既存 stderr format と統一 (`WARN: ...`)

### セキュリティ要件

- **[SEC-01] declarative-only**: 本 SPEC は inventory + RUN log enum のみ、runtime での agent identity 認証は対象外 (governance §9.2 維持)
- **[SEC-02] no secret in inventory**: inventory に token / API key を直接書かせない (env 名参照のみ、SPEC-0015 SEC-07 と同方針)

### 運用要件

- **[OPS-01] inventory adoption phase**: inventory 不在 → validator 既存 logic のみ (graceful)、inventory 存在 → drift detection 有効
- **[OPS-02] 4 新 RUN log field 採用 phase**: 4 field optional、RUN log writer (sage-runlog 等) が段階的に出力開始
- **[OPS-03] expected_* tighten phase**: inventory の `expected_runtime` を最初は `["claude-code", "codex-cli", "human"]` 等の broad list、運用で実 RUN log を集計後に narrow

- **[OPS-04] 段階採用昇格条件**:

  | 昇格 | 条件 | 検証コマンド |
  |---|---|---|
  | none → inventory 導入 | sage-doctor で 0 FAIL 維持、existing RUN log で validator PASS | `bash scripts/sage-doctor.sh && bash scripts/sage-runlog-validate.sh` |
  | inventory broad → narrow | broad inventory で 7 日運用 + drift event 0 件 | `python3 scripts/sage-agent-inventory-audit.sh \| awk -F'\\t' '$1=="WARN" && $2=="agent_inventory_drift"' \| wc -l` で 0 |
  | optional field → required | RUN log writer が 4 field 出力で 14 日運用 + missing_runtime 0 件 | doctor [4/5] で `agent_inventory_missing_runtime` が `0/N` |

## 受け入れ条件 (AC)

- [ ] AC-01: `templates/sage/agent-inventory-template.yaml` 存在、7 agent_id 全 declare、yaml lint pass
- [ ] AC-02: `templates/run-log-template.yaml` に 4 新 field (commented optional) 追加
- [ ] AC-03: `.sage/config.yaml` `run_log_schema.fields` に 4 新 field 追加
- [ ] AC-04: `scripts/sage-runlog-validate.sh` 拡張、4 新 case (inventory 不在 / runtime 不在 / runtime mismatch / approval mismatch) 全 PASS
- [ ] AC-05: `scripts/sage-doctor.sh` に「agent inventory drift」step 追加
- [ ] AC-06: `templates/hooks/tests/test-agent-inventory-validator.sh` 新規、6+ シナリオ全 PASS
- [ ] AC-07: 5 doc files に cross-ref 追加 (各 +3 行以内、R7 厳守)
- [ ] AC-08: `bash scripts/sage-validate.sh` PASS
- [ ] AC-09: `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] AC-10: `bash scripts/sage-doc-drift.sh` PASS
- [ ] AC-11: `bash templates/hooks/tests/run-tests.sh` 全 PASS (既存 + 新規)
- [ ] AC-12: 既存 RUN log (.sage/runs/RUN-*.yaml) backward compat (validator PASS)

### Quality Gate との対応

| AC | 検証 Gate | 検証コマンド (CI) |
|---|---|---|
| AC-01, AC-02, AC-03 | Gate 1 (Structural: yaml lint) | `python3 -c "import yaml; yaml.safe_load(open('templates/sage/agent-inventory-template.yaml'))"` |
| AC-04, AC-06, AC-11 | Gate 2 (Functional: validator + hook tests) | `bash templates/hooks/tests/run-tests.sh && bash templates/hooks/tests/test-agent-inventory-validator.sh` |
| SEC-01, SEC-02 | Gate 3 (Security: declarative-only / no secret) | `! grep -E "(api_key\|token\|secret).*[:=].*['\"]" templates/sage/agent-inventory-template.yaml` |
| AC-05, AC-08, AC-09, AC-10, AC-12 | Gate 4 (Architecture: traceability / doctor / doc-drift / regression) | `bash scripts/sage-validate.sh && bash scripts/sage-doctor.sh && bash scripts/sage-doc-drift.sh && bash scripts/sage-runlog-validate.sh` |
| AC-07 | Gate 4 (Architecture: doctrine alignment、R7 厳守) | `wc -l SECURITY.md sage/governance.md AGENTS.md CLAUDE.md docs/codex-security.md` で各ファイル増分 ≤ +3 行 |

Gate 5 (Release) は本 SPEC 単独では発火しない (main/production PR の prerequisite check のみ)。

## エラーケース

- **EC-01**: inventory YAML parse error → validator warn + skip inventory check
- **EC-02**: RUN log の `runtime` field が enum 外 (`unknown` を含めて 6 値以外) → warn
- **EC-03**: agent_id が inventory に未 declared → warn (新 agent role 追加時の reminder)
- **EC-04**: tool_runtime pattern が regex として invalid → validator warn + skip その agent

## 依存関係 / リスク

### 依存
- 既存 RUN log validator (Phase 2A TASK-0074、SPEC-0008)
- `.sage/config.yaml` `run_log_schema.fields` (Phase 1 完成済)
- `.sage/agent-inventory.yaml` (本 SPEC で導入)
- Python 3 + PyYAML (validator が既に依存)

### リスク

各リスクに mitigation + 検証コマンド (CI で発火可能) を併記:

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | inventory が陳腐化 (新 agent role 追加で inventory 更新忘れ → drift noise) | inventory 不在で graceful (NFR-02)、warn-only (NFR-01) | `bash scripts/sage-doctor.sh \| grep "agent_inventory"` で WARN 件数を週次集計 |
| 2 | YAML 1.1 で `network_mode: off` が bool parse される | `_coerce_yaml_str()` で bool→string 変換 (validator + audit script 両方) | `python3 -c "import yaml; print(type(yaml.safe_load('off')))"` で bool 確認 + validator test |
| 3 | 既存 RUN log (4 新 field なし) が validator FAIL する | 全 4 field optional、`unknown` で unset 表現、warn-only (NFR-01) | `bash scripts/sage-runlog-validate.sh .sage/runs/*.yaml` で既存 4 RUN log PASS 確認 |
| 4 | inventory に declared でない agent_id の RUN log で warn 過多 | 未 declared なら silent (validator inventory_warnings で early return) | test scenario 7 で検証 (agent_id not in inventory → silent) |
| 5 | tool_runtime regex が invalid で validator crash | EC-04 で warn + skip (graceful)、validator 全体は PASS | unit test で invalid regex inject |
| 6 | Python yaml module 不在で validator FAIL | 既存 validator と同パターンで明示 ImportError → exit 1 | `pip install pyyaml` 案内 |
| 7 | inventory file が secret を含む可能性 (env 名のみで OK だが運用ミス) | SEC-02 で declarative-only 明記、env 名参照のみ許可 | `grep -E "(api_key\|token\|secret).*[:=].*['\"]" templates/sage/agent-inventory-template.yaml` で 0 件 |

## 失敗時の知識蓄積

本 SPEC は validator-only doctrine のため、検出された drift / false positive は **知識蓄積パスを介して継続改善** に繋げる。

### 知識蓄積フロー (3 ステップ)

```
Step 1 [検出]
  validator / sage-doctor が drift event を stderr に出力
  ↓
Step 2 [記録]
  同 root cause で 2 回以上発生 → `sage/failures.md` に FAIL-AGENT-XXXX として追記
  ↓
Step 3 [昇格]
  同 root cause で 3 回以上発生 → `sage/anti-patterns.md` に追記、inventory schema へ field 追加検討
```

### sage/failures.md 連携

- **誰が**: validator drift を運用上 false positive と判断した user / sage-doctor で WARN を出した repo の owner
- **いつ**: 同 agent_id / 同 drift type で 2 回以上記録された時 (RUN log 集計で抽出)
- **どの手順で**: 該当 RUN log entry を抽出 → `sage/failures.md` に FAIL-AGENT-XXXX として 6 elements (発生日 / 影響 / 検出経路 / 一次原因 / 再発防止 / 関連 SPEC-ID) で追記

### sage/anti-patterns.md への昇格

同 root cause の drift event が **3 回以上 failures.md に記録された場合**:
1. `sage/anti-patterns.md` に「AGENT-XXXX: <pattern name>」追記
2. inventory schema field 追加検討 (例: 新 expected_* field を Phase 6 で SPEC 起票)

### Error Resolution 手順 (実行時)

| EC | エラー時メッセージ例 | Resolution |
|---|---|---|
| EC-01 (inventory parse error) | `WARN: inventory parse failed; SPEC-0017 EC-01` | YAML lint で行番号特定 → 修正 PR |
| EC-02 (runtime field enum 外) | `WARN: runtime not in enum {...}: got 'X'` | 該当 RUN log の runtime を 6 値のいずれかに修正 |
| EC-03 (agent_id 未 declared) | (silent) | inventory に該当 agent_id を declare する PR |
| EC-04 (tool_runtime regex invalid) | `WARN: invalid expected_tool_runtime_pattern; skip agent X` | inventory の regex 修正 |

## ロールバック手順

本 SPEC の inventory + validator 拡張は **opt-in / backward-compat** で設計されているため、ロールバックは段階的に実施可能:

| レベル | 手順 | 影響範囲 |
|---|---|---|
| 1. inventory 一時 disable | `.sage/agent-inventory.yaml` を rename / delete | validator inventory check 無効、既存 logic のみ動作 |
| 2. RUN log 4 新 field 撤回 | RUN log writer で 4 field 出力停止 | warn 多発するが validator PASS 維持 |
| 3. validator 拡張 revert | `scripts/sage-runlog-validate.sh` の inventory_warnings 関数を `return []` で空 stub | warn 完全消失、既存 enum check のみ |
| 4. 完全 revert | 本 SPEC 導入 PR を `git revert` | template / validator / doctor / installer 全て元に戻る |

各ロールバック後の検証:
- `bash scripts/sage-doctor.sh` が 0 FAIL を返すこと
- `bash templates/hooks/tests/run-tests.sh` が 138/138 (Phase 5 base line) を返すこと
- 既存 .sage/runs/RUN-*.yaml で `bash scripts/sage-runlog-validate.sh` PASS

## 関連 Doctrine

- **SPEC-0015 design hints**: SPEC-0015 末尾「SPEC-0017 design hints」section の RUN log schema mapping 表を実装で踏襲
- **R5 (RUN log redaction)**: 4 新 field は enum + free-form string、secret 値は記録しない
- **R7 (CLAUDE/AGENTS 肥大化禁止)**: doc cross-refs 各 +3 行以内
- **R10 (一次ソース)**: validator 差分検出は declared vs observed の事実比較、人間 readable message 不依存
