# TASK-0108: secret-read-multi-layer.sh + tests (Bash subprocess deny)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0108 |
| SPEC-ID   | SPEC-0012 |
| PLAN-ID   | PLAN-0012 |
| ステータス | Pending |
| 担当Agent | Implementation/Test |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 60m |

## 責務

Phase 1 SECURITY.md §3 で開示した「Read deny だけでは Bash subprocess 経由を防げない」穴を実防御で塞ぐ PreToolUse Bash hook を新規作成。`cat .env`, `grep KEY`, `printenv | grep` 等の secret read 経路を block。

## 入力

- SPEC-0012 FR-02, SEC-02, リスク3
- Phase 1 SECURITY.md §3 (「Read(./.env) deny だけでは Bash の cat .env を防げない」記載)
- 参考: [SkillBakery Protect Secrets 動画](https://www.youtube.com/watch?v=T1TjBsYH6Bk) (Phase 1 ATTRIBUTION 経由)
- Phase 2A test harness

## 出力

1. `templates/hooks/secret-read-multi-layer.sh` 新規:
   - `set -euo pipefail` + profile gating
   - jq + grep fallback で COMMAND parse
   - **Block patterns**:
     - `cat|less|more|head|tail|view|nl|od|xxd` の引数に `\.env(\.local|\.production)?$`, `secrets/.*`, `\.pem$`, `\.key$`, `id_rsa`, `\.aws/credentials`, `gcloud.*credentials.*\.json`
     - `grep|rg|ag` で同上の path を target (検索対象として)
     - `printenv|env|set` の出力を pipe 経由で `grep|rg` に渡し、grep target が `KEY|TOKEN|SECRET|API_KEY|PASSWORD|PASSWD` を含む
     - 直接 path: `cat ~/.ssh/id_rsa`, `cat ~/.aws/credentials` 等
   - **Allowlist (false positive 0 のため)**:
     - `.env.example`, `.env.sample`, `.env.template` (テンプレ、実 secret なし)
     - `grep KEY src/**`, `grep TOKEN test/**` のように file argument が source code dir (このパターンは KEY/TOKEN を変数名として検索)
   - block 時 stderr message に対象 file pattern + Phase 1 doctrine link

2. `templates/hooks/tests/test-secret-read-multi-layer.sh`:
   - Block: `cat .env`, `cat ~/.ssh/id_rsa`, `head -5 .env.local`, `printenv | grep API_KEY`, `env | grep TOKEN`
   - Allow: `cat .env.example`, `grep KEY src/main.go`, `cat README.md`, empty stdin
   - Boundary: `.env.test` (allow, テストは secret なし想定), `cat .env-prod` (block, .env-* 系)

## File Scope（変更許可範囲）

- 作成: `templates/hooks/secret-read-multi-layer.sh`
- 作成: `templates/hooks/tests/test-secret-read-multi-layer.sh`
- 削除: なし

## 禁止事項

- 既存 protect-sage-files.sh / block-dangerous-commands.sh への変更禁止 (新規 hook、責務分離)
- false positive を生むほど厳しいパターン禁止 (e.g., `grep KEY` 単独で block すると変数名検索が動かない)
- Allowlist (`.env.example` 等) の定義をハードコードでなく上部 const として宣言 (将来拡張可能性)
- commit が hook 自体に block されないこと (`.env.example` allowlist の test で確認)

## 完了条件

- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS
- [ ] `cat .env` で exit 2
- [ ] `printenv | grep API_KEY` で exit 2
- [ ] `cat ~/.ssh/id_rsa` で exit 2
- [ ] `cat .env.example` で exit 0 (allowlist)
- [ ] `grep KEY src/main.go` で exit 0 (legitimate variable name search)
- [ ] block 時 stderr に Phase 1 doctrine link が含まれる
- [ ] profile=minimal で全 skip
- [ ] commit message に `TASK-0108:` を含む
