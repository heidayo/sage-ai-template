# TASK-0137: SPEC-0014 doc cross-refs + 既存 install.sh 不変確認

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0137 |
| SPEC-ID   | SPEC-0014 |
| PLAN-ID   | PLAN-0014 |
| ステータス | Pending |
| 並列可否  | No (last) |
| 依存TASK  | TASK-0135..0136 |
| 見積     | 30m |

## 責務

5 doc cross-refs (R7 厳守、各 +3 行以内) + 最終 install.sh 再生成 + byte-identical 確認 + v1.4.0 → v1.5.0。

## 出力

1. doc cross-refs:
   - `sage/governance.md` §9.1: installer の generator modular 化 (SPEC-0014) 言及
   - `CLAUDE.md` §9.1: Phase 5+ 完了 + installer modular note
   - `AGENTS.md` §9.1: 同上
   - `SECURITY.md` §3: maintainability 改善で security regression 0 (Phase 5+ 完了 mention)
   - `docs/codex-security.md`: Codex 利用者向け mention 不要 (内部 refactor のため)、もし必要なら 1 行のみ

2. 最終 install.sh 再生成:
   - `bash scripts/generate-installer.sh > install.sh`
   - `bash install.sh --update` で install-state.yaml refresh
   - byte-identical 確認 (refactor 前と完全一致)

3. `.sage-version` 1.4.0 → 1.5.0

## File Scope

- 変更: 4-5 doc files + `install.sh` + `.sage-version`

## 禁止事項

- 5 doc files 各 +3 行以内 (R7 厳守)
- AGENTS.md / CLAUDE.md の本文 (§9 以外) を触らない
- governance §9.2 の既存内容を削除しない
- install.sh を手動編集しない
- doc cross-reference は **本 SPEC へのリンク** に集約
- SPEC-0015/0016/0017 の内容を本 TASK で具体化しない (merged 済 SPEC への reference のみ可)
- `docs/codex-security.md` は internal refactor のため必要最小限の mention のみ (skip 可)

## 完了条件

- [ ] 5 doc files 各 +3 行以内 (R7)
- [ ] install.sh 再生成済 (byte-identical 確認)
- [ ] `.sage-version` = 1.5.0
- [ ] doctor 0 FAIL
- [ ] doc-drift PASS
- [ ] commit message に `TASK-0137:` 含む
