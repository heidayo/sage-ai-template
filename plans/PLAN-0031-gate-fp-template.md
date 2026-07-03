# PLAN-0031: Gate False Positive 記録テンプレートの標準搭載 — 実装計画

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0031 |
| SPEC-ID   | SPEC-0031 |
| ステータス | Draft |
| 作成日    | 2026-07-03 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（governance ドキュメント: sage/failures.md、CLI スクリプト: scripts/sage-id-gen.sh、installer 成果物: install.sh / SHA256SUMS）
- [ ] frontend
- [ ] infra
- [x] test（templates/hooks/tests/ 配下の integration テスト + fixtures）

## 影響範囲

SPEC-0031 実装メモの File Scope と 1:1 対応。以下 6 点以外の変更は禁止（AP-03 Silent Scope Expansion）。

| ファイル | 変更種別 | TASK | 備考 |
|---------|---------|------|------|
| `sage/failures.md` | 変更（節追加のみ） | TASK-0208 | **human-only 領域 — PR レビュー・マージが承認行為**（SPEC §human 承認要件）。既存エントリ・既存節はバイト単位で不変（AC-11, INV-05） |
| `scripts/sage-id-gen.sh` | 変更（gate-fp 分岐 + usage 追記のみ） | TASK-0209 | SPEC-0027 ローダー（`sage_id_default_regex`）は呼ばない（設計判断2, SEC-01） |
| `templates/hooks/tests/test-gate-fp-idgen.sh` | 新規 | TASK-0210 | **Test Agent 責務・別セッション**（AP-04 回避） |
| `templates/hooks/tests/fixtures/`（fixture failures.md 2 種） | 新規 | TASK-0210 | GATE-FP 0 件版 / 複数件（欠番あり）版 |
| `templates/hooks/tests/run-tests.sh` | 変更（登録行のみ、自動 discovery なら変更不要） | TASK-0210 | |
| `install.sh` / `SHA256SUMS` | 再生成のみ | TASK-0211 | **専用 TASK・単独コミット**（FAIL-0002 教訓、リスク3） |

非変更保証（Gate 4 / AC-10 相当）: `scripts/sage-id-pattern.sh`、`templates/pre-commit-task-id.sh`（SPEC-0027 INV-03 非波及）、`sage/anti-patterns.md`、`.sage/id-patterns.json`、`scripts/generator/`（embed_file が実行時読み込みのため変更不要 — 必要と判明したら Spec Agent へ差し戻し）、`AGENTS.md` / `docs/codex-*.md` / `CLAUDE.md`。

## 実装方針

- **failures.md（T1 = TASK-0208）**: 「エントリフォーマット」節（FAIL-XXXX）の直後に新節「Gate False Positive エントリフォーマット (GATE-FP-XXXX)」を追加し、必須 7 フィールド（発生日 / 誤検知した Gate + チェック名 / TASK-ID / 誤検知の根拠 / 一時対応 / 恒久対応 / 再発回数）を定義。「記録ルール」節に (a) FAIL-XXXX との使い分け（gate 側の誤検知 = GATE-FP、迷えば FAIL 優先 + 相互参照）、(b) 同一チェック誤検知 3 回で gate 設定見直し必須化のエスカレーションルールを追記。追加のみで実現し既存節は変更しない（NFR-01）。言語は日本語。
- **sage-id-gen.sh（T2 = TASK-0209）**: 既存 `case "$TYPE"` に `gate-fp)` 分岐を追加。ローダーを経由せずローカル定数 `DEFAULT_RE='GATE-FP-[0-9]{4}'` で `sage/failures.md` を grep スキャン（`fail` 種別踏襲、ファイル不在 = LAST_NUM 0）。**sort キー注意**: GATE-FP-0001 は `-` 区切りで 3 フィールドになるため、既存 `fail` の `sort -t'-' -k2 -n` を共用せず gate-fp 専用のソートキー（`-k3` 相当）を使う（SPEC 実装メモ明記）。usage に `gate-fp` を追加し、記録専用 ID（SPEC-0027 ローダー・コミット規約対象外）である旨のコメントを添える。bash 3.2+ / POSIX のみ、jq / eval 不使用（NFR-02, SEC-01）。
- **テスト（T3 = TASK-0210）**: `test-id-patterns.sh` の流儀（`_helpers.sh` / 一時ディレクトリ / fixture 配置）を踏襲し、AC-03〜07 を integration テストで検証。Test Agent が Implementation Agent と別セッションで実装（役割分離）。
- **再生成（T4 = TASK-0211）**: `bash scripts/generate-install.sh`（既存の再生成手順）で install.sh を再生成し SHA256SUMS を更新。単独コミット。drift check（`git diff --exit-code install.sh SHA256SUMS` 再生成後）+ 埋め込み確認 grep で検証（AC-09, INV-06）。

