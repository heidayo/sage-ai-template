# SPEC-0011: Hook Hardening & Test Infrastructure (Phase 2A)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0011 |
| ステータス | Approved |
| 作成日    | 2026-05-01 |
| 更新日    | 2026-05-01 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0003 (hooks-enforcement), SPEC-0010 (Phase 1 distribution-trust) |
| 権限レベル | system |

## 背景・目的

SAGE v2 改修ロードマップ Phase 2A。Phase 1 で「SAGE は runtime sandbox を提供しない」「hook は pattern matching であり sandbox の代替ではない」と正直に開示した上で、**hook そのものの品質を底上げ** する。

Codex review (cross-model adversarial) の以下に対応する:

- **R8**: 新規 hook には test 必須 → CONTRIBUTING.md で要求済み、本 SPEC で **test harness を実装** + 既存 5 hooks に smoke test を遡及付与
- **R9**: shellcheck 通過必須 → CONTRIBUTING.md で要求済み、本 SPEC で **CI で enforce**
- 旧 R3 (Lethal Trifecta は warn-only)、R5 (RUN log redaction 先行) は SPEC-0012 (Phase 2B) で対応

加えて、参考資料 (Adversa AI / BeyondTrust / Check Point CVE-2025-59536 + CVE-2026-33068 + CVE-2025-61260) で報告された具体的攻撃ベクターに対応する pattern を既存 hook に追加:

- `block-dangerous-commands.sh`: subcommand chain 長制限 (Adversa 50+ subcommands bypass 対応)、redirection write (`echo > .claude/settings.json` 系、CVE-2026-25723 piped sed と同質)、`python/node/ruby -c` 経由の file write、Unicode obfuscation 検出 (BeyondTrust branch name injection 対応)
- `protect-sage-files.sh`: 既存の path 単位の block に加え、**書き込み内容に dangerous keys** (`bypassPermissions`, `CODEX_HOME`, `ANTHROPIC_BASE_URL`, `mcp_servers`) が含まれる場合の追加検査 (CVE-2026-33068 / CVE-2025-59536 / CVE-2025-61260 と同質の supply chain attack 検出)

最後に、`AGENTS.md` / `sage/governance.md` に **hook が Claude Code 中心であり Codex には別途 sandbox/approval 設定が必要** という事実を明文化 (Codex review R2 への追加補強)。

## 対象ユーザー

- SAGE 採用組織 (hook 強化により Phase 1 の "honest disclosure" を補う実防御力を提供)
- SAGE への contributor (hook 変更に test と shellcheck が要求されることで品質維持)
- Codex を併用する開発者 (hook の Claude 中心性を明示することで誤った安全期待を防ぐ)

## スコープ（含む）

- `templates/hooks/tests/` 新規ディレクトリ + bash-based test harness (`run-tests.sh`)
- 既存 5 hooks (block-dangerous-commands, protect-sage-files, check-file-scope, session-start, session-stop) への smoke test 各 1-3 ケース
- `.github/workflows/sage-structural-gate.yml` に shellcheck step 追加 (新規 .sh のみ block、既存 baseline は WARN 扱い)
- `block-dangerous-commands.sh` 拡張: chain 長制限、redirection write、python/node/ruby -c 経由 file write、Unicode obfuscation 検出
- `protect-sage-files.sh` 拡張: 書き込み内容に dangerous keys (bypassPermissions / CODEX_HOME / ANTHROPIC_BASE_URL / mcp_servers / `enableAllProjectMcpServers: true`) を含む場合の追加検出
- `AGENTS.md` / `sage/governance.md` の Codex 非対応の明記 (1-2 段落の追記)
- `scripts/generate-installer.sh` + `install.sh` の対応再生成 (hooks がテンプレートに embed されているため)

## スコープ外（明示的に除外）

- **新規 hook ファイル追加**: lethal-trifecta-detect.sh / secret-read-multi-layer.sh / security-filter.sh は Phase 2B (SPEC-0012) で扱う
- **Sandbox settings template**: `templates/settings/sandbox.json` も SPEC-0012 範囲
- **Codex 専用 docs/codex-security.md**: Phase 3 (SPEC-0014 予定)
- **MCP allowlist runtime mechanism**: Phase 5 (別 SPEC)
- **既存 hook の動作変更**: 新規 pattern 追加のみ。既存 pattern の振る舞い (exit code, message format) は保持
- **shellcheck 既存 baseline 違反の解消**: 既存 .sh の warning は本 SPEC では touch しない (新規 .sh 追加分と本 SPEC で変更した行のみ enforce)
- **install.sh 構造分割**: SPEC-0011 とは独立に install.sh splitting SPEC を後で起案する

## 要件

### 機能要件

