# TASK-0111: doctrine update + .claude/settings.json + install.sh re-sync

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0111 |
| SPEC-ID   | SPEC-0012 |
| PLAN-ID   | PLAN-0012 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0107..0110 全て後) |
| 依存TASK  | TASK-0107, TASK-0108, TASK-0109, TASK-0110 |
| 見積     | 60m |

## 責務

Phase 2B の最終 wrap-up: 新 hook 3 件を `.claude/settings.json` の hooks 配列に登録、governance / SECURITY.md を新 hook で更新、`.gitignore` に `.sage/runtime/` 追加、install.sh を再生成。

## 入力

- SPEC-0012 FR-06, FR-07, FR-08, FR-09
- TASK-0107..0110 の成果物

## 出力

### 1. `.claude/settings.json` の hooks 配列拡張

既存の PreToolUse/Bash + Edit|Write、SessionStart/Stop matchers を保持しつつ:
- `PreToolUse` Bash matcher に `secret-read-multi-layer.sh` と `lethal-trifecta-detect.sh` 追加
- `PreToolUse` Read matcher に `lethal-trifecta-detect.sh` 追加 (Read tool 経由の private data 痕跡記録)
- `Stop` matcher に `security-filter.sh` 追加 (既存 session-stop.sh と並列実行) — TASK-0112 で `SessionStop` → `Stop` に rename (Claude Code 公式準拠)

### 2. `sage/governance.md` §9.1 更新

「Hook テンプレート」行に Phase 2B 新 hook 3 件を列挙:
> - `templates/hooks/`: block-dangerous-commands / protect-sage-files / check-file-scope / session-start / session-stop / **lethal-trifecta-detect (Phase 2B, warn-only)** / **secret-read-multi-layer (Phase 2B)** / **security-filter (Phase 2B, Stop hook で全 RUN log redact)**
> - `templates/settings/sandbox.json` (Phase 2B, **雛形のみ — 適用は user 責任**)

### 3. `SECURITY.md` §3 threat model 更新

該当行を `[partial]` から `[partial → improved (Phase 2B)]` に更新:
- §3.1 Template Supply Chain: `installer_url` の `[partial]` 行は SPEC-0011 で扱うとして変更しない
- §3.1 Skill / hook ファイル経由の任意コード実行: `[partial] → [improved Phase 2B: secret-read-multi-layer + lethal-trifecta-detect で部分緩和、完全防御は引き続き runtime sandbox 必要]`
- §3.3 Lethal Trifecta: `[partial → improved (Phase 2B): warn-only 検出 hook 追加。block は依然として user の judgement 責任]`

### 4. `.gitignore` 拡張

新規 entry: `.sage/runtime/` (lethal-trifecta-detect.sh の状態管理 dir)

### 5. `scripts/generate-installer.sh` 更新 + `install.sh` 再生成

- 新 hook 3 件の embed_file 呼び出し追加
- `templates/settings/sandbox.json` と `templates/settings/README.md` の embed
- install logic の `[7/9] Claude Code hooks...` step に新 hook 3 件の write_file_if_new / update_file 追加
- 新 step `[8/9] Settings template...` (sandbox.json/README を `templates/settings/` に配置)
- step 番号調整: 既存 `[8/9] Pre-commit hook...` → `[9/10]`, `[9/9] .gitignore...` → `[10/10]` (または合計 step 数を維持して新 step を既存 step に統合)
- install.sh 再生成

## File Scope（変更許可範囲）

- 変更: `.claude/settings.json` (hooks 配列拡張のみ、他の section 変更禁止)
- 変更: `sage/governance.md` (§9.1 の Hook テンプレート行のみ)
- 変更: `SECURITY.md` (§3.1 と §3.3 の該当行のみ)
- 変更: `.gitignore` (1 entry 追加のみ)
- 変更: `scripts/generate-installer.sh` (embed + install step 拡張)
- 変更: `install.sh` (生成成果物)
- 削除: なし

## 禁止事項

- `.claude/settings.json` の他 section (permissions / sandbox 設定など、もし存在すれば) の変更禁止
- governance / SECURITY.md の他 section 変更禁止
- install.sh への直接編集禁止 (必ず generator 経由で再生成)
- `.gitignore` の既存 entry 順序変更禁止 (.sage/runtime/ を SAGE Runtime section 末尾に追加)

## 完了条件

- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (47 + Phase 2B 追加分)
- [ ] `bash install.sh --dry-run` exit 0
- [ ] `bash install.sh --print-provenance` で SAGE_VERSION 表示 (Phase 1 機能保持)
- [ ] `wc -c install.sh` ≤ 259000 (NFR-03)
- [ ] `.claude/settings.json` の hooks 配列に新 3 hooks 登録
- [ ] `.gitignore` に `.sage/runtime/` 含む
- [ ] `grep -c "lethal-trifecta\|secret-read-multi-layer\|security-filter" sage/governance.md` >= 3
- [ ] commit message に `TASK-0111:` を含む
