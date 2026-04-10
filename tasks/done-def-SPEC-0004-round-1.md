# Done Definition: SPEC-0004 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0004 |
| PLAN-ID   | PLAN-0004 |
| ラウンド   | 1 |
| 作成者     | Planning Agent（skeleton） |
| 検証者     | Verify Agent |

## 目的

install lifecycle / audit 系機能の初回実装ラウンドで必要な完了条件を定義する。

## 受け入れ条件

- [ ] `install.sh` / `sage-adopt.sh` / `sage-doctor.sh` / `sage-report.sh` が相互整合する
- [ ] install-state と doctor metrics が破綻なく記録される
- [ ] repair / report / validate 系コマンドが最低限の運用を支える
