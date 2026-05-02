# SPEC-0015: MCP allowlist audit + agent identity inventory

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0015 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |
| 更新日    | 2026-05-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0010 (Distribution & Trust Foundation), SPEC-0011 (Hook Hardening), SPEC-0012 (New Defense Layers), SPEC-0013 (Codex Security Guide) |
| 権限レベル | platform |
| 予約Phase | Phase 5 (SPEC-0010/0011/0012/0013 で予約済) |

## 背景・目的

Phase 1-3 で SAGE は以下を整備した:

- **Phase 1** (SPEC-0010): Distribution / template trust / installer
- **Phase 2A** (SPEC-0011): Hook 共通基盤 + protect-sage-files の dangerous keys 検出 (mcp_servers / CODEX_HOME / ANTHROPIC_BASE_URL / bypassPermissions)
- **Phase 2B** (SPEC-0012): security-filter (RUN log redaction) + secret-read-multi-layer + lethal-trifecta-detect (warn-only)
- **Phase 3** (SPEC-0013): Codex security guide

これらにより **「mcp_servers の新規追加を block」「lethal trifecta pattern を warn」「secret を redact」** までは到達したが、以下のギャップが残存:

1. **MCP server の許可リスト概念がない**: 現状は「新規追加を block」のみで、**「どの server が承認済か」を declarative に管理する仕組み**がない。承認済 server も含めて毎回 protect-sage-files で block されるため、結果的に MCP の運用が「初回設定後は変更しない」という暗黙の運用ルールに依存している。
2. **MCP allowlist drift detection がない**: `~/.codex/config.toml` / `.mcp.json` が知らないうちに変更されても、SAGE 側で検知する手段がない (protect-sage-files は **書き込み時** の Claude Code セッション内検出のみ。Codex セッション / 手動編集 / 別ツール経由の変更は素通り)。
3. **AGENT-ID が runtime context と紐づいていない**: `agent_id` enum (spec/planning/implementation/review/test/security/operations) は traceability の field として存在するが、「どの runtime (Claude Code session / Codex session / cron) でどの AGENT-ID が期待されるか」の inventory がない。RUN log validator は enum に含まれることだけ検証し、context 整合性は見ていない。
4. **runtime enforcement は SAGE の責務外** (sage/governance.md §9.2): したがって本 SPEC は **detection / audit のみ** を提供する。実 runtime の MCP 起動 block は Claude Code / Codex 本体機能。

本 SPEC は上記 ① ② ③ を **detection-only / audit-only doctrine** で埋め、Phase 1-3 の defense-in-depth の最後の隙間を closes する。

## 対象ユーザー

- SAGE Development System を Claude Code または Codex と組み合わせて利用する組織 / 開発者
- 特に複数 MCP server を運用する team で「いつの間にか server が増えていた」「conf 編集者が誰か追跡したい」需要がある case
- audit log 文化が既に組織にある場合、SAGE doctor の出力を既存 audit pipeline に流したい運用

## スコープ（含む）

- **MCP allowlist registry schema**: `.sage/mcp-allowlist.yaml` の YAML schema 定義 (各 server に名前 / コマンド / hash / 承認 SPEC-ID / 承認日)
- **MCP allowlist audit hook**: `templates/hooks/mcp-allowlist-audit.sh` 新規 — SessionStart で実 `.mcp.json` / `~/.codex/config.toml` (利用可能な場合) を registry と照合、drift 検出時 warn (standard profile) / block (strict profile)
- **doctor 拡張**: `scripts/sage-doctor.sh` に MCP allowlist check を新ステップとして追加 (registry 存在 / drift / 期限切れ承認の 3 観点)
- **agent identity inventory schema**: `.sage/agent-inventory.yaml` の YAML schema 定義 — どの AGENT-ID がどの runtime context (claude-code / codex-cli / codex-cloud / cron) で expected かを宣言
- **RUN log validator 拡張**: 既存 validator (TASK-0074) に agent_id ↔ inventory 整合性チェックを追加。RUN log の `agent_id` が inventory に declared でない / 矛盾する runtime context の場合 warn
- **doctrine documentation**: SECURITY.md / sage/governance.md §9.1 に「MCP allowlist audit (detection-only)」追加、§9.2 から「MCP allowlist 強制」を残しつつ「audit は提供」に分離。AGENTS.md / CLAUDE.md は cross-reference 1 行のみ (R7 doctrine)

## スコープ外（明示的に除外）

