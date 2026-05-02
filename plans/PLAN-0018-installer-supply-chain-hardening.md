# PLAN-0018: Installer Supply Chain Hardening Phase 1 — implementation plan

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0018 |
| SPEC-ID   | SPEC-0018 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |

## 変更レイヤ

- [x] infra (GitHub Actions workflow + release artifact distribution)
- [x] tooling (scripts/sage-publish.sh + sage-validate.sh + sage-update-check.sh)
- [x] installer (scripts/generator/02-config.sh default URL, scripts/generator/07-installer-main.sh `--remote` mode)
- [x] docs (README / SECURITY / 5 cross-refs / scripts/generator/README.md)
- [x] test (templates/hooks/tests/test-release-workflow.sh)
- [ ] frontend / domain / usecase (該当なし)

## 影響範囲

- **配布チャネル**: Gist 単独 → Releases primary + Gist legacy fallback
- **新規 install のデフォルト URL**: Gist → Releases (`releases/latest/download/install.sh`)
- **既存 install**: 影響なし (NFR-01 backward compat、`.sage/config.yaml` の installer_url を触らない)
- **CI**: 新 workflow `.github/workflows/release.yml` 追加 (tag push trigger のみ、既存 5 Gate workflow に影響なし)
- **maintainer 運用**: `bash scripts/sage-publish.sh patch` ワンコマンドで Releases も発行されるよう拡張

## 実装方針

### 配布チャネル設計

| 項目 | Gist (現状) | Releases (本 SPEC) |
|---|---|---|
| URL | `gist.githubusercontent.com/heidayo/.../raw/install.sh` | `github.com/heidayo/sage-ai-template/releases/latest/download/install.sh` |
| immutability | mutable (HEAD 固定) | tag-pinned `releases/download/v$VERSION/install.sh` で immutable |
| SHA256 公開 | なし | SHA256SUMS を release artifact に attach |
| release notes | なし | `gh release create` の `--notes` で生成 |
| 廃止判断 | Phase 6.4+ 別 SPEC | 本 SPEC で primary に昇格 |

### 後方互換戦略

- 既存利用者の `.sage/config.yaml` は触らない (NFR-01)
- 新規 install は Releases URL を default (FR-04)
- `--update` は config の URL に従って動作 (Gist でも Releases でも可)
- `--verify-checksum --remote` は新規 opt-in flag (default は local 比較のまま)

### 後続 SPEC への引き継ぎ

- **SPEC-0019 (cosign)**: release.yml に `cosign sign` step 追加 + `id-token: write` permissions 拡張 (本 SPEC の workflow を起点に)
- **SPEC-0020 (SLSA)**: `slsa-framework/slsa-github-generator` を release.yml の reusable workflow として呼び出し (build attestation)
- **SPEC-0021 (adoption guide)**: 配布チャネル変更を docs adoption pattern と紐付け (独立で進行可)

## TASK 分割 (5 TASK)

| TASK | 責務 | 見積 | 依存 | 並列可否 |
|---|---|---|---|---|
| TASK-0139 | `.github/workflows/release.yml` 新規 (tag push trigger + byte-identical 検証 + SHA256SUMS 生成 + release artifact attach) | 60m | none | Yes (TASK-0140 と並列可) |
| TASK-0140 | `scripts/sage-publish.sh` + `sage-validate.sh` + `sage-update-check.sh` + `scripts/generator/02-config.sh` 拡張 | 75m | none | Yes (TASK-0139 と並列可) |
| TASK-0141 | `scripts/generator/07-installer-main.sh` に `--verify-checksum --remote` mode 追加 | 45m | TASK-0139 (SHA256SUMS URL format 確定後) | No |
| TASK-0142 | doc cross-refs (5 doc + scripts/generator/README.md) + README.md + SECURITY.md §3.1 更新 | 45m | TASK-0139..0141 (実装済機能を doc 化) | No |
| TASK-0143 | `templates/hooks/tests/test-release-workflow.sh` 新規 + install.sh 再生成 + .sage-version v1.5.0→1.6.0 + .sage/install-state.yaml 更新 | 45m | TASK-0139..0142 | No |

