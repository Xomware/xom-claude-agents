#!/usr/bin/env bash
# hooks/pre-pr/type-check.sh
# Runs tsc --noEmit if tsconfig exists, else passes gracefully
set -euo pipefail

echo "🔷 [type-check] Running TypeScript type check..."

TSCONFIG=""

# Search for tsconfig in current dir or subdirs (up to 2 levels)
for candidate in tsconfig.json tsconfig.build.json tsconfig.base.json; do
  if [[ -f "$candidate" ]]; then
    TSCONFIG="$candidate"
    break
  fi
done

if [[ -z "$TSCONFIG" ]]; then
  echo "  ℹ️  No tsconfig.json found — skipping type check."
  exit 0
fi

echo "  Found: $TSCONFIG"

# Check if tsc is available
if ! command -v tsc &>/dev/null; then
  # Try local node_modules
  if [[ -f "node_modules/.bin/tsc" ]]; then
    TSC="./node_modules/.bin/tsc"
  else
    echo "  ⚠️  tsc not found. Install TypeScript: npm install -g typescript"
    echo "  ℹ️  Skipping type check (tsc unavailable)."
    exit 0
  fi
else
  TSC="tsc"
fi

echo "  Running: $TSC --noEmit --project $TSCONFIG"
if $TSC --noEmit --project "$TSCONFIG"; then
  echo "  ✅ Type check passed."
  exit 0
else
  echo "  ❌ TypeScript type errors found. Fix before creating PR."
  exit 1
fi
