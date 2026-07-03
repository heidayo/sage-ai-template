# PLAN-0028: project_checks スタックプリセットと導入時自動検出 — 実装計画

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0028 |
| SPEC-ID   | SPEC-0028 |
| ステータス | Draft |
| 作成日    | 2026-07-02 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（installer generator / install.sh の引数解析・config 生成経路）
- [ ] frontend
- [x] infra（install.sh 再生成 + SHA256SUMS 更新の配布経路 — SPEC-0018 フロー非破壊）
- [x] test（templates/hooks/tests/ の integration テスト + golden fixture）

このリポジトリはシェルスクリプト製テンプレートであり、アプリケーションレイヤ (controller/usecase/domain) は非該当。

## 影響範囲

SPEC-0028 実装メモの File Scope と 1:1 対応:

| ファイル | 影響内容 | 担当TASK |
|---------|---------|----------|
| `templates/project-checks/go.yaml`（新規） | Go プリセット（5 キー: lint/format/type_check/test_command/coverage_command） | TASK-0192 |
| `templates/project-checks/ts-pnpm.yaml`（新規） | TypeScript/pnpm プリセット（同 5 キー） | TASK-0192 |
| `templates/project-checks/node-npm.yaml`（新規） | Node/npm プリセット（同 5 キー） | TASK-0192 |
| `templates/project-checks/python.yaml`（新規） | Python プリセット（同 5 キー） | TASK-0192 |
| `scripts/generator/01-templates.sh` | プリセット埋め込み（配置は 02 と実装時に判断、いずれか一方） | TASK-0193 |
| `scripts/generator/02-config.sh` | TMPL_CONFIG の project_checks セクション置換ロジック | TASK-0193 |
| `scripts/generator/07-installer-main.sh` | `--stack` 解析（許可リスト完全一致）+ マーカー自動検出 + INFO 出力 + dry-run 分岐 | TASK-0194 |
| `install.sh` | 再生成のみ（手動編集禁止） | TASK-0195 |
| `SHA256SUMS` | install.sh 再生成に追随 | TASK-0195 |
| `templates/hooks/tests/test-stack-presets.sh`（新規） | AC-01〜08 の integration テスト（**Test Agent 責務**） | TASK-0196 |
| `templates/hooks/tests/fixtures/project-checks-default.golden`（新規） | AC-05 baseline fixture（変更前 install.sh の生成物から固定） | TASK-0196 |
| `templates/hooks/tests/run-tests.sh` | 登録行のみ（自動 discovery なら変更不要 — Test Agent 責務） | TASK-0196 |
| `docs/stack-presets.md`（新規） | プリセット一覧・選択手順・優先順位・カスタマイズ方法（日本語） | TASK-0197 |
| `README.md` | docs/stack-presets.md への参照追記のみ | TASK-0197 |

上記以外の変更は禁止（AP-03 Silent Scope Expansion）。本リポジトリの `.sage/config.yaml`（AC-11）/ `AGENTS.md` / `docs/codex-*.md` / `sage/` / `CLAUDE.md` は特に不可。CLAUDE.md §9.1 への追記は Human follow-up として PR 本文に追記案のみ記載する。

## 実装方針

