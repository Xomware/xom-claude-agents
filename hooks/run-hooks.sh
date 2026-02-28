#!/usr/bin/env bash
# hooks/run-hooks.sh
# Master hook runner — executes all hooks for a given stage
#
# Usage:
#   ./hooks/run-hooks.sh pre-pr       # Run all pre-PR quality gates
#   ./hooks/run-hooks.sh pre-commit   # Run all pre-commit checks
#   ./hooks/run-hooks.sh post-merge   # Run all post-merge actions
#
# Exit codes:
#   0 — all hooks passed
#   1 — one or more hooks failed
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Usage: $0 <stage>"
  echo "  stage: pre-pr | pre-commit | post-merge"
  exit 1
}

[[ $# -lt 1 ]] && usage

STAGE="$1"

case "$STAGE" in
  pre-pr|pre-commit|post-merge) ;;
  *) echo "❌ Unknown stage: $STAGE"; usage ;;
esac

HOOKS_DIR="$SCRIPT_DIR/$STAGE"

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "❌ No hooks directory found for stage '$STAGE' at: $HOOKS_DIR"
  exit 1
fi

# Collect all .sh files in the stage directory, sorted
HOOK_FILES=()
while IFS= read -r -d '' f; do
  HOOK_FILES+=("$f")
done < <(find "$HOOKS_DIR" -maxdepth 1 -name "*.sh" -type f -print0 | sort -z)

if [[ ${#HOOK_FILES[@]} -eq 0 ]]; then
  echo "ℹ️  No hooks found in $HOOKS_DIR"
  exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🪝  Running hooks: $STAGE (${#HOOK_FILES[@]} hook(s))"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASSED=0
FAILED=0
FAILED_HOOKS=()

for hook in "${HOOK_FILES[@]}"; do
  hook_name="$(basename "$hook")"
  echo "▶  Running: $hook_name"
  echo "---"

  if bash "$hook"; then
    ((PASSED++)) || true
    echo "---"
    echo "✅ $hook_name passed"
  else
    ((FAILED++)) || true
    FAILED_HOOKS+=("$hook_name")
    echo "---"
    echo "❌ $hook_name FAILED"
  fi
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Results: $PASSED passed, $FAILED failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAILED -gt 0 ]]; then
  echo ""
  echo "❌ The following hooks FAILED:"
  for h in "${FAILED_HOOKS[@]}"; do echo "   - $h"; done
  echo ""
  echo "Fix all failing hooks before proceeding."
  exit 1
fi

echo ""
echo "✅ All $STAGE hooks passed!"
exit 0
