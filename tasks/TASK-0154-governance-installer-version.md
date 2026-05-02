# TASK-0154: governance.md §10 + installer generator + install.sh 再生成 + v1.6.0→1.7.0

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0154 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0152, TASK-0153 完了後) |
| 依存TASK  | TASK-0152, TASK-0153 |
| 見積     | 75m |

## 責務

SPEC-0023 の formalization と installer 伝播を完成させる:

1. `sage/governance.md` §10「AI Agent Doc Pairing Doctrine」を新設し、shared rules / CLI-specific rules / paired-update 要件を規範化
2. `scripts/generator/03-rules.sh` に `TMPL_CLAUDE_COLLABORATION_BRIEF` embed を追加 (SPEC-0022 `TMPL_CODEX_DELEGATION_PACKET` の隣接行で対称配置)
3. `scripts/generator/07-installer-main.sh` に write_file_if_new / update_file / managed_files 3 箇所追加
4. `bash scripts/generate-installer.sh > install.sh` で再生成 (byte-identical 保証)
5. `.sage-version` を 1.6.0 → 1.7.0 に bump (minor、新機能追加)
6. `SHA256SUMS` を再生成 install.sh と sync

## 入力

- SPEC-0023 §「機能要件」FR-05 (governance §10), FR-06 (installer 伝播)
- TASK-0152 の `docs/claude-collaboration-brief.md`
- 既存 `scripts/generator/03-rules.sh` の `TMPL_CODEX_DELEGATION_PACKET` 配置 (SPEC-0022)
- 既存 `scripts/generator/07-installer-main.sh` の write/update/managed_files 該当箇所
- 既存 `.sage-version` (1.6.0)
- 既存 `SHA256SUMS` (install.sh の旧 SHA256)

## 出力

### sage/governance.md §10 新設 (≤30 行)

「## 10. AI Agent Doc Pairing Doctrine」として以下を含む:
- 趣旨説明 (なぜ paired-update が必要か、SPEC-0022/0023 を最初の事例として参照)
- Shared rules 一覧 (lifecycle / lanes / traceability / quality gates 等、両 doc で identical 維持必須)
- CLI-specific rules 一覧 (Codex Delegation Packet / Claude Collaboration Brief / hook implementation 等、divergence 可)
- Paired-update 手続 (SPEC を片側に追加する際は paired SPEC-ID を明示、別 SPEC として起票するか同 PR で並行更新)
- Drift 検知 (test-claude-collaboration-pairing.sh が CI で常時検証)
- 例外 (CLI 一方にしか存在しない機能は対側 SPEC で「該当なし」と明示すれば paired 完了とみなす)

### scripts/generator/03-rules.sh 拡張

`TMPL_CODEX_DELEGATION_PACKET` (SPEC-0022 で追加) の直下に新行を追加:

```bash
# SPEC-0023: Claude collaboration brief (paired with SPEC-0022 Codex delegation packet)
embed_file "TMPL_CLAUDE_COLLABORATION_BRIEF" "$ROOT/docs/claude-collaboration-brief.md"
echo ""
```

### scripts/generator/07-installer-main.sh 拡張 (3 箇所)

1. install mode: `write_file_if_new "docs/claude-delegation-brief.md"` 行の直下 (= `write_file_if_new "docs/codex-delegation-packet.md"` の隣):
   ```
   write_file_if_new "docs/claude-collaboration-brief.md" "$TMPL_CLAUDE_COLLABORATION_BRIEF"
   ```
2. update mode: `update_file "docs/codex-delegation-packet.md"` の隣:
   ```
   update_file "docs/claude-collaboration-brief.md" "$TMPL_CLAUDE_COLLABORATION_BRIEF"
   ```
3. managed_files 配列: `"docs/codex-delegation-packet.md"` の隣:
   ```
   "docs/claude-collaboration-brief.md"
   ```

### install.sh 再生成

`bash scripts/generate-installer.sh > install.sh` で再生成。新しい SHA256 を SHA256SUMS に反映。

### .sage-version

`1.6.0` → `1.7.0` (minor bump)

### SHA256SUMS

新 install.sh の SHA256 で更新。format `<sha256>  install.sh`。

## File Scope（変更許可範囲）

- 変更: `sage/governance.md` (§10 追加)
- 変更: `scripts/generator/03-rules.sh` (embed 追加)
- 変更: `scripts/generator/07-installer-main.sh` (write/update/managed_files 3 箇所)
- 変更: `install.sh` (再生成)
- 変更: `.sage-version` (1.6.0 → 1.7.0)
- 変更: `SHA256SUMS` (新 SHA256)

## 禁止事項

- governance.md §1-9.x の section header / 内容を編集しない (§10 新設のみ)
- installer の Codex side embed (TMPL_CODEX_DELEGATION_PACKET) を編集しない (SPEC-0022 territory)
- install.sh を手編集しない (generator 経由で再生成のみ)
- shellcheck error を残さない (R9、03-rules.sh / 07-installer-main.sh)
- byte-identical 検証を skip しない (SPEC-0014 doctrine、`bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` で 0 行確認)
- SHA256SUMS を手書きしない (sha256sum / shasum -a 256 で算出)
- .sage-version を 1.6.x patch でなく 1.7.0 minor で bump (新機能追加のため、semver 遵守)
- sage/governance.md §10 が ≤30 行を超過しない (簡潔性維持)

## 完了条件

- [ ] `sage/governance.md` §10「AI Agent Doc Pairing Doctrine」存在、`grep -F "## 10. AI Agent Doc Pairing Doctrine" sage/governance.md` PASS
- [ ] §10 が「Shared rules」「CLI-specific rules」「Paired-update」「Drift 検知」セクションを含む、`grep -F "Paired-update" sage/governance.md` PASS
- [ ] `scripts/generator/03-rules.sh` に `TMPL_CLAUDE_COLLABORATION_BRIEF` embed 追加
- [ ] `scripts/generator/07-installer-main.sh` の write_file_if_new / update_file / managed_files 3 箇所に `docs/claude-collaboration-brief.md` 含む
- [ ] `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` 0 行 (byte-identical)
- [ ] `install.sh` に `TMPL_CLAUDE_COLLABORATION_BRIEF` および `docs/claude-collaboration-brief.md` 書き込みパスを含む (`grep -c "TMPL_CLAUDE_COLLABORATION_BRIEF\|claude-collaboration-brief.md" install.sh` で 5+)
- [ ] `.sage-version` が `1.7.0`
- [ ] `SHA256SUMS` が `shasum -a 256 install.sh` の出力と一致 (`shasum -a 256 -c SHA256SUMS` PASS)
- [ ] shellcheck error 0 件 (`shellcheck -x scripts/generator/03-rules.sh scripts/generator/07-installer-main.sh`)
- [ ] commit message に `TASK-0154:` 含む
