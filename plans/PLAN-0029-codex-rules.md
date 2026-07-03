# PLAN-0029: Codex ルール層の対称化 — .codex/rules/ テンプレートと優先順位の公式化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0029 |
| SPEC-ID   | SPEC-0029 |
| ステータス | Draft |
| 作成日    | 2026-07-03 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（installer generator: `scripts/generator/03-rules.sh` / `07-installer-main.sh`、生成物 `install.sh` + `SHA256SUMS`）
- [ ] frontend
- [ ] infra
- [x] test（`templates/hooks/tests/test-codex-rules.sh` — Test Agent 責務）
- [x] templates / docs（`templates/codex-rules/` 5 ファイル、`docs/codex-rules.md`、`README.md` 参照追記）

## 影響範囲

SPEC-0029 実装メモの File Scope と 1:1 対応。

| 領域 | ファイル | 変更種別 | 担当 TASK |
|------|---------|---------|-----------|
| Codex rules テンプレート | `templates/codex-rules/specs-rules.md` | 新規 | TASK-0198 |
| Codex rules テンプレート | `templates/codex-rules/plans-rules.md` | 新規 | TASK-0198 |
| Codex rules テンプレート | `templates/codex-rules/tasks-rules.md` | 新規 | TASK-0198 |
| Codex rules テンプレート | `templates/codex-rules/src-rules.md` | 新規 | TASK-0198 |
| Codex rules テンプレート | `templates/codex-rules/sage-governance-rules.md` | 新規 | TASK-0198 |
| generator | `scripts/generator/03-rules.sh`（`TMPL_CODEX_RULES_*` embed 5 件 + Codex 向け overlay 注記 + docs embed 経路） | 変更 | TASK-0199 |
| generator | `scripts/generator/07-installer-main.sh`（mkdir `.codex/rules` / write 5 件 / docs write / managed_files 追加 / dry-run WOULD-* 表示） | 変更 | TASK-0199 |
| docs | `docs/codex-rules.md`（優先順位・読み込み手順・対応表・overlay 案内の 4 節） | 新規 | TASK-0200 |
| docs | `README.md`（`docs/codex-rules.md` 参照追記のみ） | 変更 | TASK-0200 |
| 生成物 | `install.sh`（再生成のみ・手動編集禁止） | 再生成 | TASK-0201 |
| 生成物 | `SHA256SUMS` | 更新 | TASK-0201 |
| テスト | `templates/hooks/tests/test-codex-rules.sh` | 新規 | TASK-0202 |
| テスト | `templates/hooks/tests/run-tests.sh`（登録行のみ、自動 discovery なら変更不要） | 変更(条件付) | TASK-0202 |
| PR 本文 | AGENTS.md 追記案 (Codex follow-up) + CLAUDE.md §9.1 追記案 (Human follow-up) | PR body のみ | TASK-0203 |

上記以外の変更は禁止 (AP-03)。特に不可: `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` / `templates/rules/` / `.claude/rules/` / `sage/` / `CLAUDE.md` / 本リポジトリの `.sage/config.yaml`（AC-12 で機械検証）。

## 実装方針

