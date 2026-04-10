#!/bin/bash
# sage-validate.sh — SAGE構造検証スクリプト
# CLAUDE.mdの必須セクション存在確認 + テンプレートフィールド検証
set -euo pipefail

ERRORS=0

echo "=== SAGE Validation ==="
echo ""

# --- CLAUDE.md Section Check ---
echo "[1/7] CLAUDE.md 必須セクション検証..."
REQUIRED_SECTIONS=(
  "Project Overview"
  "Instruction Priority"
  "SAGE Lifecycle Protocol"
  "Forbidden Shortcuts"
  "Error Resolution Protocol"
  "Agent Constraints"
  "File Scope Rules"
  "Traceability Requirements"
  "Quality Gate Checklist"
  "Language Rules"
)

if [ ! -f CLAUDE.md ]; then
  echo "  ERROR: CLAUDE.md が存在しません"
  ERRORS=$((ERRORS + 1))
else
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -q "$section" CLAUDE.md; then
      echo "  OK: $section"
    else
      echo "  MISSING: $section"
      ERRORS=$((ERRORS + 1))
    fi
  done
fi
echo ""

# --- specs/_template.md Field Check ---
echo "[2/7] テンプレート必須フィールド検証..."

if [ -f specs/_template.md ]; then
  REQUIRED_SPEC_FIELDS=("スコープ外" "受け入れ条件" "異常系" "契約" "リスク" "PLAN-ID")
  for field in "${REQUIRED_SPEC_FIELDS[@]}"; do
    if grep -q "$field" specs/_template.md; then
      echo "  OK: specs/_template.md → $field"
    else
      echo "  MISSING in specs/_template.md: $field"
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  echo "  SKIP: specs/_template.md が存在しません"
fi

if [ -f plans/_template.md ]; then
  REQUIRED_PLAN_FIELDS=("SPEC-ID" "変更レイヤ" "影響範囲" "リスク" "タスク分解")
  for field in "${REQUIRED_PLAN_FIELDS[@]}"; do
    if grep -q "$field" plans/_template.md; then
      echo "  OK: plans/_template.md → $field"
    else
      echo "  MISSING in plans/_template.md: $field"
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  echo "  SKIP: plans/_template.md が存在しません"
fi

if [ -f tasks/_template.md ]; then
  REQUIRED_TASK_FIELDS=("SPEC-ID" "PLAN-ID" "File Scope" "禁止事項" "完了条件" "RUN-ID")
  for field in "${REQUIRED_TASK_FIELDS[@]}"; do
    if grep -q "$field" tasks/_template.md; then
      echo "  OK: tasks/_template.md → $field"
    else
      echo "  MISSING in tasks/_template.md: $field"
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  echo "  SKIP: tasks/_template.md が存在しません"
fi
echo ""

# --- Directory Structure Check ---
echo "[3/7] ディレクトリ構造検証..."
REQUIRED_DIRS=("specs" "plans" "tasks" "sage" ".sage" "docs" "scripts")
for dir in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "  OK: $dir/"
  else
    echo "  MISSING: $dir/"
    ERRORS=$((ERRORS + 1))
  fi
done
echo ""

# --- Document Integrity Check ---
echo "[4/7] ドキュメント整合性チェック..."

# SPEC-0002: Error Context Template
if grep -q "Error Context Template" CLAUDE.md 2>/dev/null; then
  echo "  OK: CLAUDE.md → Error Context Template"
else
  echo "  MISSING: CLAUDE.md → Error Context Template"
  ERRORS=$((ERRORS + 1))
fi

# SPEC-0003: 4必須要素
if grep -q "4必須要素" sage/governance.md 2>/dev/null; then
  echo "  OK: governance.md → 4必須要素"
else
  echo "  MISSING: governance.md → 4必須要素"
  ERRORS=$((ERRORS + 1))
fi

# SPEC-0004: バイブコーディング
if grep -q "バイブコーディング" sage/governance.md 2>/dev/null; then
  echo "  OK: governance.md → バイブコーディング"
else
  echo "  MISSING: governance.md → バイブコーディング"
  ERRORS=$((ERRORS + 1))
