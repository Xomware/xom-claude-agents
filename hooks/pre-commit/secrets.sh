#!/usr/bin/env bash
# hooks/pre-commit/secrets.sh
# Scans staged files for API keys, tokens, and passwords using regex patterns
set -euo pipefail

FAIL=0
FINDINGS=()

echo "🔐 [secrets] Scanning staged files for secrets..."

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
[[ -z "$STAGED_FILES" ]] && { echo "  ℹ️  No staged files."; exit 0; }

# Secret patterns: (label, regex)
declare -a PATTERNS=(
  "AWS_ACCESS_KEY:AKIA[0-9A-Z]{16}"
  "AWS_SECRET_KEY:[A-Za-z0-9/+=]{40}"
  "GITHUB_TOKEN:gh[pousr]_[A-Za-z0-9_]{36,}"
  "GENERIC_API_KEY:(?i)(api[_-]?key|apikey)\s*[:=]\s*['\"]?[A-Za-z0-9\-_]{20,}"
  "GENERIC_SECRET:(?i)(secret|password|passwd|pwd)\s*[:=]\s*['\"]?[A-Za-z0-9\-_!@#\$%^&*]{8,}"
  "PRIVATE_KEY:-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"
  "SLACK_TOKEN:xox[baprs]-[A-Za-z0-9\-]+"
  "STRIPE_KEY:sk_(live|test)_[A-Za-z0-9]{24,}"
  "SENDGRID_KEY:SG\.[A-Za-z0-9\-_]{22,}\.[A-Za-z0-9\-_]{43,}"
  "BASIC_AUTH_URL:https?://[^:@\s]+:[^@\s]+@"
  "HARDCODED_TOKEN:(?i)(token|bearer)\s*[:=]\s*['\"]?[A-Za-z0-9\-_.]{20,}"
  "HEX_SECRET:(?i)(secret|key)\s*[:=]\s*['\"]?[0-9a-f]{32,}"
)

# Files/patterns to always skip
SKIP_PATTERNS=(
  "*.md"
  "*.example"
  "*.sample"
  "*.test.*"
  "*.spec.*"
  "test/*"
  "tests/*"
  "__tests__/*"
)

should_skip() {
  local file="$1"
  for pattern in "${SKIP_PATTERNS[@]}"; do
    # shellcheck disable=SC2053
    if [[ "$file" == $pattern ]]; then return 0; fi
  done
  return 1
}

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ ! -f "$file" ]] && continue

  if should_skip "$file"; then
    echo "  ⏭️  Skipping: $file"
    continue
  fi

  # Check if binary
  if file "$file" 2>/dev/null | grep -q "binary"; then continue; fi

  for entry in "${PATTERNS[@]}"; do
    label="${entry%%:*}"
    pattern="${entry#*:}"

    if grep -Pn "$pattern" "$file" &>/dev/null; then
      LINE=$(grep -Pn "$pattern" "$file" | head -1)
      FINDINGS+=("[$label] $file:$LINE")
      ((FAIL++)) || true
    fi
  done

done <<< "$STAGED_FILES"

if [[ ${#FINDINGS[@]} -gt 0 ]]; then
  echo ""
  echo "  🚨 SECRETS DETECTED — DO NOT COMMIT:"
  for f in "${FINDINGS[@]}"; do
    echo "     ⛔ $f"
  done
  echo ""
  echo "  Actions:"
  echo "    1. Remove the secret from the file"
  echo "    2. Rotate the key/token immediately"
  echo "    3. Use environment variables or a secrets manager"
  echo "    4. Add to .gitignore if it's a config file"
  echo ""
  echo "  If this is a false positive, add the file to .secretsignore"
  exit 1
fi

echo "  ✅ No secrets detected."
exit 0
