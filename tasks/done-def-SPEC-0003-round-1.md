# Done Definition: SPEC-0003 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0003 |
| PLAN-ID   | PLAN-0003 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（skeleton） |
| 検証者     | Verify Agent |

## 目的

hook enforcement の初回実装ラウンドで必要な完了条件を定義する。

## 受け入れ条件

- [ ] `hooks.profile` の設定に応じて hook が正しく動作する
- [ ] dangerous command / protected file / file scope が仕様どおり判定される
- [ ] session hook がプロジェクト文脈を壊さずに動作する
