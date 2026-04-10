# SPEC-0005: テンプレート安定化 + セキュリティ是正

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0005 |
| ステータス | Implemented |
| 作成日    | 2026-04-10 |
| 更新日    | 2026-04-10 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0002, SPEC-0003, SPEC-0004 |
| 権限レベル | system |

## 背景・目的

v0.3.0 時点の `sage-ai-template` には、公開テンプレートとして無視できない問題が残っている。主なものは、GitHub Actions の安全でない PR 本文処理、フックの `hooks.profile: none` 未対応、タスク状態表記ゆれによる File Scope ガード不全、配布スキルの参照切れ、未検証な自動更新実行、文書間の権限・品質ゲート定義の矛盾である。

本SPECの目的は、互換優先で既存の利用体験を大きく変えずに、公開配布・ローカル利用・CI 実行の各面で「壊れているところ」と「危険なところ」を一括で是正することである。

## 対象ユーザー

- SAGE テンプレートをそのまま導入する利用者
- SAGE テンプレート自身をメンテナンスする開発者

## スコープ（含む）

- `.github/workflows/` の安全性と再現性改善
- `templates/hooks/` のプロファイル制御・アクティブTASK検出・File Scope 判定改善
- `scripts/` の update-check / validate / doctor / report / publish / adopt / generate-installer 改善
- `templates/skills/sage-review/` と配布先 `.claude/skills/sage-review/` の参照切れ解消
- `.sage/config.yaml`、`README.md`、`CLAUDE.md`、`AGENTS.md`、`sage/traceability.md` の整合修正
- `SPEC-0001` の受け入れ条件・関連ID・トレーサビリティ記述の是正
- 欠損している historical traceability artifact（`PLAN-0001`, `TASK-0001`〜`TASK-0026`, `done-def-*`）の補完
- remediation 用の SPEC / PLAN / TASK 追加

## スコープ外（明示的に除外）

- 過去欠損している `TASK-0001`〜`TASK-0026` の完全な履歴再構築
- `docs/setup.md` のようなユーザー作業中ファイルの上書き
- 言語固有の lint/test 設定追加
- SAGE 本体の新機能追加
- 失われた実装履歴の完全再現。補完する historical artifact は retrospective placeholder として扱う

## 要件

### 機能要件
- [FR-01] Gate 4 は PR 本文をシェル展開せずに評価し、PR 本文に heredoc 終端文字列を含めても任意コマンド実行が起きない
- [FR-02] すべての hook は `hooks.profile: none` で無効化される
- [FR-03] hook は `In Progress` / `Blocked` と `実行中` / `ブロック中` の両方をアクティブ状態として扱う
- [FR-04] `block-dangerous-commands.sh` は `git push --force` / `-f` をブロックし、`--force-with-lease` はブロックしない
- [FR-05] `sage-review` は `references/review-scoring-rubric.md` を必ず配布する
- [FR-06] `sage-update-check.sh` は未検証の remote installer を自動実行しない。更新は通知のみにする
- [FR-07] `sage-report.sh` は historical failure と recent failure を区別し、14日間 FAIL 0 件なら `READY FOR STRICT` を出力できる
- [FR-08] `sage-validate.sh` は root commit / shallow history でも Noise Diff Check で落ちない
- [FR-09] `sage-doctor.sh --check-only` は metrics 履歴を書き込まない
- [FR-10] 公開文書は gist URL、権限文書、品質ゲート定義、AGENT-ID 記録先について整合する
- [FR-11] `SPEC-0001` は現存する plan/task/done-definition artifact を参照し、受け入れ条件とステータスが実測と矛盾しない
- [FR-12] config 由来コマンドを実行する workflow は `eval "$CMD"` を使わず、専用ラッパー経由で実行する

### 非機能要件
- [NFR-01] 既存の導入フロー (`bash install.sh`, `bash scripts/sage-adopt.sh`) を維持する
- [NFR-02] フック修正は互換優先とし、既存テンプレートの状態表記を強制変更しない
- [NFR-03] GitHub Actions の third-party action は commit SHA で pin する

