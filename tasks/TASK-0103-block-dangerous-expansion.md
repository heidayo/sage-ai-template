# TASK-0103: block-dangerous-commands.sh expansion

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0103 |
| SPEC-ID   | SPEC-0011 |
| PLAN-ID   | PLAN-0011 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0101 test harness が前提) |
| 依存TASK  | TASK-0101 |
| 見積     | 75m |

## 責務

`templates/hooks/block-dangerous-commands.sh` に、Adversa AI / CVE-2026-25723 / BeyondTrust 報告で示された攻撃ベクターに対応する 4 系統の追加 pattern を実装。同時に test ファイルにケースを追加。

## 入力

- SPEC-0011 FR-04
- 既存 `templates/hooks/block-dangerous-commands.sh` (150 行、TASK-0036 / TASK-0086 / TASK-0089 で拡張済)
- 参考: [Adversa AI deny rule bypass](https://adversa.ai/blog/claude-code-security-bypass-deny-rules-disabled/) (50+ subcommand chain で deny rule skip)
- 参考: [CVE-2026-25723 piped sed bypass](https://nvd.nist.gov/vuln/detail/CVE-2026-25723)
- 参考: [BeyondTrust Codex branch name injection](https://www.beyondtrust.com/blog/entry/openai-codex-command-injection-vulnerability-github-token) (Unicode obfuscation)
- TASK-0101 で構築した test harness

## 出力

`templates/hooks/block-dangerous-commands.sh` に以下を末尾追加 (既存 pattern の後):

1. **Chain length limit**: `;` / `&&` / `||` / `|` が合計 30 個以上含まれる command は block。fail-closed: 解析不能な複雑性は危険として扱う (Codex review R3 fail-closed 原則)
2. **Redirection write to AI control plane**: `> .claude/`, `>> .claude/`, `> .git/`, `>> .git/`, `> .github/workflows/`, `> .sage/config.yaml`, `> .mcp.json`, `> .codex/config.toml`, および `tee .claude/`, `tee .mcp.json`, `tee .codex/config.toml` を block (CVE-2026-25723 同質)
3. **Interpreter -c file write**: `python -c "...open('foo','w')..."`, `python -c "...open(\"foo\",\"w\")..."`, `node -e "...writeFile..."`, `node -e "...createWriteStream..."`, `ruby -e "...File.open(...,'w')..."`, `perl -e "...open(...,'>>',...)..."` を block (subprocess file write 経由の bypass 防止)
4. **Unicode obfuscation警告 (warn-only)**: command または argument に U+3000 (Ideographic Space) / U+200B-200F (zero-width / bidi) が含まれる場合、stderr に `WARN: suspicious unicode whitespace/zero-width detected — possible obfuscation` を出力。block はしない (誤検知回避、実 attack は test/CI で検出すべき)

`templates/hooks/tests/test-block-dangerous-commands.sh` に各 pattern の positive (block 期待) + negative (allow 期待) ケース追加。

`scripts/generate-installer.sh` 内の `embed_file "TMPL_HOOK_BLOCK_DANGEROUS"` 経由で hook 変更が install.sh に反映されるため、install.sh を再生成。

## File Scope（変更許可範囲）

- 変更: `templates/hooks/block-dangerous-commands.sh` (末尾追加のみ)
- 変更: `templates/hooks/tests/test-block-dangerous-commands.sh` (test ケース追加)
- 変更: `install.sh` (generate-installer.sh からの再生成)
- 削除: なし

## 禁止事項

- 既存 pattern (--no-verify, git push --force, rm -rf /|~|., curl|bash 等) の変更/削除禁止
- profile gating ロジックの変更禁止 (minimal/none では skip 維持)
- jq fallback path の変更禁止
- false positive を生むほど厳しいパターン追加禁止 (Unicode は warn-only に留める)
- chain length 30 を変更する場合は SPEC 修正 + Codex 再レビュー必要

## 完了条件

- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (regression なし + 新 pattern PASS)
- [ ] 30 個以上の `;` を含むダミー JSON を hook stdin に渡すと exit 2
- [ ] `echo malicious > .claude/settings.json` を含む JSON を渡すと exit 2
- [ ] `python -c "open('foo','w').write('x')"` を含む JSON を渡すと exit 2
- [ ] U+3000 を含む command を渡すと stderr に WARN 出力 + exit 0 (block しない)
- [ ] 既存の `git push --force` block が依然 exit 2
- [ ] `bash install.sh --dry-run` exit 0
- [ ] commit message に `TASK-0103:` を含む
