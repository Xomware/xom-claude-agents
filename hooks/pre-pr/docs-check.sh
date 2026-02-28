#!/usr/bin/env bash
# hooks/pre-pr/docs-check.sh
# Verifies README.md or AGENTS.md exists and was recently modified
set -euo pipefail

FAIL=0
ERRORS=()

echo "📄 [docs-check] Checking documentation requirements..."

# 1. Ensure at least one primary doc file exists
DOC_FOUND=false
for doc in README.md AGENTS.md docs/README.md; do
  if [[ -f "$doc" ]]; then
    DOC_FOUND=true
    echo "  Found: $doc"
    break
  fi
done

if [[ "$DOC_FOUND" != "true" ]]; then
  ERRORS+=("MISSING_DOCS: No README.md or AGENTS.md found in repo root")
  ((FAIL++)) || true
fi

# 2. Check if docs were modified alongside code changes
BASE_BRANCH="${BASE_BRANCH:-main}"
if git rev-parse --verify "origin/$BASE_BRANCH" &>/dev/null; then
  CHANGED_FILES=$(git diff --name-only "origin/$BASE_BRANCH"...HEAD 2>/dev/null || true)
else
  CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null || true)
fi

HAS_CODE_CHANGES=false
HAS_DOC_CHANGES=false

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  case "$file" in
    *.md|*.rst|*.txt) HAS_DOC_CHANGES=true ;;
    *.sh|*.ts|*.js|*.py|*.go|*.yaml|*.yml) HAS_CODE_CHANGES=true ;;
  esac
done <<< "$CHANGED_FILES"

if [[ "$HAS_CODE_CHANGES" == "true" && "$HAS_DOC_CHANGES" == "false" ]]; then
  echo "  ⚠️  Code changed but no documentation updated."
  echo "     Consider updating README.md or AGENTS.md to reflect changes."
  # Warn only — don't block
fi

# 3. Check README isn't empty/stub
if [[ -f "README.md" ]]; then
  LINE_COUNT=$(wc -l < README.md)
  if [[ "$LINE_COUNT" -lt 5 ]]; then
    ERRORS+=("STUB_README: README.md is too short ($LINE_COUNT lines). Expand it.")
    ((FAIL++)) || true
  fi
fi

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "  ❌ Documentation errors:"
  for err in "${ERRORS[@]}"; do echo "     - $err"; done
  exit 1
fi

echo "  ✅ Documentation check passed."
exit 0
