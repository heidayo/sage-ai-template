# TASK-0100: Codex Review Follow-up — Phase 1 (PR #11) Fixes

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0100 |
| SPEC-ID   | SPEC-0010 |
| PLAN-ID   | PLAN-0010 |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (must precede merge) |
| 依存TASK  | TASK-0094..0099 |
| 見積     | 60m |

## 責務

Codex (cross-model adversarial review) が PR #11 に対して指摘した P1×2 / P2×2 / P3×2 = 6 件の問題を解消し、Phase 1 を merge 可能な品質に戻す。

## 入力 (Codex 指摘 6 件)

1. **[P1]** `.gitignore` に `.sage/runs/` が追加されたが、`.sage/runs/RUN-0001..0004.yaml` は tracked のため `bash scripts/sage-validate.sh` が exit 1。AC-10 PASS 表示と矛盾。
2. **[P1]** `README.md` 行 152 付近で導入手順の先頭が `curl | bash` のまま。Phase 1 で追加した `--print-provenance` / `--dry-run` の存在意義が反映されていない。
3. **[P2]** `install.sh --verify-checksum` が state file 欠落時に `return 0` (成功扱い)。integrity verification として人間/CI が誤認するリスク。
4. **[P2]** `SECURITY.md` 行 66 で `installer_url` (auto-update) 取得先の書き換えを `[covered]` と表示。実装は local install-state checksum までで、remote installer_url の pinning/signing/trust flow は未実装 → `[partial]` または out-of-scope に修正。
5. **[P3]** checksum manifest の `path` を `$sha_cmd "$current_path"` に渡す際、`--` separator がない。option-like path や malformed state file での誤動作リスク。
6. **[P3]** `§13 Scope Boundary` の参照が `SECURITY.md` (2件) / `ATTRIBUTION.md` / `tasks/TASK-0098-*.md` に残っている。実際の chapter は §9。trust boundary 文書なので参照ずれは混乱を招く。

## 出力

- `.gitignore`: `.sage/runs/` 削除 (tracked と整合させる)
- `README.md`: 導入手順を「download → provenance → dry-run → review → execute」順に再構成。`curl | bash` を非推奨マーク + 推奨手順を上に配置
- `scripts/generate-installer.sh` + `install.sh`: `do_verify_checksum` で state 欠落時 `return 1` (失敗扱い)、`$sha_cmd -- "$path"` に変更
- `SECURITY.md`: 行 66 の installer_url claim を `[partial]` に変更 + 行 76, 84 の §13 → §9
- `ATTRIBUTION.md`: 行 113 §13 → §9
- `tasks/TASK-0098-*.md`: 行 36 §13 → §9
- `.sage/install-state.yaml`: `bash install.sh --update` で再生成 (managed file 内容変更を反映)

## File Scope（変更許可範囲）

- 変更: `.gitignore`, `README.md`, `SECURITY.md`, `ATTRIBUTION.md`, `tasks/TASK-0098-claude-agents-template-trust-callout.md`, `scripts/generate-installer.sh`, `install.sh`
- 自動再生成: `.sage/install-state.yaml` (gitignored)
- 削除: なし

## 禁止事項

- 既存 install.sh の `--update` / `--version` / `--print-provenance` / `--dry-run` の挙動変更禁止 (`--verify-checksum` の rc=1 化のみ)
- `curl | bash` 自体の削除は不要 (代替手段の提示順序を変えるのみ)
- README の他のセクション (Lane 説明、よく使うコマンド等) は変更しない
- 新規 LICENSE / SECURITY.md / CONTRIBUTING.md 内容の追記は行わない (typo 修正レベルのみ)
- 新規 hook の追加禁止 (Phase 2 範囲)

## 完了条件

- [ ] `bash scripts/sage-validate.sh` exit 0 (P1 #1 解消)
- [ ] `README.md` で `--print-provenance` / `--dry-run` 推奨手順が `curl | bash` より上に出る (P1 #2)
- [ ] `cd /tmp && bash $REPO/install.sh --verify-checksum; [ $? -eq 1 ]` (P2 #3, state 欠落時 rc=1)
- [ ] `grep "installer_url" SECURITY.md | grep -q "partial"` (P2 #4)
- [ ] `grep -- "-- " scripts/generate-installer.sh | grep -q "sha_cmd"` (P3 #5, sha_cmd に -- が付く)
- [ ] `! grep -rn "§13" specs/ tasks/ sage/ SECURITY.md ATTRIBUTION.md README.md CLAUDE.md AGENTS.md` (P3 #6)
- [ ] `bash scripts/sage-doctor.sh` ALL OK
- [ ] commit message に `TASK-0100:` を含む
