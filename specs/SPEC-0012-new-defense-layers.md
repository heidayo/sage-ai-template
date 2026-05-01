# SPEC-0012: New Defense Layers (Phase 2B)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0012 |
| ステータス | Approved |
| 作成日    | 2026-05-01 |
| 更新日    | 2026-05-01 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0010 (Phase 1 distribution-trust), SPEC-0011 (Phase 2A hook hardening) |
| 権限レベル | system |

## 背景・目的

SAGE v2 改修ロードマップ Phase 2B。Phase 2A で既存 hook の品質強化と test infra を入れた上で、本フェーズは **新規 hook 3 種** と **Claude Code sandbox 設定テンプレート** を追加する。

参考資料との対応:

- **lethal-trifecta-detect.sh** (warn-only): Simon Willison の Lethal Trifecta (private data + untrusted input + exfiltration vector) を検出。Codex review R3 通り **block ではなく warn-only** で起動 — pattern matching では完全判定不能だが、3 条件揃った瞬間に開発者に注意喚起する価値はある
- **secret-read-multi-layer.sh**: Phase 1 で「Read deny だけでは Bash subprocess 経由を防げない」と SECURITY.md §3 で開示した穴を実防御で塞ぐ。`cat .env`, `grep ANTHROPIC_API_KEY`, `head ~/.ssh/id_rsa`, `printenv | grep KEY` 等を Bash 経路で block
- **security-filter.sh** (Stop hook): Cluster I (Make Culture sub-agent 報告) で提案された RUN log secret mask。`.sage/runs/RUN-*.yaml` の **全ファイル** を scan して API key / token / JWT パターンを redact。Codex review R5 (RUN log SQLite/FTS は redaction 先行) の前提条件を満たす (Stop event 名と全ファイル scan は TASK-0112 で確定)
- **templates/settings/sandbox.json** (Codex review R2 と整合): SAGE が **runtime sandbox を提供しない** という doctrine は維持しつつ、Claude Code の `denyRead` / `network.allowedDomains` / `failIfUnavailable: true` を含む推奨設定を template として提供 (適用は user の責任、SAGE は雛形提示のみ)

doctrine 更新: governance §9.1 (SAGE が提供するもの) に新規 hook と sandbox template を追記、SECURITY.md threat model の `[partial]` → `[partial→improved]` 表記更新 (実防御層が追加されたことを正直に反映)。

## 対象ユーザー

- SAGE 採用組織 (新規 hook で Phase 1 で開示した穴の一部を実防御化)
- セキュリティ重視の Claude Code ユーザー (sandbox.json テンプレで初期設定を簡略化)
- RUN log を後で SQLite/FTS 索引化したい開発者 (security-filter で secret 漏洩リスクを先に潰す = SPEC-0014+ の前提条件)

## スコープ（含む）

- `templates/hooks/lethal-trifecta-detect.sh` 新規 (warn-only、PreToolUse Bash + Read matcher)
- `templates/hooks/secret-read-multi-layer.sh` 新規 (PreToolUse Bash matcher、`cat .env`/`grep KEY` 等を block)
- `templates/hooks/security-filter.sh` 新規 (Stop hook、`.sage/runs/RUN-*.yaml` の全ファイルを redact)
- `templates/hooks/tests/test-lethal-trifecta-detect.sh`, `test-secret-read-multi-layer.sh`, `test-security-filter.sh` 新規
- `templates/settings/sandbox.json` 新規 (Claude Code sandbox 推奨設定の雛形 — denyRead / network allowlist / failIfUnavailable)
- `templates/settings/README.md` 新規 (sandbox.json の使い方、SAGE は雛形のみ・適用は user 責任の doctrine 明記)
- `.claude/settings.json` の hooks 設定に新 3 hooks 登録 (PreToolUse Bash + Read matcher 拡張、Stop matcher 追加)
- `sage/governance.md` §9.1 に「SAGE が提供するもの」追記 (新 hook 3 種 + sandbox template)
- `SECURITY.md` §3 threat model の `[partial]` 表記を新 hook 追加分について更新 (`[partial → 改善]` 表記)
- `scripts/generate-installer.sh` + `install.sh` 再生成 (新 hook を embed)

## スコープ外（明示的に除外）

- **Codex 専用 sandbox 設定 generator**: SPEC-0014 (Phase 3 docs/codex-security.md) で扱う
- **MCP allowlist runtime mechanism**: Phase 5 (別 SPEC)
- **RUN log SQLite/FTS 索引化**: Phase 5 (security-filter.sh による redaction が前提条件、本 SPEC で先行整備)
- **agent identity inventory**: Phase 5
- **install.sh 分割**: 別 SPEC (Phase 1 で deferred のまま)
- **新規 anti-pattern 追加**: 既存 anti-patterns.md は touch しない (現実観測してから追加すべき)
- **既存 hook の挙動変更**: Phase 2A で完了済、本 SPEC では新規 file 追加のみ

## 要件

### 機能要件

