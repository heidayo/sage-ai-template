# SAGE 品質ゲート定義

## 概要

SAGEでは5段階の品質ゲートを定義する。すべてのゲートはCIで自動実行され、マージ前に通過が必須。

---

## Gate 1: Structural（構造）

**トリガー**: すべてのPR（ドキュメント変更を除く）

| チェック | ツール例 | 必須 |
|---------|---------|------|
| Lint | golangci-lint / ESLint / ruff | Yes |
| Format | gofmt / prettier / black | Yes |
| Type check | go vet / tsc / mypy | Yes |
| Schema validation | oapi-codegen check / sqlc check | 条件付き |
| SAGE structure | sage-validate.sh | Yes |
| Noise diff check | git diff --check | Yes |

**閾値**: エラー0件で通過。Warning は許容するがログに記録。
ノイズ差分（trailing whitespace、行末改行変更など変更意図のない差分）: 0件。

**設定方法**: `.sage/config.yaml` の `project_checks.lint` / `format` / `type_check` にコマンドを設定する。未設定のチェックは SKIPPED として扱われる（偽PASSにはならない）。

**注**: `git diff --check` はwhitespace系の差分のみ検出。変更意図のないリフォーマット、既存パターンとの不整合、投機的コードの混入はセルフレビュー（src-rules）およびレビュー（sage-review）で担保する。

---

## Gate 2: Functional（機能）

**トリガー**: `src/**` または `tests/**` の変更時

| チェック | ツール例 | 必須 |
|---------|---------|------|
| Unit test | go test / jest / pytest | Yes |
| Integration test | テストスイート | 条件付き |
| Coverage | octocov / jest --coverage | Yes |

**閾値**:
- カバレッジ: **80%以上**（`.sage/config.yaml` で調整可）
- テスト: 全件パス
- カバレッジが既存より低下した場合は失敗

**設定方法**: `.sage/config.yaml` の `project_checks.test_command` にテストコマンドを設定する。未設定の場合は SKIPPED。

---

## Gate 3: Security（セキュリティ）

**トリガー**: すべてのPR + 週次スケジュール

| チェック | ツール例 | 必須 |
|---------|---------|------|
| Secret scan | Gitleaks | Yes |
| Dependency vuln scan | Trivy | Yes |
| SAST | CodeQL / Semgrep | 条件付き |

**閾値**:
- Secret 検出: 0件で通過（1件でも失敗）
- 脆弱性: CRITICAL/HIGH は0件必須。MEDIUM は記録のみ。

---

## Gate 4: Architecture（アーキテクチャ）

**トリガー**: `src/**` の変更時

| チェック | ツール例 | 必須 |
|---------|---------|------|
| Layer boundary | カスタムスクリプト / archunit | Yes |
| Forbidden dependency | import解析 | Yes |
| Traceability | sage-trace-check.sh | Yes |

**閾値**:
- レイヤ境界違反: 0件
- TASK-ID未記載コミット: 0件（初期コミット・マージコミットを除く）

**Enforcement**: トレーサビリティ違反検出時は FAIL（exit 1）。WARN ではなくマージをブロックする。

---

## Gate 5: Release（リリース）

**トリガー**: main/production への PR

| チェック | 内容 | 必須 |
|---------|------|------|
| Migration safety | マイグレーションの可逆性確認 | Yes |
| Rollback plan | ロールバック手順の存在 | Yes |
| Monitoring readiness | 監視設定の確認 | Yes |
| Gate 1-4 すべて通過 | 前提条件 | Yes |

**閾値**: すべてのチェックが通過で合格。

**前提条件チェック**: Gate 1-4 の最新実行結果を GitHub Actions API で取得し、いずれかが failure の場合は Gate 5 も failure とする。

---

## マージ条件（すべて満たすこと）

- [ ] 仕様にひもづいている（SPEC-ID あり）
- [ ] タスク責務が単一（TASK-ID あり）
- [ ] 検証が通っている（Gate 1-3 必須、Gate 4-5 条件付き）
- [ ] レビュー指摘が解消済み
- [ ] 実行ログが残っている（RUN-ID）

---

## ステータス表示

PRコメントには以下の3状態で結果が表示される:

| 状態 | アイコン | 意味 |
|------|---------|------|
| PASS | ✅ | チェック通過 |
| FAIL | ❌ | チェック失敗（マージブロック） |
| SKIPPED | ⏭️ | チェック未設定（`.sage/config.yaml` で設定可能） |
