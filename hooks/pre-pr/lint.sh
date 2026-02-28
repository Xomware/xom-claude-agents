#!/usr/bin/env bash
# hooks/pre-pr/lint.sh
# Checks for common lint issues: trailing whitespace, TODO without ticket, debug statements
set -euo pipefail

FAIL=0
ERRORS=()

echo "🔍 [lint] Running lint checks on changed files..."

BASE_BRANCH="${BASE_BRANCH:-main}"
if git rev-parse --verify "origin/$BASE_BRANCH" &>/dev/null; then
  CHANGED_FILES=$(git diff --name-only "origin/$BASE_BRANCH"...HEAD 2>/dev/null || true)
else
  CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null || git ls-files 2>/dev/null || true)
fi

if [[ -z "$CHANGED_FILES" ]]; then
  CHANGED_FILES=$(git ls-files)
fi

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ ! -f "$file" ]] && continue
  # Skip binary files
  if file "$file" 2>/dev/null | grep -q "binary"; then continue; fi

  # 1. Trailing whitespace
  if grep -Pn " +$" "$file" &>/dev/null; then
    ERRORS+=("TRAILING_WHITESPACE: $file has trailing whitespace")
    ((FAIL++)) || true
  fi

  # 2. TODO without a ticket reference (TODO(#123) or TODO: JIRA-123 are OK)
  if grep -Pn "TODO(?!\s*[\(\[#]|\s*:[A-Z]+-[0-9]+)" "$file" &>/dev/null; then
    ERRORS+=("TODO_WITHOUT_TICKET: $file — use TODO(#N) or TODO: TICKET-N")
    ((FAIL++)) || true
  fi

  # 3. Debug statements
  for pattern in "console\.log\(" "debugger;" "binding\.pry" "byebug" "import pdb" "pdb\.set_trace" "var_dump\("; do
    if grep -Pn "$pattern" "$file" &>/dev/null; then
      ERRORS+=("DEBUG_STATEMENT: $file contains '$pattern'")
      ((FAIL++)) || true
      break
    fi
  done

done <<< "$CHANGED_FILES"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "  ❌ Lint errors found:"
  for err in "${ERRORS[@]}"; do echo "     - $err"; done
  echo "  Fix these issues before creating a PR."
  exit 1
fi

echo "  ✅ All lint checks passed."
exit 0
