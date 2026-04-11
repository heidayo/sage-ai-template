#!/bin/bash
# sage-retro-spec.sh — Generate a Retro-SPEC draft from branch diff and commit history
# SPEC-0006: Vibe Coding Lanes & Promotion Protocol
#
# Usage: bash scripts/sage-retro-spec.sh [branch-name]
#        (defaults to current branch)
#
# Input sources:
#   1. git diff main...HEAD — change diff
#   2. git log --oneline main..HEAD — commit history
#   3. Changed file list — layer estimation
#
# Output: specs/RETRO-SPEC-{feature-name}.md (draft for human review)

set -euo pipefail

# --- Determine branch ---
if [ $# -ge 1 ]; then
  BRANCH="$1"
else
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
fi

# Extract feature name from branch
FEATURE_NAME="$BRANCH"
FEATURE_NAME="${FEATURE_NAME#vibe/}"
FEATURE_NAME="${FEATURE_NAME#promote/}"
FEATURE_NAME="${FEATURE_NAME#feature/}"

# Sanitize for filename
SAFE_NAME=$(echo "$FEATURE_NAME" | tr '/' '-' | tr ' ' '-')
SOURCE_BRANCH="${SAGE_PROMOTION_SOURCE_BRANCH:-$BRANCH}"
SOURCE_SHA="${SAGE_PROMOTION_SOURCE_SHA:-$(git rev-parse "$BRANCH" 2>/dev/null || echo "")}"

echo "=== SAGE Retro-SPEC Generator ==="
echo ""
echo "  Branch: $BRANCH"
echo "  Feature: $FEATURE_NAME"
echo ""

# --- Determine base branch ---
BASE_BRANCH="main"
if ! git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
  BASE_BRANCH="master"
  if ! git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
    echo "  ERROR: Neither 'main' nor 'master' branch found"
    exit 1
  fi
fi

# --- Gather data ---
echo "[1/5] Gathering commit history..."
COMMIT_LOG=$(git log --oneline "$BASE_BRANCH".."$BRANCH" 2>/dev/null || git log --oneline -20)
COMMIT_COUNT=$(echo "$COMMIT_LOG" | wc -l | tr -d ' ')
echo "  Found $COMMIT_COUNT commits"

echo "[2/5] Gathering changed files..."
CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"..."$BRANCH" 2>/dev/null || git diff --name-only HEAD~5)
FILE_COUNT=$(echo "$CHANGED_FILES" | grep -c . || echo "0")
echo "  Found $FILE_COUNT changed files"

echo "[3/5] Analyzing diff stats..."
DIFF_STAT=$(git diff --stat "$BASE_BRANCH"..."$BRANCH" 2>/dev/null | tail -1 || echo "unknown")

echo "[4/5] Estimating affected layers..."
# Layer estimation from file paths
LAYERS=""
if echo "$CHANGED_FILES" | grep -qE "^(src/)?controller" 2>/dev/null; then LAYERS="$LAYERS\n- controller"; fi
if echo "$CHANGED_FILES" | grep -qE "^(src/)?usecase|^(src/)?service|^(src/)?application" 2>/dev/null; then LAYERS="$LAYERS\n- usecase"; fi
if echo "$CHANGED_FILES" | grep -qE "^(src/)?domain|^(src/)?model|^(src/)?entity" 2>/dev/null; then LAYERS="$LAYERS\n- domain"; fi
if echo "$CHANGED_FILES" | grep -qE "^(src/)?infra|^(src/)?repository|^(src/)?adapter|^(src/)?db" 2>/dev/null; then LAYERS="$LAYERS\n- infrastructure"; fi
if echo "$CHANGED_FILES" | grep -qE "^(src/)?(component|page|view|ui|frontend)" 2>/dev/null; then LAYERS="$LAYERS\n- frontend"; fi
if echo "$CHANGED_FILES" | grep -qE "^test|^spec|__test__" 2>/dev/null; then LAYERS="$LAYERS\n- test"; fi
if echo "$CHANGED_FILES" | grep -qE "^script|^\.github|^infra|Dockerfile|docker-compose" 2>/dev/null; then LAYERS="$LAYERS\n- infra/ops"; fi
if [ -z "$LAYERS" ]; then LAYERS="\n- TBD (could not auto-detect layers)"; fi

# --- Generate SPEC-ID ---
echo "[5/5] Generating SPEC-ID..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/sage-id-gen.sh" ]; then
  SPEC_ID=$(bash "$SCRIPT_DIR/sage-id-gen.sh" spec 2>/dev/null || echo "SPEC-XXXX")
