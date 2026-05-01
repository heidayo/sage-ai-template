# TASK-0113: Codex 2nd-round Review Follow-up — Phase 2B (PR #13)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0113 |
| SPEC-ID   | SPEC-0012 |
| PLAN-ID   | PLAN-0012 |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (must precede merge) |
| 依存TASK  | TASK-0107..0112 |
| 見積     | 45m |

## 責務

Codex 2nd-round (TASK-0112 後の再レビュー) で指摘された P1×1 / P2×1 / P3×1 = 3 件を解消する。

## 入力 (Codex 2nd-round 指摘 3 件)

1. **[P1]** `sage-release-gate.yml` の Release readiness check が `ERRORS` を `GITHUB_OUTPUT` に積むだけで `exit 1` していないため、`scripts/sage-validate.sh` が fail しても check 自体は green になり、PR コメントの「Gate 5: FAIL」と required-check status (`pass`) が乖離。merge 判断を誤らせる。
2. **[P2]** TASK-0112 で security-filter を `Stop` hook + 全 RUN log scan に変更したが、SPEC-0012 / PLAN-0012 / TASK-0109 / governance §9.1 が旧仕様 (`SessionStop` / 最新 1 file) のまま。SAGE doctrine 「SPEC は single source of truth」違反、traceability 不整合。
3. **[P3]** `.gitleaks.toml` が path 単位で 4 file 全体を exempt。将来 fixture file に本物の secret が混入しても検出されないリスク。fixture 偽 secret 行のみ inline `gitleaks:allow` か path + regex の AND 条件に絞るべき。Gitleaks v8.25+ の `[[allowlists]]` 形式への移行も視野。

## 出力

1. **`.github/workflows/sage-release-gate.yml`**: Release readiness check で `ERRORS > 0` のとき `exit 1` を追加 (fail-close)。`set -euo pipefail` の `-e` を `-uo` に変更し、明示的に exit 1 を呼ぶことで早期 abort と区別。
2. **`.gitleaks.toml`**: `[allowlist]` を `paths` AND `regexes` 両方持つ条件に変更。8 個の fixture 値 (sk-/ghp_x2/xoxb-/AKIA/JWT/MyTotallyUnsafeSecretValueLongerThanTwentyChars/ShouldBeRedactedExampleStringValue) を explicit 列挙。コメントに v8.25+ 移行ガイダンス。
3. **SPEC-0012 / PLAN-0012 / TASK-0109 / TASK-0111 / governance.md §9.1**: `SessionStop` → `Stop`、「最新ファイル」→「全 RUN-*.yaml ファイル」、「per-file atomic write、1 file 失敗が他 file を block しない」を反映。TASK-0112 履歴記述は維持 (rename の経緯を残す)。

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-release-gate.yml`, `.gitleaks.toml`, `specs/SPEC-0012-new-defense-layers.md`, `plans/PLAN-0012-new-defense-layers.md`, `tasks/TASK-0109-security-filter-redact.md`, `tasks/TASK-0111-doctrine-and-installer-sync.md`, `sage/governance.md`
- 自動再生成: `install.sh` (governance 変更を embed する場合)
- 削除: なし

## 禁止事項

- TASK-0112 で確定した hook 実装の挙動変更禁止 (本 TASK は SPEC/PLAN/TASK の同期と CI/Gitleaks 設定の引き締めのみ)
- Gitleaks allowlist の broader regex 禁止 (explicit fixture 値のみ)
- Release gate の他 step 変更禁止 (Release readiness check のみ fail-close 化)
- governance §9 章構造変更禁止 (該当行のみ更新)

## 完了条件

- [ ] `bash scripts/sage-validate.sh` 失敗を induce すると `sage-release-gate.yml` の `Release readiness check` step が exit 1 になる (fail-close 確認)
- [ ] CI Gate 5 (Release) の comment と check status が一致 (PASS なら check pass、FAIL なら check fail)
- [ ] `.gitleaks.toml` の `[allowlist]` に `paths` AND `regexes` 両方が定義
- [ ] `grep -rn "SessionStop" specs/ plans/ tasks/ sage/` で TASK-0112/TASK-0113 履歴記述以外残存なし
- [ ] `grep -rn "最新.*RUN\|最新 1 file" specs/ plans/ tasks/ sage/` で stale record 解消
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (regression なし)
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0113:` を含む
