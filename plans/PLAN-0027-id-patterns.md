# PLAN-0027: ID パターンの設定外部化 — 実装計画

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0027 |
| SPEC-ID   | SPEC-0027 |
| ステータス | Draft |
| 作成日    | 2026-07-02 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（bash スクリプト群 / pre-commit hook / installer generator）
- [ ] frontend
- [x] infra（install.sh 再生成 + SHA256SUMS 更新の配布経路）
- [x] test（templates/hooks/tests/ の integration テスト）

このリポジトリはシェルスクリプト製テンプレートであり、アプリケーションレイヤ (controller/usecase/domain) は非該当。

## 影響範囲

SPEC-0027 実装メモの File Scope と 1:1 対応:

| ファイル | 影響内容 | 担当TASK |
|---------|---------|----------|
| `scripts/sage-id-pattern.sh`（新規） | 共有ローダー: `sage_id_accept_regex` / `sage_id_default_regex` + fallback | TASK-0185 |
| `.sage/id-patterns.json`（新規） | ID 種別ごとの `accept` regex 配列テンプレート（人間承認の上で追加） | TASK-0185 |
| `scripts/sage-trace-check.sh` | 受理判定 regex（:19）をローダー参照化 | TASK-0186 |
| `scripts/sage-validate.sh` | 受理判定 regex（:195）をローダー参照化 | TASK-0186 |
| `scripts/sage-report.sh` | 受理判定 regex（:123-125、BRE 混在）を `grep -E` 化 + ローダー参照化 | TASK-0186 |
| `scripts/sage-id-gen.sh` | 連番スキャン（:47,52）を `sage_id_default_regex` 経由に | TASK-0187 |
| `templates/pre-commit-task-id.sh` | fallback 内包 + `.sage/id-patterns.json` 優先読み込み（:56） | TASK-0188 |
| `scripts/generator/02-config.sh` | hook 埋め込み経路（変更が必要な場合のみ） | TASK-0189 |
| `install.sh` | 再生成のみ（手動編集禁止）+ preserve-if-exists 対応 | TASK-0189 |
| `SHA256SUMS` | install.sh 再生成に追随 | TASK-0189 |
| `templates/hooks/tests/test-id-patterns.sh`（新規） | AC-01〜07/11 の integration テスト | TASK-0190 |
| `templates/hooks/tests/run-tests.sh` | 登録行のみ（自動 discovery なら変更不要） | TASK-0190 |
| `docs/id-patterns.md`（新規） | カスタム ID 形式の設定手順・書式・注意点 | TASK-0191 |
| `README.md` | docs への参照追記 | TASK-0191 |
| `.sage/config.yaml` | `id_schema` コメント整合のみ（人間承認必須、PR で変更行を明示） | TASK-0191 |

上記以外の変更は禁止（AP-03 Silent Scope Expansion）。`AGENTS.md` / `docs/codex-*.md` / `sage/` は特に不可。

## 実装方針

- ID 受理 regex を `.sage/id-patterns.json` に外部化し、共有ローダー `scripts/sage-id-pattern.sh`（source 用）経由で 5 スクリプトが同一設定を参照する。
- 設定欠損・パース不能・空 accept 時は現行ハードコードと同一の fallback（WARN のみ、exit 0）。後方互換（NFR-01 / INV-01）が最優先。
- パースは POSIX ツール（grep/sed/awk）のみ。jq 依存・jq 分岐は設けない（単一コードパス）。
- `eval` 禁止（SEC-01/INV-02）。regex は `grep -E` のパターン引数としてのみ使用。空パターン合成は fallback に切替（SEC-03/INV-04）。
- ハードコード fallback はローダーと pre-commit hook 内包分の 2 箇所のみ・同一値（INV-03）。AC-06 テストで機械強制。
- `pre-commit-task-id.sh` は導入先スタンドアロン配布物のため fallback を自己内包し、generator 経由で install.sh に再埋め込み → SHA256SUMS 更新（FAIL-0002 教訓、専用 TASK・単独コミット）。
- `sage-report.sh` の `git log --grep`（BRE）箇所が最大の置換事故ポイント。合成 ERE を BRE 互換に落とすか `--format` 出力を `grep -E` でフィルタする方式に変更（SPEC 実装メモ準拠）。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0185 | ローダー `sage-id-pattern.sh` + `.sage/id-patterns.json` テンプレート新設（T1） | Implementation | 2h | none | Yes（起点） |
| TASK-0186 | trace-check / validate / report の受理判定ローダー参照化（T2） | Implementation | 2h | TASK-0185 | Yes（0187/0188/0191 と並列可） |
| TASK-0187 | id-gen のデフォルト形式スキャン参照化（T3） | Implementation | 1h | TASK-0185 | Yes（0186/0188/0191 と並列可） |
| TASK-0188 | pre-commit hook の設定優先 + fallback 内包化（T4） | Implementation | 1.5h | TASK-0185 | Yes（0186/0187/0191 と並列可） |
| TASK-0189 | install.sh 再生成 + SHA256SUMS 更新 + preserve-if-exists（T5、専用 TASK・単独コミット） | Implementation | 1h | TASK-0188 | No |
| TASK-0190 | test-id-patterns.sh 追加 + run-tests.sh 登録（T6） | Test | 2h | TASK-0189 | No |
| TASK-0191 | docs/id-patterns.md + README + config.yaml コメント整合（T7） | Implementation | 1h | TASK-0185 | Yes |

実行順: TASK-0185 → (TASK-0186 / TASK-0187 / TASK-0188 並列) → TASK-0189 → TASK-0190。TASK-0191 は TASK-0185 完了後に並列可。

## リスク

- リスク1: 5 箇所の置換漏れ・部分置換で受理判定が不整合になる → 軽減策: AC-06 のハードコード残存検出テスト（TASK-0190）で機械強制。fallback 定義はローダー + hook 内包分の 2 箇所に集約（INV-03）
- リスク2: POSIX ツールの JSON パースが表記揺れで誤読 → 軽減策: 書式を「1 パターン 1 行」サブセットとして docs 規定（TASK-0191）、表記揺れ fixture をテストに含める。パース不能時は常に fallback（安全側）
- リスク3: pre-commit hook の generator 再埋め込み漏れでテンプレートとインストール済み hook が乖離（FAIL-0002 再演） → 軽減策: 再生成 + SHA256SUMS 更新を専用 TASK-0189 に分離し単独コミット。AC-08 で機械検証
- リスク4: 緩すぎるカスタム regex で traceability 形骸化 → 軽減策: docs に推奨パターンとアンチ例を記載（TASK-0191）。デフォルトは現行厳格形式を維持（ASM-02）
- リスク5: `sage-report.sh` の `git log --grep`（BRE）へ合成 ERE を渡して silent miss → 軽減策: `--format` 出力の `grep -E` フィルタ方式へ変更し BRE/ERE 混在を排除（TASK-0186 の完了条件で既存挙動維持を検証）

## 必要な検証

- [ ] unit test — N/A（対象がシェル関数のため非適用。SPEC 検証方針準拠）
- [x] integration test — `templates/hooks/tests/test-id-patterns.sh`（AC-01〜07/10/11/12 + 境界ケース2/3）+ `run-tests.sh` 全件（AC-09）
- [x] security scan — eval 不使用検証（AC-11/SEC-01）、空パターン全マッチ防止（AC-05/SEC-03）、Gate 3
- [ ] e2e test — N/A（Web アプリケーションではない。installer 実行検証は integration テストで担保）
- [x] architecture boundary check — ハードコード regex 残存検出（AC-06/INV-03）、File Scope 遵守（Gate 4）
