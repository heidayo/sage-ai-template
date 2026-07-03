# PLAN-0030: TypeScript Enforcement プリセット — tsc ラチェット + ESLint 断片 + 運用 docs

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0030 |
| SPEC-ID   | SPEC-0030 |
| ステータス | Draft |
| 作成日    | 2026-07-03 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（`scripts/` 汎用 CLI スクリプト + `templates/ts-enforcement/` 配布断片）
- [ ] frontend
- [ ] infra
- [x] test（`templates/hooks/tests/` integration テスト + mock tsc fixtures）
- [x] docs（`docs/ts-enforcement.md` 新設、`docs/stack-presets.md` / `README.md` 参照追記）

## 影響範囲

SPEC-0030 実装メモの File Scope と 1:1 対応。**全て新規ファイル追加 + docs 参照追記のみ**（NFR-01 後方互換）。

| ファイル | 種別 | 担当 TASK |
|---------|------|----------|
| `scripts/sage-tsc-ratchet.sh` | 新規 | TASK-0204 |
| `templates/ts-enforcement/eslint-flat.mjs` | 新規 | TASK-0205 |
| `templates/ts-enforcement/eslint-flat-transitional.mjs` | 新規 | TASK-0205 |
| `templates/ts-enforcement/eslintrc-fragment.json` | 新規 | TASK-0205 |
| `docs/ts-enforcement.md` | 新規 | TASK-0206 |
| `docs/stack-presets.md` | 参照追記 1 行のみ | TASK-0206 |
| `README.md` | 参照追記のみ | TASK-0206 |
| `templates/hooks/tests/test-ts-enforcement.sh` | 新規（Test Agent） | TASK-0207 |
| `templates/hooks/tests/fixtures/mock-tsc-*.sh` | 新規 fixture（Test Agent） | TASK-0207 |
| `templates/hooks/tests/run-tests.sh` | 登録行のみ（自動 discovery なら不要、Test Agent） | TASK-0207 |

**非変更（全 TASK 横断の禁止、AC-09 / AC-12 / INV-05 / INV-06）**: `install.sh` / `SHA256SUMS` / `scripts/generator/` / `templates/project-checks/ts-pnpm.yaml` / `.sage/config.yaml` / `AGENTS.md` / `docs/codex-*.md` / `sage/` / `.claude/rules/` / CLAUDE.md。

installer 非配布の設計判断（SPEC-0030 §installer 配布判断）により、**install.sh 再生成 TASK・SHA256SUMS 更新 TASK は不要**（FAIL-0002 の再生成専用 TASK 規約は非該当）。

## 実装方針

1. **ラチェットスクリプト（TASK-0204）**: 既存 `scripts/sage-promote.sh` 等の流儀（`set -euo pipefail` / usage 関数 / INFO・ERROR プレフィックス）に合わせた単一 bash スクリプト。
   - モード: 検査（デフォルト）/ `--update` / `--init`。tsc コマンドは `SAGE_TSC_COMMAND` > `--tsc-command` > `npx tsc --noEmit`（FR-03）
   - エラーカウント: stdout/stderr 両捕捉のうえ `grep -cE 'error TS[0-9]+'`。tsc 実行失敗（パターン 0 件 + 非0 exit）は exit 1 + 出力透過（境界ケース2、fail-closed / INV-02）
   - JSON 読み書きは POSIX ツールのみ（sed 抽出 + 非負整数検証、printf 固定テンプレート書き込み）。jq / eval 禁止（AC-08 / INV-03、SPEC-0027 と同方針）。tsc 出力内容の baseline 非転記（SEC-02 / INV-04）
