# TASK-0206: docs/ts-enforcement.md 新設 + stack-presets.md / README 参照追記

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0206 |
| SPEC-ID   | SPEC-0030 |
| PLAN-ID   | PLAN-0030 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0207 と並列可 — File Scope 互いに素） |
| 依存TASK  | TASK-0204, TASK-0205 |
| 見積     | 1h |

## 責務

TS enforcement の運用 docs（日本語）を新設し、`docs/stack-presets.md` と `README.md` から参照導線を張る。

## 入力

- SPEC-0030 FR-07・FR-08・OPS-01・SEC-01（docs 明記事項）・リスク1/2/5・境界ケース3・§installer 配布判断
- TASK-0204 の実装済みスクリプト仕様（CLI 契約）、TASK-0205 の断片ファイル

## 出力

- `docs/ts-enforcement.md`（新規、日本語）— 6 節必須（FR-07）:
  1. 導入手順（リポジトリからのファイルコピー — installer 非配布）
  2. ESLint 断片の適用（flat / legacy 両方、transitional 差し替え手順）
  3. ラチェット運用（検査 / `--update` / `--init`、CI 組込みコマンド例、`.tsc-baseline.json` 手動編集禁止、`SAGE_TSC_COMMAND` に外部入力を渡さない旨 [SEC-01]、`error TS` カウントパターン明記 [リスク1]、同数入れ替えは exit 0 の仕様 [境界ケース3]）
  4. tsconfig 変更規約（PR に ratchet 実行ログ + build/typecheck 結果を添付。CI 強制はスコープ外と明示）
  5. SPEC-0028 ts-pnpm プリセットとの関係
  6. 段階的昇格（graduation）: (a) transitional→error 切替条件（warn 検出 0 件確認後）、(b) baseline 0 到達後の zero-tolerance 運用
- `docs/stack-presets.md` — `docs/ts-enforcement.md` への参照 1 行追記のみ
- `README.md` — 参照追記のみ

## File Scope（変更許可範囲）

- 作成: `docs/ts-enforcement.md`
- 変更: `docs/stack-presets.md`（参照 1 行のみ）, `README.md`（参照追記のみ）
- 削除: なし

## 禁止事項

- `templates/project-checks/ts-pnpm.yaml` への追記（コメント 1 行でも drift check で installer 再生成が強制される — リスク5 判断済み、AC-12）
- `install.sh` / `SHA256SUMS` / `scripts/generator/` / `.claude/rules/` / `sage/` / `AGENTS.md` / `docs/codex-*.md` / CLAUDE.md への変更
- 参照追記以外の stack-presets.md / README 改稿（AP-03 Silent Scope Expansion）

## 完了条件

- [ ] `grep -qF 'sage-tsc-ratchet' docs/ts-enforcement.md && grep -qF 'ts-enforcement' docs/stack-presets.md && grep -qF 'ts-enforcement' README.md` が exit 0（AC-11）
- [ ] `grep -qF 'tsconfig' docs/ts-enforcement.md` が exit 0（AC-11）
- [ ] `grep -qE '昇格|graduation' docs/ts-enforcement.md` が exit 0（AC-11）
- [ ] `git diff main -- templates/project-checks/ts-pnpm.yaml` の差分が空（AC-12）
- [ ] `git diff --name-only main | grep -E '^(install\.sh|SHA256SUMS|scripts/generator/)'` が exit 非0（AC-09）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0030-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
