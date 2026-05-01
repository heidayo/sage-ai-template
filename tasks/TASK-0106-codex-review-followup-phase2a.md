# TASK-0106: Codex Review Follow-up — Phase 2A (PR #12) Fixes

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0106 |
| SPEC-ID   | SPEC-0011 |
| PLAN-ID   | PLAN-0011 |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (must precede merge) |
| 依存TASK  | TASK-0101..0105 |
| 見積     | 60m |

## 責務

Codex (cross-model adversarial review) が PR #12 に対して指摘した P1×2 / P2×2 / P3×1 = 5 件の問題を解消し、Phase 2A を merge 可能な品質に戻す。

## 入力 (Codex 指摘 5 件)

1. **[P1]** GitHub Checks: structural と release が fail。ローカルでも `bash scripts/sage-doc-drift.sh` が AGENTS.md の §2.1 Codex specificity を CLAUDE.md にも探して fail。
2. **[P1]** `block-dangerous-commands.sh` の redirection block が common shell syntax を取り逃がす:
   - 通る: `echo x > ./.claude/settings.json` (`./` 付き)
   - 通る: `echo x>.claude/settings.json` (空白なし)
   - 通る: `echo x >./.mcp.json`
3. **[P2]** AGENTS.md §2.1 の Codex CLI config キー名が不正確:
   - `internet_access = false` は CLI config reference に存在しない
   - 正: `sandbox_mode = "workspace-write"` + `[sandbox_workspace_write]` 配下 `network_access = false`
   - Codex Cloud の "agent internet access" は別物 (環境単位、既定 off)
4. **[P2]** `block-dangerous-commands.sh` の interpreter -c file write 検出が single-quote mode を取り逃がす:
   - `[\x27"]` は grep -E では `\x27` を `'` と解釈しない (BRE/ERE では escape 不適用)
   - 通る: `python -c "open('foo','w').write('x')"`, `ruby -e "File.open('foo','w')..."`, `perl -e "open(..., '>foo')"`
5. **[P3]** `.github/workflows/sage-structural-gate.yml` の shellcheck action pin SHA `00b27aa7...` は `master` HEAD であり、`v2.0.0` tag は `00cae500...`。コメント `# v2.0.0` と SHA が一致しない (trust foundation 文脈で provenance 表示の正確性)。

## 出力

- `CLAUDE.md`: §2.1 として **Claude Code specificity** parallel section を追加 (Codex 側との対称性確保 + doc-drift PASS)
- `AGENTS.md` §2.1: Codex CLI / Cloud の設定キーを公式 reference 準拠に修正:
  - CLI: `sandbox_mode = "workspace-write"` + `[sandbox_workspace_write]` `network_access = false`
  - Cloud: 別段落で「agent internet access は環境単位で管理、既定 off」と明記
  - 参考リンク追加: `https://developers.openai.com/codex/config-reference`, `https://developers.openai.com/codex/cloud/internet-access`
- `templates/hooks/block-dangerous-commands.sh`:
  - **Redirection regex 修正**: `[[:space:]]*` で空白省略可、`\.?/?` で `./` 任意先頭、leading dot ファイル (`.claude/`, `.mcp.json`, etc.) 全 variant をカバー
  - **Interpreter -c regex 修正**: literal apostrophe `'` を含む character class (BRE/ERE で正しく動く形式)。複数 grep に分けて single quote / double quote 両ケース block
- `templates/hooks/tests/test-block-dangerous-commands.sh`: 上記 4 抜けケースに対応する block test 追加 (positive/negative 両方)
- `.github/workflows/sage-structural-gate.yml`: shellcheck action SHA を `00cae500...` (v2.0.0 tag commit) に変更 + コメント整合
- `scripts/generate-installer.sh` + `install.sh`: hook 修正を反映 (regen)

## File Scope（変更許可範囲）

- 変更: `CLAUDE.md`, `AGENTS.md`, `templates/hooks/block-dangerous-commands.sh`, `templates/hooks/tests/test-block-dangerous-commands.sh`, `.github/workflows/sage-structural-gate.yml`, `scripts/generate-installer.sh`, `install.sh`
- 自動再生成: `.sage/install-state.yaml` (gitignored)
- 削除: なし

## 禁止事項

- 既存 hook の他 pattern 削除/挙動変更禁止 (新規 false negative の修正のみ)
- doc-drift script の挙動変更禁止 (CLAUDE.md 側に対応 section を入れることで解消、normalization 改変は scope 外)
- AGENTS.md §2.1 の context 増分 ≤ 5 行 / 200 字 (Codex review R7 budget 厳守)
- shellcheck action を v2.0.0 から別バージョンに変更しない (タグ commit に固定するだけ)

## 完了条件

- [ ] `bash scripts/sage-doc-drift.sh` exit 0
- [ ] `bash scripts/sage-validate.sh` exit 0
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash templates/hooks/tests/run-tests.sh` PASS (regression なし + 新 test 追加分も PASS)
- [ ] `echo x > ./.claude/settings.json` を含む command が hook で block (rc=2)
- [ ] `echo x>.claude/settings.json` (no space) が block
- [ ] `python -c "open('foo','w').write('x')"` (single quote) が block
- [ ] `ruby -e "File.open('foo','w')..."` (single quote) が block
- [ ] AGENTS.md §2.1 に `sandbox_workspace_write` と `network_access` が記載
- [ ] CLAUDE.md に `2.1 Claude Code specificity` (または equiv. doc-drift通過する section name) が存在
- [ ] `.github/workflows/sage-structural-gate.yml` shellcheck SHA が `00cae500...` または `master` snapshot コメントに整合
- [ ] commit message に `TASK-0106:` を含む
