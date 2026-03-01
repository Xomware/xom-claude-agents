#!/usr/bin/env bash
# validate-routing.sh — Validate route-model.sh routing correctness
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROUTE="$SCRIPT_DIR/route-model.sh"

PASS=0
FAIL=0
TOTAL=0

assert_route() {
  local desc="$1" expected="$2"; shift 2
  TOTAL=$((TOTAL + 1))
  local actual
  actual=$("$ROUTE" "$@" 2>/dev/null)
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: $desc → $actual"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc → expected $expected, got $actual"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Routing Validation ==="
echo ""
echo "--- Haiku tasks ---"
for task in triage status_check board_update format lookup; do
  assert_route "$task" "claude-haiku-4-5" --task-type "$task"
done

echo ""
echo "--- Sonnet tasks ---"
for task in planning strategy architecture_design roadmapping documentation; do
  assert_route "$task" "claude-sonnet-4-6" --task-type "$task"
done

echo ""
echo "--- Opus tasks ---"
for task in implementation code_review debugging refactoring test_writing security_audit analysis; do
  assert_route "$task" "claude-opus-4-5" --task-type "$task"
done

echo ""
echo "--- Agent overrides ---"
assert_route "dispatcher+implementation" "claude-haiku-4-5" --agent dispatcher --task-type implementation
assert_route "forge-code+triage" "claude-opus-4-5" --agent forge-code --task-type triage
assert_route "forge-code+planning" "claude-opus-4-5" --agent forge-code --task-type planning

echo ""
echo "=== $PASS/$TOTAL assertions passed ==="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
