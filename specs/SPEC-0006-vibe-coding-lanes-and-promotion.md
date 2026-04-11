# SPEC-0006: バイブコーディング対策 — レーン分離と昇格プロトコル

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0006 |
| ステータス | Draft |
| 作成日    | 2026-04-11 |
| 更新日    | 2026-04-11 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0002（Gate Enforcement）, SPEC-0003（Hooks実用化） |
| 権限レベル | system |

## 背景・目的

現在のSAGEは本番コード（7フェーズ全実施）とバイブコーディング（`vibe/*` ブランチで完全免除）の二択構造になっている。governance.md に事後SPEC・昇格ゲートの方針は記載されているが、以下のギャップが存在する:

1. **中間レーンの不在**: 1ファイル修正やtypo fix にもフルSPECを要求するか、完全に免除するかの二択
2. **昇格プロトコルの未制度化**: `vibe/*` → 本番への変換手順が文書上のルールのみで、enforcement がない
3. **探索成果の回収手段なし**: バイブコーディングの成果物から仕様を逆生成する仕組みがない

`vibe/*` の pre-commit hook は TASK-ID を免除しており（`templates/pre-commit-task-id.sh:13-16`）、`sage-validate.sh` はブランチ規約違反の検出のみで昇格条件の検証は行っていない。`.sage/config.yaml` の `minimal/standard/strict` は導入フェーズの段階設計であり、変更リスクに応じたレーン分けではない。

本SPECは「バイブコーディングを禁止する」のではなく、「探索を正式開発へ変換する昇格プロトコル」を制度化する。

## 対象ユーザー

- SAGE テンプレートを利用するソロ開発者・チーム
- AI エージェント（Implementation Agent, Review Agent）
- CI/CD パイプライン

## スコープ（含む）

- 3レーン定義の導入（explore / lite / standard）
- `lite` レーンの適用条件・必須ゲートの定義
- `vibe/*` ブランチからの昇格プロトコル（Promotion Gate）の制度化
- Retro-SPEC ドラフト自動生成の仕組み
- pre-commit hook への lite レーン対応追加
- `sage-validate.sh` への昇格条件チェック追加
- `.sage/config.yaml` へのレーン設定追加
- `governance.md` のバイブコーディング章の更新

## スコープ外（明示的に除外）

- `minimal/standard/strict` hook プロファイルの再設計（SPEC-0003 の管轄、本SPECはレーン分離のみ）
- CI/CD ワークフロー（`.github/workflows/`）の実装（本SPECはスクリプト・hook・設定の変更まで）
- Retro-SPEC の完全自動承認（ドラフト生成まで、正式化は人間承認）
- 既存の Gate 1-5 の閾値変更
- `vibe/*` ブランチ内の開発ワークフロー自体への介入

## 要件

### 機能要件

- [FR-01] `.sage/config.yaml` に `lanes` セクションを追加し、`explore` / `lite` / `standard` の3レーンを定義できる
- [FR-02] `lite` レーンの適用条件を設定可能にする:
  - 変更ファイル数上限（デフォルト: 3）
  - 公開契約（API/DB/イベント）変更の禁止
  - 対象ブランチパターン（デフォルト: `fix/*`, `chore/*`, `docs/*`）
- [FR-03] `lite` レーンのコミットは `TASK-ID` を必須とし、Gate 1（lint + format + type check）+ 対象テストの通過を要求する
- [FR-04] `vibe/*` ブランチから本番ブランチへの昇格時、以下を強制する:
  - 新しい管理ブランチ（`promote/{original-branch-name}`）の作成
  - Retro-SPEC ドラフトの生成
  - TASK-ID の付与
  - Gate 1 + Gate 2（テスト）の通過
- [FR-05] Retro-SPEC ドラフト生成スクリプトを提供する。入力: diff、コミットログ、テスト結果。出力: `specs/_template.md` に沿ったドラフト
- [FR-06] `sage-validate.sh` に昇格条件チェックを追加する: `promote/*` ブランチに Retro-SPEC が存在し、TASK-ID が付与されているか検証する
- [FR-07] pre-commit hook を拡張し、`lite` レーン対象ブランチでは TASK-ID を必須とする（現状の `vibe/*` 免除はそのまま維持）

### 非機能要件

- [NFR-01] 既存のSAGEテンプレート利用者が `lite` レーンを使い始めるまでの手順が3ステップ以内
- [NFR-02] Retro-SPEC ドラフト生成は 10 秒以内に完了する（ローカル実行）
- [NFR-03] 既存の `standard` レーン（現行フル7フェーズ）の動作に影響を与えない

