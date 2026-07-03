# PLAN-0026: Installer カスタマイズ保全の強化 — 実装計画

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0026 |
| SPEC-ID   | SPEC-0026 |
| ステータス | Draft |
| 作成日    | 2026-07-02 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（installer generator: `scripts/generator/07-installer-main.sh`、生成物 `install.sh` + `SHA256SUMS`）
- [ ] frontend
- [ ] infra
- [x] test（`templates/hooks/tests/test-installer-preservation.sh` 新規 + `run-tests.sh` 登録）
- [x] docs（`README.md`、`docs/installer-preservation.md` 新規、`templates/claude-md-snippet.md`）

## 影響範囲

SPEC-0026 の File Scope 8 ファイルと 1:1 で整合する。

| # | ファイル | 変更種別 | 影響内容 |
|---|---------|---------|---------|
| 1 | `scripts/generator/07-installer-main.sh` | 変更 | `backup_before_write()` 新設、世代ローテーション、`upsert_sage_section()` 片方欠損スキップ、`--diff` オプション + usage |
| 2 | `install.sh` | 再生成のみ | generator 出力の追随（手動編集禁止） |
| 3 | `SHA256SUMS` | 再生成のみ | `install.sh` 再生成に追随 |
| 4 | `templates/hooks/tests/test-installer-preservation.sh` | 新規 | AC-01〜05 (04b 含む)/08/09/11/12/13 + 境界ケース2件のリグレッションテスト |
| 5 | `templates/hooks/tests/run-tests.sh` | 変更（登録行のみ） | 新テストの登録（自動 discovery なら変更不要） |
| 6 | `README.md` | 変更 | 手動復元手順への導線 |
| 7 | `docs/installer-preservation.md` | 新規 | 復元手順 + マーカー方式「防御される / 防御されないケース」対比表 |
| 8 | `templates/claude-md-snippet.md` | 変更 | バックアップ規約 1〜2 行追記 (FR-08) |

overlay 機構 (SPEC-0025)・GitHub Releases フロー (SPEC-0018)・`sage/` 配下・AGENTS.md / `docs/codex-*.md` には触れない（SPEC スコープ外 + CLAUDE.md §2.1 boundary）。

## 実装方針

1. **バックアップの単一関数集約**: 「既存 + 内容差分あり」判定と `.sage/backup/<UTC timestamp>/` へのコピーを `backup_before_write()` に集約し、全書き込み経路が経由する (INV-02/04)。ローテーション削除は `^[0-9]{8}-[0-9]{6}(-[0-9]+)?$` にマッチするディレクトリのみ対象 (INV-03)。timestamp 衝突時は `-N` suffix (FR-02)。バックアップ先書き込み不可時は上書きせず非0 exit (fail-safe, AC-09)。
2. **マーカー安全側フォールバック**: `upsert_sage_section()` にマーカー整合判定 (両方 / 片方 / 不在) を追加。片方のみ検出時は変更せず WARN (stderr、docs へのポインタ含む) + installer 継続 exit 0 (FR-05)。両方不在時は既存の append 挙動を維持 (境界ケース2)。
3. **`--diff` は書き込みフェーズ前に分岐**: dry-run 相当の判定パスを流用し、UPDATE 対象ごとに unified diff を表示して exit 0。マーカー外の差分行も隠さず表示 (FR-03/04, PRE-02)。既存 `--dry-run` / `--verify-checksum` / `--remote` の挙動は不変 (NFR-01)。
4. **再生成の分離コミット**: SPEC-0025 実装の教訓 (FAIL-0002) に従い、`install.sh` / `SHA256SUMS` の再生成は再生成専用 TASK (TASK-0181) の TASK-ID で別コミットにする。生成入力 (`templates/claude-md-snippet.md` 等) の変更も TASK-0181 に集約し、同一 PR 内で再生成が必ず追随する構成とする。
5. **テストは既存流儀踏襲**: `_helpers.sh` + 一時ディレクトリ + 生成 `install.sh` 実行 (test-local-overlay.sh の流儀)。全 AC をケース名 1:1 対応で固定。

