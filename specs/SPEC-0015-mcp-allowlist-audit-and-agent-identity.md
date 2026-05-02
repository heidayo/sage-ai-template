# SPEC-0015: MCP allowlist audit (supply-chain pinned, audit-only)

> **Note**: 元の SPEC-0015 は「MCP allowlist audit + agent identity inventory」を同梱していたが、Codex Specify-phase review (PR #21) の P1 finding に基づき agent identity inventory は **SPEC-0017** として分離した。本 SPEC は **MCP allowlist audit のみ** を扱う (single-responsibility 原則)。
>
> **ファイル名 (`-and-agent-identity`) は履歴維持のため変更せず**。本文の scope は MCP audit のみに縮小。SPEC-0017 が future work として「Phase 5 全体の position」に予約。

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0015 |
| ステータス | Draft (Specify-phase Codex review 反映済) |
| 作成日    | 2026-05-02 |
| 更新日    | 2026-05-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0010, SPEC-0011, SPEC-0012, SPEC-0013 |
| 権限レベル | platform |
| 予約Phase | Phase 5 (SPEC-0010/0011/0012/0013 で予約済) |

## 背景・目的

Phase 1-3 で以下を整備:

- **Phase 1** (SPEC-0010): Distribution / template trust / installer
- **Phase 2A** (SPEC-0011): Hook 共通基盤 + protect-sage-files の dangerous keys 検出 (mcp_servers / CODEX_HOME / ANTHROPIC_BASE_URL / bypassPermissions)
- **Phase 2B** (SPEC-0012): security-filter (RUN log redaction) + secret-read-multi-layer + lethal-trifecta-detect (warn-only)
- **Phase 3** (SPEC-0013): Codex security guide

これらにより MCP server 周りは「**新規追加を block**」+「**lethal trifecta pattern を warn**」+「**secret を redact**」まで到達したが、以下の supply-chain 観点のギャップが残存:

1. **MCP server の許可リスト概念がない** + **承認 server も実体 pin されていない**: 現状は「新規追加を block」のみで、承認済 server について「どの version / どの publisher / どの sha256」を pin する仕組みがない。`@latest` / 任意 version 許可だと、同じ command shape の中身が悄かに差し替わる **supply-chain drift** が検出できない (Codex review P1)
2. **MCP allowlist drift detection がない**: `~/.codex/config.toml` / `.mcp.json` が知らないうちに変更されても SAGE 側で検知不能 (protect-sage-files は **書き込み時** の Claude Code セッション内検出のみ。Codex セッション / 手動編集 / 別ツール経由の変更は素通り)
3. **runtime enforcement は SAGE の責務外** (sage/governance.md §9.2): したがって本 SPEC は **detection / audit のみ** を提供。実 runtime の MCP 起動 block は Claude Code / Codex 本体機能

本 SPEC は上記 ① ② を **detection-only / audit-only doctrine** + **supply-chain pin (sha256 / version / publisher / source registry)** で埋める。

## 対象ユーザー

- SAGE Development System を Claude Code / Codex CLI と組み合わせて利用する組織 / 開発者
- 特に複数 MCP server を運用する team で「いつの間にか server が増えていた」「`@latest` で気付かないうちに supply-chain が乗っ取られていた」を防ぎたい case
- audit log 文化が既に組織にある場合、SAGE doctor の出力を既存 audit pipeline に流したい運用

## スコープ（含む）

- **MCP allowlist registry schema** (JSON 形式): `.sage/mcp-allowlist.json` の schema 定義 (各 server に **name / command / args (locked version) / sha256 / publisher / source_registry / approved_by / approved_at / expires_at**)
- **MCP allowlist audit hook**: `templates/hooks/mcp-allowlist-audit.sh` 新規 — SessionStart で以下を比較:
  - **デフォルト**: `.mcp.json` (cwd 直下、Claude Code) + **repo-local** `.codex/config.toml` (cwd/.codex/、Codex CLI、存在時のみ)
  - **opt-in**: `.sage/config.yaml` で `mcp_audit.include_user_global_codex: true` を明示した時のみ user-global `~/.codex/config.toml` も対象 (Codex review P2 対応)
- **doctor 拡張**: `scripts/sage-doctor.sh` に MCP allowlist check 新ステップ追加 (registry 存在 / drift / 期限切れ承認 / sha256 mismatch の 4 観点)
- **Performance test helper**: `templates/hooks/tests/measure-hook-time.sh` 新規 — 5 回測定中央値で AC-12 検証 (Codex review P2 対応)
- **Detection-only behavior test**: TASK-0124 で `kill / pkill / killall` 等の実コマンド禁止検証 (grep ではなく挙動 test、Codex review P2 対応)
- **doctrine documentation**: SECURITY.md / sage/governance.md §9.1 / AGENTS.md / CLAUDE.md / docs/codex-security.md に cross-reference 追加 (R7 厳守、各最大 +3 行)

## スコープ外（明示的に除外）

- **runtime での MCP server 起動 block**: Claude Code / Codex 本体機能 (governance §9.2 維持)
- **user-global `~/.codex/config.toml` の default audit**: Codex review P2 で指摘された複数 repo 混乱回避のため opt-in に変更
- **`.codex/config.toml` runtime の自動更新 / 同期**: user が手で書く前提
- **MCP server コード自体の SAST / dynamic analysis**: 別 SPEC で検討
- **organization-wide allowlist の中央配布**: 各 repo の `.sage/mcp-allowlist.json` で完結
- **Agent identity inventory + RUN log runtime field 拡張**: **SPEC-0017** に分離 (Codex review P1 対応、本 SPEC は MCP allowlist audit のみに専念)
- **既存 hook (protect-sage-files) の content-check ロジック変更**: 既存維持、補完関係
- **install.sh 分割** (SPEC-0014)
- **RUN log SQLite-FTS** (SPEC-0016)

## 要件

### 機能要件

- **[FR-01] MCP allowlist registry schema** (`.sage/mcp-allowlist.json`、JSON 形式):

  ```json
  {
    "version": "1.0",
    "servers": [
      {
        "name": "playwright",
        "command": "npx",
        "args": ["@anthropic-ai/mcp-playwright@1.42.0"],
        "version_pin": "1.42.0",
        "sha256": "abc123...",
        "publisher": "anthropic",
        "source_registry": "https://registry.npmjs.org",
        "approved_by": "SPEC-0015 / PR #99",
        "approved_at": "2026-05-02",
        "expires_at": "2027-05-02",
        "notes": "browser automation MCP"
      }
    ],
    "policy": {
      "forbid_latest_tag": true,
      "require_sha256": false,
      "require_publisher": true
    },
    "bypass": {
      "enabled": false,
      "reason": "",
      "expires_at": ""
    }
  }
  ```

  必須 field: `name` / `command` / `args` / `version_pin` / `publisher` / `source_registry` / `approved_by` / `approved_at` / `expires_at`
  推奨 field: `sha256` (`policy.require_sha256: true` で必須化可能)
  optional field: `notes`

- **[FR-02] policy enforcement**: `policy` セクションで organization 方針を declarative に表現:
  - `forbid_latest_tag: true` (default) — args に `@latest` を含む server が registry にあれば WARN、`.mcp.json` に `@latest` が出現したら drift と判定
  - `require_sha256: false` (default) — true にすると sha256 不在の server entry を WARN
  - `require_publisher: true` (default) — publisher field 不在を FAIL (registry validity 違反)

- **[FR-03] MCP allowlist audit hook (`templates/hooks/mcp-allowlist-audit.sh`)**:
  - SessionStart hook として動作 (`.claude/settings.json` の `hooks.SessionStart`)
  - profile gating: `none` / `minimal` で skip。`standard` で warn、`strict` で block (exit 1)
  - **デフォルト比較対象**:
    - `.mcp.json` (cwd 直下、Claude Code MCP)
    - **repo-local** `.codex/config.toml` (`./.codex/config.toml`、存在時のみ)
  - **opt-in 比較対象**: `.sage/config.yaml` で `mcp_audit.include_user_global_codex: true` を明示した場合のみ `~/.codex/config.toml` も追加 (default は opt-out で複数 repo 混乱を回避)
  - drift 検出ロジック: 実 config の各 server entry について registry に同 `name` + `command` + `args` (locked version) + (sha256 if specified) + publisher の entry があるか確認
  - 検出 case:
    - **drift 1: 実 config に registry にない server**: warn / block (重大)
    - **drift 2: 実 config の args が registry と異なる (version mismatch)**: warn (中程度)
    - **drift 3: registry にあるが 実 config にない**: info (削除されたか未設定)
    - **drift 4: `@latest` 出現 (`policy.forbid_latest_tag: true` 時)**: warn
    - **drift 5: sha256 mismatch (`policy.require_sha256: true` + 実 binary の sha256 が一致しない)**: warn (重大、supply-chain compromise の signal)
    - **expired approval**: warn (`expires_at` < 今日)
  - registry 不在: warn 1 回 + skip
  - **audit log 出力**: `.sage/audit/mcp-allowlist-YYYYMMDD.log` に append。args は **redact** (raw command line 全体ではなく `<command> <package-name>@<version>` 形式に正規化、API key 等が args に紛れ込んでも log に出ない、Codex review P2 対応)

- **[FR-04] doctor 拡張**: `scripts/sage-doctor.sh` に新ステップ追加:
  - registry 存在 (FAIL: missing → WARN)
  - registry schema validity (Python stdlib `json.loads()` で parse、不正 → FAIL)
  - drift check (audit hook と同 logic を function source で reuse)
  - expired approvals 集計 (期限切れ件数 → WARN)
  - **sha256 verification** (optional、`policy.require_sha256: true` 時のみ実行)

- **[FR-05] Performance test helper**: `templates/hooks/tests/measure-hook-time.sh` 新規:
  - hook を 5 回実行、各実行時間を `time` で計測
  - 中央値 (median) を算出して閾値 (200ms) と比較
  - `time` 単発の flakiness を回避 (Codex review P2 対応)
  - 戻り値: 中央値 < 閾値 で exit 0、超過で exit 1

- **[FR-06] documentation 更新**:
  - `SECURITY.md`: §3 Threat Model に「MCP allowlist supply-chain drift」追加 (1-2 行)
  - `sage/governance.md` §9.1: hook テンプレート行に `mcp-allowlist-audit (Phase 5, audit-only with supply-chain pin)` 追加
  - `sage/governance.md` §9.2: 「MCP server の実行時許可制御」行を「runtime での起動 block は Claude/Codex 本体。**audit / drift / supply-chain pin 検出は SPEC-0015**」に拡張
  - `AGENTS.md` / `CLAUDE.md`: §9 章末に 1 行 cross-reference (R7 doctrine 厳守)
  - `docs/codex-security.md`: §2 末尾に 1 行追加

### 非機能要件

- **[NFR-01] パフォーマンス**: audit hook の **5 回測定中央値 < 200ms** (`templates/hooks/tests/measure-hook-time.sh` で検証、Codex review P2 反映)
- **[NFR-02] idempotency**: 同条件で複数回実行しても同 audit log 内容 (timestamp 除く)
- **[NFR-03] graceful degradation**: registry 不在 / Codex CLI 未 install / `.codex/config.toml` 不在 / Python 不在 等で hook が fail しないこと
- **[NFR-04] auditability**: 全 drift event を機械可読形式 (JSON-lines) で `.sage/audit/` に保存、args は redact 済
- **[NFR-05] portability**: macOS / Linux 両対応 (BSD awk / GNU awk 差異吸収、bash 4+ 想定)
- **[NFR-06] test scenario coverage**: shell script のため code coverage 概念は不適。代わりに以下のシナリオ網羅性を要求:
  - drift 5 case (drift1 / drift2 / drift3 / drift4 / drift5) 全カバー
  - error case 5 個 (EC-01..EC-05) 全カバー
  - profile 3 状態 (minimal / standard / strict) 全カバー
  - 合計 13 シナリオを test 必須、AC-03 / AC-08 で検証
- **[NFR-07] parser robustness**: registry を **JSON** に統一し Python stdlib `json` で parse (PyYAML 依存回避、Codex review P2 反映)。awk-based shape comparison は脆弱なため不採用

### セキュリティ要件

- **[SEC-01] detection-only 設計** (`audit-first` / `runtime-process-safe`): 本 SPEC で導入される hook / script は **runtime process を kill / signal しない**。`templates/hooks/mcp-allowlist-audit.sh` 内で `kill / pkill / killall / kill -*` 等の実コマンド使用禁止 (TASK-0124 doctor 検証で behavior test、Codex review P2 反映)。strict profile の `exit 1` は **session 開始の block** であり、process kill ではない (terminology 精緻化、Codex review continued doctrine 反映)
- **[SEC-02] positive list (allowlist) + supply-chain pin 原則**: registry に明示列挙された server **のみ + 明示 version pin + (推奨) sha256** が承認済。`@latest` は default で禁止 (`policy.forbid_latest_tag: true`)、明示 risk acceptance 時のみ false 化可能
- **[SEC-03] audit log の改ざん検出**: `.sage/audit/*.log` への追記は append-only 推奨。args は redact (Codex review P2 反映)。技術的な append-only enforcement (immutable file flag 等) は範囲外
- **[SEC-04] bypass の auditability**: registry の `bypass.enabled: true` は warn を抑止できるが、その事実自体が doctor の出力に記録される (silent bypass 禁止)
- **[SEC-05] supply chain 連鎖の検知**: 既存 protect-sage-files の content-check (mcp_servers 書き込み block) と本 SPEC の registry-based audit + sha256 verification は **直交補完**。前者は書き込み時の即時防御、後者は drift / 後発編集 / supply-chain compromise の検出
- **[SEC-06] user-global config の default exclusion**: `~/.codex/config.toml` は user の他 repo 設定を含む可能性があるため default audit から除外 (Codex review P2 反映)。`.sage/config.yaml` で明示 opt-in した場合のみ含める

### 運用要件

- **[OPS-01] profile gating**: `.sage/config.yaml` `hooks.profile` が `none` / `minimal` の場合は audit hook は完全 skip。`standard` で warn、`strict` で block
- **[OPS-02] 初回 setup 体験**: registry 不在の場合、hook は warn 1 回出して skip (block しない)。`scripts/sage-doctor.sh` の出力で「registry 未設定」を案内
- **[OPS-03] expired approval handling**: `expires_at` < 今日の server について、hook は warn のみ (block しない)
- **[OPS-04] template 雛形**: `templates/sage/mcp-allowlist-template.json` を installer 経由で配置可能にする
- **[OPS-05] profile 段階昇格条件**:

  | 昇格 | 条件 | 検証コマンド |
  |---|---|---|
  | minimal → standard | minimal で 7 日運用 + sage-doctor で 0 FAIL 維持 | `bash scripts/sage-doctor.sh && find .sage/audit -name 'mcp-allowlist-*.log' -mtime -7 \| xargs grep -c WARN` |
  | standard → strict | standard で 14 日運用 + drift1 / drift5 (sha256 mismatch) 各 0 件 | `awk '/drift1\|drift5/' .sage/audit/mcp-allowlist-*.log \| wc -l` で 0 |
  | strict 維持 | sha256 mismatch 1 件で即 incident response 起動 | `bash scripts/sage-incident-trigger.sh mcp-supply-chain` (本 SPEC 範囲外、SECURITY.md IR 手順) |

  各段階の昇格は `.sage/config.yaml` `hooks.profile` 更新 PR で実施、PR body に上記検証コマンド出力を貼る (auditability)。

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `.sage/mcp-allowlist.json` schema が JSON 形式で定義され、`templates/sage/mcp-allowlist-template.json` として例が配置される (sha256 / version_pin / publisher / source_registry 全 field 含む)
- [ ] AC-02: `templates/hooks/mcp-allowlist-audit.sh` が存在し、shellcheck で error 0 件、`kill / pkill / killall / kill -*` 実コマンド 0 件 (Codex review P2 detection-only behavior)
- [ ] AC-03: `templates/hooks/tests/test-mcp-allowlist-audit.sh` が以下 case を全 PASS:
  - drift 1 (registry にない server) で warn
  - drift 2 (args version mismatch) で warn
  - drift 3 (registry only) で info
  - drift 4 (`@latest` + `policy.forbid_latest_tag: true`) で warn
  - drift 5 (sha256 mismatch + `policy.require_sha256: true`) で warn (重大)
  - expired approval で warn
  - registry 不在で warn + skip (exit 0)
  - profile=`minimal` で完全 skip (exit 0、log なし)
  - profile=`strict` で drift 1 / drift 5 が block (exit 1)
  - audit log で args が redact されている (raw command line 不在)
  - default で user-global `~/.codex/config.toml` を読まない、opt-in 時のみ読む
- [ ] AC-04: `scripts/sage-doctor.sh` 実行で MCP allowlist check が新ステップとして OK / WARN / FAIL を返す
- [ ] AC-05: Performance test helper `templates/hooks/tests/measure-hook-time.sh` が 5 回測定中央値で AC-12 を機械的判定 (exit code で fail/pass、Codex review P2 反映)
- [ ] AC-06: `SECURITY.md` / `sage/governance.md` §9.1 / §9.2 / `AGENTS.md` / `CLAUDE.md` / `docs/codex-security.md` の 5 ファイルに本 SPEC の cross-reference / 追記が反映 (各最大 +3 行、R7 厳守)
- [ ] AC-07: `bash templates/hooks/tests/run-tests.sh` 全 PASS (109 + 13 シナリオ = 122+)
- [ ] AC-08: `bash scripts/sage-validate.sh` PASS
- [ ] AC-09: `bash scripts/sage-doctor.sh` 0 FAIL (新ステップ含む)
- [ ] AC-10: `bash scripts/sage-doc-drift.sh` PASS
- [ ] AC-11: `bash templates/hooks/tests/measure-hook-time.sh templates/hooks/mcp-allowlist-audit.sh` で 5 回測定中央値 < 200ms (NFR-01)
- [ ] AC-12: registry 不在時 hook が exit 0 (graceful degradation)
- [ ] AC-13: registry が JSON parse 不能の場合、hook は warn 1 回 + skip、doctor は FAIL レベル (EC-01)

### Quality Gate との対応

| AC | 検証 Gate | 検証コマンド (CI) |
|---|---|---|
| AC-01 | Gate 1 (Structural: JSON validity) | `python3 -c "import json; json.load(open('templates/sage/mcp-allowlist-template.json'))"` |
| AC-02 | Gate 1 (Structural: shellcheck) + Gate 3 (Security: detection-only behavior) | `shellcheck templates/hooks/mcp-allowlist-audit.sh && ! grep -nE "\\b(kill\|pkill\|killall)\\b" templates/hooks/mcp-allowlist-audit.sh` |
| AC-03, AC-07, AC-11 | Gate 2 (Functional: hook tests, performance) | `bash templates/hooks/tests/run-tests.sh && bash templates/hooks/tests/measure-hook-time.sh templates/hooks/mcp-allowlist-audit.sh` |
| SEC-01..SEC-06 | Gate 3 (Security: detection-only validation, supply chain 補完, opt-in default) | AC-02 と AC-03 (test case 内) で検証 |
| AC-04, AC-08, AC-09, AC-10, AC-12, AC-13 | Gate 4 (Architecture: traceability, doc drift) | `bash scripts/sage-validate.sh && bash scripts/sage-doctor.sh && bash scripts/sage-doc-drift.sh` |
| AC-06 | Gate 4 (Architecture: doctrine alignment、R7 厳守) | `wc -l SECURITY.md sage/governance.md AGENTS.md CLAUDE.md docs/codex-security.md` で各ファイル増分 ≤ +3 行 |

Gate 5 (Release) は本 SPEC 単独では発火しない (main/production PR の prerequisite check のみ)。

## エラーケース

- **EC-01: registry JSON が parse エラー**: hook 側 → warn 1 回出して skip (block しない)。doctor 側 → FAIL レベル (CI で気付かせる)
- **EC-02: Codex CLI 未 install / `.codex/config.toml` 不在**: 該当 runtime の audit を skip、Claude Code 側のみ続行
- **EC-03: `.mcp.json` 不在**: Claude Code の MCP 機能未使用と判断、skip (warn しない)
- **EC-04: drift 検出 + bypass enabled**: warn を抑止、ただし `.sage/audit/mcp-allowlist-bypass.log` に記録 (silent bypass にしない)
- **EC-05: hook 実行中に signal interrupt**: trap で audit log を partial state にしない (atomic write 推奨)、Codex review continued doctrine の `runtime-process-safe` 用語と整合

## 依存関係 / リスク

### 依存
- 既存 `templates/hooks/protect-sage-files.sh` (Phase 2A TASK-0104) — 補完関係
- `.sage/config.yaml` の `hooks.profile` (Phase 2A 完成済) — profile gating 利用
- `templates/skills/sage-harness/SKILL.md` (Phase 1) — harness が新 hook を発火する経路
- **Python 3.x** (stdlib `json` のみ、PyYAML 不要) — registry parse + sha256 verification

### リスク

各リスクに mitigation + 検証コマンド (CI で発火可能) を併記:

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | registry が陳腐化 (新 server 追加時に registry 更新忘れ → drift noise) | profile 分離 (NFR-03 / OPS-01) | `bash scripts/sage-doctor.sh \| grep "MCP allowlist"` で WARN 件数を週次集計 |
| 2 | `expires_at` の日次計算で false positive (timezone) | ISO 8601 + UTC 固定、hook 内 `date -u` 利用 | `grep -nE "date[^u]" templates/hooks/mcp-allowlist-audit.sh` で 0 件 |
| 3 | sha256 計算負荷 (大きな npm package で 数百 MB) | `policy.require_sha256: false` default、有効化は user 判断 | `time bash templates/hooks/mcp-allowlist-audit.sh < /tmp/empty.json` の継続監視 |
| 4 | Codex CLI 不在環境での behavior | `.codex/config.toml` 存在時のみ active 化 (EC-02) | test-mcp-allowlist-audit.sh の Codex 不在 case で exit 0 |
| 5 | audit log 蓄積で disk 圧迫 | 日次 rotate (`mcp-allowlist-YYYYMMDD.log`)、保持 90 日推奨 | `find .sage/audit -name 'mcp-allowlist-*.log' -mtime +90` で出力 |
| 6 | Python 不在環境での parse 不能 | hook 側で `command -v python3` 失敗時 warn + skip (NFR-03) | test-mcp-allowlist-audit.sh の Python 不在 simulation case |
| 7 | user-global config 漏洩 | default opt-out (SEC-06)、opt-in 時は audit log の args redact 強化 | AC-03 の「default で user-global を読まない」case |

## 失敗時の知識蓄積

本 SPEC は audit-only doctrine のため、検出された drift / false positive は **知識蓄積パスを介して継続改善** に繋げる。

### 知識蓄積フロー (3 ステップ)

```
Step 1 [検出]
  audit hook / sage-doctor が drift event を `.sage/audit/mcp-allowlist-YYYYMMDD.log` に記録
  ↓
Step 2 [記録]
  同 root cause で 2 回以上発生 → `sage/failures.md` に FAIL-MCP-XXXX として追記
  ↓
Step 3 [昇格]
  同 root cause で 3 回以上発生 → `sage/anti-patterns.md` に追記、SAGE doctor へ check ステップ追加検討
```

### sage/failures.md 連携

- **誰が**: drift 検出を運用上 false positive と判断した user / SAGE doctor で WARN を出した repo の owner
- **いつ**: 同 server / 同 drift type で 2 回以上同種 event が記録された時 (`.sage/audit/mcp-allowlist-*.log` を `awk` で集計)
- **どの手順で**: 該当 entry を抽出 → `sage/failures.md` に FAIL-MCP-XXXX として 6 elements (発生日 / 影響 / 検出経路 / 一次原因 / 再発防止 / 関連 SPEC-ID) で追記

### sage/anti-patterns.md への昇格

同 root cause の drift event が 3 回以上 failures.md に記録された場合:
1. `sage/anti-patterns.md` に「MCP-XXXX: <pattern name>」追記
2. SAGE doctor (`scripts/sage-doctor.sh`) に該当 anti-pattern の check ステップ追加検討

### Error Resolution 手順 (実行時)

| EC | エラー時メッセージ例 | Resolution |
|---|---|---|
| EC-01 (registry parse error) | `WARN: .sage/mcp-allowlist.json parse failed; see SPEC-0015 §EC-01` | JSON validity 確認 (`python3 -c "import json; json.load(open(...))"`) → 修正 PR |
| EC-02 (Codex CLI 不在) | (silent skip) | 設計通り |
| EC-03 (.mcp.json 不在) | (silent skip) | Claude Code MCP 未使用時の正常動作 |
| EC-04 (drift + bypass) | `INFO: bypass enabled; logged to .sage/audit/mcp-allowlist-bypass.log` | 該当 server の正規承認 PR、bypass 解除 |
| EC-05 (signal interrupt) | (audit log は trap で atomic 保護) | 設計通り |

## ロールバック手順

本 SPEC の hook / doctor 拡張は **すべて opt-in / profile-gated** で設計、ロールバックは段階的に実施可能:

| レベル | 手順 | 影響範囲 |
|---|---|---|
| 1. 一時 disable (緊急停止) | `.sage/config.yaml` の `hooks.profile: none` で全 hook を skip | 全 SAGE hook が skip (本 SPEC 以外も含む) |
| 2. 部分 disable (本 SPEC のみ無効化) | `.claude/settings.json` の `hooks.SessionStart` から `mcp-allowlist-audit.sh` 行のみ削除 | 他の SessionStart hook は継続動作 |
| 3. 完全 revert | 本 SPEC 導入 PR (PR #21 系) を `git revert` で巻き戻し | template / hook / doctor 拡張すべて元に戻る |

各ロールバック後の検証:
- `bash scripts/sage-doctor.sh` が 0 FAIL を返すこと
- `bash templates/hooks/tests/run-tests.sh` が 109/109 (Phase 1-3 base line) を返すこと

## 関連 SPEC / Doctrine

- **SPEC-0010** Distribution & Trust Foundation: §52 で SPEC-0015 を Phase 5 として予約
- **SPEC-0011** Hook Hardening: §53 で「MCP allowlist runtime mechanism」を Phase 5 別 SPEC として予約
- **SPEC-0012** New Defense Layers: §50 で同上
- **SPEC-0013** Codex Security Guide: §57 で「MCP allowlist runtime / agent identity inventory」を Phase 5 SPEC-0015 として予約 (本 SPEC で MCP audit のみ実装、agent identity は SPEC-0017 へ)
- **R-doctrine** (Codex review 累積): R3 (Lethal Trifecta warn-only) と本 SPEC は同方向 — `audit-first` / `runtime-process-safe` (Codex review continued doctrine 用語精緻化)
- **sage/governance.md §9.2**: 「MCP server の実行時許可制御」を SAGE 範囲外と明記。本 SPEC で「audit / drift / supply-chain pin 検出」を §9.1 に追加し、§9.2 の「runtime 起動 block」記述は維持
- **OWASP Agentic Skills Top 10**: inventory / approval / audit logging を要求 (Codex review continued doctrine R10 反映)、本 SPEC の方向性と整合

## Phase 5 全体の position (将来 reference)

| SPEC | スコープ | 状態 |
|---|---|---|
| **SPEC-0014** | install.sh 分割 (262KB → module 化) | 予約 |
| **SPEC-0015** | **MCP allowlist audit (supply-chain pinned, audit-only)** ← 本 SPEC | Draft (Codex review 反映済) |
| **SPEC-0016** | RUN log SQLite-FTS / redaction 後の検索基盤 | 予約 |
| **SPEC-0017** | **Agent identity inventory + RUN log runtime field 拡張** (元 SPEC-0015 から分離) | 予約 (Codex review P1 で本 SPEC から分離) |

4 SPEC は互いに独立 — 着手順は user / project priority による。SPEC-0017 は本 SPEC 完了後に着手することで、agent identity inventory に **runtime field を最初から含めた設計** が可能になる (元 SPEC-0015 の「将来 scope」を 1st-party scope に格上げ)。
