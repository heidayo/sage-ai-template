# PLAN-0004: Install Lifecycle + AI Control Plane監査

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0004 |
| SPEC-ID   | SPEC-0004 |
| ステータス | Draft |
| 作成日    | 2026-04-10 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（scripts/, .sage/）
- [ ] frontend
- [x] infra（install.sh, generate-installer.sh, makefile）
- [x] test（sage-validate.sh 拡張）

## 影響範囲

- `scripts/` — 3つの新規スクリプト（doctor, repair, report）
- `scripts/sage-validate.sh` — AI Control Plane セキュリティチェック追加
- `.sage/install-state.yaml` — 新規自動生成ファイル
- `.sage/metrics/` — doctor-history.jsonl 出力先
- `install.sh` / `scripts/generate-installer.sh` — install-state 生成ロジック追加
- `makefile` — 3コマンド追加

## 実装方針

### doctor / repair の分離設計

doctor は**診断のみ**（ReadOnly）、repair は**修復のみ**（Write）と明確に分離する。これはSAGEの Evaluator Read-Only 原則と同じ思想。

```
make doctor  →  診断（ReadOnly）→  OK/WARN/FAIL 表示
                                    + failures.md 候補出力 (stderr)
                                    + doctor-history.jsonl 記録

make repair  →  doctor の結果を参照  →  確認プロンプト  →  修復実行
                                        (--dry-run で preview)
                                        (--yes で確認スキップ)
```

### install-state.yaml のスキーマ

```yaml
version: "0.2.0"
installed_at: "2026-04-10T12:00:00Z"
files:
  - path: "sage/governance.md"
    sha256: "abc123..."
    source: "embedded"
    managed: true       # SAGE管理 — update時に上書き対象
  - path: "CLAUDE.md"
    sha256: "def456..."
    source: "embedded"
    managed: false      # ユーザーカスタマイズ — update時は上書きしない
  - path: ".sage/config.yaml"
    sha256: "ghi789..."
    source: "embedded"
    managed: false      # プロジェクト固有設定
```

`managed: true` / `false` の区別は既存の install.sh のロジックと一致させる:
- `write_file_if_new` で作成 → `managed: false`（ユーザーが自由にカスタマイズ）
- `update_file` で作成/更新 → `managed: true`（SAGE更新時に上書き対象）

### セキュリティチェックパターン

```bash
# シークレット検出（Gitleaks 互換）
SECRET_PATTERN='(api[_-]?key|secret[_-]?key|access[_-]?token|password|credential|private[_-]?key)\s*[:=]\s*["'"'"']?[A-Za-z0-9+/=_-]{8,}'
# AWS Key
AWS_PATTERN='(AKIA|ASIA)[A-Z0-9]{16}'
# JWT
JWT_PATTERN='eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
# GitHub Token
GH_PATTERN='gh[pousr]_[A-Za-z0-9_]{36,}'

# 権限チェック
OVERLY_PERMISSIVE='"allow"\s*:\s*\[\s*"\*"\s*\]'

# 危険な hook パターン
DANGEROUS_HOOK='(curl|wget)\s.*\|\s*(bash|sh)|eval\s+"\$'
```

### sage-report.sh のステータス判定

```bash
SESSIONS=$(wc -l < .sage/metrics/sessions.jsonl 2>/dev/null || echo 0)
DOCTOR_FAILS=$(grep '"level":"FAIL"' .sage/metrics/doctor-history.jsonl 2>/dev/null | wc -l || echo 0)

# 14日間ウィンドウ判定（strict昇格条件）
TWO_WEEKS_AGO=$(date -d '14 days ago' +%s 2>/dev/null || date -v-14d +%s 2>/dev/null || echo 0)
RECENT_FAILS=$(... 14日以内のFAIL件数 ...)

if [ "$SESSIONS" -lt 10 ]; then STATUS="INSUFFICIENT DATA"
elif [ "$DOCTOR_FAILS" -eq 0 ]; then STATUS="HEALTHY"
else STATUS="WARN (recurring failures)"
fi

if [ "$STATUS" = "HEALTHY" ] && [ "$RECENT_FAILS" -eq 0 ] && [ "$SESSIONS" -ge 10 ]; then
  echo "READY FOR STRICT"
fi
```

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0045 | `install.sh` / `generate-installer.sh` に install-state.yaml 生成ロジック追加 | Implementation | 45m | - | Yes |
| TASK-0046 | `scripts/sage-doctor.sh` 実装（ファイル存在＋整合性チェック） | Implementation | 45m | TASK-0045 | No |
| TASK-0047 | `scripts/sage-doctor.sh` に AI Control Plane セキュリティチェック追加 | Implementation | 30m | TASK-0046 | No |
| TASK-0048 | `scripts/sage-doctor.sh` に failures.md 候補出力 + doctor-history.jsonl 記録追加 | Implementation | 20m | TASK-0047 | No |
| TASK-0049 | `scripts/sage-repair.sh` 実装 | Implementation | 45m | TASK-0046 | No |
| TASK-0050 | `scripts/sage-report.sh` 実装 | Implementation | 30m | TASK-0048 | No |
| TASK-0051 | `scripts/sage-validate.sh` に [7/8] AI Control Plane チェック追加 | Implementation | 20m | TASK-0047 | No |
| TASK-0052 | `makefile` に doctor / repair / report コマンド追加 | Implementation | 10m | TASK-0046, TASK-0049, TASK-0050 | No |
| TASK-0053 | SPEC-0004 の全 AC 検証（AC-01〜AC-13） | Test | 45m | TASK-0052 | No |

**並列実行可能グループ**:
- グループA: TASK-0045（install-state基盤）
- グループB（TASK-0045完了後）: TASK-0046（doctor基盤）
- グループC（TASK-0046完了後、互いに並列）: TASK-0047, TASK-0049
- グループD（TASK-0047完了後）: TASK-0048 → TASK-0050, TASK-0051
- グループE（全完了後）: TASK-0052 → TASK-0053

## リスク

- リスク1: install-state.yaml の SHA256 計算が macOS/Linux で異なるコマンドを要する -> 軽減策: `sha256sum` / `shasum -a 256` 自動検出関数を共通化
- リスク2: シークレット検出の false positive でユーザーが doctor を信頼しなくなる -> 軽減策: パターンを保守的に設定し、疑わしい場合は WARN（FAIL ではない）
- リスク3: SPEC-0003 の hooks が未完成の場合、hook 安全性チェックが空振りする -> 軽減策: SPEC-0003 完了後に SPEC-0004 を着手する依存関係を遵守

## 必要な検証

- [x] unit test（doctor / repair / report の各入出力テスト）
- [ ] integration test（install.sh → doctor → 破壊 → repair → doctor のフルサイクル確認）
- [x] security scan（doctor 自体のセキュリティパターン検証）
- [ ] e2e test（該当なし）
- [x] architecture boundary check（sage-validate.sh の拡張がセクション構造を壊さないか）
