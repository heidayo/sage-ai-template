# SAGE 開発フロー

## 全体フロー

```
1. Specify  →  2. Plan  →  3. Slice  →  4. Execute  →  5. Verify  →  6. Merge  →  7. Observe
```

## 具体例: ユーザー認証機能の追加

### Step 1: Specify
```
SPEC-0042: ユーザー認証機能
- 目的: メールアドレスとパスワードによるログイン機能を提供
- スコープ: ログインAPI、トークン発行、認証ミドルウェア
- スコープ外: パスワードリセット、OAuth、2FA
- 受け入れ条件:
  - [ ] POST /api/auth/login が200を返す（正常系）
  - [ ] 不正パスワードで401を返す
  - [ ] make test が全件パス
- 異常系: レート制限超過、アカウントロック
```

### Step 2: Plan
```
PLAN-0042: ユーザー認証実装計画
- SPEC: SPEC-0042
- 変更レイヤ: controller, usecase, domain, infrastructure
- タスク分解:
  - TASK-0101: domain/auth entity + repository interface
  - TASK-0102: infrastructure/auth repository implementation
  - TASK-0103: usecase/auth login flow
  - TASK-0104: controller/auth handler + OpenAPI
  - TASK-0105: テスト作成（全レイヤ）
```

### Step 3: Slice
各TASKに単一責務・File Scope・完了条件を定義。
TASK-0101～0103は並列可能、0104は0101-0103に依存。

### Step 4: Execute
- Implementation Agent が TASK-0101 から着手
- コミットメッセージ: `feat: add auth domain entity [TASK-0101]`
- File Scope: `src/domain/auth/`

### Step 5: Verify
- Gate 1: lint + type check → PASS
- Gate 2: unit test coverage 85% → PASS
- Gate 3: secret scan → PASS
- Gate 4: traceability → SPEC-0042, TASK-0101 確認 → PASS

### Step 6: Merge
- Review Agent がレビュー完了
- 全Gate通過を確認
- PRマージ

### Step 7: Observe
- デプロイ後にログイン成功率を監視
- 認証エラーの頻度を記録
- 問題があれば sage/failures.md に記録
