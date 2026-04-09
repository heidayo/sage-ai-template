# Plans

PLAN-XXXX 形式の実装計画を格納するディレクトリ。

## 使い方

1. `_template.md` をコピーして新しいPLANを作成
2. `make id-gen TYPE=plan` で次のIDを取得
3. 必ず対応するSPEC-IDを記載
4. タスク分解テーブルに全TASKを列挙

## ルール

- PLANは必ずSPECに紐づく
- 変更レイヤ・影響範囲・リスクを明記
- タスク分解で依存関係と並列可否を明示