- [FR-01] `templates/hooks/lethal-trifecta-detect.sh` が以下を warn-only で検出 (exit 0 + stderr WARN):
  - 直前/同 session で private data path (`.env*`, `~/.ssh/`, `~/.aws/`, `secrets/`, `*.pem`, `*.key`) が読まれた痕跡
  - 現コマンドが untrusted source (`https://`, `gh issue view`, `gh pr view`, `cat README.md` 等) の文字列を含む
  - 現コマンドが exfiltration vector (`curl -X POST`, `webhook.site`, mail send, `nc <host>`) を含む
  - 3 条件のうち 2 条件以上同時成立で WARN (block ではない、Codex R3 厳守)
  - profile=minimal/none では skip
- [FR-02] `templates/hooks/secret-read-multi-layer.sh` が PreToolUse Bash matcher で以下を block (exit 2):
  - `cat .env`, `cat .env.local`, `cat .env.production`, `cat secrets/*`
  - `grep|rg|ag` で `.env*`/`*.pem`/`*.key`/`secrets/*` を直接 target
  - `head|tail|less|more` で同上
  - `printenv|env|set` の出力を `grep KEY|TOKEN|SECRET|API_KEY` で filter (環境変数経由 secret 漏洩)
  - `~/.ssh/id_rsa`, `~/.aws/credentials`, `~/.config/gcloud/application_default_credentials.json` 直接 read
- [FR-03] `templates/hooks/security-filter.sh` が Stop hook で `.sage/runs/RUN-*.yaml` の **全ファイル** を scan し、以下のパターンを `***REDACTED***` に置換 (per-file atomic write、1 file 失敗が他 file を block しない):
  - `[A-Za-z0-9_-]{20,}` の値で key 名が `api[_-]?key|token|secret|password|jwt` を含む YAML field
  - `sk-[A-Za-z0-9]{32,}` (OpenAI/Anthropic style)
  - `ghp_[A-Za-z0-9]{36}`, `gho_[A-Za-z0-9]{36}` (GitHub PAT)
  - `xox[abp]-[A-Za-z0-9-]+` (Slack token)
  - `AKIA[0-9A-Z]{16}` (AWS Access Key)
  - 置換時は元行をログに残さない (mask 対象は完全消去)
- [FR-04] `templates/settings/sandbox.json` が以下を含む Claude Code sandbox 推奨設定:
  - `permissions.deny`: `Read(./.env*)`, `Read(~/.ssh/**)`, `Read(~/.aws/**)`, `Bash(rm -rf *)`, `Bash(curl *|*sh)`, `Bash(git push --force *)`
  - `sandbox.enabled: true`, `sandbox.failIfUnavailable: true`
  - `sandbox.filesystem.denyRead`: `~/.ssh`, `~/.aws`, `~/.config/gcloud`, `./.env`, `./.env.local`, `./secrets`
  - `sandbox.network.allowedDomains`: `registry.npmjs.org`, `api.github.com`, `api.anthropic.com`
  - 各 key にコメント (JSON 内コメントは無効なので、別途 `templates/settings/README.md` で説明)
- [FR-05] `templates/settings/README.md` に以下を明記:
  - SAGE は **runtime sandbox を提供しない** ことの再確認 (governance §9.2 への link)
  - 雛形を user の `.claude/settings.json` に merge する手順 (jq + マニュアル review)
  - 各 deny rule / sandbox setting の根拠 (CVE-2026-25723 / CVE-2026-33068 等への link)
- [FR-06] `.claude/settings.json` の `hooks` セクションを以下に拡張:
  - `PreToolUse` Bash matcher に `secret-read-multi-layer.sh` と `lethal-trifecta-detect.sh` を追加
  - `PreToolUse` Read matcher に `lethal-trifecta-detect.sh` を追加 (Read tool 経由の private data 痕跡検出)
  - `Stop` matcher に `security-filter.sh` を追加
- [FR-07] `sage/governance.md` §9.1 (SAGE が提供するもの) の「Hook テンプレート」行に新 3 hooks を列挙
- [FR-08] `SECURITY.md` §3.1, §3.3 threat model の該当行を `[partial]` から「partial → Phase 2B で改善」に更新 (正直 disclosure)
- [FR-09] `scripts/generate-installer.sh` を更新し、新 hook 3 件 + `templates/settings/` を install.sh に embed

### 非機能要件

- [NFR-01] 互換性: 既存 hook + Phase 1 機能 (`--dry-run` etc.) は完全保持
- [NFR-02] テスト実行時間: hook test suite が引き続き < 5 秒
- [NFR-03] install.sh size 増加 ≤ 10% (現 235KB → 259KB 以内)
- [NFR-04] sandbox.json は valid JSON (jq parse 通過必須)
- [NFR-05] security-filter.sh の redaction は idempotent (二重実行で破壊的影響なし)

### セキュリティ要件

- [SEC-01] security-filter.sh が誤って RUN log 全体を破壊しない (失敗時は元 file を保持)
- [SEC-02] secret-read-multi-layer.sh の pattern が legitimate use case を block しない (`grep KEY src/` のような変数名検索は allow)
- [SEC-03] lethal-trifecta-detect.sh の WARN message が secret value 自体を含めない (検出パターンの種別のみ報告)
- [SEC-04] sandbox.json の network allowlist が Claude API endpoint を含むことを確認 (Claude Code 自身の動作確保)

