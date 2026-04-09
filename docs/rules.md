# SAGE アーキテクチャルール

このファイルは非交渉のルールを定義する。AIエージェントはこのルールに従わなければならない。

## 構造ルール

1. **仕様なしの実装禁止** — すべての変更はSPEC-IDに紐づく
2. **1タスク1責務** — 複数レイヤ・複数目的を1タスクに含めない
3. **レイヤ境界の尊重** — 内側のレイヤが外側に依存しない
4. **生成コードの手動修正禁止** — 生成物は再生成で更新する
5. **CI未通過のマージ禁止** — 品質ゲートをバイパスしない

## 依存方向

```
controller → usecase → domain ← infrastructure
```

- domain は純粋で、外部依存を持たない
- infrastructure は domain のインタフェースを実装する
- controller は軽量で、ビジネスロジックを持たない

## ファイル命名規則

| 種類 | パターン |
|------|---------|
| 仕様 | `specs/SPEC-XXXX-<description>.md` |
| 計画 | `plans/PLAN-XXXX-<description>.md` |
| タスク | `tasks/TASK-XXXX-<description>.md` |
| 実行ログ | `.sage/runs/RUN-XXXX.yaml` |

## コミットメッセージ

```
<type>: <description> [TASK-XXXX]
```

type: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`

## 禁止事項

- TODO/FIXMEを残したままのコミット
- SPEC-IDなきPRの作成
- テスト省略
- force push（明示的承認なし）
- スコープ外ファイルの変更