- **runtime での MCP server 起動 block**: Claude Code / Codex 本体機能。SAGE は audit log を出すだけで実 process は止めない (governance §9.2 維持)
- **`.codex/config.toml` runtime の自動更新 / 同期**: user が手で書く前提。SAGE は drift を検出するだけ
- **MCP server の安全性自体の評価**: server コード / バイナリの SAST / dynamic analysis は本 SPEC 範囲外 (SPEC-0017+ で別途検討)
- **organization-wide allowlist の中央配布**: 各 repo の `.sage/mcp-allowlist.yaml` で完結。複数 repo 間の sync は本 SPEC 範囲外
- **agent identity の暗号証明 / SSO 統合**: OS process / OAuth / SSO 経由の agent 認証は SAGE 範囲外。本 SPEC の inventory は **declarative な期待値表** に留まる
- **既存 hook (protect-sage-files) の content-check ロジック変更**: 既存の「mcp_servers 新規追加 block」は維持。本 SPEC の audit hook は **別 hook** として動き、両者は補完関係
- **install.sh 分割** (SPEC-0014 で別途)
- **RUN log SQLite-FTS** (SPEC-0016 で別途)

## 要件

### 機能要件

- **[FR-01] MCP allowlist registry schema**: `.sage/mcp-allowlist.yaml` に以下の field を必須とする:
  - `version` (string, 現状 `"1.0"`)
  - `servers` (list of objects), 各 object に:
    - `name` (string, MCP server の論理名、例 `playwright`)
    - `command` (string, 実行コマンド、例 `npx`)
    - `args` (list of string, 例 `["@anthropic-ai/mcp-playwright@latest"]`)
    - `approved_by` (string, 承認 SPEC-ID または PR URL)
    - `approved_at` (ISO 8601 date)
    - `expires_at` (ISO 8601 date, optional, default 1 year from `approved_at`)
    - `notes` (string, optional, 承認の根拠 / レビュー観点)
  - `bypass` (object, optional): `enabled: false` (default) / `reason` / `expires_at`

- **[FR-02] MCP allowlist audit hook (`templates/hooks/mcp-allowlist-audit.sh`)**:
  - SessionStart hook として動作 (`.claude/settings.json` の `hooks.SessionStart`)
  - profile gating: `none` / `minimal` で skip。`standard` で warn、`strict` で block (exit 1)
  - 比較対象: `.mcp.json` (Claude Code) と `~/.codex/config.toml` (Codex CLI、存在する場合のみ)
  - drift 検出ロジック: 実 config の各 server entry について allowlist registry に同 `name` + `command` + `args` の entry があるか確認
  - 検出 case:
    - **drift 1: 実 config に registry にない server**: warn / block (重大)
    - **drift 2: 実 config の args が registry と異なる**: warn (中程度、version pin 違反等)
    - **drift 3: registry にあるが 実 config にない**: info (削除されたか未設定)
    - **expired approval**: warn (`expires_at` < 今日)
  - registry 不在: 警告 (initial setup 推奨) + skip
  - audit log 出力: `.sage/audit/mcp-allowlist-YYYYMMDD.log` に append (timestamp / runtime / drift type / 詳細)

- **[FR-03] doctor 拡張**: `scripts/sage-doctor.sh` に新ステップを追加:
  - registry 存在チェック (FAIL: missing → WARN レベル)
  - registry schema validity (FAIL: invalid → FAIL レベル)
  - drift check (audit hook と同ロジックを reuse、CLI から呼べる形に factor out)
  - expired approvals の集計 (期限切れ件数 > 0 → WARN)

- **[FR-04] agent identity inventory schema**: `.sage/agent-inventory.yaml` に以下の field:
  - `version` (string, 現状 `"1.0"`)
  - `agents` (list of objects), 各 object に:
    - `agent_id` (enum: spec / planning / implementation / review / test / security / operations、既存 enum と一致)
    - `runtime` (enum: claude-code / codex-cli / codex-cloud / cron / human、複数可)
    - `expected_role` (string, 自由記述)
    - `restricted_to_branches` (list of glob, optional)

- **[FR-05] RUN log validator 拡張**:
  - 既存 validator (TASK-0074) は `agent_id ∈ enum` だけ確認している
  - 本拡張で `agent_id ∈ inventory.agents[*].agent_id` も確認
  - RUN log の `agent_id` が inventory に declared でない場合 warn (operational tip: 新規 agent_id 追加時は inventory も更新)
  - 将来拡張予定 (本 SPEC スコープ外): RUN log に `runtime` field 追加して inventory との runtime 整合性も検証

