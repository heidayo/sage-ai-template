# TASK-0134: SPEC-0016 doc cross-refs + installer regen + v1.4.0

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0134 |
| SPEC-ID   | SPEC-0016 |
| PLAN-ID   | PLAN-0016 |
| ステータス | Pending |
| 並列可否  | No (last) |
| 依存TASK  | TASK-0131..0133 |
| 見積     | 30m |

## 責務

5 doc cross-refs (R7 厳守、各 +3 行以内) + `generate-installer.sh` 拡張で indexer / search / db-audit script を embed + `install.sh` 再生成 + v1.3.0 → v1.4.0 + `.gitignore` に `.sage/runs.db` 追加。

## 出力

1. doc cross-refs:
   - `sage/governance.md` §9.1: doctor step に RUN log DB check (Phase 5+, SPEC-0016) 追記
   - `CLAUDE.md` §9.1: hook table に runlog-index (auto-incremental, minimal+) 追記
   - `AGENTS.md` §9.1: 同上
   - `SECURITY.md` §3: incident response の検索基盤として SPEC-0016 言及
   - `docs/codex-security.md` §7: search で `agent_id=codex-cli + drift_type=*` 抽出可能と言及

2. `scripts/generate-installer.sh`:
   - embed_file 4 new vars (TMPL_SCRIPT_RUNLOG_INDEX / SEARCH / DB_AUDIT / TEST_RUNLOG_*)
   - write_file_if_new + update_file calls

3. `install.sh` 再生成 + `.sage-version` 1.3.0 → 1.4.0 + `bash install.sh --update`

4. `.gitignore` に `.sage/runs.db` 追加 (OPS-03)

## File Scope

- 変更: 5 doc files + `scripts/generate-installer.sh` + `install.sh` + `.sage-version` + `.gitignore`

## 禁止事項

- 5 doc files 各 +3 行以内 (R7 厳守)
- AGENTS.md / CLAUDE.md の本文 (§9 以外) を触らない
- governance §9.2 の既存内容を削除しない
- install.sh を手動編集しない (必ず `bash scripts/generate-installer.sh > install.sh` で再生成)
- doc cross-reference は **本 SPEC へのリンク** に集約、説明本文を 5 文書に複製しない
- SPEC-0014 / SPEC-0017 の内容を本 TASK で具体化しない (予約 reference のみ)
- `.gitignore` で `.sage/` 全体を除外しない (config.yaml / agent-inventory.yaml は track 必須、`.sage/runs.db` のみ追加)

## 完了条件

- [ ] 5 doc files 各 +3 行以内 (R7)
- [ ] install.sh 再生成済 (4 new files embedded)
- [ ] `.sage-version` = 1.4.0
- [ ] `.gitignore` に `.sage/runs.db` あり
- [ ] doctor 0 FAIL
- [ ] doc-drift PASS
- [ ] commit message に `TASK-0134:` 含む
