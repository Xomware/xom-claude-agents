#!/usr/bin/env bash
# hooks/pre-pr/test.sh
# Verifies test files exist alongside changed source files
set -euo pipefail

FAIL=0
WARNINGS=()

echo "🧪 [test] Checking for test coverage on changed source files..."

BASE_BRANCH="${BASE_BRANCH:-main}"
if git rev-parse --verify "origin/$BASE_BRANCH" &>/dev/null; then
  CHANGED_FILES=$(git diff --name-only "origin/$BASE_BRANCH"...HEAD 2>/dev/null || true)
else
  CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null || git ls-files 2>/dev/null || true)
fi

[[ -z "$CHANGED_FILES" ]] && CHANGED_FILES=$(git ls-files)

check_test_exists() {
  local src="$1"
  local base="${src%.*}"
  local ext="${src##*.}"
  local dir
  dir="$(dirname "$src")"
  local filename
  filename="$(basename "$base")"

  # Common test file patterns
  local candidates=(
    "${base}.test.${ext}"
    "${base}.spec.${ext}"
    "${dir}/__tests__/${filename}.test.${ext}"
    "${dir}/__tests__/${filename}.spec.${ext}"
    "${dir}/tests/test_${filename}.${ext}"
    "${dir}/tests/${filename}_test.${ext}"
    "tests/test_${filename}.${ext}"
    "test/test_${filename}.${ext}"
    "spec/${filename}_spec.${ext}"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      return 0
    fi
  done
  return 1
}

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ ! -f "$file" ]] && continue

  # Only check source files (skip tests, configs, docs, yaml, json, md)
  case "$file" in
    *.test.*|*.spec.*|*__tests__*|*/tests/*|*/test/*|*/spec/*) continue ;;
    *.md|*.yaml|*.yml|*.json|*.toml|*.ini|*.cfg|*.txt|*.sh) continue ;;
  esac

  # Only check common source extensions
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.py|*.rb|*.go|*.java|*.rs)
      if ! check_test_exists "$file"; then
        WARNINGS+=("MISSING_TEST: No test file found for $file")
        ((FAIL++)) || true
      fi
      ;;
  esac
done <<< "$CHANGED_FILES"

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "  ⚠️  Missing test coverage:"
  for w in "${WARNINGS[@]}"; do echo "     - $w"; done
  echo ""
  echo "  Add test files before merging, or set SKIP_TEST_CHECK=1 to warn-only."
  if [[ "${SKIP_TEST_CHECK:-0}" == "1" ]]; then
    echo "  ⚠️  SKIP_TEST_CHECK=1 — treating as warning only."
    exit 0
  fi
  exit 1
fi

echo "  ✅ Test coverage check passed."
exit 0