- **[FR-06] documentation 更新**:
  - `SECURITY.md`: §3 Threat Model に「MCP allowlist drift」追加、§4 SAGE Coverage に audit hook 追加
  - `sage/governance.md` §9.1: hook テンプレート行に `mcp-allowlist-audit (Phase 5, audit-only)` 追加、§9.2 から「MCP allowlist 強制」削除しつつ「runtime での起動 block は Claude/Codex 本体」を維持
  - `AGENTS.md` / `CLAUDE.md`: §9 章末に 1 行 cross-reference (R7 doctrine 厳守)
  - `docs/codex-security.md`: §2 末尾に 1 行追加 (MCP allowlist registry が SAGE 側で audit 可能になったことを言及)

### 非機能要件

- **[NFR-01] パフォーマンス**: audit hook の実行時間 < 200ms (SessionStart hook なので体感遅延が出ない範囲)
- **[NFR-02] idempotency**: 同条件で複数回実行しても同 audit log 内容 (timestamp 除く)
- **[NFR-03] graceful degradation**: registry 不在 / Codex CLI 未 install / `~/.codex/config.toml` 不在 等で hook が fail しないこと
- **[NFR-04] auditability**: 全 drift event を機械可読形式 (TSV または JSON-lines) で `.sage/audit/` に保存
- **[NFR-05] portability**: macOS / Linux 両対応 (BSD awk / GNU awk 差異吸収、bash 4+ 想定)

### セキュリティ要件

- **[SEC-01] detection-only 設計**: 本 SPEC で導入される hook / script は **runtime process を kill / block しない**。MCP server 起動の実阻止は Claude Code / Codex 本体機能。SAGE doctrine の boundary を維持
- **[SEC-02] positive list (allowlist) 原則**: registry に明示列挙された server **のみ** が承認済。「黙認」「default OK」は不可。新 server 追加は SPEC-ID または PR URL を `approved_by` に記録
- **[SEC-03] audit log の改ざん検出**: `.sage/audit/*.log` への追記は append-only 推奨。本 SPEC では運用 doctrine として記述、技術的な append-only enforcement (immutable file flag 等) は範囲外
- **[SEC-04] bypass の auditability**: registry の `bypass.enabled: true` は warn を抑止できるが、その事実自体が doctor の出力に記録される (silent bypass を作らない)
- **[SEC-05] supply chain 連鎖の検知**: 既存 protect-sage-files の content-check (mcp_servers 書き込み block) と本 SPEC の registry-based audit は **直交補完**。前者は書き込み時の即時防御、後者は drift / 後発編集の検出

### 運用要件

- **[OPS-01] profile gating**: `.sage/config.yaml` `hooks.profile` が `none` / `minimal` の場合は audit hook は完全 skip。`standard` で warn、`strict` で block
- **[OPS-02] 初回 setup 体験**: registry 不在の場合、hook は warn 1 回出して skip (block にしない)。`scripts/sage-doctor.sh` の出力で「registry 未設定」を案内
- **[OPS-03] expired approval handling**: `expires_at` < 今日の server について、hook は warn のみ (block しない)。strict profile でも warn のみ。renewal は user 責任 (`approved_at` を更新するだけの PR で済む)
- **[OPS-04] template 雛形**: `templates/sage/mcp-allowlist-template.yaml` + `templates/sage/agent-inventory-template.yaml` を installer 経由で配置可能にする

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `.sage/mcp-allowlist.yaml` schema が定義され、`templates/sage/mcp-allowlist-template.yaml` として例が配置される
- [ ] AC-02: `templates/hooks/mcp-allowlist-audit.sh` が存在し、shellcheck で error 0 件
- [ ] AC-03: `templates/hooks/tests/test-mcp-allowlist-audit.sh` が以下 case を全 PASS:
  - drift 1 (registry にない server) で warn
  - drift 2 (args mismatch) で warn
  - drift 3 (registry only) で info
  - expired approval で warn
  - registry 不在で skip + 1 回 warn
  - profile=minimal で完全 skip
  - profile=strict で drift 1 が block (exit 1)
- [ ] AC-04: `scripts/sage-doctor.sh` 実行で MCP allowlist check が新ステップとして OK / WARN / FAIL を返す
- [ ] AC-05: `.sage/agent-inventory.yaml` schema が定義され、`templates/sage/agent-inventory-template.yaml` として例が配置される
- [ ] AC-06: 既存 RUN log validator が agent_id ↔ inventory 整合性チェックを含み、不整合時 warn
- [ ] AC-07: `SECURITY.md` / `sage/governance.md` §9.1 / `AGENTS.md` / `CLAUDE.md` / `docs/codex-security.md` の 5 ファイルに本 SPEC の cross-reference / 追記が反映 (各最大 +3 行)
- [ ] AC-08: `bash templates/hooks/tests/run-tests.sh` 全 PASS (109 + 新規 ≥ 7 = 116+)
- [ ] AC-09: `bash scripts/sage-validate.sh` PASS
- [ ] AC-10: `bash scripts/sage-doctor.sh` 0 FAIL (新ステップが OK 返す)
- [ ] AC-11: `bash scripts/sage-doc-drift.sh` PASS
- [ ] AC-12: audit hook の実行時間が `time bash templates/hooks/mcp-allowlist-audit.sh < /tmp/empty.json` で **200ms 以内**
- [ ] AC-13: registry 不在時に hook が exit 0 (graceful degradation 確認)

