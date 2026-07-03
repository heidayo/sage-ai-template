# TASK-0177: install.sh 再生成 + SHA256SUMS 更新（T4/T5 反映）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0177 |
| SPEC-ID   | SPEC-0025 |
| PLAN-ID   | PLAN-0025 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No（TASK-0174 / TASK-0175 の generator 変更を全て取り込んだ最終状態で直列実行） |
| 依存TASK  | TASK-0174, TASK-0175 |
| 見積     | 30m |

## 責務

TASK-0174（03-rules.sh 注記）と TASK-0175（01-templates.sh CLAUDE.md 規約）の generator 変更を反映した `install.sh` を再生成し、`SHA256SUMS` を更新する。再生成の直列化により、T4/T5 並列実行後の checksum 不整合（PLAN-0025 リスク4）を解消する。

## 入力

- SPEC-0025（AC-05, AC-06, AC-10, NFR-02）
- TASK-0174 / TASK-0175 完了後の `scripts/generator/` 一式
- 既存の再生成手順（TASK-0172 と同一手順）

## 出力

- 再生成済み `install.sh`（TASK-0174/0175 の変更を反映）
- 更新済み `SHA256SUMS`

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `install.sh`（再生成のみ）, `SHA256SUMS`
- 削除: なし

## 禁止事項

- `install.sh` の手動編集（generator からの再生成のみ許可）
- `scripts/generator/` の修正（generator 不備は TASK-0174/0175 へ構造化フィードバックで差し戻す）
- File Scope 外の変更（AP-03 Silent Scope Expansion）
- 他 TASK 責務の取り込み（AP-02 Big Bang）
- TASK-ID なしコミット（AP-05）

## 完了条件

- [ ] `shasum -a 256 -c SHA256SUMS` が PASS する（AC-06）
- [ ] 再生成2回で `install.sh` がバイト一致する（NFR-02 再現性）
- [ ] clean install した一時ディレクトリで `grep -l 'rules/local/' .claude/rules/*.md | wc -l` が managed ルールファイル数と一致する（AC-05 / TASK-0174 反映確認）
- [ ] clean install 後 `grep -q 'rules/local/' CLAUDE.md` が成功する（AC-10 / TASK-0175 反映確認）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0025-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | - |
| 完了     | - |
| 結果     | - |
| Gate結果  | - |
