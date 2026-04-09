# Tasks

TASK-XXXX 形式のタスク定義を格納するディレクトリ。

## 使い方

1. `_template.md` をコピーして新しいTASKを作成
2. `make id-gen TYPE=task` で次のIDを取得
3. 必ず対応するSPEC-IDとPLAN-IDを記載
4. 完了条件をコマンドベースで定義

## ルール

- 1タスク1責務（複数レイヤ・複数目的を含まない）
- File Scope（変更許可範囲）を明記
- 禁止事項を明記
- 実行後はRUN-IDを記録