## エラーケース

- **EC-01: registry YAML が parse エラー**: hook 側 → warn 1 回出して skip (block しない)。doctor 側 → FAIL レベル (CI で気付かせる)
- **EC-02: Codex CLI 未 install / `~/.codex/config.toml` 不在**: 該当 runtime の audit を skip、Claude Code 側のみ続行
- **EC-03: `.mcp.json` 不在**: Claude Code の MCP 機能未使用と判断、skip (warn しない)
- **EC-04: drift 検出 + bypass enabled**: warn を抑止、ただし `.sage/audit/mcp-allowlist-bypass.log` に記録 (silent bypass にしない)
- **EC-05: agent inventory に未 declared の agent_id**: validator → warn (新規 agent role 追加時の運用上の reminder)
- **EC-06: hook 実行中に signal interrupt**: trap で audit log を partial state にしない (atomic write 推奨、本 SPEC の実装 TASK で詳細)

## 依存関係 / リスク

### 依存
- 既存 `templates/hooks/protect-sage-files.sh` の content-check ロジック (Phase 2A TASK-0104) — 本 SPEC は補完関係で動く
- 既存 RUN log validator (Phase 2A TASK-0074) — 本 SPEC で拡張
- `.sage/config.yaml` の `hooks.profile` 仕組み (Phase 2A 完成済) — 本 SPEC で profile gating 利用
- `templates/skills/sage-harness/SKILL.md` (Phase 1) — 本 SPEC で harness が新 hook を発火する経路を確認

### リスク
1. **registry が陳腐化する**: user が server 追加時に registry 更新を忘れる → drift 検出で気付く設計、ただし「気付き」が多すぎると noise 化。Mitigation: warn ↔ block の profile 分離 (NFR-03 / OPS-01)
2. **`expires_at` の日次計算で false positive**: timezone 違いで期限ぎりぎりが揺れる可能性。Mitigation: ISO 8601 + UTC で固定、hook 内も `date -u` 利用
3. **agent_id inventory の運用負荷**: 新 agent role 追加のたびに inventory PR が必要。Mitigation: 既存 enum (7 値) を default 全 declare、追加は opt-in
4. **Codex CLI 不在環境での behavior**: 多くの user は Claude Code only。Codex audit を `~/.codex/config.toml` 存在時のみ active 化 (EC-02)
5. **audit log の蓄積で disk 圧迫**: append-only で日次 rotate (`.log.YYYY-MM-DD` 形式)、保持期間は OPS doctrine で 90 日推奨 (本 SPEC の implementation TASK で記述、強制はしない)

## 関連 SPEC / Doctrine

- **SPEC-0010** Distribution & Trust Foundation: §52 で SPEC-0015 を Phase 5 として予約
- **SPEC-0011** Hook Hardening: §53 で「MCP allowlist runtime mechanism」を Phase 5 別 SPEC として予約
- **SPEC-0012** New Defense Layers: §50 で同上
- **SPEC-0013** Codex Security Guide: §57 で「MCP allowlist runtime / agent identity inventory」を Phase 5 SPEC-0015 として予約
- **R-doctrine** (Codex review 累積): R3 (Lethal Trifecta warn-only) と本 SPEC は同方向 — 「detection > enforcement」の SAGE 原則維持
- **sage/governance.md §9.2**: 「MCP server の実行時許可制御」を SAGE 範囲外と明記。本 SPEC は「audit-only」として §9.1 に追加し、§9.2 の「runtime 起動 block」記述は維持

## Phase 5 全体の position (将来 reference)

| SPEC | スコープ | 状態 |
|---|---|---|
| **SPEC-0014** | install.sh 分割 (262KB → module 化) | 予約 (本 SPEC とは独立) |
| **SPEC-0015** | MCP allowlist audit + agent identity inventory (本 SPEC) | Draft |
| **SPEC-0016** | RUN log SQLite-FTS / redaction 後の検索基盤 | 予約 (SPEC-0017+ で再採番可能性あり) |

3 SPEC は互いに独立 — 着手順は user / project priority による。
