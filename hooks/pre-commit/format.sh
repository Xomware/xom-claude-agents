#!/usr/bin/env bash
# hooks/pre-commit/format.sh
# Checks for consistent YAML formatting, warns on JSON without formatting
set -euo pipefail

FAIL=0
ERRORS=()
WARNINGS=()

echo "🎨 [format] Checking file formatting..."

# Get staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
[[ -z "$STAGED_FILES" ]] && { echo "  ℹ️  No staged files."; exit 0; }

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ ! -f "$file" ]] && continue

  case "$file" in
    *.yaml|*.yml)
      echo "  Checking YAML: $file"

      # Check for tabs (YAML must use spaces)
      if grep -Pn "\t" "$file" &>/dev/null; then
        ERRORS+=("YAML_TABS: $file uses tabs — YAML requires spaces")
        ((FAIL++)) || true
      fi

      # Check for consistent indentation (2 or 4 spaces)
      # Detect mixing of 2-space and 4-space indentation
      TWO_SPACE=$(grep -cP "^  [^ ]" "$file" 2>/dev/null || echo 0)
      FOUR_SPACE=$(grep -cP "^    [^ ]" "$file" 2>/dev/null || echo 0)
      if [[ "$TWO_SPACE" -gt 0 && "$FOUR_SPACE" -gt 0 ]]; then
        WARNINGS+=("YAML_MIXED_INDENT: $file mixes 2-space and 4-space indentation")
      fi

      # Check for trailing whitespace in YAML
      if grep -Pn " +$" "$file" &>/dev/null; then
        ERRORS+=("YAML_TRAILING_WS: $file has trailing whitespace")
        ((FAIL++)) || true
      fi

      # Validate YAML syntax if python/yq available
      if command -v python3 &>/dev/null; then
        if ! python3 -c "import yaml, sys; yaml.safe_load(open('$file'))" 2>/dev/null; then
          ERRORS+=("YAML_INVALID: $file has invalid YAML syntax")
          ((FAIL++)) || true
        fi
      fi
      ;;

    *.json)
      echo "  Checking JSON: $file"

      # Warn if JSON isn't formatted (check via python if available)
      if command -v python3 &>/dev/null; then
        FORMATTED=$(python3 -m json.tool "$file" 2>/dev/null || true)
        if [[ -n "$FORMATTED" ]]; then
          ORIGINAL=$(cat "$file")
          if [[ "$FORMATTED" != "$ORIGINAL" ]]; then
            WARNINGS+=("JSON_UNFORMATTED: $file is not pretty-printed (run: python3 -m json.tool $file > $file.tmp && mv $file.tmp $file)")
          fi
        else
          ERRORS+=("JSON_INVALID: $file has invalid JSON syntax")
          ((FAIL++)) || true
        fi
      fi
      ;;
  esac
done <<< "$STAGED_FILES"

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "  ⚠️  Format warnings:"
  for w in "${WARNINGS[@]}"; do echo "     - $w"; done
fi

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "  ❌ Format errors (must fix before commit):"
  for err in "${ERRORS[@]}"; do echo "     - $err"; done
  exit 1
fi

echo "  ✅ Format check passed."
exit 0
