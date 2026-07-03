# TASK-0194: `--stack` 解析 + マーカー自動検出 + INFO 出力 + dry-run 分岐

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0194 |
| SPEC-ID   | SPEC-0028 |
| PLAN-ID   | PLAN-0028 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0197 と並列可） |
| 依存TASK  | TASK-0193 |
| 見積     | 3h |

## 責務

`scripts/generator/07-installer-main.sh` に `--stack` オプション解析・マーカー自動検出・INFO 出力・dry-run 分岐を実装する（SPEC-0028 Slice ヒント T3）。

## 入力

- TASK-0193 の成果物: プリセット埋め込み + セクション置換関数（シグネチャ参照）
- FR-02〜07 / SEC-01〜02 / PRE-01〜03 / POST-01〜02:
  - `--stack` は許可リスト（go/ts-pnpm/node-npm/python）完全一致比較のみで分岐。パス連結・コマンド評価禁止（SEC-01）。未知値は usage を stderr + exit 非0・書き込みゼロ（FR-03）
  - 自動検出: `go.mod` → go、`pnpm-workspace.yaml` または `pnpm-lock.yaml` → ts-pnpm、`package.json`（pnpm マーカーなし）→ node-npm、`pyproject.toml` → python。優先順位 go > ts-pnpm > node-npm > python。存在チェック（`[ -f ]`）のみ、内容の読み取り禁止（PRE-02）
  - 検出結果・全マーカー・採用理由を INFO 出力（POST-02）。検出不能時は現行同一の未設定テンプレート + 現行同等出力（FR-05/NFR-01）
  - 既存 config.yaml 存在時は一切変更しない。`--stack` 明示時はスキップ INFO（FR-06/INV-01）。適用判定は書き込み直前（PRE-01）
  - `--dry-run` は全書き込みに先行して評価（FR-07/PRE-03）
- オプション解析は install.sh 既存の引数ループ（`--dry-run` / `--verify-checksum` 周辺）に追随。`--stack` は値を取るため `case` の shift 処理に注意

## 出力

- `scripts/generator/07-installer-main.sh` の変更（`--stack` 解析・自動検出・INFO・dry-run 分岐・write_file_if_new 直前のプリセット適用呼び出し）
- 一時ディレクトリでの手動 install 検証が AC-02/03/04/05/06/07/08 相当を満たすこと（正式テストは TASK-0196）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/07-installer-main.sh`
- 削除: なし

## 禁止事項

- 本リポジトリの `.sage/config.yaml` の変更（AC-11、全 TASK 横断制約）
- `install.sh` の手動編集・再生成、SHA256SUMS の更新（TASK-0195 の責務・単独コミット）
- `--stack` 値のパス連結によるプリセット読み込み（SEC-01 — 許可リスト分岐で静的文字列を選ぶ）
- 導入先ファイル内容の config.yaml への転記（SEC-02）
- `--verify-checksum` / provenance 経路の変更（SEC-03、SPEC-0018 非介入）
- 対話的プロンプトの追加（非対話 CI 実行を壊すためスコープ外）

## 完了条件

- [ ] 一時ディレクトリで generator から再生成した install.sh（コミットはしない）を用いた手動検証で: 明示適用（AC-02 相当）・単一マーカー検出（AC-03 相当）・複数マーカー優先順位（AC-04 相当）・非検出 fallback（AC-05 相当）・既存 config 保持（AC-06 相当）・未知値 exit 非0（AC-07 相当）・dry-run 非介入（AC-08 相当）が確認できる
- [ ] `git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0（AC-11）
- [ ] コミットメッセージに TASK-0194 を含む（install.sh / SHA256SUMS は含めない）

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
