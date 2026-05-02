# SPEC-0018: Installer Supply Chain Hardening Phase 1 (GitHub Releases + SHA256SUMS + URL pinning)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0018 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |
| 更新日    | 2026-05-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0010 (distribution & trust foundation), SPEC-0014 (installer modularize) |
| 権限レベル | platform |
| 予約Phase | Phase 6.1 (SECURITY.md §3.1 で「Phase 6+ で別途起票予定」と予約済の枠を埋める) |

## 背景・目的

外部レビュー 2026-05-02 ([docs/external-reviews/2026-05-02-general-repo-review.md](../docs/external-reviews/2026-05-02-general-repo-review.md)) で以下のギャップが指摘された:

> 「installer の供給網リスクが大きい」「remote installer URL の pinning, signing, SLSA provenance, GitHub Releases primary distribution は未実装」「`curl ... | bash` で入れるのはおすすめしません」

[SECURITY.md §3.1](../SECURITY.md) でも同ギャップが事前認識されており、「将来 SPEC で扱う候補 (具体 SPEC-ID 未確定、Phase 6+ で別途起票予定)」と明記されている。

現状の配布フロー (Phase 1 以降):

| 配布物 | 場所 | 整合性検証 |
|---|---|---|
| install.sh | Gist (`gist.githubusercontent.com/heidayo/.../raw/install.sh`) | local `--verify-checksum` のみ (TASK-0097) |
| SAGE_VERSION | install.sh 内 hardcode (`SAGE_VERSION="1.5.0"`) | `--print-provenance` で表示 |
| SHA256 | local `.sage/install-state.yaml` の sha256 (drift 検出のみ) | リモート公開 SHA256SUMS なし |

問題:

1. **mutable distribution**: Gist の `/raw/install.sh` は HEAD を返し、過去 version の immutable URL を提供しない
2. **integrity verification 不可**: 利用者が手元で SHA256 を計算しても、信頼すべき "正解値" の公開ソースがない
3. **single point of failure**: Gist は GitHub Releases と異なり、release notes / artifact / signature の標準機構を持たない
4. **`curl | bash` UX 不安全**: 利用者は内容確認なしに実行することになり、レビュアー指摘 "本番リポジトリに対してこの方式は推奨しない" の根拠

本 SPEC は Phase 6 ロードマップの最初として **GitHub Releases primary distribution + SHA256SUMS 公開 + URL pinning** を実装する。cosign keyless signing (SPEC-0019) と SLSA provenance (SPEC-0020) は本 SPEC の後続として別 SPEC で扱う。

## 対象ユーザー

- 本番リポジトリへの SAGE 導入を検討する組織 (現状 `curl | bash` を躊躇している)
- supply chain audit を要求される regulated industry の利用者
- `--verify-checksum` で local drift しか検証できない既存利用者
- Renovate / Dependabot 風の自動更新を将来導入したい maintainer
- 過去 version の install.sh を pin したい reproducibility 重視 user

## スコープ（含む）

- **`.github/workflows/release.yml` 新規**: tag push (`v*.*.*`) で GitHub Release を自動発行
  - generate-installer.sh で install.sh を再生成し byte-identical 確認
  - install.sh の SHA256 を計算
  - SHA256SUMS file を生成 (single-file format: `<sha256>  install.sh`)
  - Release に install.sh + SHA256SUMS を attach
  - Release notes に SAGE_VERSION / 主要変更 / verification 手順を含める
- **`scripts/sage-publish.sh` 拡張**: 既存の Gist 更新フローに加え、`gh release create` で GitHub Release も発行
  - `--no-release` flag で legacy Gist-only モードも維持 (backward compat)
  - SHA256SUMS をローカルでも生成し commit
