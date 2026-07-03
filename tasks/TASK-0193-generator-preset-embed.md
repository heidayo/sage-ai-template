# TASK-0193: generator プリセット埋め込み + project_checks セクション置換関数

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0193 |
| SPEC-ID   | SPEC-0028 |
| PLAN-ID   | PLAN-0028 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0197 と並列可） |
| 依存TASK  | TASK-0192 |
| 見積     | 2h |

## 責務

generator にプリセット 4 ファイルの埋め込みと、TMPL_CONFIG の `project_checks:` セクション境界のみを置換する関数を実装する（SPEC-0028 Slice ヒント T2）。

## 入力

- TASK-0192 の成果物: `templates/project-checks/*.yaml`（読み取りのみ）
- SPEC-0028 実装メモ: 現行 config.yaml 生成経路は `scripts/generator/02-config.sh`（TMPL_CONFIG 生成）→ `scripts/generator/07-installer-main.sh:732` の `write_file_if_new`。プリセット適用は write 直前のセクション置換として実装するのが最小介入
- INV-06: プリセット定義の実体は `templates/project-checks/` のみ、install.sh 内埋め込みは generator による派生物（二重管理禁止）
- SEC-02/INV-04: config.yaml へ書き込む値は埋め込み済みの静的プリセット文字列のみ
- リスク4 対策: 置換は `project_checks:` セクション境界のみを対象とし、他の行に差分を出さない（POST-01）

## 出力

- `scripts/generator/01-templates.sh` または `scripts/generator/02-config.sh` へのプリセット埋め込み（配置はいずれか一方、実装時に判断）
- `scripts/generator/02-config.sh` の project_checks セクション置換関数
- generator 単体実行で TMPL_CONFIG 置換結果が期待値（各プリセット・非適用時とも）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/01-templates.sh`, `scripts/generator/02-config.sh`
- 削除: なし

## 禁止事項

- 本リポジトリの `.sage/config.yaml` の変更（AC-11、全 TASK 横断制約）
- `install.sh` の手動編集・再生成、SHA256SUMS の更新（TASK-0195 の責務・単独コミット）
- `scripts/generator/07-installer-main.sh` の変更（TASK-0194 の責務）
- 導入先ファイル内容（package.json 等）を config.yaml へ転記する実装（SEC-02）

## 完了条件

- [ ] generator 単体実行で、各プリセット指定時の TMPL_CONFIG の project_checks セクションが `templates/project-checks/<name>.yaml` の内容と一致する（AC-02 部分）
- [ ] プリセット非適用時の TMPL_CONFIG が変更前と完全同一である（NFR-01/INV-02 の前提確認）
- [ ] `git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0（AC-11）
- [ ] コミットメッセージに TASK-0193 を含む

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0028-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