2. **ESLint 断片（TASK-0205）**: 3 ファイル。flat config は `export default` の配列要素 1 つ（spread 取り込み形）、legacy は `rules` 断片。`ban-ts-comment`=error（`ts-expect-error` は `allow-with-description`）、`no-explicit-any` は error / warn（transitional）の 2 バリアント。冒頭に適用手順コメント + 前提バージョン（@typescript-eslint v6+）を記載
3. **docs（TASK-0206）**: `docs/ts-enforcement.md` に 6 節（導入手順 / ESLint 断片適用 / ラチェット運用 / tsconfig 変更規約 / SPEC-0028 ts-pnpm 参照 / graduation）。`docs/stack-presets.md` へ参照 1 行、README へ参照追記。**ts-pnpm.yaml へは触れない**（リスク5 判断済み）
4. **テスト（TASK-0207、Test Agent・別セッション）**: mock tsc fixture（`printf` でエラー行 N 件出力する bash スクリプト）を `SAGE_TSC_COMMAND` / `--tsc-command` で注入し、AC-01〜08 を integration テストで検証。Node / tsc 実物非依存（NFR-03）。test-stack-presets.sh の流儀を踏襲

代替案比較: ratchet を hooks（PreToolUse 等）として実装する案は不採用 — 導入先 CI での実行が主用途であり、hook 化は opt-in 原則と非 TS 導入先への影響ゼロ要件に不適合。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0204 | `scripts/sage-tsc-ratchet.sh` 新設（検査/--update/--init/注入/整合検証） | Implementation | 2h | none | Yes（TASK-0205 と並列、File Scope 互いに素） |
| TASK-0205 | `templates/ts-enforcement/` ESLint 設定断片 3 ファイル新設 | Implementation | 1h | none | Yes（TASK-0204 と並列、File Scope 互いに素） |
| TASK-0206 | docs 新設 + 参照追記（ts-enforcement.md / stack-presets.md / README） | Implementation | 1h | TASK-0204, TASK-0205 | Yes（TASK-0207 と並列、File Scope 互いに素） |
| TASK-0207 | test-ts-enforcement.sh + mock tsc fixtures + run-tests.sh 登録（**Test Agent 責務・別セッション**） | Test | 2h | TASK-0204, TASK-0205 | Yes（TASK-0206 と並列、File Scope 互いに素） |

実行順: TASK-0204 / TASK-0205 並列 → TASK-0206 / TASK-0207 並列。AC-09 / AC-12（installer・プリセット非変更）は全 TASK 横断制約として Done Definition + PR レビューで検証。

## リスク

- リスク1: tsc 出力フォーマット変更で誤カウント → 軽減策: `error TS[0-9]+` パターンを docs 明記 + mock tsc テストで固定。誤カウント報告は OPS-03 の failures.md フローで捕捉
- リスク2: 正しいフォーマットでの baseline 手動改竄は機械検出不能 → 軽減策: docs で手動編集禁止 + PR レビュー規約。完全な機械強制は scope-out（AP-06 残存リスクとして認識）
- リスク3: TASK-0206 の docs 追記が誤って `templates/project-checks/ts-pnpm.yaml` に波及すると drift check で installer 再生成が強制される → 軽減策: TASK-0206 の禁止事項に明記 + CHECK（AC-12）で機械検証
- リスク4: ESLint 断片と導入先 @typescript-eslint バージョン不整合 → 軽減策: 断片コメントに前提バージョン記載、実行検証は scope-out
- リスク5: 実装とテストを同一 agent が持つと AP-04 / AP-07（幻覚の相互隠蔽）→ 軽減策: TASK-0207 を Test Agent・別セッションに分離、テスト期待値は SPEC の AC から導出（AC-N 参照必須）

## 必要な検証

- [ ] unit test — N/A（bash スクリプト。integration テストで代替）
- [x] integration test — `templates/hooks/tests/test-ts-enforcement.sh`（mock tsc、AC-01〜08）+ `run-tests.sh` 全件 PASS（AC-10）
- [x] security scan — Gate 3（gitleaks / secret scan）。SEC-01〜04 は実装レビュー + AC-08 grep 検証
- [ ] e2e test — N/A（実 TS プロジェクトでの実行検証は scope-out）
- [x] architecture boundary check — Gate 4 + AC-09 / AC-12 の git diff 検証（installer 非変更 / プリセット不変）
