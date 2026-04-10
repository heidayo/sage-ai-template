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

---

## サブエージェント呼び出しパターン（Agent Tool）

### なぜコンテキスト分離が必要か

SAGE では実装エージェントとレビューエージェントを別セッションで実行することを要求している（CLAUDE.md Section 6）。これは単なるルールではなく、以下の技術的理由に基づく:

1. **AI Monolith アンチパターンの防止**: 1つのセッションで仕様策定・実装・レビュー・テストを行うと、自分で作ったコードを自分で評価することになり、判定が甘くなる
2. **コンテキスト汚染の防止**: 実装時の大量のデバッグログやエラー出力がレビュー時の判断を歪める。逆に、仕様の詳細な議論が実装の選択肢を不要に制約する
3. **トークン予算の保護**: 長時間セッションではコンテキストが膨張し、初期の仕様や受け入れ条件が押し出されて見えなくなる（context anxiety）

### Agent Tool の基本

Claude Code の Agent tool は独立したサブコンテキストを作成する:

- サブエージェントは専用のコンテキストウィンドウを持つ
- 親セッションの履歴はサブエージェントに渡らない（真の分離）
- サブエージェントの実行結果のみが親に返される
- 大量の探索ログやテスト出力がメインコンテキストを汚さない

### 具体的な呼び出し例

#### 例1: Spec Agent の呼び出し

```
Agent tool を使用:
prompt: "あなたは Spec Agent です。
  .claude/prompts/spec-agent.md を読み、その役割定義に従ってください。
  
  以下の要求に基づいて SPEC を作成してください:
  [ユーザーの要求をここに記述]
  
  手順:
  1. bash scripts/sage-id-gen.sh spec で SPEC-ID を生成
  2. specs/_template.md をコピーして SPEC ファイルを作成
  3. 全セクションを埋める
  
  出力: SPEC-ID とファイルパスを報告"
```

#### 例2: Implementation Agent の呼び出し（フィードバック付き再実行）

```
Agent tool を使用:
prompt: "あなたは Implementation Agent です。
  .claude/prompts/implementation-agent.md を読み、その役割定義に従ってください。
  
  TASK: tasks/TASK-0101-auth-entity.md を実装してください。
  SPEC: specs/SPEC-0042-user-auth.md
  PLAN: plans/PLAN-0042-auth-implementation.md
  
  【前回の Verify フィードバック】
  - CHECK-001: テストカバレッジ 65%（閾値 80%）
  - 修正スコープ: tests/auth/login.test.ts
  - 修正指示: 401応答のテストケースを追加
  
  File Scope: src/domain/auth/, tests/domain/auth/
  コミットメッセージに TASK-0101 を含めてください。"
```

#### 例3: Verify Agent の呼び出し

```
Agent tool を使用:
prompt: "あなたは Verify Agent です。
  .claude/prompts/review-agent.md と .claude/prompts/test-agent.md を読んでください。
  
  【ツール制限】Read と Bash のみ使用可。Write/Edit 禁止。
  
  検証対象:
  - SPEC: specs/SPEC-0042-user-auth.md
  - Done Definition: tasks/done-def-SPEC-0042-round-1.md
  
  検証内容:
  1. make lint（Gate 1）
  2. make test + カバレッジ確認（Gate 2）
  3. File Scope 遵守確認（Gate 4）
  
  結果を Pass/Fail で報告。Fail の場合は構造化フィードバック YAML で報告。"
```

### ハーネスパターン（推奨ワークフロー）

上記の手動呼び出しを自動化したものが `/sage-harness` スキルです。

```
/sage-harness
ユーザー認証機能を追加してください。
```

これにより、Specify → Plan → Execute → Verify が自動でループし、人間は最初の要求と最終承認のみ担当します。

詳細: `templates/skills/sage-harness/SKILL.md`

### サブエージェント呼び出しのアンチパターン

| アンチパターン | 問題 | 正しい方法 |
|--------------|------|-----------|
| コンテキストの渡しすぎ | プロンプトにファイル内容を全文貼り付けると、サブエージェントのコンテキストを圧迫する | ファイルパスを渡し、サブエージェント内で Read させる |
| コンテキストの渡さなすぎ | SPEC-ID や File Scope なしで「実装して」と指示すると、スコープが曖昧になる | SPEC/PLAN/TASK のファイルパスと File Scope を必ず含める |
| 同一セッションで実装+レビュー | AI Monolith。自己採点が甘くなる | 必ず別の Agent tool 呼び出しで分離する |
| フィードバック無視 | Verify の結果を読まずに次のイテレーションを実行 | 前回の構造化フィードバックを必ず次の Execute プロンプトに含める |
| Verify Agent にコード修正を依頼 | 役割の越境。レビュアーが実装を兼ねる | Verify は報告のみ。修正は Implementation Agent に差し戻す |