- **`scripts/generator/02-config.sh` 修正**: 新規 install のデフォルト `installer_url` を Releases URL に変更
  - 旧: `https://gist.githubusercontent.com/heidayo/.../raw/install.sh`
  - 新: `https://github.com/heidayo/sage-ai-template/releases/latest/download/install.sh` (latest) または tag-pinned URL
  - 既存 install (`.sage/config.yaml` 既存) は触らない (backward compat)
- **`scripts/sage-update-check.sh` 拡張**: Releases URL も認識可能にする (URL pattern 追加)
- **`scripts/sage-validate.sh` Check 9 拡張**: installer_url が Releases / Gist いずれでも sync check が動作するように pattern 拡張
- **install.sh `--verify-checksum` 拡張**: optional remote SHA256SUMS 取得モード追加
  - `bash install.sh --verify-checksum --remote` で `releases/latest/download/SHA256SUMS` を fetch して比較
  - default (no `--remote`) は従来の local install-state.yaml と現状ファイル比較を維持
- **README.md 更新**: 配布チャネルセクションを Releases primary に書き換え (Gist は legacy fallback として残す)
- **SECURITY.md §3.1 更新**: `[partial]` → `[improved]` (本 SPEC 完了時)
- **doctrine documentation**: 5 doc cross-refs (R7 厳守、各 +3 行以内)

## スコープ外（明示的に除外）

- **cosign keyless signing**: GitHub Actions OIDC + Sigstore Fulcio keyless signing は **SPEC-0019 (Phase 6.2)** で扱う。本 SPEC は SHA256 整合性検証のみで、改ざん検知は可能だが「誰が署名したか」の証明は未提供
- **SLSA provenance**: build attestation (`slsa-framework/slsa-github-generator`) は **SPEC-0020 (Phase 6.3)** で扱う。本 SPEC は workflow 自体は記録するが SLSA Level 2+ 準拠ではない
- **Gist URL の即時廃止**: 既存利用者の `.sage/config.yaml` の installer_url を強制書き換えない。新規 install のみ Releases URL を default に。Gist 廃止は Phase 6.4 以降の運用判断 (利用者通知期間を設けてから)
- **renovate.json / dependabot.yaml**: 自動更新支援は別 SPEC、本 SPEC は配布側のみ
- **install.sh の更なる分割 / minimization**: SPEC-0014 で modular source 化済、本 SPEC は配布チャネルのみ
- **adoption guide (Next.js / Go / monorepo)**: SPEC-0021 候補 (docs lane) で扱う
- **threat model 視覚化 (mermaid)**: 本 SPEC は配布フロー図を 1 件追加するに留める。Threat model 全体図は別 docs SPEC

## 要件

### 機能要件

- **[FR-01] release workflow** (`.github/workflows/release.yml`):
  - trigger: `push: tags: v*.*.*`
  - permissions: `contents: write` (release 作成のみ)、それ以外は read
  - steps:
    1. checkout (full history not required)
    2. `bash scripts/generate-installer.sh > /tmp/install.sh && diff install.sh /tmp/install.sh` (byte-identical 検証)
    3. SHA256 計算 (`shasum -a 256 install.sh > SHA256SUMS`)
    4. `gh release create "$TAG" install.sh SHA256SUMS --notes-file <generated>`
  - tag が semver 形式でない場合は exit 1 (validation)

- **[FR-02] SHA256SUMS format**:
  - 単一行: `<64-char-sha256-hex>  install.sh` (POSIX `shasum` / `sha256sum` 互換)
  - utf-8、改行は LF
  - 複数 artifact 化は将来 (cosign signature 等) 拡張可能な format を採用

- **[FR-03] sage-publish.sh 拡張**:
  - 既存: version bump + install.sh 再生成 + Gist 更新
  - 追加: `git tag v$NEW_VERSION && git push --tags` で release.yml をトリガー
  - flag: `--no-release` で legacy Gist-only mode (CI 不在の local-only test 用)
  - flag: `--no-gist` で Releases-only mode (Gist 廃止 phase で利用)
  - SHA256SUMS をローカルでも生成し `.sage/install-state.yaml` に記録