fi

# SPEC-0005: 3層計測
if grep -q "3層計測" sage/governance.md 2>/dev/null; then
  echo "  OK: governance.md → 3層計測"
else
  echo "  MISSING: governance.md → 3層計測"
  ERRORS=$((ERRORS + 1))
fi
echo ""

# --- Vibe Branch Check ---
echo "[5/7] ブランチ規約チェック..."
CURRENT_BRANCH=${GITHUB_HEAD_REF:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}
if [[ "$CURRENT_BRANCH" == vibe/* ]]; then
  echo "  ERROR: vibe/* ブランチから直接マージ禁止。staging経由 + SPEC作成後にmainへ"
  ERRORS=$((ERRORS + 1))
else
  echo "  OK: ブランチ規約準拠 (${CURRENT_BRANCH:-unknown})"
fi
echo ""

# --- Check 6: Noise Diff Check ---
echo "[6/7] ノイズ差分チェック..."
# CI環境では直近コミットをルート安全に検査、ローカルではステージング済みファイル比較
if [ -n "${CI:-}" ]; then
  DIFF_CMD="git diff-tree --check --no-commit-id --root -r HEAD"
else
  DIFF_CMD="git diff --cached --check"
fi
NOISE=$($DIFF_CMD 2>/dev/null | grep -E "trailing whitespace|space before tab|new blank line at EOF" || true)
if [ -n "$NOISE" ]; then
  NOISE_COUNT=$(echo "$NOISE" | wc -l | tr -d ' ')
  echo "  FAIL: $NOISE_COUNT noise diff(s) detected"
  echo "  Fix: Remove trailing whitespace and unnecessary blank lines"
  ERRORS=$((ERRORS + 1))
else
  echo "  OK: ノイズ差分なし"
fi
echo ""

# --- Check 7: AI Control Plane Security Check ---
echo "[7/7] AI Control Plane セキュリティチェック..."

# Secret patterns (lightweight subset of sage-doctor.sh)
SECRET_PATTERN='(api[_-]?key|secret[_-]?key|access[_-]?token|password|credential)\s*[:=]\s*["'"'"']?[A-Za-z0-9+/=_-]{8,}'
AWS_PATTERN='(AKIA|ASIA)[A-Z0-9]{16}'
JWT_PATTERN='eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.'
GITHUB_TOKEN_PATTERN='gh[pousr]_[A-Za-z0-9_]{20,}'

SECURITY_SCAN_FILES=()
[ -f CLAUDE.md ] && SECURITY_SCAN_FILES+=("CLAUDE.md")
if [ -d ".claude/prompts" ]; then
  while IFS= read -r f; do
    SECURITY_SCAN_FILES+=("$f")
  done < <(find .claude/prompts -type f 2>/dev/null)
fi

SECRET_FOUND=false
for file in "${SECURITY_SCAN_FILES[@]}"; do
  for pattern in "$SECRET_PATTERN" "$AWS_PATTERN" "$JWT_PATTERN" "$GITHUB_TOKEN_PATTERN"; do
    if grep -qEi "$pattern" "$file" 2>/dev/null; then
      echo "  FAIL: Secret pattern detected in $file"
      ERRORS=$((ERRORS + 1))
      SECRET_FOUND=true
      break
    fi
  done
done
if [ "$SECRET_FOUND" = false ]; then
  echo "  OK: AI制御プレーンファイルにシークレットなし"
fi

# Permission check
if [ -f ".claude/settings.json" ]; then
  if grep -qE '"allow"\s*:\s*\[\s*"\*"' .claude/settings.json 2>/dev/null; then
    echo "  WARN: .claude/settings.json に過度に許可的な allow: [\"*\"] が設定されています"
  else
    echo "  OK: .claude/settings.json パーミッション適切"
  fi
fi
echo ""

# --- Summary ---
if [ $ERRORS -eq 0 ]; then
  echo "=== SAGE Validation: ALL PASSED ==="
  exit 0
else
  echo "=== SAGE Validation: $ERRORS ERROR(S) FOUND ==="
  exit 1
fi