- プリセットの実体は `templates/project-checks/` の 4 ファイルのみとし、install.sh 内の埋め込みは generator による派生物とする（INV-06、二重管理 drift 禁止）。
- プリセット適用は `scripts/generator/07-installer-main.sh` の `write_file_if_new ".sage/config.yaml" "$TMPL_CONFIG"`（:732 付近）直前の `project_checks:` セクション境界のみの置換として実装する（最小介入・POST-01 置換の局所性）。既存 config.yaml の保護は `write_file_if_new` の現行 preserve 挙動をそのまま利用し、テストで確認する（INV-01）。
- `--stack` 引数は許可リスト（go/ts-pnpm/node-npm/python）との完全一致比較のみで分岐する。値をパス連結・コマンド評価する経路は作らない（SEC-01/INV-03）。未知値は usage を stderr に出し exit 非0・書き込みゼロ（FR-03）。
- 自動検出はマーカーファイルの存在チェック（`[ -f ]` 定数回）のみ。優先順位 go > ts-pnpm > node-npm > python。ファイル内容は読み取らない（SEC-02/PRE-02）。検出結果・採用理由を INFO 出力する（POST-02、Invisible Development 回避）。
- 検出不能時は現行の未設定テンプレート（commented examples）を書き込み、出力・exit code とも変更前と完全同一（NFR-01/INV-02、AC-05 golden fixture で機械検証）。
- `--dry-run` 判定はプリセット適用を含む全書き込みに先行して評価する（PRE-03/FR-07）。
- generator 変更 → install.sh 再生成 → SHA256SUMS 更新は専用 TASK・単独コミット（FAIL-0002 教訓、AC-09 で機械検証）。
- プリセットのコマンド内容は config.yaml の既存 commented examples + SPEC-0008 Go 実績値ベースの標準ツールチェーンのみ（golangci-lint 等の追加ツール前提を置かない）。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0192 | プリセット 4 ファイル `templates/project-checks/` 新設（T1） | Implementation | 1h | none | Yes（起点） |
| TASK-0193 | generator: プリセット埋め込み + project_checks セクション置換関数（T2） | Implementation | 2h | TASK-0192 | Yes（TASK-0197 と並列可） |
| TASK-0194 | generator: `--stack` 解析 + 自動検出 + INFO + dry-run 分岐（T3） | Implementation | 3h | TASK-0193 | Yes（TASK-0197 と並列可） |
| TASK-0195 | install.sh 再生成 + SHA256SUMS 更新（T4、**専用 TASK・単独コミット** = FAIL-0002） | Implementation | 0.5h | TASK-0194 | No |
| TASK-0196 | test-stack-presets.sh 追加 + golden fixture 作成 + run-tests.sh 登録（T5、**Test Agent 責務・別セッション**） | Test | 3h | TASK-0195 | No |
| TASK-0197 | docs/stack-presets.md 新規 + README 参照追記（T6） | Implementation | 1h | TASK-0192 | Yes |

実行順: TASK-0192 → TASK-0193 → TASK-0194 → TASK-0195 → TASK-0196。TASK-0197 は TASK-0192 完了後に並列可（File Scope は他 TASK と互いに素）。

**全 TASK 横断制約（AC-11）**: いずれの TASK も本リポジトリの `.sage/config.yaml` を変更してはならない（`git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0 であること）。各 TASK の禁止事項に明記し、PR レビューで最終確認する。

## リスク

- リスク1: 自動検出の誤判定（ツール置き場の go.mod 等）で意図しないプリセットが適用される → 軽減策: 検出マーカーと採用理由を INFO で明示（TASK-0194）、docs に `--stack` 上書き手順とカスタマイズ方法を記載（TASK-0197）。適用は新規 install 時のみで既存設定は壊さない
- リスク2: generator 再埋め込み漏れでテンプレートと install.sh 内プリセットが乖離する（FAIL-0002 再演） → 軽減策: 再生成 + SHA256SUMS 更新を専用 TASK-0195 に分離し単独コミット。AC-09 で機械検証、AC-01 で形式検証
- リスク3: プリセットコマンドが導入先ツールバージョンで動かない（pnpm 未導入で ts-pnpm 検出等） → 軽減策: 実行検証はスコープ外と明示（SPEC）。Gate 実行時に FAIL/SKIPPED で自然に顕在化。docs に前提ツールを記載（TASK-0197）
- リスク4: `project_checks` セクション置換が他の行に差分を出す（TMPL_CONFIG 破壊） → 軽減策: 置換は `project_checks:` セクション境界のみを対象とし（TASK-0193）、AC-05 の golden fixture diff（非検出時バイト同一）で機械検証（TASK-0196）
- リスク5: golden fixture を変更後の install.sh から生成してしまい後方互換検証が自己言及になる（AP-07 類型） → 軽減策: fixture は**変更前**（main の install.sh）の生成物から固定することを TASK-0196 の完了条件に明記

## 必要な検証

- [ ] unit test — N/A（対象がシェルスクリプトのため非適用。SPEC 検証方針準拠）
- [x] integration test — `templates/hooks/tests/test-stack-presets.sh`（AC-01〜08、想定エラー1〜3・境界ケース1〜3 全件）+ `run-tests.sh` 全件（AC-10）
- [x] security scan — `--stack` 許可リスト完全一致・パス連結不使用（SEC-01/INV-03）、導入先ファイル内容の非転記（SEC-02/INV-04）、SHA256SUMS 検証フロー非破壊（SEC-03/INV-05）、Gate 3
- [ ] e2e test — N/A（Web アプリケーションではない。installer 実行検証は integration テストで担保）
- [x] architecture boundary check — File Scope 遵守 + AC-11 本リポジトリ config.yaml 非変更（Gate 4）、プリセット実体の単一管理（INV-06）
