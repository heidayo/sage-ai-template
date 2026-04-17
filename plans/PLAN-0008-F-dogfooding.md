# PLAN-0008-F: Dogfooding (実アプリ適用)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0008-F |
| SPEC-ID   | SPEC-0008 |
| ステータス | Active |
| 作成日    | 2026-04-17 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infra (project_checks 設定)
- [ ] frontend
- [x] test (Go unit/integration)

## 影響範囲

`src/calculator/` と `tests/calculator/` (Go HTTP API)、`.sage/config.yaml` の `project_checks`、新規 SPEC-0009 (別 SPEC として切り出し)、`.sage/runs/` に新規 RUN ログ。

## 実装方針

「SAGE 自身が SAGE に準拠したプロジェクトを運用できる」ことの実証。SPEC-0008 の Track A/B/D が main にマージ後に実施するのが原則だが、feature ブランチ上での事前検証も可。

- **Go 単一言語採用 (TASK-0090)**: 標準ライブラリのみ使用、外部依存なし。coverage tooling が単純 (`go test -coverprofile`)。
- **project_checks 実コマンド化 (TASK-0091)**: Go 向け lint/format/type_check/test コマンドを config に有効化。Gate 1-2 が実走。
- **SPEC-0009 切り出し (TASK-0092)**: 別 SPEC として管理。本 PLAN はスコープ外への参照のみ。
- **5 Gate 全 PASS 実走 (TASK-0093)**: Track A-D 実装の動作確認。RUN ログ生成の自動化も検証。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0090 | Go 電卓 HTTP API の src/tests 配置 | Implementation | 2h | - | Yes |
| TASK-0091 | project_checks を Go 向け実コマンドに | Implementation | 0.3h | TASK-0090 | No |
| TASK-0092 | SPEC-0009 (calculator-api) の切り出し | Spec | 1h | TASK-0091 | No |
| TASK-0093 | 5 Gate 全 PASS の実走 + RUN ログ蓄積 | Operations | 1h | Track A-D | No |

## リスク

- リスク 1: Go 未インストールの CI runner で Gate 2 が SKIP 扱いになる → 軽減策: GitHub Actions 標準 runner は Go プリインストール、他 CI は ubuntu-latest で setup-go を前提
- リスク 2: Track A-D が未完の状態で Track F を走らせると失敗がどの Track に起因するか切り分け困難 → 軽減策: Track F 実施前に A-D の unit test を個別確認

## 必要な検証

- [ ] unit test (Go テスト作成)
- [ ] integration test
- [ ] security scan
- [ ] e2e test
- [ ] architecture boundary check (自分自身の architecture.yaml で dogfooding)
