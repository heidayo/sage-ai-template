#!/bin/bash
# sage-publish.sh — バージョン更新 + install.sh 再生成 + SHA256SUMS + Gist 更新 + git tag push
# SPEC-0018 で GitHub Releases publish も追加 (tag push が release.yml を発火)。
#
# Usage:
#   bash scripts/sage-publish.sh <version|major|minor|patch> [--no-gist] [--no-release]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
GIST_ID_FILE="$ROOT/.sage/gist-id"
VERSION_FILE="$ROOT/.sage-version"
SHA256SUMS_FILE="$ROOT/SHA256SUMS"

# --- セマンティックバージョニング自動インクリメント ---
increment_version() {
  local version="$1"
  local part="$2"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  major=${major:-0}; minor=${minor:-0}; patch=${patch:-0}

  case "$part" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    patch) echo "${major}.${minor}.$((patch + 1))" ;;
    *) echo "" ;;
  esac
}

validate_semver() {
  echo "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'
}

usage() {
  cat <<USAGE
Usage: bash scripts/sage-publish.sh <version|major|minor|patch> [--no-gist] [--no-release]

  セマンティックバージョニング:
    bash scripts/sage-publish.sh major          # 1.5.0 → 2.0.0
    bash scripts/sage-publish.sh minor          # 1.5.0 → 1.6.0
    bash scripts/sage-publish.sh patch          # 1.5.0 → 1.5.1

  直接指定:
    bash scripts/sage-publish.sh 1.6.0

  Flags (SPEC-0018):
    --no-gist     Gist 更新を skip (Releases-only mode、Gist 廃止 phase で利用)
    --no-release  git tag push を skip (release.yml を発火させない、local-only test 用)

事前準備:
  1. gh auth login                             (GitHub CLI 認証)
  2. echo 'YOUR_GIST_ID' > .sage/gist-id       (Gist ID 保存、--no-gist 時は不要)
  3. git remote -v                             (origin が GitHub に向いていること、--no-release 時は不要)
USAGE
}

# --- 引数パース ---
NO_GIST=0
NO_RELEASE=0
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --no-gist)
      NO_GIST=1
      shift
      ;;
    --no-release)
      NO_RELEASE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [ ${#POSITIONAL[@]} -lt 1 ]; then
  usage
  exit 1
fi

OLD_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")
ROLLBACK_VERSION=""

rollback_version_file() {
  if [ -n "$ROLLBACK_VERSION" ]; then
    echo "$ROLLBACK_VERSION" > "$VERSION_FILE"
    echo "  ROLLBACK: .sage-version を $ROLLBACK_VERSION に戻しました。" >&2
  fi
}

trap rollback_version_file EXIT

# major / minor / patch なら自動インクリメント、それ以外は直接指定
case "${POSITIONAL[0]}" in
  major|minor|patch)
    NEW_VERSION=$(increment_version "$OLD_VERSION" "${POSITIONAL[0]}")
    if [ -z "$NEW_VERSION" ]; then
      echo "Error: バージョン計算に失敗しました。現在: $OLD_VERSION"
      exit 1
    fi
    echo "Auto-increment: $OLD_VERSION → $NEW_VERSION (${POSITIONAL[0]})"
    ;;
  *)
    NEW_VERSION="${POSITIONAL[0]}"
    ;;
esac

if ! validate_semver "$NEW_VERSION"; then
  echo "Error: バージョン '$NEW_VERSION' は semver (X.Y.Z) 形式で指定してください。"
  exit 1
fi

# --- バージョン確認 ---
if [ "$NEW_VERSION" = "$OLD_VERSION" ]; then
  echo "Error: バージョン $NEW_VERSION は現在と同じです。新しいバージョンを指定してください。"
  exit 1
fi

echo "========================================="
echo "  SAGE Publish: v${OLD_VERSION} → v${NEW_VERSION}"
echo "========================================="
[ "$NO_GIST" -eq 1 ]    && echo "  flag: --no-gist (Gist 更新 skip)"
[ "$NO_RELEASE" -eq 1 ] && echo "  flag: --no-release (tag push skip)"
echo ""

# --- Step 1: バージョン更新 ---
echo "[1/4] バージョン更新..."
ROLLBACK_VERSION="$OLD_VERSION"
echo "$NEW_VERSION" > "$VERSION_FILE"
echo "  OK: .sage-version = $NEW_VERSION"

# --- Step 2: install.sh 再生成 + SHA256SUMS ---
echo ""
echo "[2/4] install.sh 再生成 + SHA256SUMS..."
bash "$SCRIPT_DIR/generate-installer.sh" > "$ROOT/install.sh"
LINES=$(wc -l < "$ROOT/install.sh" | tr -d ' ')
echo "  OK: install.sh ($LINES lines)"

