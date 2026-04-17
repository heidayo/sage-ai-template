# TASK-0088: hooks.profile デフォルトを minimal → standard に変更

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0088 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-E |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0078 (install.sh 再現性 CI が先行している方が安全だが本 TASK 単独でも実行可) |
| 見積     | 0.2h |

## 責務

`.sage/config.yaml` の `hooks.profile` を `minimal` から `standard` に変更し、新規インストール直後から:

- block-dangerous-commands.sh (危険コマンドブロック)
- protect-sage-files.sh (SAGE 管理ファイル保護)

が有効になる状態にする。`check-file-scope.sh` は standard では warning のみ (ブロックはしない)、完全ブロック化は strict 昇格時 (別 TASK)。

## 入力

- 現状 ([.sage/config.yaml:152](.sage/config.yaml:152)): `profile: minimal`
- minimal 状態では block-dangerous-commands.sh が即 exit 0 するため、TASK-0086 で追加した `git add -f .DS_Store` ブロックも実質無効

## 出力

- `.sage/config.yaml` line 152: `profile: standard`
- install.sh 生成時に同じ値が埋め込まれる (install.sh 再生成は本 TASK では行わない — Sprint 終盤で一括再生成予定)

## File Scope（変更許可範囲）

- 作成: なし
- 変更:
  - `.sage/config.yaml` (`hooks.profile` の 1 行のみ)
- 削除: なし

## 禁止事項

- install.sh の再生成禁止 (Sprint 1 複数の template 変更を一括で反映する方針。本 TASK 単独で install.sh を更新すると差分が混ざり原因追跡が難しくなる)
- hook スクリプト自身の変更禁止 (TASK-0089 の担当)
- `hooks.profile` のコメント (昇格条件の記述) 変更禁止

## 完了条件

- [ ] `.sage/config.yaml:152` が `profile: standard`
- [ ] `python3 -c "import yaml; d=yaml.safe_load(open('.sage/config.yaml')); assert d['hooks']['profile']=='standard'"` が成功
- [ ] hook スクリプトが期待通り動作: `echo '{"tool_name":"Bash","tool_input":{"command":"git add -f .DS_Store"}}' | bash templates/hooks/block-dangerous-commands.sh` が exit 2 (TASK-0086 で追加したパターンが実際に block される)
- [ ] コミットメッセージに `TASK-0088` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-E 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
