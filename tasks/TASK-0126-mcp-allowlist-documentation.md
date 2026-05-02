# TASK-0126: SPEC-0015 documentation 更新 + installer regeneration

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0126 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (最後にまとめて、TASK-0122..0124 完了後)|
| 依存TASK  | TASK-0122, 0123, 0124 (実装確定後に doc 書く) |
| 見積     | 45m |

## 責務

SPEC-0015 で導入された MCP allowlist audit (supply-chain pinned) に関する cross-reference を 5 ファイルに追加する (R7 doctrine 厳守: 各最大 +3 行)。`install.sh` を再生成して新 hook / template の embed を反映する。doctrine の boundary 表現を governance §9.1 / §9.2 で正確に分離する。**SPEC-0017 (agent identity inventory) を予約として「Phase 5 全体の position」表に明示**。

## 入力

- SPEC-0015 FR-06 (documentation 更新詳細)
- SPEC-0015 AC-06 (5 ファイル更新、各最大 +3 行)
- TASK-0122..0124 で確定した実装 (doc 内容を実装と整合させる)
- 既存 `sage/governance.md` §9.1 (SAGE 提供物) / §9.2 (SAGE 範囲外)
- `scripts/generate-installer.sh` (install.sh 生成器)
- Phase 3 の TASK-0117/0119 で経験した「install.sh 再生成忘れで template が古い版で配布される」問題

## 出力

1. `SECURITY.md` 更新:
   - §3 Threat Model に「MCP allowlist supply-chain drift」項目追加 (1-2 行)
   - §4 SAGE Coverage に「mcp-allowlist-audit (Phase 5, supply-chain pinned audit-only)」追加 (1 行)

2. `sage/governance.md` 更新:
   - §9.1 hook テンプレート行に `mcp-allowlist-audit (Phase 5, SessionStart audit-only with supply-chain pin)` 追加
   - §9.2 「MCP server の実行時許可制御」行を **「runtime での起動 block は Claude/Codex 本体。audit / drift / supply-chain pin (sha256 / version_pin / publisher) 検出は SPEC-0015 で提供」** に書き換え (拡張のみ、削除しない)

3. `AGENTS.md` 更新:
   - §9 章末に 1 行追加: `MCP allowlist audit (supply-chain pinned, audit-only): SAGE が提供、詳細は [SPEC-0015](specs/SPEC-0015-mcp-allowlist-audit-and-agent-identity.md) と [docs/codex-security.md](docs/codex-security.md) §2 末尾`

4. `CLAUDE.md` 更新:
   - 同様に §9 章末に 1 行追加 (AGENTS.md と semantic alignment)

5. `docs/codex-security.md` 更新:
   - §2 末尾に 1 行追加: `SAGE side audit (supply-chain pinned): SAGE は \`templates/sage/mcp-allowlist-template.json\` で declarative registry を提供、SessionStart hook で drift + version pin + sha256 検出 (詳細は [SPEC-0015](../specs/SPEC-0015-mcp-allowlist-audit-and-agent-identity.md))`

6. `install.sh` 再生成:
   - `bash scripts/generate-installer.sh > install.sh` を実行
   - 新 templates (`templates/sage/mcp-allowlist-template.json`) と新 hook (`templates/hooks/mcp-allowlist-audit.sh`) と performance helper (`templates/hooks/tests/measure-hook-time.sh`) と detection-only behavior test (`templates/hooks/tests/test-detection-only-behavior.sh`) と doctor 共通 script (`scripts/sage-mcp-allowlist-audit.sh`) が embed されているか確認
   - `.claude/settings.json` template の `hooks.SessionStart` に `mcp-allowlist-audit.sh` が standard profile で追加されているか確認

7. (もし `scripts/generate-installer.sh` が新 ファイルの embed をサポートしていない場合) generator 拡張:
   - 新 templates を embed する section を追加
   - `bash scripts/generate-installer.sh` 実行で install.sh が新 ファイルを含むことを確認

## File Scope（変更許可範囲）

- 変更: `SECURITY.md`
- 変更: `sage/governance.md`
- 変更: `AGENTS.md`
- 変更: `CLAUDE.md`
- 変更: `docs/codex-security.md`
- 変更: `install.sh` (再生成のみ、手動編集禁止)
- 変更: (必要なら) `scripts/generate-installer.sh` で新 template / hook / script の embed 設定追加

## 禁止事項

- 5 文書ファイルへの追加が **各 +3 行以内** を超えない (R7 厳守)
- AGENTS.md / CLAUDE.md の本文 (§9 以外) を触らない
- governance §9.2 の「MCP server の実行時許可制御」行を完全削除しない (拡張のみ、SAGE doctrine の boundary 維持)
- install.sh を手動編集しない (必ず generate-installer.sh で再生成)
- doc cross-reference は **本 SPEC へのリンク** に集約、説明本文を 5 文書に複製しない
- SPEC-0017 (agent identity inventory) の内容を本 TASK で具体化しない (予約 reference のみ)

## 完了条件

- [ ] SECURITY.md / sage/governance.md / AGENTS.md / CLAUDE.md / docs/codex-security.md の 5 ファイルに SPEC-0015 reference / hook 名追加
- [ ] 各ファイルへの追加が +3 行以内 (R7 doctrine)
- [ ] `install.sh` 再生成済 (`bash scripts/generate-installer.sh > install.sh` で生成、手動編集なし)
- [ ] `bash scripts/sage-doc-drift.sh` PASS (CLAUDE/AGENTS 整合)
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL (TASK-0124 で追加された step 含む)
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (TASK-0123 + behavior test 含む合計 ≥ 122)
- [ ] commit message に `TASK-0126:` を含む