### 運用要件

- [OPS-01] `templates/settings/README.md` に「user の `.claude/settings.json` への merge は SAGE が自動で行わない」と明記
- [OPS-02] 新 hook 3 件すべてに minimal profile での skip を実装 (既存 hook と整合)

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `bash templates/hooks/tests/run-tests.sh` exit 0 (既存 47 + 新規分すべて PASS)
- [ ] AC-02: `templates/hooks/lethal-trifecta-detect.sh` が 2 条件成立で stderr に WARN 出力 + exit 0 (block しない)
- [ ] AC-03: `templates/hooks/secret-read-multi-layer.sh` が `cat .env` を含む command で exit 2
- [ ] AC-04: `templates/hooks/secret-read-multi-layer.sh` が `printenv | grep KEY` で exit 2
- [ ] AC-05: `templates/hooks/secret-read-multi-layer.sh` が `grep KEY src/` (legitimate) で exit 0 (false positive 0)
- [ ] AC-06: `templates/hooks/security-filter.sh` が `sk-abcdef0123...` を含む YAML field を `***REDACTED***` に置換
- [ ] AC-07: `templates/settings/sandbox.json` が `jq . templates/settings/sandbox.json` で valid JSON
- [ ] AC-08: `templates/settings/README.md` に "SAGE does not auto-apply" の disclaimer
- [ ] AC-09: `.claude/settings.json` の hooks に新 3 hooks 登録
- [ ] AC-10: `sage/governance.md` §9.1 に新 hooks 言及
- [ ] AC-11: `bash scripts/sage-validate.sh` PASS
- [ ] AC-12: `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] AC-13: `bash scripts/sage-doc-drift.sh` PASS
- [ ] AC-14: `bash install.sh --dry-run` exit 0 (Phase 1 regression なし)
- [ ] AC-15: `wc -c install.sh` ≤ 259000 (NFR-03)

## 異常系

- 想定エラー1: lethal-trifecta-detect の「直前で private data 読まれた痕跡」判定が session 跨ぎ管理難しい → `.sage/runtime/lethal-trifecta-state.json` で状態管理 (TTL 5 分、profile=minimal で無効化)
- 想定エラー2: security-filter.sh が `.sage/runs/` を破壊する事故 → atomic write (`.tmp` → mv) + 失敗時 rollback
- 想定エラー3: sandbox.json を user が誤 merge して Claude Code が起動できない → README に「merge 後 1 セッション目は plan mode から始める」明記
- 境界ケース1: secret-read-multi-layer.sh で `cat .env.example` (テンプレ・実 secret なし) が誤 block → `.env.example`/`.env.sample`/`.env.template` は allowlist

## 契約

- API: なし
- DB: なし
- イベント: Claude Code PreToolUse + Stop hook payload schema (既存依存)
- File contract: `templates/hooks/*.sh` 3 件新規、`templates/settings/sandbox.json` + README 新規、`.claude/settings.json` hooks 配列拡張

## リスク

- リスク1: 新 hook 3 件で false positive が増える → test harness で各 hook positive/negative 両ケース必須、profile=minimal で全無効化可能
- リスク2: security-filter.sh が performance bottleneck (毎 Stop で全 RUN log scan) → per-file atomic write で 1 file 失敗が他 file を block しない設計、profile=minimal で skip。100+ RUN log で計測時間が問題化したら recent N file 化を SPEC-0014 で検討
- リスク3: sandbox.json の denyRead に user の必要 path が含まれて誤動作 → README で「user 環境に合わせて削るのが前提」と明記
- リスク4: lethal-trifecta-detect の 「session 跨ぎ状態」が `.sage/runtime/` を生成して .gitignore に新規 entry が必要 → installer の setup_gitignore で対応 (ただし .sage/runs/ の轍を踏まないよう、最小範囲で追加)

## 実装メモ（Implementation Agent向け）

- 新 hook 3 件すべて Phase 2A の test harness pattern (`_helpers.sh` の `bash_input_json` / `edit_input_json`) で test 可能
- `lethal-trifecta-detect.sh` の状態管理は `.sage/runtime/lethal-trifecta-state.json` (gitignored 推奨)、TTL ベース cleanup
- `security-filter.sh` は `mktemp` + `mv` で atomic write、`trap` で失敗時 rollback
- sandbox.json は **valid JSON のみ** (コメント不可)、説明は別 README
- `.claude/settings.json` の修正は SAGE-managed file change として TASK-0111 で human-approved meta change
- install.sh embed は `embed_file` 関数を新 hook 用に追加 (generate-installer.sh)

## 関連ID

- PLAN-ID: PLAN-0012 (本 SPEC と同時作成)
- TASK-ID: TASK-0107 (lethal-trifecta), TASK-0108 (secret-read), TASK-0109 (security-filter), TASK-0110 (sandbox.json), TASK-0111 (doctrine + install.sh)