else
  SPEC_ID="SPEC-XXXX"
fi

# --- Build scope bullets from changed files ---
SCOPE_BULLETS=""
while IFS= read -r file; do
  if [ -n "$file" ]; then
    SCOPE_BULLETS="$SCOPE_BULLETS\n- \`$file\`"
  fi
done <<< "$CHANGED_FILES"

# --- Build commit summary ---
COMMIT_SUMMARY=""
while IFS= read -r line; do
  if [ -n "$line" ]; then
    COMMIT_SUMMARY="$COMMIT_SUMMARY\n- $line"
  fi
done <<< "$(echo "$COMMIT_LOG" | head -20)"
if [ "$COMMIT_COUNT" -gt 20 ]; then
  COMMIT_SUMMARY="$COMMIT_SUMMARY\n- ... and $((COMMIT_COUNT - 20)) more commits"
fi

# --- Generate output ---
OUTPUT_FILE="specs/RETRO-SPEC-${SAFE_NAME}.md"
TODAY=$(date +%Y-%m-%d)

cat > "$OUTPUT_FILE" << HEREDOC
# ${SPEC_ID}: [Retro-SPEC] ${FEATURE_NAME}

> **This is a Retro-SPEC draft generated from explore branch \`${SOURCE_BRANCH}\`.**
> **Human review and approval required before merge.**

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | ${SPEC_ID} |
| ステータス | Draft (Retro-SPEC — 要人間承認) |
| 作成日    | ${TODAY} |
| 更新日    | ${TODAY} |
| 担当Agent | Retro-SPEC Generator (sage-retro-spec.sh) |
| 依存SPEC  | none |
| 権限レベル | TBD |
| 元ブランチ | ${SOURCE_BRANCH} |
| 昇格元SHA | ${SOURCE_SHA:-TBD} |

## 背景・目的

**TBD — 以下のコミット履歴から目的を記述してください:**
$(echo -e "$COMMIT_SUMMARY")

## 対象ユーザー

TBD — この変更が影響するユーザー・システムを記述してください。

## スコープ（含む）

変更された ${FILE_COUNT} ファイル:
$(echo -e "$SCOPE_BULLETS")

## スコープ外（明示的に除外）

TBD — 意図的に除外した範囲を記述してください。「なし」は不可。

- TBD

## 要件

### 機能要件
- [FR-01] TBD — 変更差分から機能要件を抽出してください

### 非機能要件
- [NFR-01] TBD

### セキュリティ要件
- [SEC-01] TBD（「該当なし」の場合は理由を付記）

### 運用要件
- [OPS-01] TBD

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: TBD — テストまたはコマンドで検証可能な条件（最低3件）
- [ ] AC-02: TBD
- [ ] AC-03: TBD

## 異常系

- TBD — 最低1件定義すること

## 契約

- API: TBD
- DB: TBD
- イベント: TBD

## リスク

- TBD — 最低1件

## 実装メモ（Implementation Agent向け）

### 変更統計
\`\`\`
${DIFF_STAT}
\`\`\`

### 推定影響レイヤ
$(echo -e "$LAYERS")

### コミット履歴（参考）
$(echo -e "$COMMIT_SUMMARY")

## 関連ID

- PLAN-ID: （計画フェーズで記入）
- TASK-ID: （分割フェーズで記入）
HEREDOC

echo ""
echo "  Generated: $OUTPUT_FILE"
echo "  SPEC-ID:   $SPEC_ID"
echo ""
echo "  IMPORTANT: This is a DRAFT. Review and fill in all TBD sections."
echo "  Run 'grep -c TBD $OUTPUT_FILE' to check remaining items."
echo ""
echo "=== Retro-SPEC Generation Complete ==="
