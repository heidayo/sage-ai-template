# Done Definition: SPEC-0005 Round 1

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0005 |
| PLAN-ID   | PLAN-0005 |
| ラウンド   | 1 |
| 作成者     | Planning Agent |
| 検証者     | Verify Agent |

## 目的

template stabilization remediation ラウンドで必要な完了条件を定義する。

## 受け入れ条件

- [x] workflow / hook / packaging / documentation の致命的不整合が是正されている
- [x] `CI=1 bash scripts/sage-validate.sh` が通る
- [x] targeted hook checks が通る
- [x] retrospective traceability / done-definition / AGENTS wording / workflow hardening が反映されている
