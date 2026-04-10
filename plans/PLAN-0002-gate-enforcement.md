# PLAN-0002: Gate Enforcement化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0002 |
| SPEC-ID   | SPEC-0002 |
| ステータス | Draft |
| 作成日    | 2026-04-10 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（CI workflow）
- [ ] frontend
- [x] infra（.sage/config.yaml）
- [ ] test

## 影響範囲

- `.github/workflows/` 内の全5ゲート workflow
- `.sage/config.yaml` の設定スキーマ
- PR上に表示されるゲートコメントの表示形式

## 実装方針

### config.yaml 駆動のチェック実行

言語をハードコードせず、`.sage/config.yaml` の `project_checks` セクションに設定されたコマンドを実行する方式を採用する。

```yaml
# .sage/config.yaml に追加する構造
project_checks:
  # lint: "npm run lint"        # 未設定時は SKIP
  # format: "npm run format:check"
  # type_check: "npm run type-check"
  # test_command: "npm test"
```

### 3状態表示

PRコメントは PASS / FAIL / SKIPPED の3状態を区別する。既存の marker コメント upsert パターンを踏襲し、アイコンを変更する:
- PASS: `✅`
- FAIL: `❌`
- SKIPPED: `⏭️`

### Gate 4 の enforcement

`sage-architecture-gate.yml` の最終ステップに traceability errors > 0 で `exit 1` するステップを追加。既存の WARN コメントは FAIL に変更。

### Gate 5 の前提条件化

GitHub Actions API で同一 head_sha の Gate 1-4 run conclusion を取得し、failure があれば Gate 5 を fail させる。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0027 | `.sage/config.yaml` に `project_checks` セクション追加 | Implementation | 15m | - | Yes |
| TASK-0028 | Gate 1 (`sage-structural-gate.yml`) を config 駆動に改修 | Implementation | 30m | TASK-0027 | No |
| TASK-0029 | Gate 2 (`sage-functional-gate.yml`) を config 駆動に改修 | Implementation | 30m | TASK-0027 | No |
| TASK-0030 | Gate 4 (`sage-architecture-gate.yml`) を WARN → FAIL に変更 | Implementation | 15m | - | Yes |
| TASK-0031 | Gate 5 (`sage-release-gate.yml`) に Gate 1-4 前提条件を追加 | Implementation | 30m | TASK-0028, TASK-0029, TASK-0030 | No |
| TASK-0032 | Gate 3 (`sage-security-gate.yml`) の enforcement 確認 | Review | 15m | - | Yes |
| TASK-0033 | 全 Gate の PRコメントに PASS/FAIL/SKIPPED 3状態表示を統一 | Implementation | 20m | TASK-0028, TASK-0029, TASK-0030 | No |
| TASK-0034 | SPEC-0002 の全 AC 検証 | Test | 30m | TASK-0033 | No |

## リスク

- リスク1: yq が GitHub Actions ubuntu-latest から将来削除される可能性 -> 軽減策: 冒頭で `command -v yq` チェックし、不在時は `python3 -c "import yaml"` フォールバックを検討（本SPECでは yq 前提、フォールバックは別SPEC）
- リスク2: Gate 4 の FAIL 化で既存開発中 PR がブロックされる -> 軽減策: TASK-0030 の実装後に自身の PR で動作確認してからマージ

## 必要な検証

- [ ] unit test（該当なし — workflow YAML はユニットテスト対象外）
- [ ] integration test（GitHub Actions 上での実行確認）
- [x] security scan（Gate 3 の既存チェック）
- [ ] e2e test（該当なし）
- [x] architecture boundary check（Gate 4 の traceability チェック自体が対象）