### セキュリティ要件
- [SEC-01] GitHub Actions で PR 本文・設定値を評価する箇所は、シェル注入を防ぐ形で扱う
- [SEC-02] 自動更新チェックは未検証の remote code execution を行わない
- [SEC-03] 開発者ローカル設定ファイル (`.claude/settings.local.json`) は repo-level ignore に含める

## 受け入れ条件（Acceptance Criteria）

- [x] AC-01: `pull_request.body` に `PRBODYEOF` を含むケースでも Gate 4 の shell step で任意コマンド実行が起きない
- [x] AC-02: `hooks.profile: none` の状態で各 hook を実行すると、block / write が発生せず exit 0 する
- [x] AC-03: `ステータス | In Progress |` の TASK を 1 件作ると、File Scope / protect hook / session-start が active TASK として認識する
- [x] AC-04: `git push --force-with-lease` を含む JSON stdin で `block-dangerous-commands.sh` が exit 0 を返す
- [x] AC-05: `.claude/skills/sage-review/references/review-scoring-rubric.md` が配布対象に含まれる
- [x] AC-06: `bash scripts/sage-update-check.sh` は新バージョン検出時に通知のみ行い、remote installer を実行しない
- [x] AC-07: `make report` は recent failure 0 件かつ十分なセッション数の状態で `READY FOR STRICT` を出力し exit 0 する
- [x] AC-08: `CI=1 bash scripts/sage-validate.sh` は root commit 履歴でも `HEAD~1` 不在で停止しない
- [x] AC-09: `bash scripts/sage-doctor.sh --check-only` 実行時に `doctor-history.jsonl` が増えない
- [x] AC-10: `README.md` と `.sage/config.yaml` の installer URL が実値に更新され、CLAUDE/AGENTS の権限文言が相互矛盾しない
- [x] AC-11: `SPEC-0001` の `PLAN-0001` / `TASK-0001`〜`TASK-0026` / AC-04 が現物と一致する
- [x] AC-12: Gate 1 / Gate 2 workflow に `eval "$CMD"` が残っていない

## 異常系

- `github.base_ref` が取得できない場合: Gate 4 はトレーサビリティチェックを fail-safe に失敗させる
- `gh` が未認証で gist 情報を更新できない場合: publish はバージョンをロールバックして終了する
- 複数の active TASK がある場合: File Scope 判定は union scope で評価する
- `.sage/config.yaml` に `hooks:` セクションがない場合: hooks は従来どおり profile default で動く

## 契約

- API: GitHub Actions workflow runner / GitHub Gist API（既存の `gh` 利用範囲内）
- DB: なし
- イベント:
  - `.sage/runs/RUN-XXXX.yaml`
  - `.sage/metrics/doctor-history.jsonl`
  - `.sage/metrics/sessions.jsonl`

## リスク

- リスク1: action の SHA pin により更新が見えづらくなる -> 軽減策: 元の tag を YAML コメントに残す
- リスク2: historical failure と recent failure の区別で `make report` の解釈が変わる -> 軽減策: README と status 表示を更新する
- リスク3: CLAUDE.md / AGENTS.md の文言調整が他ツールの期待とずれる -> 軽減策: 「ツール別の最高権限」を明示し、意味を揃える

## 残留制約

- `SPEC-0001` の `PLAN-0001` / `TASK-0001`〜`TASK-0026` は retrospective placeholder による補完であり、失われた当時の真正な実行履歴を復元したものではない
- この制約は historical artifact に限定され、現在の開発フローで新規に作成される SPEC / PLAN / TASK / RUN のチェーンには適用しない
- Gate 1 / Gate 2 の config command 実行ラッパーは non-zero exit code を正しく伝播する形まで修正済みであり、D-11 は解消済み

## 関連ID

- PLAN-ID: PLAN-0005
- TASK-ID: TASK-0054