- **[FR-04] default installer_url 切り替え**:
  - `scripts/generator/02-config.sh` の template `.sage/config.yaml` 生成箇所で URL を変更
  - 新 default: `https://github.com/heidayo/sage-ai-template/releases/latest/download/install.sh`
  - 既存 install (`.sage/config.yaml` 既存) は install.sh が触らない (現状 logic 維持、SPEC-0008 NFR-01 backward compat)

- **[FR-05] `--verify-checksum --remote` モード**:
  - default (no flag): 従来通り local `.sage/install-state.yaml` の sha256 と現状 file の sha256 を比較
  - `--remote` flag: `curl -fsSL https://github.com/heidayo/sage-ai-template/releases/latest/download/SHA256SUMS` を fetch し、現状 install.sh の sha256 と比較
  - 比較 mismatch → exit 1、stderr に「remote SHA256 mismatch: expected X, got Y」
  - network 不可 → warning + exit 0 (graceful、verification skip)

- **[FR-06] URL sync check 拡張**:
  - `scripts/sage-validate.sh` Check 9: 既存は Gist URL pattern 限定で、Releases URL では SKIP に倒れていた
  - 拡張: Gist と Releases 両方の URL pattern を許可、URL 種別を判定して適切な sync check を実施

- **[FR-07] update-check 拡張**:
  - `scripts/sage-update-check.sh`: 既存は Gist URL から install.sh を fetch して SAGE_VERSION 抽出
  - 拡張: Releases URL の場合は `gh api repos/heidayo/sage-ai-template/releases/latest` で tag_name (`v1.6.0`) を取得して比較

- **[FR-08] documentation**:
  - README.md: 「インストール」節に Releases URL を primary、Gist URL を legacy fallback として記載
  - SECURITY.md §3.1: `[partial]` row を `[improved]` に更新、SPEC-0018 link を追加
  - 5 doc cross-refs (sage/governance.md §9.1 / AGENTS.md / CLAUDE.md / docs/codex-security.md / docs/maintainer-guide.md、各 +3 行以内、R7 厳守)
  - `scripts/generator/README.md` に「Phase 6 で `02-config.sh` の installer_url を Releases に変更した」と追記

### 非機能要件

- **[NFR-01] backward compat**: 既存 `.sage/config.yaml` の Gist URL は触らず動作継続。`bash install.sh --update` で Gist URL のままでも従来動作
- **[NFR-02] no breaking change for `curl | bash` UX**: Releases URL も `curl -fsSL <URL> | bash` 互換 (302 redirect 経由でも問題なし)
- **[NFR-03] performance**: workflow 実行時間 < 60s (Codex review R7 と同等の速度要件)
- **[NFR-04] portability**: macOS / Linux 両対応 (`shasum -a 256` / `sha256sum` 既存 fallback logic 流用)
- **[NFR-05] auditability**: workflow logs が GitHub Actions UI で参照可能、`gh release view` で artifact 一覧

### セキュリティ要件

- **[SEC-01] workflow least privilege**: release.yml の `permissions:` は `contents: write` のみ。`packages: write` / `id-token: write` は不要 (cosign は SPEC-0019 で追加)
- **[SEC-02] no secret in workflow**: `GITHUB_TOKEN` は default、別 PAT / API key / SSH key を使用しない
- **[SEC-03] tag protection**: workflow trigger を `tags: v*.*.*` に限定、branch push では発火しない
- **[SEC-04] byte-identical 強制**: workflow が生成した install.sh と repo の install.sh が一致しない場合は release を中止 (commit 漏れ防止)
- **[SEC-05] SHA256SUMS の改ざん**: SHA256SUMS 自体は SPEC-0019 で cosign 署名予定。本 SPEC では「workflow が生成、release artifact に attach」までのみ提供 (Threat model 上、Releases artifact の改ざんは GitHub repo 自体の compromise を要し本 SPEC scope 外)
- **[SEC-06] no external download**: workflow は外部 URL から code を fetch しない (supply chain pollution 防止)

