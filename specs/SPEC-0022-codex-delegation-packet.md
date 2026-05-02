# SPEC-0022: Codex Delegation Packet and Codex-only Agent Guidance

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0022 |
| ステータス | Review |
| 作成日    | 2026-05-03 |
| 更新日    | 2026-05-03 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0013, SPEC-0017, SPEC-0018 |
| 権限レベル | platform |

## 背景・目的

Codex と Claude Code はどちらも AI coding agent だが、実務上は Codex が「明確なタスクを委任して実行・検証する」方向、Claude Code が「曖昧な要件を相談しながら設計・レビューする」方向に強みを持つ。SAGE は両方を同一ルールで縛るだけでなく、Codex が曖昧な依頼から勝手な前提で実装を始めないよう、Codex 専用の委任入力形式と判断基準を提供する必要がある。

## 対象ユーザー

- Codex CLI / Codex App / Codex Cloud を SAGE と併用する開発者
- Claude Code で設計した結果を Codex に実装委任する利用者
- Issue / PR comment / CI failure を Codex に渡すチーム

## スコープ（含む）

- Codex 専用の `Codex Delegation Packet` 文書を追加する
- `AGENTS.md` に Codex セッション向けの短い運用ルールを追加する
- `templates/agents-md-snippet.md` に新規導入先へ伝播する Codex 委任ルールを追加する
- installer generator に `docs/codex-delegation-packet.md` を含める
- Codex 委任ルールの存在と installer 伝播を検証する hook test を追加する
- Claude 側の意味的整合性確認を follow-up TASK として起票する
- `install.sh` を再生成する

## スコープ外（明示的に除外）

- `CLAUDE.md` / `templates/claude-md-snippet.md` の更新は Claude 側タスクで扱うため本 SPEC では行わない
- Claude Code Plan Mode / slash command / subagent / memory / hooks の詳細設計は扱わない
- Codex GitHub Action workflow の新規追加は扱わない
- モデル価格・ベンチマーク値の固定化は行わない
- SAGE runtime enforcement の追加は行わない

## 要件

### 機能要件
- [FR-01] `docs/codex-delegation-packet.md` は Goal / Scope / Non-goals / Constraints / Acceptance Criteria / Tests / File Scope / Human Review の入力欄を持つ
- [FR-02] `AGENTS.md` は Codex が不完全な委任入力を受けた場合、標準レーンでは SPEC/TASK を先に作るか、不足情報を明示してから実装するよう指示する
- [FR-03] `templates/agents-md-snippet.md` は新規導入先の `AGENTS.md` に同じ Codex 委任基準を注入する
- [FR-04] installer は `docs/codex-delegation-packet.md` を生成・更新できる
- [FR-05] hook test は doc / AGENTS / snippet / generator / install.sh の整合性を検証する

### 非機能要件
- [NFR-01] `AGENTS.md` の増分は短く保ち、R7 doctrine に従って長文は `docs/codex-delegation-packet.md` に集約する
- [NFR-02] Codex 固有文書は日本語の user-facing documentation として書く
- [NFR-03] 既存 hook tests の実行時間を大きく増やさない

### セキュリティ要件
- [SEC-01] Codex Delegation Packet は irreversible action / secret / production data / external write の人間レビュー欄を持つ
- [SEC-02] branch name / PR body / issue body 由来の入力は untrusted input として扱う
- [SEC-03] Codex 側の guidance は runtime enforcement ではなく、sandbox / approval / network は Codex 本体設定で扱うことを明示する

### 運用要件
- [OPS-01] Claude 固有修正が必要な場合は Codex 側では実装せず、PR body / follow-up TASK で Claude 側作業として分離する
- [OPS-02] Codex に委任する TASK は `TASK-ID` / File Scope / 完了条件を持つ

## 受け入れ条件（Acceptance Criteria）

- [x] AC-01: `docs/codex-delegation-packet.md` が存在し、必須入力欄をすべて含む
- [x] AC-02: `AGENTS.md` に Codex-only の委任ルールがあり、`CLAUDE.md` は変更されていない
- [x] AC-03: `templates/agents-md-snippet.md` に Codex Delegation Packet の要約が含まれる
- [x] AC-04: `scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` が PASS
- [x] AC-05: `templates/hooks/tests/test-codex-delegation-packet.sh` が PASS
- [x] AC-06: `bash templates/hooks/tests/run-tests.sh` が PASS
- [x] AC-07: `bash scripts/sage-validate.sh` が PASS
- [x] AC-08: `bash scripts/sage-doc-drift.sh` が PASS
- [x] AC-09: Claude 側整合性確認が `TASK-0149` として追跡可能で、Claude 固有ファイルは変更されていない

## 異常系

- 委任入力が Goal / Scope / Acceptance Criteria を欠く場合: Codex は標準レーンの実装に進まず、SPEC/TASK 作成または不足情報の明示に戻る
- File Scope が広すぎる場合: Codex は TASK 分割を提案し、silent scope expansion を避ける
- Claude 固有ファイルの変更が必要な場合: Codex は直接編集せず、Claude 側 follow-up として残す

## 契約

- API: なし
- DB: なし
- イベント: なし

## リスク

- AGENTS.md と CLAUDE.md の header drift: 新規 H2/H3 を AGENTS.md に追加せず、既存節内の短い bullet に留める
- AGENTS.md と CLAUDE.md の semantic drift: 本 SPEC では Claude 側ファイルを触らず、TASK-0149 で follow-up として追跡する
- installer 伝播漏れ: generator test と byte-identical test で検出する
- guidance が長すぎて遵守率が落ちる: AGENTS snippet は短く、詳細を doc に分離する

## 実装メモ（Implementation Agent向け）

- `CLAUDE.md` と `templates/claude-md-snippet.md` は本 SPEC の File Scope に含めない
- `docs/codex-delegation-packet.md` を source of detail とし、AGENTS / snippet は短い参照ルールにする
- `scripts/generator/03-rules.sh` に doc embed を追加し、`scripts/generator/07-installer-main.sh` で `docs/codex-delegation-packet.md` を write/update する

## 関連ID

- PLAN-ID: PLAN-0022
- TASK-ID: TASK-0145, TASK-0146, TASK-0147, TASK-0148, TASK-0149, TASK-0150
