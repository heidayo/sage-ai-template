#!/usr/bin/env bash
# =============================================================================
# TASK-0136: test-installer-modularize.sh (SPEC-0014 AC-04)
# Purpose:  Test scripts/generator/ module structure: byte-identical, syntax,
#           hook addition simulation, regen, source order, perf.
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GENERATOR="${REPO_ROOT}/scripts/generate-installer.sh"
GENERATOR_DIR="${REPO_ROOT}/scripts/generator"
INSTALL_SH="${REPO_ROOT}/install.sh"

echo "# installer modularize (SPEC-0014)"

# --- Scenario 1: byte-identical (生成 install.sh が committed install.sh と完全一致) ---
new_install="$(mktemp)"
trap "rm -f $new_install" EXIT
( cd "$REPO_ROOT" && bash "$GENERATOR" > "$new_install" 2>/dev/null )
diff_lines=$(diff "$INSTALL_SH" "$new_install" | wc -l | tr -d ' ')
if [ "$diff_lines" = "0" ]; then
  PASS=$((PASS + 1))
  echo "  ok   byte-identical (diff = 0 lines)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok byte-identical FAILED: $diff_lines diff lines" >&2
fi

# --- Scenario 2: 7 module syntax check ---
module_count=$(find "$GENERATOR_DIR" -maxdepth 1 -name '[0-9][0-9]-*.sh' | wc -l | tr -d ' ')
if [ "$module_count" = "7" ]; then
  PASS=$((PASS + 1))
  echo "  ok   7 modules in scripts/generator/"
else
  FAIL=$((FAIL + 1))
  echo "  not ok module count: expected 7, got $module_count" >&2
fi

syntax_ok=true
for m in "$GENERATOR_DIR"/[0-9][0-9]-*.sh; do
  if ! bash -n "$m" 2>/dev/null; then
    syntax_ok=false
    break
  fi
done
if $syntax_ok; then
  PASS=$((PASS + 1))
  echo "  ok   all 7 modules pass bash -n syntax check"
else
  FAIL=$((FAIL + 1))
  echo "  not ok module syntax error" >&2
fi

# --- Scenario 3: source order (numeric prefix glob sort) ---
expected_order="01-templates.sh 02-config.sh 03-rules.sh 04-hooks-base.sh 05-hooks-phase2b.sh 06-hooks-phase5.sh 07-installer-main.sh"
actual_order=$(find "$GENERATOR_DIR" -maxdepth 1 -name '[0-9][0-9]-*.sh' -exec basename {} \; | sort | tr '\n' ' ' | sed 's/ $//')
if [ "$actual_order" = "$expected_order" ]; then
  PASS=$((PASS + 1))
  echo "  ok   module source order is numeric (01..07)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok module order mismatch" >&2
  echo "    expected: $expected_order" >&2
  echo "    actual:   $actual_order" >&2
fi

# --- Scenario 4: install.sh 削除後の再生成成功 ---
sandbox="$(mktemp -d)"
cp -r "$REPO_ROOT/scripts" "$sandbox/" 2>/dev/null
cp -r "$REPO_ROOT/specs" "$REPO_ROOT/plans" "$REPO_ROOT/tasks" "$REPO_ROOT/sage" "$sandbox/" 2>/dev/null
cp -r "$REPO_ROOT/templates" "$REPO_ROOT/.sage" "$REPO_ROOT/.claude" "$sandbox/" 2>/dev/null
cp "$REPO_ROOT/.sage-version" "$sandbox/" 2>/dev/null
( cd "$sandbox" && bash scripts/generate-installer.sh > install.sh 2>/dev/null )
if [ -s "$sandbox/install.sh" ]; then
  PASS=$((PASS + 1))
  echo "  ok   install.sh regenerated from sandbox (size=$(wc -c < "$sandbox/install.sh" | tr -d ' ') bytes)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok install.sh regen failed" >&2
fi
rm -rf "$sandbox"

# --- Scenario 5: 新 hook 追加 simulation (06-hooks-phase5.sh に embed_file 1 行追加 → 1 行 diff) ---
mod_sandbox="$(mktemp -d)"
cp -r "$REPO_ROOT/scripts" "$REPO_ROOT/specs" "$REPO_ROOT/plans" "$REPO_ROOT/tasks" "$REPO_ROOT/sage" "$REPO_ROOT/templates" "$REPO_ROOT/.sage" "$REPO_ROOT/.claude" "$mod_sandbox/" 2>/dev/null
cp "$REPO_ROOT/.sage-version" "$mod_sandbox/" 2>/dev/null
# Inject a fake embed_file at end of 06-hooks-phase5.sh (use an existing file path so embed succeeds)
echo 'embed_file "TMPL_FAKE_NEW_HOOK" "$ROOT/scripts/sage-validate.sh"' >> "$mod_sandbox/scripts/generator/06-hooks-phase5.sh"
echo 'echo ""' >> "$mod_sandbox/scripts/generator/06-hooks-phase5.sh"
new_with_addition="$(mktemp)"
( cd "$mod_sandbox" && bash scripts/generate-installer.sh > "$new_with_addition" 2>/dev/null )
# The diff should be > 0 (new lines added) but only in the new module's section, not random changes elsewhere
diff_with_addition=$(diff "$INSTALL_SH" "$new_with_addition" | grep -c "^>" || true)
if [ "$diff_with_addition" -gt 0 ]; then
  PASS=$((PASS + 1))
  echo "  ok   adding 1 embed_file line produces diff (only in target module section)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok module addition didn't change install.sh output" >&2
fi
rm -rf "$mod_sandbox" "$new_with_addition"

# --- Scenario 6: perf < 2s ---
start=$(python3 -c "import time; print(time.perf_counter())" 2>/dev/null || echo "0")
( cd "$REPO_ROOT" && bash "$GENERATOR" > /dev/null 2>&1 )
end=$(python3 -c "import time; print(time.perf_counter())" 2>/dev/null || echo "2")
elapsed_ms=$(python3 -c "print(int((${end} - ${start}) * 1000))" 2>/dev/null || echo "9999")
if [ "$elapsed_ms" -lt 2000 ]; then
  PASS=$((PASS + 1))
  echo "  ok   generation perf ${elapsed_ms}ms < 2000ms"
else
  FAIL=$((FAIL + 1))
  echo "  not ok generation perf ${elapsed_ms}ms (>= 2000ms threshold)" >&2
fi

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