- [FR-01] `templates/hooks/tests/run-tests.sh` が `bash templates/hooks/tests/run-tests.sh` で全 test を実行し、各 test の PASS/FAIL を集計、1 件でも FAIL があれば exit 1
- [FR-02] 既存 5 hooks それぞれに対し smoke test (正常系 1 + block 期待ケース 1) が `templates/hooks/tests/test-<hook-name>.sh` に存在
- [FR-03] `.github/workflows/sage-structural-gate.yml` に shellcheck job が追加され、`templates/hooks/*.sh` と `scripts/*.sh` の new/modified ファイルを検査
- [FR-04] `block-dangerous-commands.sh` に以下の追加 pattern が実装される:
  - **chain長制限**: `;` / `&&` / `||` / `|` のいずれかが ≥ 30 個含まれる command は block (Adversa AI 50+subcommands bypass 対応、安全側に倒して 30)
  - **redirection write**: `> .claude/`, `> .git/`, `> .github/`, `> .sage/config.yaml`, `> .mcp.json` (および `>>`, `tee` 経由) を block
  - **interpreter -c file write**: `python -c .* open(.*'w'`, `node -e .* writeFile`, `ruby -e .* File.open(.*'w'` を block
  - **Unicode obfuscation警告**: branch 名/file 名に `U+3000` (Ideographic Space) や `U+200B-200F` (zero-width) が含まれる場合 stderr に WARN 出力 (block はしない、誤検知を避けるため)
- [FR-05] `protect-sage-files.sh` に以下の追加検査が実装される (`tool_input.content` を読む):
  - 対象ファイルが `.claude/settings.json` で書き込み内容に `"defaultMode": "bypassPermissions"` または `enableAllProjectMcpServers.*true` を含む場合、active TASK 有無に関わらず block + 追加警告
  - 対象ファイルが `.env` で書き込み内容に `CODEX_HOME=` / `ANTHROPIC_BASE_URL=` を含む場合、active TASK 有無に関わらず block + CVE 引用警告
  - 対象ファイルが `.codex/config.toml` または `.mcp.json` で書き込み内容に `mcp_servers` 新規追加 (既存にない server name) を含む場合、active TASK 有無に関わらず block + 警告
- [FR-06] `AGENTS.md` の §1 末尾 (または §2 直後) に "**Codex specificity**" 短い段落追加 — hook は Claude Code の PreToolUse/PostToolUse 機構に依存しており Codex セッションでは効かないこと、Codex では別途 `workspace-write` + `on-request` + network allowlist を `~/.codex/config.toml` で設定する必要があることを明記
- [FR-07] `sage/governance.md` §9.2 (SAGE が提供しないもの) に「Hook の有効性は Claude Code 限定」を 1 行追加
- [FR-08] `scripts/generate-installer.sh` を更新し、上記 hook 変更を install.sh 再生成に反映

### 非機能要件

- [NFR-01] 互換性: 既存 hook が現在 PASS させているケースは引き続き PASS する (新規 pattern 追加のみ、既存 pattern 削除なし)
- [NFR-02] テスト実行時間: `bash templates/hooks/tests/run-tests.sh` が ローカルで < 5 秒で完了
- [NFR-03] CI 追加コスト: shellcheck job が < 30 秒で完了 (既存 file 数 ~10 程度)
- [NFR-04] 偽陽性管理: 新規 pattern の誤検知が pre-existing test suite で 0 件 (run-tests.sh で確認)

### セキュリティ要件

- [SEC-01] hook 自身に shell injection vulnerability が無いこと (test harness で `$(rm -rf)` 等の悪意 input を渡しても hook 自体が落ちないこと)
- [SEC-02] test harness が一時ファイルを `mktemp` で作成し、test 終了時に必ず cleanup (trap)
- [SEC-03] 既存 hook の `--no-verify` / `git push --force` / `rm -rf /|~|.` 等の core block 機能が regression なく保持

### 運用要件

