# TASK-0116: Codex 3rd-round Review Follow-up — Phase 2B (PR #13)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0116 |
| SPEC-ID   | SPEC-0012 |
| PLAN-ID   | PLAN-0012 |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (must precede merge) |
| 依存TASK  | TASK-0107..0113 |
| 見積     | 30m |

## 責務

Codex 3rd-round (TASK-0113 後の再レビュー) で指摘された P1×1 / P2×2 = 3 件を解消する。CI release-gate の実 fail を解消し、Gitleaks allowlist の暗黙 OR を AND に修正、TASK/governance の旧仕様残存を完全消去する。

## 入力 (Codex 3rd-round 指摘 3 件)

1. **[P1]** `sage-release-gate.yml` の `fetch-depth` が未指定で shallow checkout 動作。CI で `scripts/sage-validate.sh` 内の `git diff-tree --check --root -r HEAD` が広すぎる範囲を見て `24 noise diff(s)` を検出 → release gate が false fail。他 gate (structural / security) は既に `fetch-depth: 2` 以上を指定しており、release のみ outlier。
2. **[P2]** `.gitleaks.toml` のコメントは「path AND regex」と書いていたが、Gitleaks docs では複数条件 `[allowlist]` の default は **OR**。AND にするには `condition = "AND"` を明示する必要がある。現状は path 全体 + regex 単独の OR なため、4 file は repo-wide で全 secret 検出 exempt、加えて 8 fixture 値は repo-wide で exempt の二重穴。
3. **[P2]** `tasks/TASK-0109-security-filter-redact.md` の「出力」section が `最新 (mtime 最新) 1 file のみ scan` のまま、`sage/governance.md §9.1` の Hook テンプレート行末尾も `security-filter (Phase 2B, SessionStop redact)` のまま。TASK-0113 で「履歴記述以外残存なし」を完了条件にしていたが取り残し。

## 出力

- `.github/workflows/sage-release-gate.yml`: checkout step に `fetch-depth: 0` 追加 + コメントで根拠 (sage-validate.sh の git diff-tree 動作と shallow clone の干渉) 明記
- `.gitleaks.toml`: `[allowlist]` に `condition = "AND"` 明示 + `regexTarget = "match"` 追加 (regex を full line ではなく match string 自体に適用) + コメント更新 (Gitleaks default OR の罠を説明)
- `tasks/TASK-0109-security-filter-redact.md`: 「出力」section を全面更新 (`set -uo pipefail`, Stop hook, **全ファイル** scan, **per-file atomic write** の現実装と整合)
- `sage/governance.md` §9.1 Hook テンプレート行: `security-filter (Phase 2B, Stop hook で全 RUN-*.yaml を per-file atomic redact)` に修正

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-release-gate.yml`, `.gitleaks.toml`, `tasks/TASK-0109-security-filter-redact.md`, `sage/governance.md`
- 削除: なし
- 作成: なし

## 禁止事項

- TASK-0107..0112 で確定した実装の挙動変更禁止 (本 TASK は doc 同期 + CI 設定 + Gitleaks 設定のみ)
- Gitleaks allowlist の broader scope 化禁止 (narrow path AND regex のみ)
- `fetch-depth: 0` を他 gate にも勝手に変更禁止 (release-gate の outlier 問題のみ修正)
- governance §9.2 の Codex specificity 行は触らない (TASK-0115 で更新済)

## 完了条件

- [ ] CI 上で release gate が green になる (full clone で sage-validate.sh PASS)
- [ ] `.gitleaks.toml` に `condition = "AND"` と `regexTarget = "match"` 両方が明示
- [ ] `grep -rn "SessionStop redact\|最新 (mtime 最新)" specs/ plans/ tasks/ sage/` で 0 件
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS
- [ ] `bash scripts/sage-validate.sh` PASS (full clone)
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0116:` を含む