合計: 270 min (4.5h、Phase 5+ 実装で確立した pattern を流用)

## 依存グラフ

```
TASK-0139 (release.yml, 60m)         TASK-0140 (sage-publish + scripts, 75m)
    │                                     │
    └──────────────┬──────────────────────┘
                   ▼
        TASK-0141 (install.sh --remote, 45m)
                   │
                   ▼
        TASK-0142 (docs, 45m)
                   │
                   ▼
        TASK-0143 (test + regen + bump, 45m)
```

TASK-0139 と TASK-0140 は前段で並列可 (依存なし)。残りは serial。並列実行で wall-clock ~210min に短縮可能、serial で ~270min。

## 検証方法

- **Unit test**: `bash templates/hooks/tests/run-tests.sh` で既存 + 新規 4+ シナリオ PASS
- **Workflow validation**: `actionlint .github/workflows/release.yml` で error 0 件 (CI で実施)
- **Byte-identical regression**: `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` で 0 行
- **Release dry-run**: `gh workflow run release.yml --ref feature/spec-0018-installer-supply-chain` で workflow 単体実行確認 (実 release は manual gate)
- **Backward compat**: 既存 `.sage/config.yaml` (Gist URL) で `bash install.sh --update` PASS
- **Validate / Doctor / Doc-drift**: 既存 3 script で 0 FAIL / PASS

## リスク

PLAN レベル risk (SPEC レベル risk は SPEC-0018 §「依存関係 / リスク」参照):

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | 5 TASK serial 実行で wall-clock 270min 超過 | TASK-0139/0140 を前段並列化、各 TASK 単独完結性で中断・再開可 | `git log --oneline TASK-0139..0143` で 5 commit 順序確認 |
| 2 | release.yml 動作確認に実 tag push が必要、test 環境で再現困難 | `act` (nektos/act) で local 実行 + AC-02 を manual verification として明示 | `act push -j release --eventpath /tmp/event.json` で local dry-run |
| 3 | 既存 Gist URL 利用者が壊れる懸念 (sage-update-check の URL pattern 拡張で regression) | TASK-0140 で Gist / Releases 両 pattern test、既存 4 RUN log で validator PASS 維持 | `bash scripts/sage-update-check.sh` を Gist URL 設定 fixture で実行 |
| 4 | install.sh 再生成忘れで配布物が古い (TASK-0143 漏れ) | Phase 3 の TASK-0117/0119 / Phase 5+ の TASK-0130/0134/0137 教訓、TASK-0143 で明示 | `grep -c "release.yml\|--remote" install.sh` で実装済 token 検出 |
| 5 | CLAUDE/AGENTS doc cross-ref が +3 行超過 | TASK-0142 「禁止事項」で R7 厳守明示、SPEC-0017 で確立した pattern を流用 | `git diff HEAD~5 HEAD --stat -- AGENTS.md CLAUDE.md SECURITY.md sage/governance.md docs/codex-security.md` |
| 6 | release.yml の `gh release create` 権限不足 (`GITHUB_TOKEN` の default permissions が `read` の repo) | TASK-0139 で `permissions: contents: write` 明示、SEC-01 で least privilege | `grep -A1 "permissions:" .github/workflows/release.yml` で `contents: write` 確認 |
| 7 | `--remote` mode の network call で CI flaky | EC-04 で graceful degradation (warning + exit 0)、AC-06 で network 不可時の挙動明示 | `unshare -n bash install.sh --verify-checksum --remote` (Linux) / mock URL でテスト |
| 8 | Codex implementation review で予期せぬ finding | Phase 1-3 / Phase 5+ と同 pattern で 1-2 round 収束見込み、3+ round になれば SPEC へ巻き戻し | review 履歴で converge 確認 |

## R1-R10 doctrine 適用

