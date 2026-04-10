# SPEC-0002: Gate Enforcement化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0002 |
| ステータス | Draft |
| 作成日    | 2026-04-10 |
| 更新日    | 2026-04-10 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0001 |
| 権限レベル | system |

## 背景・目的

SAGEの品質ゲート（Gate 1-5）は `sage/quality-gates.md` で「すべてのゲートはCIで自動実行され、マージ前に通過が必須」と定義されている。しかし現状の5つのCI workflowはすべてadvisory-only（助言のみ）である。

具体的な問題:

- **Gate 1** (`sage-structural-gate.yml`): lint/format/type-check が行28-61で全てコメントアウト。`sage-validate.sh` のみ実行
- **Gate 2** (`sage-functional-gate.yml`): 行55-58で echo のみのプレースホルダー。テストが1件も走らず success を返す（偽PASS）
- **Gate 4** (`sage-architecture-gate.yml`): 行69でステータスを `'WARN'` に設定するのみ。errors > 0 でもジョブは success で終了
- **Gate 5** (`sage-release-gate.yml`): Gate 1-4 の通過をチェックリスト表示するが、workflow ステータスを参照していない
- **Gate 3** (`sage-security-gate.yml`): Gitleaks が `continue-on-error: false` で比較的正しく動作

この状態はSAGEの原則5「ルールは実行可能でなければならない」（`sage/governance.md` 行17）および AP-06「Human-Only Guard」（`sage/anti-patterns.md` 行98-109）に違反している。

## 対象ユーザー

SAGEテンプレートを使って新規プロジェクトを立ち上げる開発チーム。SAGEテンプレート自身のメンテナ。

## スコープ（含む）

- `.github/workflows/sage-structural-gate.yml` -- `.sage/config.yaml` の `project_checks.lint` / `format` / `type_check` を参照し、設定があれば実行、未設定なら明示的 SKIP とする仕組みの追加
- `.github/workflows/sage-functional-gate.yml` -- echo プレースホルダーを削除し、`.sage/config.yaml` の `project_checks.test_command` を参照するランナーに置換。未設定時は SKIPPED メッセージで明示的スキップ
- `.github/workflows/sage-architecture-gate.yml` -- トレーサビリティ違反時の exit code を 0 から 1 に変更
- `.github/workflows/sage-release-gate.yml` -- Gate 1-4 の workflow 実行結果を GitHub API で取得し、全 PASS を前提条件とするステップの追加
- `.github/workflows/sage-security-gate.yml` -- 現状の enforcement 確認と必要に応じた修正
- `.sage/config.yaml` -- `project_checks` セクションの追加
- PRコメントの status 表示 -- SKIPPED 状態を PASS/FAIL と区別して表示

## スコープ外（明示的に除外）

- 言語固有の lint/test ツールのインストール・設定（各プロジェクトの責務）
- Branch protection の自動設定（GitHub API経由の設定は SPEC-0001 でもスコープ外）
- `.sage/config.yaml` のスキーマバリデーション自動化（SPEC-0004 の sage-doctor.sh で対応予定）
- Gate 3 への SAST (CodeQL/Semgrep) 追加（現状 Gitleaks + Trivy で十分。追加は別SPEC）
- CI ワークフローの matrix build 対応（単一環境前提）

## 要件

### 機能要件
- [FR-01] Gate 1: `.sage/config.yaml` に `project_checks.lint` が定義されている場合、その値をシェルコマンドとして実行し、失敗時に exit 1 とする。`format`, `type_check` も同様
- [FR-02] Gate 1: `project_checks.lint` / `format` / `type_check` が未定義の場合、"SKIPPED: {check_name} not configured" をログ出力し、gate 全体は sage-validate.sh の結果のみで判定する
- [FR-03] Gate 2: `.sage/config.yaml` に `project_checks.test_command` が定義されている場合、その値を実行する。未定義の場合は "SKIPPED: test_command not configured in .sage/config.yaml" を出力し、PRコメントには SKIPPED と表示する
- [FR-04] Gate 4: `steps.trace.outputs.errors` が 0 より大きい場合、`exit 1` で失敗させる。PRコメントのアイコンを WARN から FAIL に変更する
- [FR-05] Gate 5: GitHub Actions API を使い、同一 PR の Gate 1-4 最新 run の conclusion を取得する。いずれかが failure の場合、Gate 5 を失敗させる。skipped は許容する
- [FR-06] Gate 1/2 のPRコメントに PASS / FAIL / SKIPPED の3状態を区別して表示する

### 非機能要件
- [NFR-01] 言語非依存: workflow YAML に特定言語の設定をハードコードしない。すべて `.sage/config.yaml` 経由で設定する
- [NFR-02] 後方互換: `.sage/config.yaml` に `project_checks` セクションが存在しない場合でもエラーにならない（未設定 = SKIP として動作する）
- [NFR-03] CI実行時間: 各ゲートの SAGE 固有処理（config.yaml 読み取り + ステータス判定）のオーバーヘッドは 10 秒以内