代替案比較: gate-fp を SPEC-0027 ローダー（`_sage_id_fallback_regex`）に追加する案は、pre-commit hook 埋め込み fallback との同一性維持（INV-03）へ波及し単一責務を超えるため不採用（SPEC 設計判断2 で確定済み）。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0208 | sage/failures.md に GATE-FP テンプレート + 使い分け + エスカレーションルール追記（human 承認 = PR マージ前提） | Implementation | 45m | - | Yes（TASK-0209 と並列可） |
| TASK-0209 | scripts/sage-id-gen.sh に gate-fp 種別追加（ローカル ERE・専用 sort キー・usage 追記） | Implementation | 45m | - | Yes（TASK-0208 と並列可） |
| TASK-0210 | test-gate-fp-idgen.sh + fixtures + run-tests.sh 登録（Test Agent・別セッション） | Test | 1h | TASK-0209 | No |
| TASK-0211 | install.sh 再生成 + SHA256SUMS 更新（単独コミット、FAIL-0002） | Implementation | 20m | TASK-0208, TASK-0209 | No |

実行順: TASK-0208 / TASK-0209 並列 → TASK-0210 / TASK-0211。AC-08（human 承認明記）/ AC-10（ローダー非変更）は PR レビューで全 TASK 横断確認。

## リスク

- リスク1: sort キーの取り違え（`fail` の `-k2` を流用すると GATE-FP の番号フィールドを読み誤る）→ 軽減策: SPEC 実装メモ・TASK-0209 に gate-fp 専用ソートキーを明記し、AC-04（欠番あり fixture で最大値 + 1）のテストで機械検証
- リスク2: install.sh 再生成コミットが実装コミットに混入する（FAIL-0002 再演）→ 軽減策: TASK-0211 を専用 TASK・単独コミットに分離し、File Scope を install.sh / SHA256SUMS のみに限定
- リスク3: protect-sage-files hook が sage/failures.md の編集をブロックし TASK-0208 が進行不能 → 対応: SPEC「human 承認要件」節どおり human の明示承認（SPEC-0031 承認済みが根拠）を得てから解除判断。PR 本文に「sage/ 変更の human 承認が merge 前提」を必ず記載（AC-08）
- リスク4: usage 文言変更が導入先のパースを壊す → 軽減策: usage はエラー時表示のみで正常系 stdout（ID 1 行）は完全不変。契約変更として SPEC 契約節に明記済み
- リスク5: ローダー・pre-commit への意図せぬ波及（SPEC-0027 INV-03）→ 軽減策: AC-10 の `git diff --name-only main` 検証を Done Definition CHECK に含め、TASK File Scope に両ファイルを禁止事項として明記

## 必要な検証

- [ ] unit test — N/A（bash スクリプトのため integration で代替）
- [x] integration test — `bash templates/hooks/tests/test-gate-fp-idgen.sh`（AC-03〜07）+ `bash templates/hooks/tests/run-tests.sh` 全件 PASS（AC-12）
- [x] security scan — Gate 3（secret scan / dependency scan）+ SEC-01（ローカル定数 ERE のみ、grep で jq/eval 不在確認）+ SEC-02（`bash install.sh --verify-checksum` PASS）
- [ ] e2e test — N/A（CLI スクリプト + ドキュメント）
- [x] architecture boundary check — Gate 4: AC-10（ローダー非変更）、AC-11（既存エントリ不変）、トレーサビリティ（SPEC-0031 → PLAN-0031 → TASK-0208〜0211）
- [x] ドキュメント検証 — AC-01 / AC-02 の grep、AC-08 の PR 本文確認（`gh pr view --json body`）
