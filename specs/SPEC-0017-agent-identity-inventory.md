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

## エラーケース

- **EC-01**: inventory YAML parse error → validator warn + skip inventory check
- **EC-02**: RUN log の `runtime` field が enum 外 (`unknown` を含めて 6 値以外) → warn
- **EC-03**: agent_id が inventory に未 declared → warn (新 agent role 追加時の reminder)
- **EC-04**: tool_runtime pattern が regex として invalid → validator warn + skip その agent

## 関連 Doctrine

- **SPEC-0015 design hints**: SPEC-0015 末尾「SPEC-0017 design hints」section の RUN log schema mapping 表を実装で踏襲
- **R5 (RUN log redaction)**: 4 新 field は enum + free-form string、secret 値は記録しない
- **R7 (CLAUDE/AGENTS 肥大化禁止)**: doc cross-refs 各 +3 行以内
- **R10 (一次ソース)**: validator 差分検出は declared vs observed の事実比較、人間 readable message 不依存
