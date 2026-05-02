# TASK-0130: SPEC-0017 doc cross-refs + installer regen

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0130 |
| SPEC-ID   | SPEC-0017 |
| PLAN-ID   | PLAN-0017 |
| ステータス | Pending |
| 並列可否  | No (last) |
| 依存TASK  | TASK-0127..0129 |
| 見積     | 30m |

## 責務

5 doc cross-refs (R7 厳守、各 +3 行以内) + `generate-installer.sh` 拡張で新 templates / scripts を embed + `install.sh` 再生成 + v1.2.1 → 1.3.0。

## 出力

1. doc cross-refs (各 +3 行以内):
   - `sage/governance.md` §9.1: agent inventory に言及
   - `CLAUDE.md` §9.1: hook table に agent-inventory-audit (Phase 5+, validator-only) 追加
   - `AGENTS.md` §9.1: 同上 (semantic alignment)
   - `SECURITY.md` §3: declared vs observed runtime drift 追加
   - `docs/codex-security.md`: agent identity inventory mention

2. `scripts/generate-installer.sh`:
   - embed_file 3 new vars (TMPL_AGENT_INVENTORY / TMPL_TEST_AGENT_INVENTORY / TMPL_SCRIPT_AGENT_INVENTORY)
   - write_file_if_new + update_file calls

3. `install.sh` 再生成 + `.sage-version` 1.2.1 → 1.3.0 + `bash install.sh --update`

## File Scope

- 変更: 5 doc files + `scripts/generate-installer.sh` + `install.sh` + `.sage-version`

## 禁止事項

- 5 doc files の追加が **各 +3 行以内** を超えない (R7 厳守)
- AGENTS.md / CLAUDE.md の本文 (§9 以外) を触らない
- governance §9.2 の「MCP server の実行時許可制御」行を削除しない (SPEC-0015 で確定済 doctrine)
- install.sh を手動編集しない (必ず `bash scripts/generate-installer.sh > install.sh` で再生成)
- doc cross-reference は **本 SPEC へのリンク** に集約、説明本文を 5 文書に複製しない
- SPEC-0014 / SPEC-0016 の内容を本 TASK で具体化しない (予約 reference のみ可)

## 完了条件

- [ ] 5 doc files 各 +3 行以内 (R7)
- [ ] install.sh 再生成済 (3 new files embedded)
- [ ] doctor 0 FAIL
- [ ] doc-drift PASS
- [ ] commit message に `TASK-0130:` 含む
