# TASK-0080: .gitignore ↔ tracked ファイル整合性チェック (sage-validate Check 8)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0080 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-C |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0086 (.DS_Store untrack が先行しないと Check 8 が初回から FAIL になる) |
| 見積     | 0.3h |

## 責務

`.gitignore` に記載されているのに repository に tracked で残っているファイルを検知する Check を `scripts/sage-validate.sh` に追加する。`.DS_Store` の矛盾 (TASK-0086 で解消済) が再発生することを防ぐ。

## 入力

- `scripts/sage-validate.sh` 現状: 7 チェック ([1/7] ～ [7/7])
- `git ls-files -ci --exclude-standard` コマンド:
  - `-c` cached = 追跡中
  - `-i` ignored = .gitignore にマッチする
  - `--exclude-standard` = 標準の .gitignore / .git/info/exclude / global excludes を適用
  - 両条件を満たす = tracked かつ ignored = 矛盾
- TASK-0086 後の状態: 出力が空 (矛盾なし)

## 出力

- `scripts/sage-validate.sh` の構造が [1/8] ～ [8/8] になる
- 新 Check 8: `gitignore/tracked 整合性チェック` を追加
- 矛盾検出時に ERROR 加算 + 該当ファイル名を表示

## File Scope（変更許可範囲）

- 作成:
  - `tasks/TASK-0080-gitignore-tracked-consistency.md` (本ファイル)
- 変更:
  - `scripts/sage-validate.sh` (Check 8 追加 + 全セクションの `[X/7]` → `[X/8]` 更新)
  - `.gitignore` (`.sage/runs/` の除外を撤回 — 理由は下記)
- 新規 tracking:
  - `.sage/runs/RUN-0002.yaml` / `.sage/runs/RUN-0003.yaml` (これまで gitignore で隠れていた audit trail を明示的に tracked にする)
- 削除: なし

### File Scope 拡張の理由 (当初の「検知のみ」から拡張)

Check 8 を追加したところ、`.sage/runs/RUN-0001.yaml` が tracked かつ gitignored という既存矛盾を検知した。これは `.DS_Store` と同じ型のバグで、放置すると Check 8 自体が常時 FAIL する。根本原因は `.gitignore` に `.sage/runs/` が含まれていたことだが、SAGE の設計意図 (CLAUDE.md L178 「全エージェント実行を RUN-ID で記録」、File Scope Rules の `.sage/runs/` は「Any agent (append only)」) からすると RUN ログは tracked されるべき audit trail。したがって:

- `.gitignore` から `.sage/runs/` を除外
- 既に local に存在する RUN-0002 / RUN-0003 を tracked に昇格

この拡張は Check 8 の受け入れ条件 (PASS を返す) を満たすために必須。

## 禁止事項

- 既存 7 チェックのロジック変更禁止 (ラベル番号の更新のみ許可)
- `.gitignore` の他エントリ変更禁止 (`.sage/runs/` の 1 行のみが対象)
- RUN ログの内容変更禁止 (新規 tracking は既存ファイル内容そのまま)

## 完了条件

- [ ] `bash scripts/sage-validate.sh` が実行可能で、全 8 チェックを走らせる
- [ ] 現状 (TASK-0086 後) で Check 8 が PASS を返す
- [ ] 意図的に `touch .DS_Store && git add -f .DS_Store` で再 track すると Check 8 が ERROR を報告する (検証は手動で)
- [ ] 既存の 7 チェック全てのラベルが `[X/8]` 形式に更新される
- [ ] コミットメッセージに `TASK-0080` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-C 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
