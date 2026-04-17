# PLAN-0008-A: Gate 実装完成

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0008-A |
| SPEC-ID   | SPEC-0008 |
| ステータス | Active |
| 作成日    | 2026-04-17 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infra (GitHub Actions workflows, shell scripts)
- [ ] frontend
- [ ] test

## 影響範囲

Gate 2 (functional) と Gate 4 (architecture) の workflow 定義 + 各 gate が呼ぶ helper script。Claude review workflow の verdict 処理ロジック。

## 実装方針

- **Gate 2 coverage**: `project_checks.coverage_command` を config で定義し workflow から呼ぶ。標準出力から float 抽出の parser を自前実装 (言語別 tooling への依存を避ける)。
- **Gate 4 layer boundary**: 言語中立 grep ベースで開始。`.sage/architecture.yaml` に `forbidden: [{from, to}]` 形式で禁止パターンを定義し、PR diff の import 行を検査。将来は go-arch-lint 等に opt-in 昇格可能な構造。
- **Claude review fail-close**: verdict 不取得 / 解釈不能 / timeout で `core.setFailed`。fail-open が gate の意義を無効化していた問題を解消。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0070 | Gate 2 カバレッジ閾値の数値抽出 + 比較 | Implementation | 2h | - | Yes |
| TASK-0071 | Gate 4 レイヤ境界チェックの grep ベース実装 | Implementation | 2h | - | Yes |
| TASK-0072 | Gate 4 禁止依存チェックの実装 | Implementation | 1h | TASK-0071 | No |
| TASK-0073 | Claude review workflow fail-close 化 | Implementation | 0.5h | - | Yes |

## リスク

- リスク 1: grep ベースのレイヤ境界は誤検知が発生しうる → 軽減策: `.sage/architecture.yaml` のサンプル最小化 + opt-in で言語別 linter に昇格できる設計
- リスク 2: coverage_command の標準出力形式が言語/ツールで異なる → 軽減策: 設定例を Go/Node/Python それぞれで文書化、formula は float 単一値の最初の一致

## 必要な検証

- [x] unit test (hook の単体テストは tmp 環境で実行)
- [ ] integration test
- [ ] security scan
- [ ] e2e test
- [x] architecture boundary check (自分自身で dogfooding)