### 運用要件

- **[OPS-01] release procedure**: `bash scripts/sage-publish.sh patch` (既存) で version bump → tag push → release.yml 発火 → Release 公開、ワンコマンド維持
- **[OPS-02] Gist 廃止 phase**: 本 SPEC では Gist と Releases 両方を維持 (利用者移行期間)。Phase 6.4 以降で Gist 廃止判断 (別 SPEC)
- **[OPS-03] tag 命名規約**: `v<major>.<minor>.<patch>` (semver、`v` prefix 必須)。`vX.Y.Z-rc1` 等の pre-release は本 SPEC では未対応 (Phase 6 後半で別 SPEC)
- **[OPS-04] release 失敗時**: tag を delete + push (`git push --delete origin v$VERSION`) で再 release 可能。release.yml は冪等
- **[OPS-05] 段階採用昇格条件**:

  | 昇格 | 条件 | 検証コマンド |
  |---|---|---|
  | none → Releases 導入 | release.yml が 1 度成功、SHA256SUMS が release artifact に存在 | `gh release view v1.6.0 \| grep SHA256SUMS` |
  | Releases primary → Gist legacy 通知 | Releases で 30 日運用 + 既存利用者通知済 | README 更新 commit + 通知 issue 作成 |
  | Gist legacy → Gist 廃止 | 90 日通知期間後、`installer_url` の Gist 利用が config.yaml で 0 件 (利用者調査) | (別 SPEC で扱う) |

## 受け入れ条件 (AC)

- [ ] AC-01: `.github/workflows/release.yml` 存在、`tags: v*.*.*` trigger、permissions `contents: write` 限定
- [ ] AC-02: workflow が tag push で発火し、release artifact に install.sh + SHA256SUMS が attach される (manual test for v1.6.0-test or scripted dry-run)
- [ ] AC-03: `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` で 0 行 (byte-identical 維持、SPEC-0014 regression なし)
- [ ] AC-04: `scripts/sage-publish.sh patch` 実行で .sage-version + install.sh + .sage/install-state.yaml + SHA256SUMS が更新される (`--no-release` flag 動作確認込み)
- [ ] AC-05: `scripts/generator/02-config.sh` で生成される template `.sage/config.yaml` の `installer_url` が Releases URL になっている
- [ ] AC-06: `bash install.sh --verify-checksum --remote` が、network 利用可能な環境で release SHA256SUMS と比較し、一致時 exit 0 / 不一致時 exit 1 / network 不可時 warning + exit 0
- [ ] AC-07: `bash scripts/sage-validate.sh` Check 9 が Gist URL / Releases URL 両方で SKIP せず PASS (`SKIPPED:` 表示でなく `OK:` 表示)
- [ ] AC-08: `bash scripts/sage-update-check.sh` が Releases URL でも version 比較を行う (Gist URL も従来通り)
- [ ] AC-09: README.md の「インストール」節に Releases URL が primary、Gist URL が legacy fallback として記載
- [ ] AC-10: SECURITY.md §3.1 の `installer_url` row が `[partial]` → `[improved]` に更新、SPEC-0018 へのリンクが追加
- [ ] AC-11: 5 doc cross-refs (各 +3 行以内、R7 厳守)
- [ ] AC-12: `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] AC-13: `bash templates/hooks/tests/run-tests.sh` 全 PASS (既存 + 新規 release-workflow-mock テスト)
- [ ] AC-14: `templates/hooks/tests/test-release-workflow.sh` 新規、4+ シナリオ (byte-identical / SHA256 計算 / SHA256SUMS format / `--remote` mode mock) 全 PASS
- [ ] AC-15 (異常系 — invalid input): tag が semver でない場合 (`v1.0` / `1.6.0` / `vX.Y.Z-rc1` 等) で release.yml が validation step で exit 1、`gh run list --workflow=release.yml --json conclusion` で `failure` を返す (`gh release view` で対応 release が存在しないことも併せて確認)
- [ ] AC-16 (異常系 — backward compat / legacy config): 既存 Gist URL fixture (`.sage/config.yaml` の `installer_url: https://gist.githubusercontent.com/...`) で `bash install.sh --update` が exit 0、新 Releases URL に強制書き換えされない (`grep -c "gist.githubusercontent.com" .sage/config.yaml` が 1 のまま)
- [ ] AC-17 (異常系 — release 重複): 同 tag (`v1.6.0`) で release.yml を 2 度発火させた際、2 回目が `gh release create` の `release already exists` で exit 1、既存 release artifact が破壊されない (`gh release view v1.6.0 --json assets` で count 不変)

