# SPEC-0014: installer modularize (generate-installer.sh 分割)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0014 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |
| 更新日    | 2026-05-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0010 (installer foundation), SPEC-0015/0016/0017 (各 Phase 5+ で installer 拡張) |
| 権限レベル | platform |
| 予約Phase | Phase 5+ (SPEC-0010..0013 で予約済) |

## 背景・目的

`scripts/generate-installer.sh` は当初 100 行程度の generator だったが、Phase 1-5+ の機能追加で **938 行**に肥大化:

- Phase 1 (SPEC-0010): 60+ embed_file 呼び出し (templates / configs / hooks)
- Phase 2A (SPEC-0011): hook 共通基盤 + test embed
- Phase 2B (SPEC-0012): security-filter + secret-read + lethal-trifecta + sandbox.json
- Phase 3 (SPEC-0013): docs/codex-security.md 関連
- Phase 5 (SPEC-0015): mcp-allowlist hook + template + test + perf helper
- Phase 5+ (SPEC-0017): agent-inventory template + validator + test
- Phase 5+ (SPEC-0016): runlog-index + search + db-audit + 3 tests

結果、`generate-installer.sh` は:

1. **可読性低下**: embed_file 30+、write_file_if_new 35+、update_file 35+ で同種コードが反復
2. **追加コスト増**: 新 SPEC のたびに 4-7 箇所 (declare / write / update / installer 呼び出し) を編集
3. **regression 危険**: 1 箇所修正で他箇所と整合不良 (Phase 3 の TASK-0117/0119 で経験済)

本 SPEC は **`scripts/generate-installer.sh` を機能別 module に分割** し、保守性を向上する。**`install.sh` 自体 (生成物) は単一ファイル維持** — `curl | bash` distribution UX を破壊しない。

## 対象ユーザー

- SAGE 本体 maintainer (新 hook / template 追加時のコスト削減)
- SAGE template の二次配布者 (内部構造を理解しやすく)
- Phase 6+ で installer に新機能追加する future contributor

## スコープ（含む）

- **`scripts/generate-installer.sh` 分割**: 機能別 module を `scripts/generator/` 配下に配置
  - `01-templates.sh`: SPEC/PLAN/TASK/sage governance テンプレ embed
  - `02-config.sh`: `.sage/config.yaml` / claude-md-snippet / pre-commit hook
  - `03-rules.sh`: `templates/rules/*.md` (5 file)
  - `04-hooks-base.sh`: Phase 1-2A hook (block-dangerous / protect-sage / check-file-scope / session-*)
  - `05-hooks-phase2b.sh`: Phase 2B hook (lethal-trifecta / secret-read / security-filter / sandbox)
  - `06-hooks-phase5.sh`: Phase 5 hook + audit (mcp-allowlist / agent-inventory / runlog-*)
  - `07-installer-main.sh`: install.sh の main logic (write_file_if_new / update_file 呼び出し)
- **`scripts/generate-installer.sh` re-write**: 各 module を `source` で読み込み、orchestration のみ
- **module test**: 各 module 単独実行で expected output 出すか確認
- **install.sh 再生成**: 分割後の generate-installer.sh で **同 install.sh が出力される** (regression なし)
- **doctrine documentation**: 5 doc R7 厳守 (各 +3 行以内)

## スコープ外（明示的に除外）

- **`install.sh` 自体の分割**: distribution UX (`curl | bash`) を破壊するため不可、単一ファイル維持
- **install logic 変更**: write_file_if_new / update_file の挙動は不変 (refactor only)
- **新機能追加**: 本 SPEC は refactor 専念、Phase 6+ で別 SPEC
- **Python rewrite**: bash 互換性維持、shell only
- **Gist URL 自動更新**: Phase 1 SPEC-0010 確定済 (本 SPEC で触らない)
- **install-state.yaml schema 変更**: 既存 doctor / validator 影響なし

## 要件

### 機能要件

- **[FR-01] module ディレクトリ**: `scripts/generator/` 配下に 7 module file
  - 各 module は `set -euo pipefail` + `embed_file` 関数依存 (parent から source される)
  - module 単体実行不可 (parent generate-installer.sh から source される設計)
  - module 順序: 01 → 07 (numeric prefix で順序保証)

