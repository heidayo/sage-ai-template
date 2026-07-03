# PLAN-0025: Local Overlay 機構 — installer 不可侵カスタマイズ層の実装計画

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0025 |
| SPEC-ID   | SPEC-0025 |
| ステータス | Draft |
| 作成日    | 2026-07-02 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（installer generator: `scripts/generator/01-templates.sh` / `03-rules.sh` / `07-installer-main.sh`、テンプレートソース `templates/claude-md-snippet.md`、生成物 `install.sh` + `SHA256SUMS`）
- [ ] frontend
- [ ] infra
- [x] test（`templates/hooks/tests/test-local-overlay.sh` 新設）
- [x] docs（README「カスタマイズと更新の共存」ガイド、managed rules 末尾注記、CLAUDE.md managed セクション規約）

## 影響範囲

| 領域 | 影響内容 |
|------|---------|
| `scripts/generator/07-installer-main.sh` | overlay 除外判定 `is_unmanaged_path()` の定義（単一箇所 = INV-03）、install-state 生成部への `unmanaged_paths` 追加、`--verify-checksum` の検証対象除外、非ディレクトリ/symlink WARN 処理 |
| `scripts/generator/03-rules.sh` | rules 生成での `*/rules/local/**` 不可侵 + managed rules 末尾への参照規約注記 |
| `templates/claude-md-snippet.md` | CLAUDE.md SAGE managed セクションのソース。overlay 読み込み規約を追記（`scripts/generator/02-config.sh` が embed、`07-installer-main.sh` の `upsert_sage_section()` が注入） |
| `scripts/generator/01-templates.sh` | ソース所在を示すポインタコメントの追加のみ |
| `install.sh` / `SHA256SUMS` | generator 変更に伴う再生成・checksum 更新（FR-06 / NFR-02 再現性） |
| `.sage/install-state.yaml`（契約） | `unmanaged_paths:` キー追加（追加のみ、既存キー変更なし） |
| `templates/hooks/tests/` | `test-local-overlay.sh` 新設、`run-tests.sh` から実行される既存テスト群は非破壊（AC-07） |
| `README.md` / docs | 「カスタマイズと更新の共存」ガイド（対比表 OPS-02、レビュー責任 SEC-01） |

**影響しない領域（スコープ外の再確認）**: `AGENTS.md` / `docs/codex-*.md`（Codex follow-up に分離）、`sage/` 配下、hook による runtime enforcement、バックアップ機構。

## 実装方針

1. **除外判定の単一集約（INV-03）**: overlay 判定は `07-installer-main.sh` 内の単一関数 `is_unmanaged_path()` に定義し、rules 生成 (03)・install-state 生成・verify-checksum・repair の各経路が参照する。重複実装による drift を禁止。
2. **「触らない」原則の徹底（SEC-02）**: `unmanaged_paths` は書き込み許可リストではなく不可侵宣言。`local/` が非ディレクトリ・symlink の場合も WARN のみで read/write とも行わない（PRE-02 / 想定エラー1・3）。
3. **後方互換（NFR-01 / 想定エラー2）**: `unmanaged_paths` なしの旧 install-state でも `--verify-checksum` は従来通り managed のみ検証。managed の検証範囲は縮小しない（INV-02 / SEC-03）。
4. **再現性の維持（NFR-02）**: generator 変更後に `install.sh` を再生成し SHA256SUMS を更新。バイト一致で検証（AC-06 / POST-02）。
5. **テスト先行の機械強制（AP-06 対策）**: 不可侵保証は instruction ではなく `test-local-overlay.sh` で install / 再 install / dry-run / verify-checksum の全経路を検証（INV-01）。

代替案比較: マーカー方式（`upsert_sage_section()`）の rules への拡張も検討したが、ファイル単位の全置換前提と衝突しマージロジックが複雑化するため、ディレクトリ単位の overlay 不可侵を採用（SPEC 決定事項）。

## タスク分解

