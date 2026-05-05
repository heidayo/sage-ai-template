# SPEC-XXXX: [タイトル]

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-XXXX |
| ステータス | Draft / Review / Approved / Implemented / Deprecated |
| 作成日    | YYYY-MM-DD |
| 更新日    | YYYY-MM-DD |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-YYYY（なければ "none"） |
| 権限レベル | system / platform / feature |

## 背景・目的

なぜこの変更を行うのか。どんな課題があるのか。

## 対象ユーザー

誰に影響するのか。

## スコープ（含む）

何を変えるか。変更対象を箇条書きで明示。

- 変更対象1
- 変更対象2

## スコープ外（明示的に除外）

何を変えないか。意図的に除外する範囲。
「なし」は不可 — 意識的に除外範囲を記述すること。

- 除外対象1
- 除外対象2

## 要件

### 機能要件
- [FR-01] ...
- [FR-02] ...

### 非機能要件
- [NFR-01] パフォーマンス: ...
- [NFR-02] 可用性: ...

### セキュリティ要件
- [SEC-01] ...
（「該当なし」の場合は理由を付記すること）

### 運用要件
- [OPS-01] ...

## 受け入れ条件（Acceptance Criteria）

コマンドまたはテストで検証可能な条件を記述。最低3件。

- [ ] AC-01: `make test` が全件パスする
- [ ] AC-02: `make lint` でエラーが0件
- [ ] AC-03: [具体的な業務条件]

## 異常系

最低1件定義すること。

- 想定エラー1: ...
- 想定エラー2: ...
- 境界ケース1: ...

## 契約

- API: OpenAPI spec path / なし
- DB: migration path / なし
- イベント: schema path / なし

## リスク

- リスク1: ... → 軽減策: ...

## 実装メモ（Implementation Agent向け）

実装時に参考にすべき既存コード・パターン・制約。

## Properties

SPEC が満たすべき意味論的性質を declarative に列挙する。Verify / Review phase で機械的に proof-attempt が行われる (SPEC-0024 / governance §11)。

権限レベル別の下限:
- `system` / `platform` + Security 要件あり: 5 件以上必須
- `platform` (Security 要件なし): 3 件以上推奨
- `feature` (低リスク): 任意、`Properties: not applicable + 理由` 許容

各 Property に Gate mapping `(Gate N)` を必須記入 (N = 2: Functional / 3: Security / 4: Architecture / 横断)。

### Invariants
- [INV-01] (Gate N) <常に成立すべき不変条件>

### Pre-conditions
- [PRE-01] (Gate N) <関数 / API 入口の前提条件>

### Post-conditions
- [POST-01] (Gate N) <関数 / API 出口の保証条件>

### Assumptions
- [ASM-01] (Gate 横断) <仕様外の前提 (環境 / ツール)>

## 関連ID

- PLAN-ID: （計画フェーズで記入）
- TASK-ID: （分割フェーズで記入）