### Quality Gate との対応

| AC | 検証 Gate | 検証コマンド (CI) |
|---|---|---|
| AC-01, AC-05, AC-09, AC-10 | Gate 1 (Structural: file 存在 + content pattern) | `test -f .github/workflows/release.yml && grep -q "tags: v" .github/workflows/release.yml` 等 |
| AC-03, AC-04, AC-13, AC-14 | Gate 2 (Functional: byte-identical + tests) | `diff install.sh /tmp/new.sh && bash run-tests.sh` |
| AC-06, AC-07, AC-08 | Gate 2 (Functional: --verify-checksum / sage-validate / update-check) | 各コマンド直接実行 |
| AC-15, AC-16, AC-17 | Gate 2 (Functional: 異常系) + Gate 5 (Release: tag validation) | `act push --eventpath /tmp/invalid-tag.json` で AC-15 / Gist fixture で `bash install.sh --update` で AC-16 / 同 tag 再発火で AC-17 |
| SEC-01..SEC-06 | Gate 3 (Security: workflow privilege / no secret / no external download) | `grep -E "permissions:|secrets\." .github/workflows/release.yml` |
| AC-11, AC-12 | Gate 4 (Architecture: doc-drift / doctor) | `bash sage-doc-drift.sh && bash sage-doctor.sh` |
| AC-02 | Gate 5 (Release: actual tag push) | manual verification per release |

Gate 5 (Release) は本 SPEC で初めて意味のある artifact 検証が可能になる (release.yml が release artifact を生成するため)。

## エラーケース

- **EC-01** (workflow byte-identical fail): release.yml step 2 で diff > 0 → workflow 全体 fail、release 中止。原因: install.sh が generate-installer.sh と同期していない (commit 漏れ)。Resolution: `bash scripts/generate-installer.sh > install.sh && git commit` で再 push
- **EC-02** (tag が semver でない): `v1.0` (3 桁未満) や `1.6.0` (`v` prefix なし) で push → workflow が validation 失敗で exit 1
- **EC-03** (release 既存): 同 tag で再 push → `gh release create` が `release already exists` で fail。Resolution: 旧 release を delete (`gh release delete v1.6.0`) してから再 push
- **EC-04** (network 不可で `--verify-checksum --remote`): `curl -fsSL .../SHA256SUMS` が fail → warning「remote verification skipped」、exit 0 (graceful)
- **EC-05** (SHA256SUMS format 不正): release artifact の SHA256SUMS が想定 format と異なる → install.sh の verify は exit 1 + 「SHA256SUMS format invalid」
- **EC-06** (Gist URL 旧 default を使い続ける既存 install): 触らない (NFR-01 backward compat)、警告も出さない (利用者の選択を尊重)

## 依存関係 / リスク

### 依存

