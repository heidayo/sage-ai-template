# Contributing to SAGE Development System

SAGE への貢献を歓迎します。SAGE は AI coding agent 時代の「**仕様駆動・役割分離・実行可能ルール**」開発プロセスのテンプレート OSS です。本ガイドは contribution の最小要件をまとめます。

---

## 0. ライセンス同意

すべての contribution は [Apache License 2.0](LICENSE) のもとで配布されます。PR を開いた時点で、あなたが contribution の権利を持ち、Apache-2.0 のもとで配布することに同意したものとみなされます。

---

## 1. SAGE-on-SAGE Development Flow

> **重要**: SAGE 自身も SAGE プロセスで開発されます。
> 新機能・バグ修正・doc 改善のいずれも、対応する Lane に従ってください。

### Lane 早見表

| Lane          | Branch prefix                  | SPEC | TASK-ID | Gates  | 用途                                |
| ------------- | ------------------------------ | ---- | ------- | ------ | ----------------------------------- |
| 🟢 explore    | `vibe/*`                       | No   | No      | None   | 探索・実験 (本番には直接 merge 不可)|
| 🟡 lite       | `fix/*` `chore/*` `docs/*`    | No   | Yes     | 1+3    | 軽微修正 (max 3 files, no contract) |
| 🔵 standard   | `feature/*` その他             | Yes  | Yes     | 1-4    | 通常の新機能・改修                  |
| 🔴 promotion  | `promote/*`                    | Retro-SPEC | Yes | 1-4 | vibe/* を本番昇格                   |

詳細: [CLAUDE.md §10](CLAUDE.md), [sage/governance.md](sage/governance.md)

### 標準フロー (standard / promotion)

```
1. SPEC を起票       bash scripts/sage-id-gen.sh spec
2. PLAN を起票       bash scripts/sage-id-gen.sh plan
3. TASK を起票       bash scripts/sage-id-gen.sh task
4. ブランチ作成      git switch -c feature/spec-XXXX-short-name
5. 実装             commit ごとに `TASK-XXXX:` prefix を含める
6. ローカル検証     make doctor / shellcheck / sage-validate
7. PR 作成          PR body に SPEC-ID / PLAN-ID / TASK-ID を明記
```

---

## 2. Before You Open a PR

### 必須

- [ ] PR 対象 Lane に応じた SPEC / PLAN / TASK が存在する (lite Lane は TASK のみ)
- [ ] commit message に `TASK-XXXX:` を含む (pre-commit hook で enforce 済み)
- [ ] 変更が TASK File Scope の範囲内に収まっている
- [ ] PR body に SPEC-ID / PLAN-ID / TASK-ID を記載
- [ ] PR title に対応 Lane と一行サマリ (例: `feature: SPEC-0010 distribution trust foundation`)

### 推奨

- [ ] `sage/failures.md` を確認し、過去の失敗パターンを再発させていないか
- [ ] 既存 SPEC で代替できる場合は新 SPEC を作らず追記する
- [ ] 大きな PR は分割を検討 (1 PR = 1 SPEC + 1 PLAN を目安)

---

## 3. Code Quality Requirements

### shell scripts (必須)

- 新規 `*.sh` ファイルは `shellcheck` で warning 0 必須
- 既存 shell file への変更は **変更行に対して** shellcheck warning 0 必須 (既存 baseline は本 PR で解消する責任を持たない)
- `set -euo pipefail` を冒頭に置く (例外: 既存スクリプトで意図的に外している箇所)

```bash
shellcheck install.sh scripts/*.sh templates/hooks/*.sh
```

### hook (`templates/hooks/`)

新規 hook には `templates/hooks/tests/` 以下にテストを追加してください (Codex review R8)。最低限の検証:

- 想定 input (`tool_input.command` / `tool_input.file_path`) で `exit 0` または `exit 2` の挙動が期待通り
- 偽陽性 (false positive) と偽陰性 (false negative) の代表ケース 1 件ずつ
- pattern matching の限界 (bypass 例) を doc コメントで言及

Hook は **pattern matching であり sandbox の代替ではない** という前提を doctrine としてください ([SECURITY.md §5](SECURITY.md))。

### markdown / docs

- 既存ドキュメントの口調・見出しレベル・絵文字使用に合わせる
- 一次ソースを引用する場合、URL は実在する公式ページのみ ([ATTRIBUTION.md](ATTRIBUTION.md) 参照)
- AI 生成テキストをそのまま貼り付けない (人間の編集を経る)

---

## 4. Documentation Changes (Special Rules)

以下のファイルは **human approval が必須** です (CLAUDE.md / AGENTS.md / sage/ への変更)。

| ファイル              | 変更要件                                                        |
| --------------------- | --------------------------------------------------------------- |
| `CLAUDE.md`           | maintainer review 必須。commit message に `human-approved` 明記 |
| `AGENTS.md`           | 同上 (CLAUDE.md と semantic alignment 維持)                     |
| `sage/governance.md`  | maintainer review 必須                                          |
| `sage/anti-patterns.md` | 新規 anti-pattern 追加には **3 件以上の根拠** を示す          |
| `.sage/config.yaml`   | hook profile 変更は影響範囲を PR description に記載             |

理由: これらは AI agent の行動規範に直接影響するため、無検査の変更は supply chain 攻撃面を増やします (Codex review R7 / [Check Point CVE-2025-59536](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/) と同質の課題)。

---

## 5. Quality Gates 概要

PR が merge される前に以下の Gate が走ります (詳細: [sage/quality-gates.md](sage/quality-gates.md), [.github/workflows/](.github/workflows/)):

| Gate | 内容                                                                | 失敗時          |
| ---- | ------------------------------------------------------------------- | --------------- |
| 1    | Structural (lint / format / type / schema)                          | block           |
| 2    | Functional (test / coverage threshold)                              | block (config)  |
| 3    | Security (gitleaks / dependency scan / SAST)                        | block           |
| 4    | Architecture (layer boundary / forbidden deps / traceability)       | block           |
| 5    | Release (Gate 1-4 prerequisite, main/production PR のみ)            | block           |

**AI 評価 (sage-evaluate / sage-review skill) は補助** であり、Gate を pass しない代わりに使うことはできません ([SECURITY.md §5](SECURITY.md))。

---

## 6. Reporting Issues

### Bug / Feature request

通常の GitHub Issue を使ってください: <https://github.com/heidayo/sage-ai-template/issues>

### Security vulnerability

**公開 Issue を作らないでください**。報告手順は [SECURITY.md](SECURITY.md) を参照してください (GitHub Security Advisory 推奨)。

---

## 7. Style and Tone

- **言語**: ユーザー向けドキュメント = 日本語、コード/コメント/commit message = 英語、PR description = 日本語推奨 ([CLAUDE.md §10 言語ルール](CLAUDE.md))
- **AI 生成コードの正直開示**: PR description で AI 生成 / AI 補助の有無に触れる (隠す必要はないが、reviewer が context を持てるように)
- **過度な抽象化を避ける**: SAGE の anti-pattern を踏まないこと ([sage/anti-patterns.md](sage/anti-patterns.md))

---

## 8. Maintainer Notes

現在 SAGE は単独 maintainer プロジェクト ([heidayo](https://github.com/heidayo)) です。response time は best-effort です ([SECURITY.md §2 SLA](SECURITY.md) 参照)。

co-maintainer / domain expert (security / Codex / Claude Code / governance) の参加を歓迎します。Issue または PR で coordinate してください。

---

## 9. References

- [CLAUDE.md](CLAUDE.md) — Claude Code 向け最上位ルール
- [AGENTS.md](AGENTS.md) — Codex 向け最上位ルール
- [sage/governance.md](sage/governance.md) — ライフサイクル詳細
- [SECURITY.md](SECURITY.md) — セキュリティ方針と非対応範囲
- [ATTRIBUTION.md](ATTRIBUTION.md) — 統合知識源・一次ソース一覧
- [sage/anti-patterns.md](sage/anti-patterns.md) — 既知の anti-pattern
- [sage/failures.md](sage/failures.md) — 過去の失敗記録

---

*本 CONTRIBUTING.md は SPEC-0010 / TASK-0096 として 2026-05-01 に追加されました。*
