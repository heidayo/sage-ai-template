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