- 既存 `scripts/generate-installer.sh` (SPEC-0010 / SPEC-0014)
- 既存 `scripts/sage-publish.sh` (Phase 1 SPEC-0010 で導入)
- 既存 `--verify-checksum` / `--print-provenance` (TASK-0097)
- GitHub Actions (release.yml の trigger / artifact attach)
- `gh` CLI (sage-publish.sh で release 作成、既に依存)
- `shasum` / `sha256sum` (TASK-0097 で fallback logic 既存)

### リスク

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | release.yml の byte-identical 検証で install.sh が generate-installer.sh と乖離 | FR-01 step 2 で diff、AC-03 で CI 検証 | `diff install.sh /tmp/new.sh \| wc -l` で 0 |
| 2 | 既存 Gist URL 利用者が壊れる | NFR-01 で backward compat 維持、install.sh は config の URL に従う | 既存 .sage/config.yaml で `bash install.sh --update` PASS |
| 3 | tag を間違えて push → 不要 release が公開 | OPS-04 で「delete + 再 push」手順、`gh release delete` 1 コマンド | `gh release delete v$WRONG --yes` で recover |
| 4 | release artifact の改ざん (GitHub repo compromise) | 本 SPEC scope 外 (SEC-05)、SPEC-0019 cosign で対処 | (cosign 署名後 `cosign verify` で検出) |
| 5 | release.yml の permissions 過大 | SEC-01 で `contents: write` のみ、`packages` / `id-token` は不要 | `grep "permissions:" .github/workflows/release.yml` で 1 line |
| 6 | `--remote` mode が CI で network 制限環境で fail | EC-04 で graceful (warning + exit 0)、AC-06 で検証 | network unreachable 環境で `--verify-checksum --remote` 実行 |
| 7 | sage-publish.sh の git tag push が CI でループ (release.yml が再度 sage-publish 呼び出し等) | release.yml は何も commit しない、tag push は loop しない | `gh run list --workflow=release.yml` で 1 tag 1 run |
| 8 | Gist URL 廃止判断が早すぎて利用者離脱 | OPS-02 で 30+ 日運用 + 90 日通知期間、Phase 6.4 で別 SPEC | 利用者 issue 監視 |

## 失敗時の知識蓄積

### 知識蓄積フロー (3 ステップ)

```
Step 1 [検出]
  release.yml fail / install.sh byte-identical fail / verify-checksum --remote 不一致 が発生
  ↓
Step 2 [記録]
  同 root cause で 2 回以上発生 → sage/failures.md に FAIL-RELEASE-XXXX として追記
  ↓
Step 3 [昇格]
  同 root cause で 3 回以上発生 → sage/anti-patterns.md に追記、release procedure 見直し
```

### sage/failures.md 連携

- **誰が**: release.yml fail を観測した maintainer / `--verify-checksum --remote` 不一致を報告した利用者
- **いつ**: 同 root cause (install.sh 同期漏れ / tag mistype / release deletion / SHA256 計算差異等) で 2 回以上発生時
- **どの手順で**: workflow log + 該当 tag + commit SHA を抽出 → `sage/failures.md` に FAIL-RELEASE-XXXX として 6 elements (発生日 / 影響 / 検出経路 / 一次原因 / 再発防止 / 関連 SPEC-ID) で追記

### sage/anti-patterns.md への昇格

3 回以上発生で `sage/anti-patterns.md` に「RELEASE-XXXX」追記。例: 「install.sh 同期漏れで release.yml が常時 fail する pattern」→ pre-commit hook で `generate-installer.sh diff` チェックを Phase 6.5 で SPEC 起票。

### Error Resolution 手順

| EC | エラー時メッセージ例 | Resolution |
|---|---|---|
| EC-01 (byte-identical fail) | `FAIL: install.sh diff: N lines` | `bash scripts/generate-installer.sh > install.sh && git commit -m "TASK-XXXX: regen install.sh"` |
| EC-02 (tag 形式違反) | `Error: tag 'X.Y.Z' is not v<semver>` | tag を `v$VERSION` 形式で再作成 |
| EC-03 (release 既存) | `release v1.6.0 already exists` | `gh release delete v1.6.0 --yes && git push --delete origin v1.6.0` で revert、修正後再 push |
| EC-04 (network 不可) | `WARN: remote SHA256SUMS fetch failed; verification skipped` | (graceful、action 不要) |
| EC-05 (SHA256SUMS format 不正) | `FAIL: SHA256SUMS line format invalid` | release artifact を再 build (workflow 再実行) |

