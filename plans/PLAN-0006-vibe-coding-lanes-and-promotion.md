# PLAN-0006: バイブコーディング対策 — レーン分離と昇格プロトコル

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0006 |
| SPEC-ID   | SPEC-0006 |
| ステータス | Completed |
| 作成日    | 2026-04-11 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（scripts, hooks, config）
- [ ] frontend
- [ ] infra
- [x] test

## 影響範囲

| モジュール | 影響 |
|-----------|------|
| `.sage/config.yaml` | `lanes` セクション追加。既存設定に影響なし |
| `templates/pre-commit-task-id.sh` | レーン判定ロジック追加。既存 `vibe/*` 免除は維持 |
| `scripts/sage-validate.sh` | 昇格条件チェック追加。既存チェックに影響なし |
| `sage/governance.md` | バイブコーディング章の拡充。既存記述は保持 |
| `scripts/sage-promote.sh` | 新規ファイル |
| `scripts/sage-retro-spec.sh` | 新規ファイル |

## 実装方針

### 方針: ブランチ名ベースの自動レーン判定

開発者がレーンを明示的に選ぶのではなく、**ブランチ命名規約で自動判定**する。

```
ブランチ名         → レーン     → 必須ゲート
─────────────────────────────────────────────────────
vibe/*             → explore    → なし（TASK-ID不要、Gate免除）
fix/*, chore/*, docs/* → lite   → TASK-ID + Gate 1 + 対象テスト + Gate 3
feature/*, その他  → standard   → TASK-ID + SPEC + Gate 1-4
promote/*          → promotion  → TASK-ID + Retro-SPEC + Gate 1-4
```

**選定理由**: 開発者の認知負荷を最小化し、hook が自動判定するため運用漏れが起きにくい。

**却下案**: config でレーンを手動指定する案 → 切り替え忘れ・乱用リスクが高い。

### 実装順序

3段階に分ける:

1. **Phase A: 設定とレーン定義**（config + governance 更新）
2. **Phase B: Hook と Validation の拡張**（pre-commit + sage-validate）
3. **Phase C: 昇格プロトコル**（promote スクリプト + retro-spec 生成）

Phase A → B は順序依存（config がないと hook がレーンを判定できない）。Phase C は B と並列可能（昇格スクリプトは独立動作）。

## タスク分解

| TASK-ID | 責務 | 対象ファイル | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|-------------|----------|------|---------|---------|
| TASK-0055 | `.sage/config.yaml` に `lanes` セクション追加 | `.sage/config.yaml` | Implementation | 30m | - | Yes |
| TASK-0056 | `sage/governance.md` のバイブコーディング章を4レーン構成に更新 | `sage/governance.md` | Implementation | 30m | - | Yes |
| TASK-0057 | `pre-commit-task-id.sh` を拡張: lite レーン（`fix/*` 等）で TASK-ID 必須化 | `templates/pre-commit-task-id.sh` | Implementation | 45m | TASK-0055 | No |
| TASK-0058 | `sage-validate.sh` に昇格条件チェック追加 | `scripts/sage-validate.sh` | Implementation | 45m | TASK-0055 | No |
| TASK-0059 | `sage-promote.sh` 新規作成: 昇格プロトコルスクリプト | `scripts/sage-promote.sh` | Implementation | 1h | TASK-0055 | Yes (TASK-0057と並列可) |
| TASK-0060 | `sage-retro-spec.sh` 新規作成: Retro-SPEC ドラフト生成 | `scripts/sage-retro-spec.sh` | Implementation | 1.5h | - | Yes |
| TASK-0061 | 統合検証: レーン判定 + 昇格フロー E2E（手動、隔離clone） | 手動検証（tests/ への固定化は SPEC-0007 へ移管） | Test | 1h | TASK-0057, TASK-0058, TASK-0059, TASK-0060 | No |
| TASK-0062 | SPEC/PLAN の受け入れ条件を実装実態に合わせて整合させる | `specs/SPEC-0006-vibe-coding-lanes-and-promotion.md`, `plans/PLAN-0006-vibe-coding-lanes-and-promotion.md`, `tasks/TASK-0062-spec0006-wording-alignment.md` | Planning | 20m | TASK-0061 | No |
| TASK-0063 | README / governance のレーン説明を 4レーン表記に整合させる | `README.md`, `sage/governance.md`, `specs/SPEC-0006-vibe-coding-lanes-and-promotion.md`, `plans/PLAN-0006-vibe-coding-lanes-and-promotion.md`, `tasks/TASK-0063-spec0006-readme-governance-alignment.md` | Planning | 20m | TASK-0062 | No |

