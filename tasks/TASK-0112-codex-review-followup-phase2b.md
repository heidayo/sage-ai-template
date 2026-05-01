# TASK-0112: Codex Review Follow-up — Phase 2B (PR #13) Fixes

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0112 |
| SPEC-ID   | SPEC-0012 |
| PLAN-ID   | PLAN-0012 |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (must precede merge) |
| 依存TASK  | TASK-0107..0111 |
| 見積     | 75m |

## 責務

Codex (cross-model adversarial review) が PR #13 に対して指摘した P1×2 / P2×3 / P3×1 + bonus = 7 件を解消し、Phase 2B を merge 可能な状態に戻す。

## 入力 (Codex 指摘 7 件)

1. **[P1]** Gate 3 Security fail — Gitleaks が `templates/hooks/tests/test-security-filter.sh` の fixture (AWS access key / JWT / generic-api-key 形式) を本物の secret として検出。`scripts/sage-doctor.sh` の allowlist は **ローカルのみ** に効くもので、CI の Gitleaks には効かない。
2. **[P1]** Claude review gate fail — `.github/workflows/sage-claude-review.yml` の verdict 抽出ロジックが `body.split('\n').find(l => l.includes('総合判定'))` で **最初に現れる** `総合判定` 含有行を取るため、checklist 行 `- [x] 総合判定の決定` (✅/❌ なし) がヒットして verdict 不明として fail。実際の `### 総合判定: ✅ PASS` は後続行にある。
3. **[P2]** lethal-trifecta-detect の wording — 2/3 条件で `WARN: lethal trifecta condition detected (2/3)` と出すが、Lethal Trifecta は本来 3/3 揃った状態を指す。2/3 は `partial trifecta risk` 等に分けるべき (alert fatigue / 用語誤用)。
4. **[P2]** sandbox.json `allowWrite` に `./.sage/runtime` がない — lethal-trifecta-detect の state file 書き込みが sandbox 厳格適用環境で失敗する。
5. **[P2]** security-filter が **最新 1 file のみ** redact — 同セッション複数 RUN log で古い RUN 内 secret が残る。全 RUN log scan に変更するか、SECURITY.md / governance / README で制限を明記。
6. **[P3]** `SessionStop` → `Stop` 用語不整合 — Claude Code の公式 hook event name は `Stop`。コメントと test payload の `SessionStop` を `Stop` に統一。
7. **[Bonus, P3 相当]** `install.sh --print-provenance` が `~213KB` と表示するが実 size は 262475 bytes。trust foundation 文脈で provenance 表示の正確性が重要。動的サイズ表示に変更。

## 出力

- `.gitleaks.toml` 新規作成 (root): test fixture path 単位 allowlist + 既存 gitleaks 設定との整合
- `.github/workflows/sage-claude-review.yml`: verdict 抽出ロジックを「`総合判定` を含む行のうち `✅` または `❌` を含むもの」に変更 (チェックリスト行を誤拾いしない)
- `templates/hooks/lethal-trifecta-detect.sh`: 2/3 = `WARN: partial trifecta risk` / 3/3 = `WARN: lethal trifecta detected`
- `templates/hooks/tests/test-lethal-trifecta-detect.sh`: 用語変更に追従
- `templates/settings/sandbox.json`: `sandbox.filesystem.allowWrite` に `./.sage/runtime` 追加
- `templates/hooks/security-filter.sh`: 全 `.sage/runs/RUN-*.yaml` を scan (既存の最新 1 file 限定を撤廃)
- `templates/hooks/tests/test-security-filter.sh`: 複数 RUN log でも全 redact される test 追加 + `SessionStop` → `Stop`
- `templates/hooks/security-filter.sh` のヘッダコメント: `SessionStop` → `Stop`
- `scripts/generate-installer.sh`: `do_print_provenance` の `~213KB` ハードコードを `wc -c` ベースの動的算出に変更
- `install.sh` 再生成

## File Scope（変更許可範囲）

- 作成: `.gitleaks.toml`
- 変更: `.github/workflows/sage-claude-review.yml`, `templates/hooks/lethal-trifecta-detect.sh`, `templates/hooks/tests/test-lethal-trifecta-detect.sh`, `templates/settings/sandbox.json`, `templates/hooks/security-filter.sh`, `templates/hooks/tests/test-security-filter.sh`, `scripts/generate-installer.sh`, `install.sh`
- 削除: なし

## 禁止事項

- security-filter の Pattern 定義変更禁止 (Codex 指摘は scope 範囲のみ)
- Gitleaks allowlist は path 単位、broader regex allowlist 禁止
- claude-review verdict gate logic を「verdict 抽出のみ」に限定、他の判定 logic 変更禁止
- lethal-trifecta の判定 logic 変更禁止 (wording のみ)
- README 更新は本 TASK の scope ではない (security-filter の挙動変更で全 scan に統一するため、限定明記が不要に)

## 完了条件

- [ ] `.gitleaks.toml` が test-security-filter.sh の path-allowlist を含む
- [ ] CI Gate 3 (security) が PASS
- [ ] CI claude-review が verdict 抽出に成功 (`✅ PASS` を正しく取れる)
- [ ] lethal-trifecta hook が 2/3 で `partial trifecta risk` を出力、3/3 で `lethal trifecta detected` を出力 (test で確認)
- [ ] `jq '.sandbox.filesystem.allowWrite | contains(["./.sage/runtime"])' templates/settings/sandbox.json` exit 0
- [ ] security-filter が 2 RUN log 両方を redact (test で確認)
- [ ] security-filter のコメント・test に `SessionStop` 残存なし (`grep -r SessionStop templates/hooks/` で 0 件)
- [ ] `bash install.sh --print-provenance` の出力に `~213KB` 残存なし、実 size を表示
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] commit message に `TASK-0112:` を含む