### セキュリティ要件
- [SEC-01] `.sage/config.yaml` の `project_checks.*` に記述されたコマンドは CI 環境内でのみ実行される。リポジトリへの push 権限がある人のみが設定変更できるため、既存の GitHub Actions trust model と同等リスク
- [SEC-02] Gate 5 で GitHub API を呼ぶ際、`GITHUB_TOKEN` のスコープは `actions:read` + `pull-requests:write` のみとする（既存と同一）

### 運用要件
- [OPS-01] `.sage/config.yaml` の `project_checks` セクションに設定例をコメントで記載する
- [OPS-02] プロジェクト固有チェックの設定手順を `docs/setup.md` に追記する

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `.sage/config.yaml` に `project_checks.test_command` を設定せずに Gate 2 workflow を実行した場合、PRコメントに "SKIPPED" と表示され、ジョブは success で終了する
- [ ] AC-02: `.sage/config.yaml` に `project_checks.test_command: "exit 1"` を設定して Gate 2 workflow を実行した場合、ジョブが failure で終了する
- [ ] AC-03: Gate 4 workflow でトレーサビリティ違反がある PR を作成した場合（SPEC-ID なし + TASK-ID なしコミット）、ジョブが failure で終了し、PRコメントに FAIL 表示がされる
- [ ] AC-04: Gate 5 workflow で Gate 1-4 のいずれかが failure の状態で実行した場合、Gate 5 も failure で終了する
- [ ] AC-05: `yq '.project_checks' .sage/config.yaml` で project_checks セクションの存在を確認できる
- [ ] AC-06: 既存の `make validate` (sage-validate.sh) が引き続き ALL PASSED を返す（回帰なし）
- [ ] AC-07: `.sage/config.yaml` が存在しない場合、Gate 2 が SKIPPED 表示（パースエラーで落ちない）
- [ ] AC-08: `.sage/config.yaml` の YAML 構文が不正な場合、Gate 2 が明示的エラーメッセージで failure

## 異常系

- `.sage/config.yaml` が存在しない場合: Gate 1/2 は全チェックを SKIP し、sage-validate.sh でエラーになる（既存動作と同一）
- `.sage/config.yaml` の YAML 構文が不正な場合: yq のパースエラーで exit 1。PRコメントに "CONFIG ERROR: .sage/config.yaml parse failed" を表示
- `project_checks.test_command` に設定されたコマンドが存在しない場合: "command not found" エラーで Gate 2 が failure
- Gate 5 で GitHub API 呼び出しが rate limit に達した場合: エラーログを出力し、Gate 1-4 チェックをスキップ（Gate 5 自体の sage-validate.sh チェックのみ実行）

## 契約

- API: GitHub Actions API (workflow runs) -- 読み取りのみ
- DB: なし
- イベント: なし

## リスク

- リスク1: `.sage/config.yaml` にコマンドインジェクションが可能 -> 軽減策: リポジトリへの push 権限がある人のみが設定変更できるため、既存の GitHub Actions trust model と同等リスク。ドキュメントに注意事項を記載
- リスク2: Gate 4 を FAIL に変更することで、既存プロジェクトの PR がブロックされる -> 軽減策: SAGE テンプレートの新規利用者に影響。既存プロジェクトは workflow を更新しない限り影響なし
- リスク3: Gate 5 の GitHub API 依存で、API の仕様変更時に壊れる -> 軽減策: actions/github-script の安定した REST API (list workflow runs) を使用

## 実装メモ（Implementation Agent向け）

- `.sage/config.yaml` のパースは `yq` コマンド（GitHub Actions ubuntu-latest にプリインストール）を使用
- Gate 1 の config 読み取りパターン: `LINT_CMD=$(yq -r '.project_checks.lint // ""' .sage/config.yaml)` で読み取り、空文字なら SKIP
- Gate 4 の修正箇所: `sage-architecture-gate.yml` の行69付近で WARN を FAIL に変更し、errors > 0 の場合に `exit 1` を追加する最終ステップを追加
- Gate 5 の API 呼び出し: `github.rest.actions.listWorkflowRunsForRepo` で同一 head_sha の run を取得
- PRコメントの SKIPPED 表示: 既存の marker コメント upsert パターン（各 workflow の末尾にある `actions/github-script`）を踏襲。ステータスに PASS / FAIL / SKIPPED の3値を追加
- 既存のコメントアウトされた言語別テンプレートは残す（ユーザーの参考情報として有用）

### CLAUDE.md追記ルール
- `.github/workflows/*.yml` の exit 0 を exit 1 に変更する際は、必ず AC 番号を commit メッセージに含める
- yq コマンドのバージョンは ubuntu-latest の標準バージョンに固定すること
- advisory-only のステップは削除せず、SKIP 状態に変換すること（機能後退禁止）
- コメントアウトされた言語別テンプレートは残す（ユーザー参考情報）

## 関連ID

- PLAN-ID: PLAN-0002
- TASK-ID: TASK-0027 〜 TASK-0034
