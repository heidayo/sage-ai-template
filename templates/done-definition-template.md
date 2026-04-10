# Done Definition: [SPEC-ID] Round N

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-XXXX |
| PLAN-ID   | PLAN-XXXX |
| ラウンド   | N |
| 作成者     | Planning Agent（スケルトン）→ Implementation Agent（具体値） |
| 検証者     | Verify Agent |

---

## 起動条件

### サーバー起動コマンド

```bash
# アプリケーション起動
[command to start the app, e.g., npm run dev]

# テストサーバー起動（必要な場合）
[command to start test server]
```

### 前提条件チェック

- [ ] 依存パッケージがインストール済み: `[check command, e.g., npm ls]`
- [ ] 環境変数が設定されている: `[check command, e.g., env | grep APP_]`
- [ ] データベースが起動している（該当する場合）: `[check command]`

---

## テスト対象URL

| URL | 期待動作 | 検証方法 |
|-----|---------|---------|
| http://localhost:3000/ | トップページが表示される | HTTP 200 + title 要素の確認 |
| http://localhost:3000/api/health | `{"status":"ok"}` が返る | JSON 応答の検証 |
| [追加URL] | [期待動作] | [検証方法] |

---

## 受け入れ条件（このラウンドの完了条件）

### 自動検証（コマンドベース）

- [ ] `make test` が全件パスする
- [ ] `make lint` でエラーが 0 件
- [ ] `make type-check` が通る（該当する場合）
- [ ] テストカバレッジが [N]% 以上: `[coverage command]`

### 機能検証

- [ ] [CHECK-001] [具体的な機能条件1]: 検証コマンド `[command]`
- [ ] [CHECK-002] [具体的な機能条件2]: 検証コマンド `[command]`
- [ ] [CHECK-003] [具体的な機能条件3]: 検証コマンド `[command]`

### 非機能検証（該当する場合）

- [ ] レスポンスタイム < [N]ms: `[command to measure]`
- [ ] エラーログに想定外のエラーがない: `[command to check logs]`

---

## ブラウザ検証（Playwright MCP 使用時のみ）

> `.mcp.json` が設定されていない場合、このセクションはスキップする。

| ステップ | アクション | 期待結果 |
|---------|-----------|---------|
| 1 | `http://localhost:3000/` にアクセス | ページが表示される |
| 2 | [操作の記述] | [期待結果] |
| 3 | [操作の記述] | [期待結果] |

---

## Pass/Fail 判定基準

| 項目 | 閾値 | 必須/オプション |
|------|------|---------------|
| 自動テスト通過率 | 100% | 必須（1つでも失敗 = Fail） |
| テストカバレッジ | >= [N]% | 必須 |
| lint/format | エラー 0 | 必須 |
| 機能検証 | 全項目 Pass | 必須 |
| 非機能検証 | 全項目 Pass | 該当する場合は必須 |
| ブラウザ検証 | 全項目 Pass | オプション（MCP 設定時のみ） |

---

## Fail 時の構造化フィードバック形式

Verify Agent が Fail 判定した場合、以下の YAML 構造で Implementation Agent にフィードバックする。
テキスト 1 行の要約ではなく、修正に必要な全情報を構造化する。

```yaml
fail_feedback:
  round: N
  iteration: M
  verdict: FAIL
  failed_items:
    - id: "CHECK-001"
      category: "functional"  # functional | structural | security | architecture
      expected: "期待値を具体的に記述"
      actual: "実測値を具体的に記述"
      log_snippet: "エラー出力の抜粋（最大10行）"
    - id: "CHECK-002"
      category: "functional"
      expected: "テストカバレッジ >= 80%"
      actual: "65%"
      log_snippet: "Coverage: 65.2% (threshold: 80%)"
  fix_scope:
    - file: "src/target-file.ts"
      reason: "修正が必要な具体的理由"
    - file: "tests/target-file.test.ts"
      reason: "テストケース不足"
  instruction: "1. [具体的な修正手順1] 2. [具体的な修正手順2]"
  retry_allowed: true   # false の場合、abort して Human にエスカレーション
  same_fail_count: 1    # 同一 CHECK-ID の連続失敗回数（3 で abort）
```

### フィードバック形式のルール

- `failed_items.id` は Done Definition の CHECK-ID と一致させること
- `category` は 4 種類のいずれか: `functional`, `structural`, `security`, `architecture`
- `log_snippet` は最大 10 行。長い場合はファイルパスで参照する
- `fix_scope` には修正が許可されるファイルのみ記載する（TASK の File Scope 内）
- `instruction` は Implementation Agent が即座に実行可能な具体性で記述する
- `same_fail_count` は同一 `id` のフィードバックが連続した回数。オーケストレーターが管理する
