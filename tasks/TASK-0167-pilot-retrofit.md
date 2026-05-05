# TASK-0167: pilot retrofit Properties to SPEC-0011 / SPEC-0014 / SPEC-0015

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0167 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Done |
| 担当Agent | Spec Agent (pilot retrofit) |
| 並列可否  | Yes (TASK-0163/0164/0165/0166 と並列、別 File Scope) |
| 依存TASK  | TASK-0162 |
| 見積     | 90m |

## 責務

高リスク既存 SPEC 3 件 (SPEC-0011 hooks / SPEC-0014 installer / SPEC-0015 MCP allowlist) に Properties セクションを additive で後付け追加。各 5 件以上、AC との対応関係を実装メモで明示。既存 AC は変更しない。

## 入力

- SPEC-0024 FR-06 (pilot 3 件 retrofit 仕様、各 5 件以上)
- TASK-0162 で確定した specs/_template.md Properties schema
- 既存 SPEC-0011 / SPEC-0014 / SPEC-0015 (各 AC / FR / SEC を Property に変換する元情報)
- SPEC-0024 実装メモの SPEC-0015 retrofit プレビュー例

## 出力

### specs/SPEC-0011-hook-hardening-and-test-infrastructure.md

「## 関連ID」直前に Properties セクション additive (5+ 件):

```markdown
## Properties

権限レベル `platform` + Security 要件あり (R8 / R9 doctrine compliance) のため 5 件以上必須。

### Invariants
- [INV-01] (Gate 3) 全 hook script は shellcheck error 0 件で merge される (R9 doctrine)
- [INV-02] (Gate 3) Hook テストは run-tests.sh に統合され、CI で常時実行される (R8 doctrine)
- [INV-03] (Gate 4) Hook の profile gating (`hooks.profile` in `.sage/config.yaml`) で minimal/standard/strict が動作差別化される

### Pre-conditions
- [PRE-01] (Gate 2) Hook 実行環境に bash 4+ が存在する (NFR-03 portability)

### Post-conditions
- [POST-01] (Gate 2) Hook 実行後、`.sage/audit/*.log` に detection-only behavior の記録が残る (kill 系コマンド呼び出しなし)

### Assumptions
- [ASM-01] (Gate 横断) macOS / Linux 両対応の bash + 標準 unix tools が利用可能
```

### specs/SPEC-0014-installer-modularize.md

```markdown
## Properties

権限レベル `platform` + Security 要件あり (supply-chain trust) のため 5 件以上必須。

### Invariants
- [INV-01] (Gate 4) `scripts/generator/` の 7 module で生成した install.sh が単一ファイルへ byte-identical (`bash scripts/generate-installer.sh > /tmp/new && diff install.sh /tmp/new` で 0 行)
- [INV-02] (Gate 3) install.sh で配布される全 managed_files が SHA256SUMS と一致 (SPEC-0018 supply chain hardening と整合)
- [INV-03] (Gate 4) 7 module の責務分離 (00-header / 01-config / 02-templates / 03-rules / 04-skills / 05-hooks / 06-scripts / 07-installer-main) を維持

### Pre-conditions
- [PRE-01] (Gate 2) install.sh 実行環境に bash 4+ + standard unix tools (sha256sum / shasum / curl) が存在

### Post-conditions
- [POST-01] (Gate 2) `bash install.sh --update` 実行後、既存 `.sage/config.yaml` の `installer_url` 値は不変 (backward compat)

### Assumptions
- [ASM-01] (Gate 横断) generator の embed 方式 (TMPL_* heredoc) で template content が install.sh 内に literal embed される
```

### specs/SPEC-0015-mcp-allowlist-audit-and-agent-identity.md

(SPEC-0024 実装メモ §「Property 記述の例」と同等、5 件以上):

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

### 各 SPEC への AC ↔ Property 対応表 (実装メモ節に追記)

各 SPEC の「## 実装メモ（Implementation Agent向け）」末尾に AC ↔ Property 対応表を追記し、矛盾発生時は SPEC を更新する手順 (governance §11.4) へリンク。

## File Scope（変更許可範囲）

- 変更: `specs/SPEC-0011-hook-hardening-and-test-infrastructure.md` (Properties セクション additive のみ + 実装メモ末尾の対応表 ≤+15 行)
- 変更: `specs/SPEC-0014-installer-modularize.md` (同上)
- 変更: `specs/SPEC-0015-mcp-allowlist-audit-and-agent-identity.md` (同上)

## 禁止事項

- pilot 3 件以外の SPEC (SPEC-0001..0010 / 0012 / 0013 / 0016..0023) を本 TASK で変更しない (incremental migration)
- 各 SPEC の既存 AC / FR / SEC / OPS の本文を変更しない (additive)
- AC ↔ Property 整合性違反を「SPEC を更新せず Property を改変」で隠蔽しない (governance §11.4 違反)
- Property 件数が 5 未満になる SPEC を含めない (権限レベル `platform` + Security 要件あり = 5 件以上必須)
- Property 例値に secret 値を直接書かない (env 名参照のみ、SEC-02)

## 完了条件

- [ ] `for f in 0011 0014 0015; do grep -F "## Properties" specs/SPEC-$f-*.md || exit 1; done`
- [ ] `for f in 0011 0014 0015; do n=$(grep -cE "^- \[(INV|PRE|POST|ASM)-[0-9]+\]" specs/SPEC-$f-*.md); [ "$n" -ge 5 ] || exit 1; done` 全件 5+
- [ ] `for f in 0011 0014 0015; do grep -E "\(Gate [234]\)|\(Gate 横断\)" specs/SPEC-$f-*.md | wc -l | awk "\$1<5{exit 1}"; done` Gate mapping 全件付与
- [ ] `git diff main HEAD -- specs/SPEC-0011*.md specs/SPEC-0014*.md specs/SPEC-0015*.md | awk '/^@@/{f=0} /^-[^-]/{f=1} END{exit f}'` で 既存行 deletion 0
- [ ] `bash scripts/sage-validate.sh` PASS (新 Property セクションで sage-validate が break しない)
- [ ] commit message に `TASK-0167:` 含む