- **[FR-02] generate-installer.sh re-write**:
  - `set -euo pipefail`
  - `embed_file` / `write_file_if_new` / `update_file` 関数定義 (既存ロジック維持)
  - `for module in scripts/generator/*.sh; do source "$module"; done` で順次 source
  - main logic のみ約 100-150 行 (現 938 → 短縮)

- **[FR-03] regression test**: 分割前後の install.sh が **byte-identical** であることを CI で検証
  - `bash scripts/generate-installer.sh > /tmp/install-new.sh && diff install.sh /tmp/install-new.sh` で 0 件

- **[FR-04] module 単体 sanity check**: 各 module が source 可能 (syntax error なし)
  - `for m in scripts/generator/*.sh; do bash -n "$m" || exit 1; done`

- **[FR-05] documentation**:
  - `scripts/generator/README.md` 新規 (module 構造 + 新 SPEC 追加時の手順)
  - 5 doc cross-refs (sage/governance.md §9.1 / AGENTS.md / CLAUDE.md / SECURITY.md / docs/codex-security.md、各 +3 行以内)

### 非機能要件

- **[NFR-01] パフォーマンス**: `bash scripts/generate-installer.sh > install.sh` 実行時間 < 2s (現状と同等)
- **[NFR-02] backward compat**: 生成された `install.sh` は既存と完全 identical (byte-level diff 0)
- **[NFR-03] portability**: macOS / Linux 両対応 (bash 4+、source / set -e)
- **[NFR-04] auditability**: 新 SPEC 追加時に編集すべき file は **最小 1 module のみ** (現状 4-7 箇所 → 1 箇所)
- **[NFR-05] test scenario coverage**: 6 シナリオ (byte-identical / module syntax 7 module / 新 hook 追加例 / 既存 install.sh 削除後の再生成 / module source 順序 / install --update PASS)

### セキュリティ要件

- **[SEC-01] no functional change**: 本 SPEC は pure refactor、install.sh の挙動は不変 (security regression 0)
- **[SEC-02] module file permission**: `scripts/generator/*.sh` は 644 (executable bit 不要、source されるのみ)
- **[SEC-03] no new external dependency**: bash + standard POSIX utilities のみ
- **[SEC-04] embed_file allowlist 維持**: 元 generate-installer.sh で embed されていた file 一覧と完全一致 (新規 file 追加禁止)

### 運用要件

- **[OPS-01] 新 SPEC 追加時の手順**: README で「新 hook 追加時は scripts/generator/0X-hooks-*.sh の embed_file + write/update を 1 箇所追加」と明示
- **[OPS-02] module rename / split 時の手順**: README で「module file rename 時は generate-installer.sh の glob 順序を確認」と明示
- **[OPS-03] regression test の運用**: `make test` で byte-identical check を含める (NFR-04a)
- **[OPS-04] 段階採用昇格条件**:

  | 昇格 | 条件 | 検証コマンド |
  |---|---|---|
  | none → modular | byte-identical 確認 + test 全 PASS | `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh \| wc -l` で 0 |
  | modular → 新 SPEC で実証 | 1 SPEC 追加で 1 module だけ編集して install.sh 再生成成功 | git log で SPEC-0018 等の installer-related commit が module 1 件のみ touch |

## 受け入れ条件 (AC)

