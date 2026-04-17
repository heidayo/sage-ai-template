#!/bin/bash
# sage-validate.sh — SAGE構造検証スクリプト
# CLAUDE.mdの必須セクション存在確認 + テンプレートフィールド検証
set -euo pipefail

ERRORS=0

echo "=== SAGE Validation ==="
echo ""

# --- CLAUDE.md Section Check ---
echo "[1/9] CLAUDE.md 必須セクション検証..."
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
echo "[2/9] テンプレート必須フィールド検証..."

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
echo "[3/9] ディレクトリ構造検証..."
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
echo "[4/9] ドキュメント整合性チェック..."

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

# --- Branch & Lane Check ---
echo "[5/9] ブランチ規約・レーンチェック..."
CURRENT_BRANCH=${GITHUB_HEAD_REF:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}

# Detect lane from branch name
DETECTED_LANE="standard"
if [[ "$CURRENT_BRANCH" == vibe/* ]]; then
  DETECTED_LANE="explore"
elif [[ "$CURRENT_BRANCH" == fix/* || "$CURRENT_BRANCH" == chore/* || "$CURRENT_BRANCH" == docs/* ]]; then
  DETECTED_LANE="lite"
elif [[ "$CURRENT_BRANCH" == promote/* ]]; then
  DETECTED_LANE="promotion"
fi
echo "  Lane: $DETECTED_LANE (branch: ${CURRENT_BRANCH:-unknown})"

# Check 1: vibe/* direct merge to main is prohibited
if [[ "$CURRENT_BRANCH" == vibe/* ]]; then
  echo "  ERROR: vibe/* ブランチから直接マージ禁止"
  echo "  昇格するには: bash scripts/sage-promote.sh $CURRENT_BRANCH"
  ERRORS=$((ERRORS + 1))
fi

# Check 2: promote/* requires a branch-matching Retro-SPEC + TASK-ID
if [[ "$CURRENT_BRANCH" == promote/* ]]; then
  PROMOTE_NAME="${CURRENT_BRANCH#promote/}"
  # Sanitize branch name the same way sage-retro-spec.sh does
  SAFE_PROMOTE_NAME=$(echo "$PROMOTE_NAME" | tr '/' '-' | tr ' ' '-')

  # Look for a retro-spec file matching this specific branch name
  RETRO_SPEC_FILE="specs/RETRO-SPEC-${SAFE_PROMOTE_NAME}.md"
  if [ -f "$RETRO_SPEC_FILE" ]; then
    echo "  OK: Retro-SPEC found: $RETRO_SPEC_FILE"

    # Check for TBD/TODO — these must be resolved before merge
    TBD_COUNT=$(grep -cE "^[^>]*TBD" "$RETRO_SPEC_FILE" 2>/dev/null || echo "0")
    if [ "$TBD_COUNT" -gt 0 ]; then
      echo "  ERROR: Retro-SPEC に TBD が $TBD_COUNT 件残っています。全て埋めてください"
      ERRORS=$((ERRORS + 1))
    else
      echo "  OK: Retro-SPEC に未記入項目なし"
    fi
  else
    echo "  ERROR: promote/* ブランチには Retro-SPEC が必要です"
    echo "  期待ファイル: $RETRO_SPEC_FILE"
    echo "  生成するには: bash scripts/sage-retro-spec.sh $CURRENT_BRANCH"
    ERRORS=$((ERRORS + 1))
  fi

  # Check 3: only promotion-lane commits need TASK-ID; inherited vibe/* commits stay exempt
  SOURCE_SHA=""
  if [ -f "$RETRO_SPEC_FILE" ]; then
    SOURCE_SHA=$(awk -F'|' '/^\| 昇格元SHA / {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3; exit}' "$RETRO_SPEC_FILE" 2>/dev/null || true)
  fi

  if [ -n "$SOURCE_SHA" ] && git rev-parse --verify "$SOURCE_SHA" > /dev/null 2>&1; then
    PROMOTION_COMMITS=$(git log --oneline "${SOURCE_SHA}..${CURRENT_BRANCH}" 2>/dev/null || true)
    if [ -z "$PROMOTION_COMMITS" ]; then
      echo "  OK: 昇格後コミットなし（TASK-ID チェック対象なし）"
    else
      COMMITS_WITHOUT_TASKID=$(printf '%s\n' "$PROMOTION_COMMITS" | grep -cvE "TASK-[0-9]{4}" || echo "0")
      if [ "$COMMITS_WITHOUT_TASKID" -gt 0 ]; then
        echo "  ERROR: promote/* ブランチの昇格後コミットに TASK-ID なしが ${COMMITS_WITHOUT_TASKID} 件あります"
        ERRORS=$((ERRORS + 1))
      else
        echo "  OK: 昇格後コミットは全て TASK-ID あり"
      fi
    fi
  else
    echo "  WARN: 昇格元SHAを特定できないため、promote/* の TASK-ID チェックをスキップしました"
  fi
fi

# Check 3: non-vibe, non-promote branches pass normally
if [[ "$DETECTED_LANE" != "explore" && "$DETECTED_LANE" != "promotion" ]]; then
  echo "  OK: ブランチ規約準拠 (${CURRENT_BRANCH:-unknown})"
fi
echo ""

# --- Check 6: Noise Diff Check ---
echo "[6/9] ノイズ差分チェック..."
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
echo "[7/9] AI Control Plane セキュリティチェック..."

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

# --- Check 8: .gitignore ↔ tracked consistency (SPEC-0008 TASK-0080) ---
echo "[8/9] .gitignore / tracked 整合性チェック..."
# git ls-files -ci --exclude-standard lists files that are tracked AND would
# be ignored by standard gitignore rules. The intersection is always a bug:
# either the file should be removed from the index (git rm --cached) or it
# should not be in .gitignore. .DS_Store was the original motivating case.
IGNORED_TRACKED=$(git ls-files -ci --exclude-standard 2>/dev/null || true)
if [ -n "$IGNORED_TRACKED" ]; then
  COUNT=$(printf '%s\n' "$IGNORED_TRACKED" | wc -l | tr -d ' ')
  echo "  FAIL: $COUNT file(s) are tracked but also gitignored:"
  printf '%s\n' "$IGNORED_TRACKED" | sed 's/^/    /'
  echo "  Fix: 'git rm --cached <path>' for each, or remove from .gitignore"
  ERRORS=$((ERRORS + 1))
else
  echo "  OK: tracked と gitignore の矛盾なし"
fi
echo ""

# --- Check 9: installer_url 3-path sync (SPEC-0008 TASK-0081) ---
# Compare local install.sh sha256 with the Gist-published version. Offline
# or unreachable Gist => SKIPPED (not a failure). On main (GITHUB_REF_NAME=main)
# a mismatch is a FAIL; elsewhere the mismatch is a warning.
echo "[9/9] installer_url 3 経路同期チェック..."
INSTALLER_URL=$(grep -E '^\s*installer_url:' .sage/config.yaml 2>/dev/null | head -1 | sed -E 's/^[^"]*"([^"]*)".*/\1/')
if [ -z "$INSTALLER_URL" ]; then
  echo "  SKIPPED: installer_url not set in .sage/config.yaml"
elif [ ! -f install.sh ]; then
  echo "  SKIPPED: local install.sh not found"
elif ! command -v curl >/dev/null 2>&1; then
  echo "  SKIPPED: curl not available"
elif ! command -v shasum >/dev/null 2>&1 && ! command -v sha256sum >/dev/null 2>&1; then
  echo "  SKIPPED: sha256 tool not available"
else
  LOCAL_SHA=$(shasum -a 256 install.sh 2>/dev/null | awk '{print $1}')
  [ -z "$LOCAL_SHA" ] && LOCAL_SHA=$(sha256sum install.sh 2>/dev/null | awk '{print $1}')
  REMOTE_CONTENT=$(curl -fsSL --max-time 10 "$INSTALLER_URL" 2>/dev/null || true)
  if [ -z "$REMOTE_CONTENT" ]; then
    echo "  SKIPPED: Gist not reachable (offline or URL 404)"
  else
    REMOTE_SHA=$(printf '%s' "$REMOTE_CONTENT" | shasum -a 256 2>/dev/null | awk '{print $1}')
    [ -z "$REMOTE_SHA" ] && REMOTE_SHA=$(printf '%s' "$REMOTE_CONTENT" | sha256sum 2>/dev/null | awk '{print $1}')
    if [ "$LOCAL_SHA" = "$REMOTE_SHA" ]; then
      echo "  OK: local install.sh matches Gist publication (sha256)"
    else
      echo "  MISMATCH:"
      echo "    local  sha256: $LOCAL_SHA"
      echo "    remote sha256: $REMOTE_SHA"
      echo "    URL:           $INSTALLER_URL"
      if [ "${GITHUB_REF_NAME:-}" = "main" ]; then
        echo "  FAIL: on main branch, mismatch is not allowed"
        ERRORS=$((ERRORS + 1))
      else
        echo "  WARN: not on main, treating as warning (fix with 'bash scripts/sage-publish.sh')"
      fi
    fi
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