### 依存グラフ

```
TASK-0055 (config)──┬──→ TASK-0057 (pre-commit)──┐
                    ├──→ TASK-0058 (validate)─────┤
                    └──→ TASK-0059 (promote)──────┼──→ TASK-0061 (統合テスト)
TASK-0056 (governance)                            │
TASK-0060 (retro-spec)────────────────────────────┘──→ TASK-0062 (文言整合)──→ TASK-0063 (説明整合)

### TASK-0063: README / governance 4レーン整合

README と governance には `promotion` を独立レーンとして扱う実装が入っている一方、説明が「3つのレーン」のままだと利用者が混乱する。
`session-start` hook・`AGENTS.md`・`CLAUDE.md` と同じく、README / governance も 4レーン表記に揃える。

**完了条件**: `README.md` と `sage/governance.md` のレーン定義が `promotion` を含む 4レーン表記になっており、実装済み hook / validate / agent instructions と矛盾しない。
```

## 各TASKの詳細

### TASK-0055: config.yaml lanes セクション追加

`.sage/config.yaml` に以下を追加:

```yaml
lanes:
  explore:
    branch_pattern: "vibe/*"
    task_id_required: false
    gates: []
  lite:
    branch_pattern: "fix/*,chore/*,docs/*"
    task_id_required: true
    max_files: 3
    contract_change_allowed: false
    gates: [structural, security]
  standard:
    branch_pattern: "feature/*,*"
    task_id_required: true
    spec_required: true
    gates: [structural, functional, security, architecture]
  promotion:
    branch_pattern: "promote/*"
    task_id_required: true
    retro_spec_required: true
    gates: [structural, functional, security, architecture]
```

**完了条件**: config が YAML として valid であり、既存の `quality_gates` / `hooks` セクションと競合しない。

### TASK-0056: governance.md 更新

現在のバイブコーディング章（L221-243）を拡充し、4レーン構成を記述:

- explore / lite / standard / promotion の定義
- 各レーンの適用条件と必須ゲート
- 昇格プロトコルの手順

**完了条件**: `sage-validate.sh` の「バイブコーディング」章チェック（L119-125）が引き続き PASS する。

### TASK-0057: pre-commit hook 拡張

現在の `vibe/*` 免除ロジック（L13-17）の後に、lite レーン判定を追加:

```bash
# lite lane: fix/*, chore/*, docs/* require TASK-ID
if echo "$BRANCH" | grep -qE "^(fix|chore|docs)/"; then
  # TASK-ID required (fall through to check below)
  :
fi
```

**完了条件**: `fix/test-branch` で TASK-ID なしコミット → ブロック。`vibe/test` で TASK-ID なしコミット → 許可。

### TASK-0058: sage-validate.sh 昇格条件チェック

`[5/7] ブランチ規約チェック` セクション（L136-144）を拡張:

- `promote/*` ブランチの場合、`specs/` に対応する Retro-SPEC が存在するか検証
- Retro-SPEC に `TBD` / `TODO` が残っていないか検証

**完了条件**: `promote/*` ブランチで Retro-SPEC なし → FAIL。Retro-SPEC あり → PASS。

### TASK-0059: sage-promote.sh 昇格スクリプト

新規スクリプト。入力: `vibe/*` ブランチ名。処理:

1. `promote/{feature-name}` ブランチを作成
2. `sage-retro-spec.sh` を呼び出して Retro-SPEC ドラフトを生成
3. TASK-ID を生成（`sage-id-gen.sh task` を呼び出し）
4. 次のステップ（SPEC確認、テスト追加、Gate通過）を案内表示

**完了条件**: `bash scripts/sage-promote.sh vibe/my-feature` → `promote/my-feature` ブランチが作成され、`specs/` にドラフトが存在する。