| Doctrine | 本 SPEC での適用 |
|---|---|
| **R1** (no branch protection auto-config) | release.yml は branch protection / Ruleset を触らない、tag push trigger のみ |
| **R2** (sandbox_mode template only, runtime change なし) | release.yml は GitHub Actions 環境内で完結、利用者 sandbox 設定に影響しない |
| **R3** (Lethal Trifecta warn-only) | `--verify-checksum --remote` mismatch は exit 1 (block)、ただし network 不可は graceful (人間判断責任維持) |
| **R4** (no SecPass thresholds) | SHA256 は equality 比較のみ、threshold の概念なし |
| **R5** (RUN log redaction) | release.yml は RUN log 出力なし、SHA256 / tag は secret 値ではないため redaction 対象外 |
| **R6** (license vs security 分離) | 本 SPEC は security (supply chain) 専念、license (Apache-2.0) 既存維持 |
| **R7** (CLAUDE/AGENTS 肥大化禁止) | TASK-0142 で 5 doc each +3 行以内、長文は SPEC-0018 + scripts/generator/README.md に集約 |
| **R8** (hook tests required) | TASK-0143 で 4+ scenario test 必須 (実際は TASK-0139 で SHA256SUMS format / `--remote` mode mock / byte-identical / network unreachable の 4 シナリオ) |
| **R9** (shellcheck required) | release.yml の shell step / sage-publish.sh / install.sh `--remote` mode に shellcheck error 0 件必須 |
| **R10** (一次ソース引用) | GitHub Actions 公式 docs (`gh release create` / `permissions:`)、Sigstore docs (cosign は SPEC-0019 で引用)、SPEC-0010 distribution doctrine を一次ソース継承 |

## Cross-model adversarial review

Phase 1-3 / Phase 5+ implementation review pattern を踏襲:

### Review プロセス

1. **Specify phase**: SPEC + PLAN + 5 TASK draft → sage-evaluate 100 点 PASS → user 承認
2. **Implementation phase**: TASK-0139/0140 (並列) → 0141 → 0142 → 0143 の順で実装
3. **Codex implementation review**: 実装完了後、Phase 5+ と同 format で Codex に依頼
4. **Multi-round 収束**: 1-2 round で converge 見込み (release workflow は確立 pattern、Codex も同種 SPEC 経験あり)

### Exit criteria (収束件数予測ではなく明示判定基準)

実装 PR の Codex review が収束したと判定する基準:

- [ ] **P1 (critical) 0 件**
- [ ] **P2 (should fix) 0 件**
- [ ] **P3 (nit) は明示 accept**
- [ ] **R7 regression なし** — `wc -l` で 5 文書合計増分 ≤ +15 行
- [ ] **R10 regression なし** — 全 claim に primary source URL 紐付き

### 失敗時のエスカレーション

3 round 経過しても新 P2 以上の finding が出続ける場合、SPEC を draft に戻し、Spec Agent で再設計。`sage/failures.md` に「FAIL-SPEC-0018-DESIGN-ITERATION」として記録、user に方針相談。

## 必要な検証

- [x] unit test (`bash templates/hooks/tests/run-tests.sh`)
- [x] integration test (release.yml `act` local dry-run + manual tag push verification)
- [x] security scan (`bash scripts/sage-validate.sh` + `gitleaks detect`)
- [ ] e2e test (本 SPEC では release.yml 単体動作のみ、e2e は Phase 6.4 利用者通知後に別 SPEC)
- [x] architecture boundary check (`bash scripts/sage-doctor.sh` + `bash scripts/sage-doc-drift.sh`)

## 完了条件

- [ ] SPEC-0018 全 AC (AC-01..AC-17) 達成 (うち異常系 AC: AC-06 / AC-15 / AC-16 / AC-17)
- [ ] PR description に SPEC-0018 / PLAN-0018 / 5 TASK link
- [ ] Codex implementation review 0 件 P1/P2
- [ ] `.sage-version` v1.5.0 → 1.6.0 (minor bump、新機能追加のため)
- [ ] CHANGELOG entry (該当 file 不在のため、PR description で代用)
