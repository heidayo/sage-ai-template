# TASK-0143: test-release-workflow.sh 新規 + install.sh 再生成 + .sage-version v1.5.0→1.6.0 + .sage/install-state.yaml 更新

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0143 |
| SPEC-ID   | SPEC-0018 |
| PLAN-ID   | PLAN-0018 |
| ステータス | Pending |
| 担当Agent | Implementation + Test |
| 並列可否  | No (TASK-0139..0142 完了後) |
| 依存TASK  | TASK-0139, TASK-0140, TASK-0141, TASK-0142 |
| 見積     | 45m |

## 責務

SPEC-0018 実装の最終 wrap-up:

1. **新規 test**: `templates/hooks/tests/test-release-workflow.sh` (4+ シナリオ、SHA256SUMS format / `--remote` mode mock / byte-identical / network unreachable)
2. **install.sh 再生成**: TASK-0140 の `02-config.sh` 変更 + TASK-0141 の `--remote` mode 反映を `bash scripts/generate-installer.sh > install.sh` で生成物に反映
3. **.sage-version bump**: v1.5.0 → 1.6.0 (minor、新機能追加のため)
4. **.sage/install-state.yaml 更新**: 新 install.sh の SHA256 / size を記録 (TASK-0097 仕様準拠)

## 入力

- SPEC-0018 §「受け入れ条件」AC-13 / AC-14 (test scenario)
- TASK-0139..0142 完了状態 (release.yml / scripts / install.sh source / docs すべて)
- 既存 `templates/hooks/tests/run-tests.sh` (test runner)

## 出力

1. `templates/hooks/tests/test-release-workflow.sh` (新規、約 80-120 行、shellcheck pass)
   - シナリオ 1: SHA256SUMS format validation (`<sha256>  install.sh` POSIX format)
   - シナリオ 2: `--verify-checksum --remote` mode で SHA256 一致 (mock SHA256SUMS)
   - シナリオ 3: `--verify-checksum --remote` mode で SHA256 不一致 (mock mismatch、exit 1 確認)
   - シナリオ 4: `--verify-checksum --remote` mode で network 不可 (curl fail mock、warning + exit 0)
2. `install.sh` 再生成 (byte-identical 検証)
3. `.sage-version` 更新 (`1.5.0` → `1.6.0`)
4. `.sage/install-state.yaml` 更新 (新 SHA256 + size + timestamp)

## File Scope

- 作成: `templates/hooks/tests/test-release-workflow.sh`
- 変更: `install.sh` (regenerated)
- 変更: `.sage-version`
- 変更: `.sage/install-state.yaml`

## 禁止事項

- test を `set +e` で誤魔化さない (実際の exit code を確認)
- mock SHA256SUMS を実際の release artifact と一致させない (test の独立性維持)
- network mock を `0.0.0.0` 等の reserved IP で行わない (CI で flaky)、curl の `--max-time 1` + 不在ホストで fail させる
- `.sage-version` を skip / patch ではなく minor bump (新機能追加のため、semver 遵守)
- `.sage/install-state.yaml` 手書きしない (sage-publish.sh で自動生成、TASK-0140 で実装)
- shellcheck error を残さない (R9)
- install.sh の byte-identical 検証 (`diff install.sh /tmp/new.sh`) を skip しない

## 完了条件

- [ ] `templates/hooks/tests/test-release-workflow.sh` 新規、4+ シナリオ全 PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (既存 + 新規)
- [ ] `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` で 0 行 (byte-identical 維持)
- [ ] `.sage-version` が `1.6.0` に更新
- [ ] `.sage/install-state.yaml` の sha256 が新 install.sh と一致
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] shellcheck error 0 件
- [ ] commit message に `TASK-0143:` 含む