| TASK-ID | 責務 | 対応 Slice | 対応 AC | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|-----------|---------|----------|------|---------|---------|
| TASK-0171 | generator overlay 除外ロジック（03/07 モジュール） | T1 | AC-01/02/08 (+03/04/09 の実装側) | Implementation | 3h | none | No |
| TASK-0172 | install.sh 再生成 + SHA256SUMS 更新 | T2 | AC-06 | Implementation | 30m | TASK-0171 | No |
| TASK-0173 | test-local-overlay.sh 追加 | T3 | AC-01〜04/08/09/10 | Test | 2h | TASK-0177（推移的に TASK-0172/0174/0175 を含む。テストは TASK-0177 再生成後の install.sh を対象とする） | No |
| TASK-0174 | managed rules 末尾注記（03-rules.sh、generator/templates のみ） | T4 | AC-05 (実装側) | Implementation | 1h | TASK-0171, TASK-0172 | Yes（T5/T6 と並列可） |
| TASK-0175 | CLAUDE.md 規約追記（templates/claude-md-snippet.md + 01-templates.sh ポインタコメント） | T5 | AC-10 (実装側) | Implementation | 1h | TASK-0171, TASK-0172 | Yes（T4/T6 と並列可） |
| TASK-0176 | README「カスタマイズと更新の共存」ガイド | T6 | OPS-02 / SEC-01 (+AC-07 非破壊) | Implementation | 1h | TASK-0171, TASK-0172 | Yes（T4/T5 と並列可） |
| TASK-0177 | install.sh 再生成 + SHA256SUMS 更新（T4/T5 反映） | T7 | AC-06 (+05/10 の生成物反映確認) | Implementation | 30m | TASK-0174, TASK-0175 | No |

実行順: TASK-0171 → TASK-0172 → (TASK-0174 / TASK-0175 / TASK-0176 並列) → TASK-0177（再生成の直列化） → TASK-0173（テスト、AC-10 の `claude_md_convention` ケースは TASK-0177 の生成物を前提とする）。
注: TASK-0174/0175 は generator/templates の変更のみを行い、`install.sh` / `SHA256SUMS` には触れない。再生成は TASK-0177 に一元化することで、並列実行後の checksum 不整合を構造的に防ぐ。

## リスク

- リスク1: generator 修正漏れで一部コードパス（repair / verify）が overlay を触る → 軽減策: 除外判定を `is_unmanaged_path()` に単一集約（INV-03）し、TASK-0173 のテストで install / 再 install / dry-run / verify の全経路をカバー
- リスク2: 注記追加で managed rules の checksum が全て変わり、既存導入先で `--verify-checksum` が一時 FAIL に見える → 軽減策: 通常のテンプレート更新と同じ扱い（install-state 再生成で解消）であることを TASK-0176 の README ガイドと release note に明記
- リスク3: 「local/ を読む」規約が instruction のみで enforcement がない（AP-06 残存） → 軽減策: 不可侵側をテストで機械強制し、読み込み enforcement は将来 SPEC 候補として記録（SPEC-0025 リスク3 の昇格条件に従う）
- リスク4: T4/T5/T6 並列実行後の再生成タイミングずれで SHA256SUMS が不整合になる → 軽減策: 再生成を TASK-0177 に直列化（T4/T5 は generator/templates 変更のみ、`install.sh` / `SHA256SUMS` は TASK-0177 が単独で更新）。AC-06 は TASK-0177 の完了条件として Verify フェーズで再確認

## 必要な検証

- [x] unit / integration test — `bash templates/hooks/tests/test-local-overlay.sh`（新設、install/再install/dry-run/verify-checksum 全経路）+ `bash templates/hooks/tests/run-tests.sh`（既存全件非破壊 AC-07）
- [ ] unit test（LOC coverage）— N/A: bash スクリプトのため Gate 2 の coverage 計測対象外（SPEC 検証方針参照）。異常系の全テストケース化で代替
- [x] security scan — Gate 3（secret scan / dependency scan）+ SEC-01〜03 のレビュー確認（検証範囲非縮小、path traversal 非波及）
- [ ] e2e test — N/A: アプリケーションではなく installer のため integration テストで代替
- [x] architecture boundary check — Gate 4（File Scope / traceability）+ INV-03（除外判定の単一定義）を Review Agent が確認
