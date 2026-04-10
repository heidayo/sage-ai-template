# SAGE セットアップガイド

## 前提条件

- Git
- Bash (macOS / Linux / WSL)
- GitHub Actions（CI用）

## 新規プロジェクトの場合

1. このテンプレートをクローンまたはフォーク:
   ```bash
   git clone https://github.com/your-org/sage-ai-template.git my-project
   cd my-project
   ```

2. `CLAUDE.md` をプロジェクト固有の内容に編集

3. `src/` と `tests/` にアプリケーションコードを配置

4. `.sage/config.yaml` の閾値を調整（必要に応じて）

## 既存リポジトリへの適用

```bash
# Phase A: Foundation（非破壊）
bash scripts/sage-adopt.sh
```

このスクリプトは:
- `specs/`, `plans/`, `tasks/`, `sage/`, `.sage/` ディレクトリを作成
- テンプレートファイルをコピー（既存ファイルは上書きしない）
- `.gitignore` に `.sage/runs/` と `.sage/metrics/` を追加
- 既存ファイルを一切変更しない

## 導入フェーズ

### Phase A: Foundation
最小限の仕組みを入れる。

チェックリスト:
- [ ] `CLAUDE.md` を作成・編集
- [ ] `sage/charter.md` を確認
- [ ] `specs/_template.md` でSPECを書き始める
- [ ] `.gitignore` を更新
- [ ] 最初のSPEC（SPEC-0001）を作成

### Phase B: Guardrails
品質ゲートを設定する。

チェックリスト:
- [ ] `.github/workflows/sage-structural-gate.yml` を設定
- [ ] `.github/workflows/sage-security-gate.yml` を設定
- [ ] `.github/pull_request_template.md` を配置
- [ ] `sage/anti-patterns.md` を確認

### Phase C: Multi-Agent
エージェント分業を開始する。

チェックリスト:
- [ ] `.claude/prompts/` にエージェントプロンプトを配置
- [ ] 実装AIとレビューAIを分離
- [ ] `scripts/sage-validate.sh` を実行できることを確認

### Phase D: Learning System
学習サイクルを回す。

チェックリスト:
- [ ] `sage/failures.md` に失敗を記録し始める
- [ ] メトリクスを計測し始める
- [ ] 3回以上繰り返す失敗を `sage/anti-patterns.md` に昇格

## プランモードについて

Claude Code や Codex にはプランモード（実装前にアプローチを設計・承認するモード）がありますが、**SAGE はプランモードなしでも動作します**。

### なぜプランモードが不要か

SAGE の `/sage-harness` は Agent tool によるサブエージェント分離を採用しています:

- **Spec Agent** が仕様を作成 → ファイルに書き出し
- **Evaluator** が採点 → フィードバックをファイルで返却
- **Implementation Agent** がタスクを実装
- **Verify Agent** が検証

各エージェントは独立したコンテキストで動作し、ファイルを介してデータを受け渡します。プランモードのように「計画→承認→実行」のフローをツール内部で実現しているため、IDE 側のプランモード機能に依存しません。

### 使い分け

| 状況 | 推奨 |
|------|------|
| `/sage-harness` で自動ループ | プランモード不要（ハーネスが制御） |
| 手動で `/sage-spec` → `/sage-plan` → 実装 | プランモードを使ってもよい（任意） |
| 小規模な修正・プロトタイプ | どちらでも可 |

### プランモードを併用する場合

プランモードと SAGE を併用しても競合しません。プランモードは IDE レベルの承認フロー、SAGE は仕様レベルの品質ゲートとして、別レイヤで機能します。

## 検証

```bash
# CLAUDE.md構造 + テンプレートフィールド検証
make validate

# トレーサビリティチェック
make trace-check

# 次のID生成
make id-gen TYPE=spec
make id-gen TYPE=plan
make id-gen TYPE=task
```

## 運用判断の5問

迷った時はこの順で判断:

1. **仕様はあるか** — なければ Specify フェーズへ
2. **責務は切れているか** — なければ Slice フェーズへ
3. **ルールで止められるか** — なければルールをCIに落とす
4. **検証で落とせるか** — なければゲートを追加
5. **追跡できるか** — なければトレーサビリティを整備
