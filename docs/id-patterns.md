# ID 受理パターンのカスタマイズ（`.sage/id-patterns.json`）

SPEC-0027 で導入された、SAGE の ID 受理パターン（SPEC / PLAN / TASK / RUN / FAIL）を
プロジェクトごとに拡張する仕組みの設定手順です。

## 概要

- 受理判定に使う正規表現（POSIX ERE）を `.sage/id-patterns.json` に外部化しています
- `scripts/sage-id-pattern.sh`（共有ローダー）経由で、以下の 5 箇所が同一設定を参照します:
  - `scripts/sage-id-gen.sh`（連番スキャンはデフォルト形式のみ）
  - `scripts/sage-trace-check.sh`
  - `scripts/sage-validate.sh`
  - `scripts/sage-report.sh`
  - `templates/pre-commit-task-id.sh`（commit-msg hook。スタンドアロン動作用の内包 fallback あり）
- **設定ファイルが無い場合の挙動は従来と完全同一**です（後方互換）。削除すれば即座に元の挙動へ戻ります

## 書式

```json
{
  "spec": { "accept": ["SPEC-[0-9]{4}"] },
  "plan": { "accept": ["PLAN-[0-9]{4}"] },
  "task": { "accept": ["TASK-[0-9]{4}"] },
  "run": { "accept": ["RUN-[0-9]{4}"] },
  "fail": { "accept": ["FAIL-[0-9]{4}"] }
}
```

- 種別キーは `spec` / `plan` / `task` / `run` / `fail`。**全キー任意**で、欠落した種別はデフォルト（上記と同じ値）に fallback します
- `accept` は受理判定に使う ERE 文字列の配列。複数指定した場合は**いずれかにマッチすれば受理**されます（内部的に `(p1|p2)` へ合成）

### 書式の制約（重要）

パースは jq に依存せず POSIX ツール（grep/sed/awk）で行うため、**JSON の制約付きサブセット**のみをサポートします:

- **1 パターン 1 行**で書くこと（配列要素を複数行に分けるか、1 行の配列に収めること）
- パターン文字列内にバックスラッシュ（`\d` 等）を使わないこと。数字は `[0-9]`、英小文字は `[a-z]` のように POSIX ブラケット表現で書くこと
- 書式を逸脱した場合はエラーにならず、**安全側（デフォルトパターンへの fallback + stderr への WARN）**に倒れます

## 設定例: 作業者プレフィックス形式の併用

`TASK-hei-a7f3` のような「作業者プレフィックス + ハッシュ」形式の TASK-ID を併用する場合:

```json
{
  "task": {
    "accept": [
      "TASK-[0-9]{4}",
      "TASK-[a-z]+-[0-9a-f]{4}"
    ]
  }
}
```

この設定で `TASK-hei-a7f3: fix login` のような commit message が pre-commit hook /
trace-check / validate のすべてで受理されます。

## 制約: 生成はデフォルト形式のみ

**拡張できるのは「受理」のみです。生成はデフォルト形式のみ**をサポートします。

- `bash scripts/sage-id-gen.sh task` は常に `TASK-0001` 形式の次連番を返します
- カスタム形式 ID（`TASK-hei-a7f3` 等）の発番はプロジェクト側の外部運用です
- カスタム形式 ID がリポジトリに存在しても、連番採番には影響しません（無視されます）

## 推奨パターンとアンチ例

| 区分 | パターン | 理由 |
|------|---------|------|
| ✅ 推奨 | `TASK-[a-z]+-[0-9a-f]{4}` | 作業者と ID が特定でき、traceability を保てる |
| ✅ 推奨 | `TASK-[A-Z]{2,4}-[0-9]{4}` | チームプレフィックス + 連番 |
| ❌ アンチ例 | `TASK-.*` | ほぼ何でもマッチし、traceability が形骸化する |
| ❌ アンチ例 | `.*` / 空文字 | 検証の無効化。空・不正パターンは自動的に fallback される（SEC-03） |

緩すぎるパターンの受理可否は導入先の運用責任です。テンプレートのデフォルトは現行の厳格形式を維持しています。

## installer との関係（preserve-if-exists）

- `bash install.sh`（新規・更新とも）は、**既存の `.sage/id-patterns.json` を上書きしません**（preserve-if-exists、SPEC-0026 の preservation 方針と整合）
- ファイルが存在しない場合のみ、デフォルト内容が配置されます
- 共有ローダー `scripts/sage-id-pattern.sh` は SAGE 管理ファイルとして更新時に上書きされます

## トラブルシューティング

- 正規の ID が拒否される / 意図しない ID が受理される場合: `.sage/id-patterns.json` を削除（または該当種別のエントリを除去）すればデフォルト挙動へ即時復帰します
- 設定が効いていない場合: stderr の `WARN: sage-id-pattern:` メッセージを確認してください（書式逸脱時は fallback されています）

## 関連

- SPEC: `specs/SPEC-0027-id-patterns.md`
- ローダー実装: `scripts/sage-id-pattern.sh`