- [ ] AC-01: `scripts/generator/` directory 存在、7 module file (01-templates / 02-config / 03-rules / 04-hooks-base / 05-hooks-phase2b / 06-hooks-phase5 / 07-installer-main)
- [ ] AC-02: `scripts/generator/README.md` 新規、module 構造 + 新 SPEC 追加手順
- [ ] AC-03: `scripts/generate-installer.sh` re-written (約 100-150 行、main orchestration のみ)
- [ ] AC-04: 各 module `bash -n` で syntax error 0 件
- [ ] AC-05: `bash scripts/generate-installer.sh > /tmp/install-new.sh && diff install.sh /tmp/install-new.sh` で 0 行 (byte-identical)
- [ ] AC-06: `templates/hooks/tests/test-installer-modularize.sh` 6 シナリオ全 PASS
- [ ] AC-07: 5 doc cross-refs (各 +3 行以内、R7 厳守)
- [ ] AC-08: `bash scripts/sage-validate.sh` PASS
- [ ] AC-09: `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] AC-10: `bash scripts/sage-doc-drift.sh` PASS
- [ ] AC-11: `bash templates/hooks/tests/run-tests.sh` 全 PASS (159 既存 + 6 新規 = 165+)
- [ ] AC-12: `time bash scripts/generate-installer.sh > install.sh` < 2s (NFR-01)

### Quality Gate との対応

| AC | 検証 Gate | 検証コマンド (CI) |
|---|---|---|
| AC-01, AC-02, AC-04 | Gate 1 (Structural: file existence + bash syntax) | `ls scripts/generator/*.sh \| wc -l` で 7 + `bash -n` |
| AC-05, AC-06, AC-11, AC-12 | Gate 2 (Functional: byte-identical + tests + perf) | `diff` + `bash run-tests.sh` + `time` |
| SEC-01..SEC-04 | Gate 3 (Security: no functional change / file permission / no new dep) | byte-identical 確認 + `stat scripts/generator/*.sh` で 644 |
| AC-08, AC-09, AC-10 | Gate 4 (Architecture: validation + doctor + doc-drift) | `bash sage-validate.sh && bash sage-doctor.sh && bash sage-doc-drift.sh` |
| AC-07 | Gate 4 (Architecture: doctrine alignment、R7 厳守) | `wc -l` で各 +3 行以内 |

Gate 5 (Release) は本 SPEC 単独では発火しない。

## エラーケース

- **EC-01** (module file 不在): generate-installer.sh が source error → exit 1 (CI で fail)
- **EC-02** (byte-identical fail): regression test が diff > 0 → CI fail、refactor が functional change を含んでいる signal
- **EC-03** (module syntax error): `bash -n` で検出 → exit 1
- **EC-04** (module の embed_file 関数依存): single module 実行で undefined function error → README で「source from parent only」明示

## 依存関係 / リスク

### 依存
- 既存 `scripts/generate-installer.sh` (Phase 1 SPEC-0010 で導入)
- `embed_file` / `write_file_if_new` / `update_file` 関数定義 (本 SPEC で parent に集約)
- bash 4+ + POSIX utilities

### リスク

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | 分割で install.sh が変わる (byte-identical fail) | FR-03 で diff CI 必須、refactor only | `diff install.sh /tmp/new.sh \| wc -l` で 0 |
| 2 | module 順序ミスで embed file が逆順に | FR-01 で numeric prefix (01-07) glob sort 保証 | `for m in scripts/generator/*.sh; do echo "$m"; done` で順序確認 |
| 3 | 新 SPEC 追加時に間違った module を編集 | OPS-01 README で「Phase で module 選択」 | 新 SPEC PR で module 1 件のみ touch |
| 4 | embed_file 関数の signature 変更で全 module 破壊 | embed_file は本 SPEC で signature 不変 | git diff で関数定義行が変更されていないこと |
| 5 | source 順序依存の hidden state | 各 module は独立、共有 state は parent 関数のみ | module 間に環境変数依存 0 件 |

## 失敗時の知識蓄積

### 知識蓄積フロー (3 ステップ)

```
Step 1 [検出]
  CI で byte-identical fail / module syntax error が発生
  ↓
Step 2 [記録]
  同 root cause で 2 回以上発生 → sage/failures.md に FAIL-INSTALL-XXXX として追記
  ↓
Step 3 [昇格]
  同 root cause で 3 回以上発生 → sage/anti-patterns.md に追記、generator architecture 見直し
```

### sage/failures.md 連携

- **誰が**: refactor PR の reviewer / CI で byte-identical fail を確認した contributor
- **いつ**: 同 root cause (embed_file 順序 / source 依存 / glob sort 違い等) で 2 回以上発生時
- **どの手順で**: error log + 該当 commit SHA を抽出 → `sage/failures.md` に FAIL-INSTALL-XXXX として 6 elements で追記

### sage/anti-patterns.md への昇格

3 回以上発生で `sage/anti-patterns.md` に「INSTALL-XXXX」追記、generator architecture 見直しを Phase 6+ で SPEC 起票。

### Error Resolution 手順

| EC | エラー時メッセージ例 | Resolution |
|---|---|---|
| EC-01 (module file 不在) | `ERROR: scripts/generator/0X-*.sh not found` | git で missing file を check、再 clone |
| EC-02 (byte-identical fail) | `FAIL: install.sh diff: N lines` | 該当 module を bisect、refactor が functional change を含んでないか確認 |
| EC-03 (module syntax) | `bash: scripts/generator/0X.sh: line N: syntax error` | 該当 module の bash syntax 修正 |
| EC-04 (single module 実行 error) | `bash: embed_file: command not found` | README に従い generate-installer.sh から source する |

## ロールバック手順

本 SPEC は pure refactor のため、ロールバックは段階的:

| レベル | 手順 | 影響範囲 |
|---|---|---|
| 1. 一時 disable | `scripts/generator/` を rename → `scripts/generate-installer.sh` を旧版に reset | 旧 monolith generator が動作 |
| 2. module 単独 revert | 問題 module を git revert | 1 module の変更が巻き戻り、他 module は新版維持 |
| 3. 完全 revert | 本 SPEC 導入 PR を `git revert` | scripts/generator/ 削除、generate-installer.sh 旧版復帰 |

各ロールバック後の検証:
- `bash scripts/generate-installer.sh > /tmp/old.sh && diff install.sh /tmp/old.sh` で 0 行
- `bash scripts/sage-doctor.sh` 0 FAIL
- `bash templates/hooks/tests/run-tests.sh` 159/159 (Phase 5+ base line) PASS

## 関連 Doctrine

- **R5 (RUN log redaction)**: 本 SPEC は redaction logic に触らない (refactor only)
- **R7 (CLAUDE/AGENTS 肥大化禁止)**: 5 doc each +3 行以内
- **R8 (hook tests)**: 6 scenario test 必須
- **R10 (一次ソース)**: bash 公式 docs (source / set -e) を一次ソースとして引用

## Phase 5+ 全体の position

| SPEC | スコープ | 状態 |
|---|---|---|
| **SPEC-0014** | **installer modularize** ← 本 SPEC | Draft |
| SPEC-0015 | MCP allowlist audit | merged (PR #21) |
| SPEC-0016 | RUN log SQLite-FTS | merged (PR #24) |
| SPEC-0017 | Agent identity inventory | merged (PR #23) |

本 SPEC は Phase 5+ の **最終 refactor SPEC**。完了で SAGE v2 ロードマップ 17 SPEC 全完了予定。

## Properties

権限レベル `platform` + Security 要件あり (supply-chain trust、SPEC-0018 と直交補完) のため 5 件以上必須 (SPEC-0024 §11.1)。

### AC ↔ Property 対応表 (SPEC-0024 retrofit、governance §11.6)

本 SPEC retrofit (TASK-0167) で追加した Properties は、既存 AC の declarative version。矛盾発生時は SPEC を更新する (governance §11.4)。

### Invariants
- [INV-01] (Gate 4) `scripts/generator/` の 7 module で生成した install.sh が canonical install.sh と byte-identical (`bash scripts/generate-installer.sh > /tmp/new && diff install.sh /tmp/new` で 0 行、AC-byte-identical と対応)
- [INV-02] (Gate 3) install.sh で配布される全 managed_files が SHA256SUMS と一致 (SPEC-0018 supply chain hardening と整合)
- [INV-03] (Gate 4) 7 module の責務分離 (01-templates / 02-config / 03-rules / 04-hooks-base / 05-hooks-phase2b / 06-hooks-phase5 / 07-installer-main) を維持、cross-module 直接呼び出し禁止
- [INV-04] (Gate 3) generator は手書き install.sh への直接編集を禁止 (`bash scripts/generate-installer.sh > install.sh` のみが正規 path)

### Pre-conditions
- [PRE-01] (Gate 2) install.sh 実行環境に bash 4+ + standard unix tools (`sha256sum` / `shasum` / `curl`) が存在

### Post-conditions
- [POST-01] (Gate 2) `bash install.sh --update` 実行後、既存 `.sage/config.yaml` の `installer_url` 値は不変 (backward compat、Phase 5+ 全 SPEC で維持)

### Assumptions
- [ASM-01] (Gate 横断) generator の embed 方式 (`TMPL_*` heredoc) で template content が install.sh 内に literal embed される (template の bytes-as-is 配布)