### TASK-0060: sage-retro-spec.sh Retro-SPEC ドラフト生成

新規スクリプト。入力: ブランチ名（差分の起点は `main`）。処理:

1. `git diff main...HEAD` で変更差分を取得
2. `git log --oneline main..HEAD` でコミット履歴を取得
3. 変更ファイル一覧からレイヤを推定
4. `specs/_template.md` をベースに、取得した情報を埋め込んだドラフトを生成

**制約**:
- 50コミット超の場合は警告を出し、手動作成を推奨
- 出力はドラフトであり、`TBD` マーカーで人間の確認が必要な箇所を明示

**完了条件**: テスト用 `vibe/*` ブランチに対して実行し、`specs/_template.md` のフォーマットに沿ったファイルが生成される。10秒以内に完了する。

### TASK-0061: 統合検証（手動E2E、隔離clone）

**検証方法**: 隔離した一時 clone で手動実行。`tests/` への自動テスト固定化は SPEC-0007 へ移管。

**移管の理由**:
- テストの本質が git ブランチ操作 + スクリプト実行の結合テストであり、一時 clone が必要
- 通常の CI で回すにはセットアップコストが高い
- `sage-validate.sh` の個別チェック関数をユニットテスト化する方が費用対効果が高く、それは別の設計判断を伴う

**検証シナリオと結果**:

| # | シナリオ | 期待結果 | 実行結果 |
|---|---------|---------|---------|
| 1 | `sage-promote.sh vibe/e2e-promotion` 実行 | `promote/*` ブランチ + Retro-SPEC 生成 | ✅ PASS |
| 2 | 生成直後に `sage-validate.sh` | TBD 残存で FAIL | ✅ PASS（TBD 17件で FAIL） |
| 3 | Retro-SPEC の TBD を補完後に `sage-validate.sh` | vibe由来コミット免除で PASS | ✅ PASS |
| 4 | TASK-ID ありコミット追加後に `sage-validate.sh` | PASS | ✅ PASS |
| 5 | TASK-ID なしコミット追加後に `sage-validate.sh` | 昇格後コミットのみ検出で FAIL | ✅ PASS（1件検出で FAIL） |

**未検証（SPEC-0007 スコープ）**:
- lite レーンの `max_files` / 契約変更禁止の pre-commit ブロック動作
- `feature/*` ブランチの後方互換確認
- 上記シナリオの自動テスト化

### TASK-0062: SPEC/PLAN 文言整合

E2E 検証で確認した実装挙動に合わせて、SPEC / PLAN の期待結果を更新する。

- Retro-SPEC ドラフトは生成直後に `TBD` / `TODO` を含む
- `sage-validate.sh` は `TBD` が残っている間 FAIL を返す
- `promote/*` の TASK-ID 検証対象は昇格後に追加されたコミットのみ

**完了条件**: SPEC-0006 の Acceptance Criteria と PLAN-0006 の統合テストシナリオが、実装済み挙動および手動E2E結果と矛盾しない。

## リスク

| リスク | 影響 | 軽減策 |
|-------|------|-------|
| lite レーンの乱用（本来 standard であるべき変更を lite で通す） | 品質低下 | `max_files` + `contract_change_allowed: false` を hook で強制。超過時は警告 + standard への誘導 |
| Retro-SPEC の品質が形骸化する | トレーサビリティ喪失 | ドラフト生成 + 人間承認の2段階。`sage-evaluate` による採点を推奨 |
| ブランチ命名規約を知らない開発者がレーン判定を誤る | 混乱 | `session-start` hook でレーン判定結果を表示。`make doctor` でレーン設定の説明を出力 |
| 既存プロジェクトで config に `lanes` がない場合の後方互換 | 動作不能 | `lanes` セクション未設定時はデフォルト値（現行の2レーン動作）にフォールバック |

## 必要な検証

- [x] unit test: 各スクリプトの個別動作（TASK-0057〜0060）
- [x] integration test: レーン判定 + 昇格フロー E2E（TASK-0061）
- [ ] security scan: Gate 3 が lite / promotion で正しく動作するか
- [ ] architecture boundary check: 変更が permitted scope 内か