- [OPS-01] 新規 hook test は `templates/hooks/tests/README.md` で書き方を文書化
- [OPS-02] CI 失敗時、shellcheck 出力が GitHub Actions の Annotation として表示される

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `bash templates/hooks/tests/run-tests.sh` exit 0 (全 test PASS)
- [ ] AC-02: 既存 5 hook の test ファイル (`test-block-dangerous-commands.sh` 他 4 件) が存在
- [ ] AC-03: `templates/hooks/tests/run-tests.sh` 内で intentional FAIL を仕込んだ branch では exit 1 (negative test)
- [ ] AC-04: `shellcheck templates/hooks/*.sh` で warning 0 (新規/変更分のみ enforce)
- [ ] AC-05: `.github/workflows/sage-structural-gate.yml` に shellcheck step が含まれる
- [ ] AC-06: 30 個以上の `;` を含むダミー command を `block-dangerous-commands.sh` に渡すと exit 2 (chain長制限)
- [ ] AC-07: `echo malicious > .claude/settings.json` を渡すと exit 2 (redirection write)
- [ ] AC-08: `python -c "open('foo','w').write('x')"` を渡すと exit 2 (interpreter file write)
- [ ] AC-09: `.claude/settings.json` への `"defaultMode": "bypassPermissions"` 書き込みが TASK active でも block (FR-05 #1)
- [ ] AC-10: `.env` への `CODEX_HOME=./malicious` 書き込みが block (FR-05 #2)
- [ ] AC-11: `AGENTS.md` に Codex specificity 段落が含まれる (`grep -q "Codex specificity\|hook は Claude Code\|Codex sessions"`)
- [ ] AC-12: `sage/governance.md` §9.2 に hook の Claude Code 限定明記
- [ ] AC-13: `bash scripts/sage-validate.sh` PASS
- [ ] AC-14: `bash scripts/sage-doctor.sh` 0 FAIL (既存 WARN は許容)
- [ ] AC-15: `bash install.sh --dry-run` exit 0 (Phase 1 機能 regression なし)

## 異常系

- 想定エラー1: jq が不在の環境で hook test → grep fallback path も test 対象に含める
- 想定エラー2: chain 長制限の境界 (29 個 vs 30 個) 検証 → boundary test を test ファイルに追加
- 想定エラー3: Unicode 検出が macOS/Linux locale 差で動作不一致 → POSIX-class 使用、test harness で確認
- 境界ケース1: hook stdin が空 / malformed JSON → 既存通り exit 0 (allow) で false-block を避ける、test で確認

## 契約

- API: なし
- DB: なし
- イベント: Claude Code PreToolUse hook payload schema (既存依存、変更なし)
- File contract: `templates/hooks/tests/` ディレクトリ新規、`templates/hooks/*.sh` 既存ファイル拡張のみ

## リスク

- リスク1: 新 pattern が legitimate use case を誤 block → mitigation: test harness に positive case を必ず付ける、profile=minimal で全機能 disable 可
- リスク2: shellcheck が既存 baseline の warning を拾って CI 全体が fail → mitigation: structural-gate 内で `--severity=error` から開始、warning は別 step で WARN 表示のみ
- リスク3: hook 拡張で install.sh size が NFR-02 (Phase 1) を超過 → mitigation: 規模を測定、超過時は Phase 2B で sandbox template と一緒に install.sh splitting を前倒し検討
- リスク4: Codex specificity 明記により SAGE adoption が下がる懸念 → mitigation: governance §9.4 補完関係図と整合させ、「Codex でも価値はある (rules / templates / governance)」を併記

## 実装メモ（Implementation Agent向け）

- hook test harness は **pure bash + diff** で実装 (BATS 等の external dep 不要、Phase 1 の "self-contained" 思想に沿う)
- test harness 構造: 各 `test-*.sh` が `setup` / `run` / `assert` 関数を export、`run-tests.sh` が glob で実行
- `block-dangerous-commands.sh` の chain 長判定は `tr -cd ';|&' | wc -c` で count、`grep` regex は使わない (既存 pattern と分離)
- `protect-sage-files.sh` の content 検査は新規セクションとして追加、既存 path 検査ロジックの後ろに置いて regression を最小化
- shellcheck の baseline 化は GitHub Actions `set-output` 経由 + Annotation で実装
- install.sh 再生成は Phase 1 同様 generator 経由

### AC ↔ Property 対応表 (SPEC-0024 retrofit、governance §11.6)

本 SPEC retrofit (TASK-0167) で追加した Properties は、既存 AC の declarative version。矛盾発生時は SPEC を更新する (Property を改変して隠蔽しない、governance §11.4)。

## Properties

権限レベル `platform` + Security 要件あり (R8 hook tests / R9 shellcheck doctrine) のため 5 件以上必須 (SPEC-0024 §11.1)。

### Invariants
- [INV-01] (Gate 3) 全 hook script は shellcheck error 0 件で merge される (R9 doctrine、AC-shellcheck と対応)
- [INV-02] (Gate 3) Hook テストは `templates/hooks/tests/run-tests.sh` の glob 自動発見で統合され、CI で常時実行される (R8 doctrine、AC-test と対応)
- [INV-03] (Gate 4) Hook の profile gating (`.sage/config.yaml` `hooks.profile`) で `none` / `minimal` / `standard` / `strict` の動作が差別化される (escalation 一方向、降格は別 PR)
- [INV-04] (Gate 3) `block-dangerous-commands.sh` の chain 長判定は `tr -cd ';|&' | wc -c` で count、grep regex に依存しない (既存 pattern と分離、誤検知抑制)

### Pre-conditions
- [PRE-01] (Gate 2) Hook 実行環境に bash 4+ が存在する (NFR-03 portability、macOS / Linux 両対応)

### Post-conditions
- [POST-01] (Gate 2) Hook 実行後、kill 系コマンド (`kill` / `pkill` / `killall`) を 1 回も呼ばない (detection-only doctrine、SPEC-0015 SEC-01 と整合)

### Assumptions
- [ASM-01] (Gate 横断) macOS / Linux 両対応の bash + 標準 unix tools が利用可能 (NFR-03)

## 関連ID

- PLAN-ID: PLAN-0011 (本 SPEC と同時作成)
- TASK-ID: TASK-0101 (test harness), TASK-0102 (shellcheck CI), TASK-0103 (block-dangerous expansion), TASK-0104 (protect-sage expansion + content check), TASK-0105 (doctrine clarify)