# SPEC-0018 FR-03: SHA256SUMS local 生成
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$ROOT" && sha256sum install.sh) > "$SHA256SUMS_FILE"
elif command -v shasum >/dev/null 2>&1; then
  (cd "$ROOT" && shasum -a 256 install.sh) > "$SHA256SUMS_FILE"
else
  echo "  WARN: sha256sum / shasum not available; SHA256SUMS not generated"
  SHA256SUMS_FILE=""
fi
if [ -n "$SHA256SUMS_FILE" ] && [ -s "$SHA256SUMS_FILE" ]; then
  echo "  OK: $(basename "$SHA256SUMS_FILE")"
  echo "      $(cat "$SHA256SUMS_FILE")"
fi

# --- Step 3: Gist 更新 ---
echo ""
if [ "$NO_GIST" -eq 1 ]; then
  echo "[3/4] Gist 更新 — SKIP (--no-gist)"
else
  echo "[3/4] Gist 更新..."
  if [ ! -f "$GIST_ID_FILE" ]; then
    echo "  SKIP: .sage/gist-id が見つかりません。"
    echo ""
    echo "  Gist を初めて作成する場合:"
    echo "    gh gist create install.sh --desc 'SAGE Development System Installer'"
    echo "    echo 'GIST_ID' > .sage/gist-id"
    echo ""
    echo "  手動で Gist を更新する場合:"
    echo "    gh gist edit GIST_ID install.sh"
  else
    GIST_ID=$(tr -d '[:space:]' < "$GIST_ID_FILE")
    if [ -z "$GIST_ID" ]; then
      echo "  Error: .sage/gist-id が空です。Gist IDを書き込んでください。"
      exit 1
    fi
    if ! command -v gh >/dev/null 2>&1; then
      echo "  Error: GitHub CLI (gh) がインストールされていません。"
      echo "  https://cli.github.com/ からインストールしてください。"
      exit 1
    fi
    if gh gist edit "$GIST_ID" "$ROOT/install.sh" 2>/dev/null; then
      echo "  OK: Gist $GIST_ID を更新しました"
    else
      echo "  Error: Gist の更新に失敗しました。"
      echo "  以下を確認してください:"
      echo "    - gh auth login で認証済みか"
      echo "    - Gist ID ($GIST_ID) が正しいか"
      exit 1
    fi
  fi
fi

# --- Step 4: git tag + push (SPEC-0018 — release.yml を発火) ---
echo ""
if [ "$NO_RELEASE" -eq 1 ]; then
  echo "[4/4] git tag push — SKIP (--no-release)"
  echo "  注意: GitHub Release は作成されません。手動で tag を push する場合:"
  echo "    git tag v${NEW_VERSION} && git push origin v${NEW_VERSION}"
else
  echo "[4/4] git tag push (release.yml を発火)..."
  if ! command -v git >/dev/null 2>&1; then
    echo "  Error: git がインストールされていません。"
    exit 1
  fi
  TAG="v${NEW_VERSION}"
  # 既存 tag チェック (AC-17 異常系: 重複 tag は事前検出)
  if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
    echo "  Error: tag ${TAG} が既に存在します。先に削除してください:"
    echo "    git tag -d ${TAG} && git push --delete origin ${TAG}"
    exit 1
  fi
  # 未 commit 変更チェック (.sage-version / install.sh / SHA256SUMS が staged 必要)
  if ! git diff --quiet -- "$VERSION_FILE" "$ROOT/install.sh" 2>/dev/null; then
    echo "  WARN: .sage-version または install.sh が未 commit です。"
    echo "  推奨: 'git add .sage-version install.sh SHA256SUMS && git commit -m \"TASK-XXXX: bump v${NEW_VERSION}\"'"
    echo "        してから 'git tag ${TAG} && git push origin ${TAG}' を実行"
    echo "  または --no-release で tag push を skip"
  else
    git tag "$TAG"
    if git push origin "$TAG" 2>/dev/null; then
      echo "  OK: tag ${TAG} を push しました (release.yml が発火)"
      echo "  確認: gh run list --workflow=release.yml --limit 1"
    else
      echo "  Error: tag ${TAG} の push に失敗しました (network / 権限を確認)"
      git tag -d "$TAG" 2>/dev/null || true
      exit 1
    fi
  fi
fi

ROLLBACK_VERSION=""

# --- 完了 ---
echo ""
echo "========================================="
echo "  SAGE v${NEW_VERSION} — Published"
echo "========================================="
echo ""
echo "次のステップ:"
echo "  - 各プロジェクトは次回セッション開始時に更新通知を表示します"
echo "    (.sage/config.yaml の installer_url が設定されている場合)"
if [ "$NO_RELEASE" -eq 0 ]; then
  echo "  - GitHub Release v${NEW_VERSION} は数分後に作成されます"
  echo "    確認: gh release view v${NEW_VERSION}"
fi
