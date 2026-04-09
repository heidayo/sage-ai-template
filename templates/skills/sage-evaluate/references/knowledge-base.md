# 知識ベース：評価の根拠となる5ソース

採点の根拠となるソースから抽出した核心知識。

---

## ① SAGE Development System

### 7フェーズ ライフサイクル
```
Specify → Plan → Slice → Execute → Verify → Merge → Observe
```
各フェーズに Exit Criteria（終了条件）があり、すべて満たさないと次に進めない。

### Forbidden Shortcuts（AIへの絶対禁止）
- TODO/FIXME をコミットに残す
- `as unknown as T` 等の型アサーションを無断で使う
- Quality Gate をバイパスする（force push含む）
- SPEC-ID なしの PR を作る
- File Scope 外のファイルを変更する
- 同一セッションで実装とレビューを兼ねる

### トレーサビリティチェーン
```
SPEC-ID → PLAN-ID → TASK-ID → commit → PR → merge
```
すべてのコミットに TASK-ID が必要。PR には SPEC-ID, PLAN-ID, TASK-ID が必要。

### Quality Gate（5段階）
| Gate | チェック |
|------|---------|
| 1. Structural | lint, format, type check |
| 2. Functional | unit test, integration test, coverage |
| 3. Security | SAST, secret scan, dependency vuln |
| 4. Architecture | layer boundary, traceability |
| 5. Release | migration safety, rollback readiness |

---

## ② ai-development-patterns

### SPEC-ID トレーサビリティ
要件→テスト→コードの双方向追跡。

```
SPEC-0001: ログインボタンが反応しない問題を修正
// Implements: SPEC-0001
function handleLoginClick() { ... }
```

SPEC-IDがない場合の問題:
- CIで要件充足を自動確認不可
- リグレッション影響範囲の特定困難
- レビュー時にSPECとの整合性を確認できない

### failures.md パターン
AIが同じミスを繰り返さないよう失敗事例を蓄積する。

```markdown
## FAIL-001: 型エラーを any で握りつぶした
- 発生条件: 複雑な型推論が必要なケースで発生
- 対策: 型を正しく定義する。any は使わない
- 再発防止: ESLint の no-explicit-any ルールで機械的に検出
```

### Codified Rules の設計
CLAUDE.md（中央司令塔）→ `.claude/rules/`（パス別詳細）
ルールは「書いてある」だけでなく「機械で検出できる」ことが重要。

---

## ③ awesome-AIDD

### 即効性のある改善パターン
| パターン | 効果 |
|---------|------|
| TDD Guard | テストなし実装をコミット時に自動ブロック |
| cc-sdd | requirements→design→tasks ワークフローを強制 |
| Guardrails | 誤ブランチへのコミット防止・自動チェックポイント |
| pr-agent | PRのAI自動レビュー |

### 品質ゲートの自動化
手動レビューに頼る部分を可能な限り CI/hook で自動化する。
「ルールがある」と「ルールが強制される」は別物。

---

## ④ auto-dev

### Error Resolution手順
```
1. エラーログを確認し、TASK-ID を記録
2. sage/anti-patterns.md の該当パターンを参照
3. 新規パターンなら sage/failures.md に追記
4. 修正スコープを File Scope 内に限定
5. 完了条件: テスト Pass + 型エラー増加なし
6. 同じエラーが3回発生したら anti-patterns.md に昇格
```

### Observable Development
```
エラー発生 → run log に記録 → failures.md に追記
  → CLAUDE.md/rules から参照 → 次のAIが同じミスをしない
```

観測可能性のキー: すべてのエージェント実行が RUN-ID で追跡可能。

---

## ⑤ SoftwareSeni SDD

### 仕様書の品質基準
| 対象 | 推奨長さ |
|------|---------|
| バグ修正 SPEC | 100-200語 |
| 機能追加 SPEC | 300-500語 |
| アーキテクチャ変更 SPEC | 500-1000語 |
| システム設計 PLAN | 1000-2000語 |

### バイブコーディング vs 仕様駆動
- 探索・PoC・プロトタイプ → `vibe/*` ブランチ（SPEC不要）
- 本番実装・チーム開発 → SAGE ワークフロー（SPEC必須）

### 5本柱の品質ゲート
1. セキュリティ（SAST・シークレット検出）
2. テスト（カバレッジ閾値・E2E）
3. コード品質（Linting・複雑度）
4. パフォーマンス（レスポンスタイム・DBクエリ）
5. デプロイ準備（設定管理・ロギング）

### 現実的な期待値
- 学習段階でデバッグ時間増加は正常（67%の開発者が経験）
- 生産性向上の実感: 約11週間後
- ROIタイムライン: 3〜6ヶ月