## ロールバック手順

本 SPEC の各機能は段階的にロールバック可能:

| レベル | 手順 | 影響範囲 |
|---|---|---|
| 1. release.yml 一時 disable | `.github/workflows/release.yml` を rename → `.disabled` 追加 | tag push で release が作られなくなる、Gist 配布のみ動作 |
| 2. installer_url default revert | `scripts/generator/02-config.sh` で URL を Gist に戻す → `bash scripts/generate-installer.sh > install.sh` で再生成 | 新規 install のみ Gist URL に戻る、既存 install 影響なし |
| 3. `--verify-checksum --remote` 撤回 | install.sh から `--remote` mode を削除 → 再生成 | local verification のみに戻る |
| 4. 完全 revert | 本 SPEC 導入 PR を `git revert` | release.yml 削除、scripts 旧版復帰、既存 release artifact は GitHub に残るが新 tag では作られない |

各ロールバック後の検証:
- `bash scripts/sage-doctor.sh` 0 FAIL
- `bash templates/hooks/tests/run-tests.sh` (Phase 5+ base line 159) PASS
- `bash install.sh --update` (Gist URL で) PASS

## 関連 Doctrine

- **R5 (RUN log redaction)**: 本 SPEC は RUN log に release tag / SHA256 を記録する場合があるが、secret 値ではないため redaction 対象外
- **R7 (CLAUDE/AGENTS 肥大化禁止)**: 5 doc each +3 行以内
- **R8 (hook tests)**: 4+ scenario test 必須 (release-workflow mock)
- **R10 (一次ソース)**: GitHub Actions 公式 docs / Sigstore docs (cosign は SPEC-0019 で引用) を一次ソース

## Phase 6 全体での position

| SPEC | スコープ | 状態 |
|---|---|---|
| **SPEC-0018** | **Releases + SHA256SUMS + URL pinning** ← 本 SPEC | Draft |
| SPEC-0019 | cosign keyless signing (GitHub OIDC + Sigstore) | 未起票 (本 SPEC 完了後) |
| SPEC-0020 | SLSA provenance (slsa-github-generator) | 未起票 (SPEC-0019 完了後) |
| SPEC-0021 | Adoption guide (Next.js / Go / monorepo) | 未起票 (docs lane、独立で進行可) |

本 SPEC は Phase 6 supply chain hardening の **最初の SPEC**。完了で `[partial]` → `[improved]`、SPEC-0019/0020 完了で `[provided]` に到達。

## 関連ID

- PLAN-ID: PLAN-0018 (本 SPEC と同時または直後に作成)
- TASK-ID: TASK-0139 (release.yml 新規) / TASK-0140 (sage-publish.sh + scripts 拡張) / TASK-0141 (install.sh `--remote` mode) / TASK-0142 (doc cross-refs + README + SECURITY.md) / TASK-0143 (test-release-workflow.sh + installer regen + version bump)

## AC 完備性メモ

- 全 17 AC (AC-01..AC-17) のうち、明示的な異常系 AC は AC-15 (invalid tag input) / AC-16 (backward compat / legacy Gist URL) / AC-17 (release 重複防止) の 3 件 + AC-06 (`--remote` mode の network 不可 graceful + mismatch exit 1) で計 4 件 +α
- 正常系 AC: AC-01..AC-14 の structural / functional / docs カバー
- Gate 5 (Release) は AC-02 (manual) + AC-15 (workflow validation) + AC-17 (release uniqueness) で初めて意味のある artifact 検証