選択肢比較: バックアップを「全ファイル tar 一括」にする案は、UPDATE 0件時の空世代生成・SEC-03 (secret を stdout に出さない) との相性・部分復元のしやすさで劣るため、UPDATE 対象ファイル個別コピー (相対パス構造維持) を採用する。

## タスク分解

| TASK-ID | 責務 | 対応 SPEC ヒント | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|------|----------|------|---------|---------|
| TASK-0178 | generator: `backup_before_write()` + 世代ローテーション | T1 | Implementation | 2h | none | Yes（起点） |
| TASK-0179 | generator: upsert マーカー片方欠損の安全側スキップ | T2 | Implementation | 1h | TASK-0178 | No（07-installer-main.sh を共有） |
| TASK-0180 | generator: `--diff` オプション | T3 | Implementation | 1.5h | TASK-0179（推移的に TASK-0178） | No（同上） |
| TASK-0181 | claude-md-snippet 追記 (FR-08) + install.sh 再生成 + SHA256SUMS 更新 | T4 | Implementation | 30m | TASK-0180（推移的に TASK-0178/0179） | No |
| TASK-0182 | test-installer-preservation.sh 追加 | T5 | Test | 2h | TASK-0181 | No |
| TASK-0183 | docs: 復元手順 + マーカー方式対比表 | T6 | Implementation | 1h | TASK-0178 | Yes（TASK-0179〜0182 と並列可） |
| TASK-0184 | generator: setup_gitignore への `.sage/backup/` エントリ追加 (FR-09、冪等) + case `gitignore_backup_entry` + install.sh/SHA256SUMS 再生成追随 | T7 | Implementation | 1h | TASK-0178 | Yes（TASK-0183 と並列可。TASK-0179〜0182 とは 07-installer-main.sh / SHA256SUMS を共有するため直列推奨） |

実行順: TASK-0178 → TASK-0179 → TASK-0180 → TASK-0181 → TASK-0182。TASK-0183 / TASK-0184 は TASK-0178 完了後に並列可（追補タスク）。
並列 TASK 同士 (TASK-0183 vs TASK-0179〜0182) の File Scope は互いに素 (`README.md` / `docs/` vs generator / templates / SHA256SUMS)。

## リスク

- リスク1: バックアップ判定と実書き込みのコードパス乖離によるバックアップ漏れ → 軽減策: `backup_before_write()` への単一集約 (INV-04) + AC-02 テスト + Review での経路確認 (SPEC リスク1 準拠)
- リスク2: TASK-0178〜0180 が同一ファイル (`07-installer-main.sh`) を変更するため、並列実行するとコンフリクト → 軽減策: 直列依存として明示 (並列可否 No)、並列可は File Scope が素な TASK-0183 のみ
- リスク3: `--diff` 追加で generator 出力が変わり SHA256SUMS / release フローが壊れる → 軽減策: 再生成を TASK-0181 に分離・専用コミット化し、AC-06/07 で機械検証 (FAIL-0002 教訓)
- リスク4: 世代削除の対象誤りでユーザーデータ削除 → 軽減策: 削除対象を timestamp 正規表現マッチのみに限定 (INV-03)、AC-11 でテスト固定

## 必要な検証

- [ ] unit test — N/A（対象は生成 bash スクリプト内関数。SPEC 検証方針どおり非適用）
- [x] integration test — `bash templates/hooks/tests/test-installer-preservation.sh`（全ケース）+ `bash templates/hooks/tests/run-tests.sh`（既存テスト非破壊, AC-07）
- [x] security scan — Gate 3（secret scan / dependency scan）+ SEC-01〜03 のテストケース検証（AC-09/11 + stdout に内容ダンプなし）
- [ ] e2e test — N/A（CLI installer のため integration テストで代替）
- [x] architecture boundary check — Gate 4（File Scope 8 ファイル遵守、traceability）+ SHA256SUMS 再現性検証（AC-06, `shasum -a 256 -c SHA256SUMS`）