- `.claude/rules/` の既存配布機構（`03-rules.sh` の embed + `RULES_LOCAL_NOTICE` + `write_rules_file`、`07-installer-main.sh` の write 呼び出し / managed_files）を**そのままミラー**し、overlay 案内先のみ `.codex/rules/local/` に差し替える。`is_unmanaged_path` ガードは既存の write 経路に組み込み済みのため、同関数（または対称の `write_codex_rules_file`）を経由して SEC-03 を満たす。
- テンプレート内容は `templates/rules/`（harness-rules.md 除外の 5 件）を起点に、Claude Code 固有記述（hooks による runtime 強制、`/sage-*` slash command）を Codex 文脈（guidance 遵守 + Codex Delegation Packet 参照）へ置換するのみ。ルールの追加・削除は行わない（semantic 同一、NFR-03）。
- generator 変更（embed 定義 + write 呼び出し）は TASK-0199 に集約し、TASK-0200（docs 実体 + README）と File Scope を互いに素に保つ。docs の generator embed はファイル内容を再生成時に読むため、TASK-0201 の再生成前に TASK-0199 / TASK-0200 の両方が完了していればよい。
- install.sh 再生成 + SHA256SUMS 更新は **専用 TASK（TASK-0201）・単独コミット**（FAIL-0002 教訓）。
- テスト実装は **Test Agent 責務・別セッション**（AP-04 回避）。実行順: TASK-0198 → TASK-0199 → TASK-0201 → TASK-0202。TASK-0200 は TASK-0198 後に TASK-0199 と並列可（TASK-0201 前に合流）。TASK-0203 は TASK-0201 後に TASK-0202 と並列可。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0198 | `templates/codex-rules/` 5 ファイル新設 (T1, AC-01) | Implementation | 1h | - | Yes（先頭） |
| TASK-0199 | generator: embed + write + managed_files + dry-run 表示 (T2, AC-02〜08 実装) | Implementation | 2h | TASK-0198 | Yes（TASK-0200 と並列） |
| TASK-0200 | `docs/codex-rules.md` 新設 + README 参照追記 (T3, AC-09) | Implementation | 1h | TASK-0198 | Yes（TASK-0199 と並列） |
| TASK-0201 | install.sh 再生成 + SHA256SUMS 更新（専用 TASK・単独コミット, T4, AC-10） | Implementation | 30m | TASK-0199, TASK-0200 | No |
| TASK-0202 | test-codex-rules.sh 追加 + run-tests.sh 登録 (T5, AC-01〜09/11) | Test（別セッション） | 2h | TASK-0201 | Yes（TASK-0203 と並列） |
| TASK-0203 | PR 本文: AGENTS.md 追記案 + CLAUDE.md §9.1 追記案 起草 (T6, AC-12 部分) | Implementation | 30m | TASK-0201 | Yes（TASK-0202 と並列） |

## リスク

- リスク1: 既存導入先の `.codex/rules/` 直下自作ルールが `--update` で上書きされる → 軽減策: docs/リリースノートに `.codex/rules/local/` への移行案内を明記。write 対象は固定 5 パスのみ（SEC-02）。
- リスク2: `templates/rules/` と `templates/codex-rules/` の semantic drift → 軽減策: AC-01 の 1:1 対応検証（TASK-0202）+ OPS-04 paired-update doctrine。
- リスク3: generator 再埋め込み漏れ（FAIL-0002 再演） → 軽減策: 再生成 + SHA256SUMS を TASK-0201 専用・単独コミットとし AC-10 で機械検証。
- リスク4: Codex が `.codex/rules/` を読まないまま放置 → 軽減策: TASK-0203 で PR 本文に follow-up 追記案を必須化、OPS-03 の Observe 基準で参照実態を確認。
- リスク5: `docs/codex-rules.md` 新設が SPEC-0023 boundary と衝突して見える → 軽減策: doc 冒頭に「新設は本 SPEC、以後の修正は Codex 側 task」を明記（TASK-0200）。既存 codex docs 2 件は非接触（AC-12）。
- リスク6: TASK-0199 と TASK-0200 の並列実行時に generator ファイルへの変更が競合する → 軽減策: generator 変更は TASK-0199 に集約し File Scope を互いに素にする（本 PLAN の分割方針）。

## 必要な検証

- [ ] unit test — N/A（bash スクリプトのため非適用、SPEC 検証方針）
- [x] integration test — `templates/hooks/tests/test-codex-rules.sh`（一時ディレクトリで install.sh を実行し AC-01〜09 検証、Test Agent 責務）
- [x] security scan — Gate 3（gitleaks: 新規テンプレート/docs に secret 非含有、SEC-04）
- [ ] e2e test — N/A
- [x] architecture boundary check — Gate 4 + AC-12（boundary 遵守: `AGENTS.md` / 既存 codex docs / `templates/rules/` / `.claude/rules/` 非変更）+ AC-10（generator 由来検証）+ AC-11（既存テスト非破壊: `run-tests.sh` 全件 PASS）
