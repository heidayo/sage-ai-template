# TASK-0097: install.sh に --dry-run / --verify-checksum / --print-provenance オプション追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0097 |
| SPEC-ID   | SPEC-0010 |
| PLAN-ID   | PLAN-0010 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes (大きいので最後にやる) |
| 依存TASK  | none |
| 見積     | 90m |

## 責務

install.sh に副作用なし (--dry-run)、整合性検証 (--verify-checksum)、由来情報 (--print-provenance) の 3 オプションを追加。既存の `bash install.sh` (フラグなし) 挙動は完全保持。

## 入力

- SPEC-0010 FR-06, FR-07, FR-08, NFR-01, NFR-02, SEC-02
- Codex review R5 (RUN log FTS は redaction 先行の順序)
- 既存 install.sh (5779行, SAGE_VERSION=1.1.0, generate_install_state 関数あり)
- 既存 `.sage/install-state.yaml` フォーマット (sha256 + path + source + managed)

## 出力

1. install.sh の冒頭オプション parser に `--dry-run`, `--verify-checksum`, `--print-provenance` を追加
2. 各オプションの実装関数を install.sh 末尾に追加:
   - `do_dry_run()`: 全 mkdir/touch/cp/redirection を `[ "$DRY_RUN" = "true" ] && echo "Would: $*" && return 0` でラップ。stdout に「Would create:」「Would modify:」等を出力
   - `do_verify_checksum()`: `.sage/install-state.yaml` を読み、各 path の sha256 を再計算して比較。drift があれば exit 1
   - `do_print_provenance()`: SAGE_VERSION, installer 自身の SHA256, GitHub Releases URL, Apache-2.0 表記、生成日時を出力
3. `bash install.sh --help` (既存ヘルプ) に新オプション説明を追加 (もし既存ヘルプがなければ簡易ヘルプを追加)

## File Scope（変更許可範囲）

- 変更: `install.sh` (オプション parser + 3 関数追加。既存ロジックの破壊的変更は禁止)
- 変更: `scripts/generate-installer.sh` (install.sh が generated artifact のため、対応する generator 修正)
- 削除: なし

## 禁止事項

- 既存 install/update/version モードの挙動変更禁止
- `.git/hooks/`, `.github/workflows/`, `~/.ssh`, `~/.aws`, `.env*` の読み書き禁止 (SEC-02)
- 外部 URL 取得を伴う provenance 出力禁止 (SEC-03 — installer 自身が起点)
- install.sh 全体構造の refactor 禁止 (Phase 1 範囲外)
- 新オプションが既存フラグ (--update, --version 等) と衝突しないこと

## 完了条件

- [ ] `bash install.sh --dry-run > /tmp/dryrun.log 2>&1; [ $? -eq 0 ]` (dry-run 成功)
- [ ] `bash install.sh --dry-run` 実行前後で `git status` の差分が同一 (副作用なし)
- [ ] `grep -E "Would (create|modify|run)" /tmp/dryrun.log` (出力検証)
- [ ] `bash install.sh --print-provenance | grep -E "SAGE.*VERSION|Apache-2.0|sha256:"` 全て match
- [ ] `bash install.sh --verify-checksum 2>&1 | grep -E "drift|verified|state not found"` (state あり/なし両ケース対応)
- [ ] `bash install.sh` (フラグなし) で従来通り install/update が動作する
- [ ] `wc -c install.sh` が NFR-02 範囲内 (現 213564 → 224000 以内)
- [ ] `shellcheck install.sh` で新規 warning なし
- [ ] commit message に `TASK-0097:` を含む