### セキュリティ要件

- [SEC-01] `lite` レーンでも Gate 3（secret scan + dependency vuln）は SKIPPED ではなく PASS を要求する
- [SEC-02] `explore` レーン（`vibe/*`）のコードが Gate 3 未通過のまま本番ブランチにマージされることを防止する

### 運用要件

- [OPS-01] レーン判定ログを `.sage/runs/` に記録する（どのレーンで実行されたか追跡可能）
- [OPS-02] `make doctor` でレーン設定の整合性チェックを行う

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `.sage/config.yaml` に `lanes` セクションが存在し、`explore` / `lite` / `standard` の3レーンが定義されている
- [ ] AC-02: `fix/*` ブランチで TASK-ID なしのコミットが pre-commit hook でブロックされる
- [ ] AC-03: `vibe/*` ブランチで TASK-ID なしのコミットが引き続き許可される
- [ ] AC-04: `bash scripts/sage-promote.sh vibe/my-feature` を実行すると `promote/my-feature` ブランチが作成され、Retro-SPEC ドラフトが `specs/` に生成される
- [ ] AC-05: `promote/*` ブランチで Retro-SPEC が存在しない場合、`sage-validate.sh` が FAIL を返す
- [ ] AC-06: `promote/*` ブランチのコミットに TASK-ID が含まれていない場合、pre-commit hook がブロックする
- [ ] AC-07: Retro-SPEC ドラフトが `specs/_template.md` の必須フィールドを全て含み、人間確認が必要な箇所を `TBD` / `TODO` で明示する

## 異常系

- `vibe/*` ブランチに 50 以上のコミットがある場合、Retro-SPEC のドラフト生成が不正確になる → 警告を出し、手動SPEC作成を推奨する
- `lite` レーンの適用条件を超える変更（4ファイル以上、API変更あり）を `fix/*` ブランチで行おうとした場合 → 警告を出し、`standard` レーンへの切り替えを案内する
- `promote/*` ブランチでコンフリクトが発生した場合 → 昇格スクリプトはブランチ作成まで行い、コンフリクト解決は手動に委ねる
- `.sage/config.yaml` に `lanes` セクションが存在しない場合 → デフォルト値で動作する（後方互換性）

## 契約

- API: なし
- DB: なし
- イベント: なし

## リスク

- リスク1: `lite` レーンが乱用され、本来 `standard` であるべき変更が `lite` で通される → 軽減策: `lite` の適用条件（ファイル数上限、契約変更禁止）を hook で強制する
- リスク2: Retro-SPEC の品質が低く、形式的に通過するだけになる → 軽減策: ドラフトは人間承認必須とし、`sage-evaluate` で採点する
- リスク3: 3レーン導入で認知負荷が増える → 軽減策: ブランチ名でレーンを自動判定し、開発者が明示的にレーンを選択する必要をなくす

## 実装メモ（Implementation Agent向け）

### レーン判定ロジック（ブランチ名ベース）

```
vibe/*           → explore レーン
fix/*, chore/*, docs/* → lite レーン（条件チェック付き）
feature/*,上記以外     → standard レーン
promote/*        → 昇格プロトコル（standard + Retro-SPEC 必須）
```

### 既存ファイルへの影響

| ファイル | 変更内容 |
|---------|---------|
| `.sage/config.yaml` | `lanes` セクション追加 |
| `templates/pre-commit-task-id.sh` | lite レーン対応（`fix/*` 等で TASK-ID 必須化） |
| `scripts/sage-validate.sh` | 昇格条件チェック追加 |
| `sage/governance.md` | バイブコーディング章の更新 |
| `scripts/sage-promote.sh` | 新規: 昇格プロトコルスクリプト |
| `scripts/sage-retro-spec.sh` | 新規: Retro-SPEC ドラフト生成 |
| `templates/skills/sage-promote/` | 新規: 昇格用スキル |

### Retro-SPEC ドラフト生成の入力ソース

1. `git diff main...HEAD` — 変更差分
2. `git log --oneline main..HEAD` — コミット履歴
3. テスト実行結果（あれば）
4. 変更ファイルの一覧とレイヤ推定

出力は `specs/_template.md` のフォーマットに沿い、人間が確認・修正するドラフト。自動承認はしない。

## 関連ID

- PLAN-ID: PLAN-0006
- TASK-ID: TASK-0055, TASK-0056, TASK-0057, TASK-0058, TASK-0059, TASK-0060, TASK-0061, TASK-0062, TASK-0063
