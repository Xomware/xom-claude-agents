#!/usr/bin/env bash
# =============================================================================
# scripts/mcp-audit.sh — MCP Tool Discipline Auditor
# Enforces the 10-tool-per-agent limit across all agent configs.
#
# Usage:
#   ./scripts/mcp-audit.sh            # Print table, exit 1 if violations
#   ./scripts/mcp-audit.sh --report   # JSON report to stdout
#   ./scripts/mcp-audit.sh --fix      # Auto-comment out excess tools
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX_TOOLS=10
FIX_MODE=false
REPORT_MODE=false
VIOLATIONS=0

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --fix)    FIX_MODE=true ;;
    --report) REPORT_MODE=true ;;
    --help|-h)
      echo "Usage: $0 [--fix] [--report]"
      echo "  (no flags)  Print audit table, exit 1 if violations"
      echo "  --fix       Auto-comment out tools beyond the max_enabled limit"
      echo "  --report    Output JSON audit report"
      exit 0
      ;;
    *)
      echo "Unknown flag: $arg" >&2
      exit 1
      ;;
  esac
done

# ─── Helpers ────────────────────────────────────────────────────────────────

count_enabled_tools() {
  local file="$1"
  # Count lines with `enabled: true` inside the tools block
  # Uses awk to only count inside the tools: section
  awk '
    /^tools:/ { in_tools=1 }
    in_tools && /^[a-z]/ && !/^tools:/ { in_tools=0 }
    in_tools && /enabled: true/ { count++ }
    END { print count+0 }
  ' "$file"
}

get_max_enabled() {
  local file="$1"
  # Read max_enabled from tools section if present, else return MAX_TOOLS default
  local val
  val=$(awk '/^tools:/{in_tools=1} in_tools && /max_enabled:/{print $2; exit}' "$file")
  echo "${val:-$MAX_TOOLS}"
}

get_agent_name() {
  local file="$1"
  awk '/^metadata:/{in_meta=1} in_meta && /name:/{gsub(/"/, "", $2); print $2; exit}' "$file"
}

fix_agent_file() {
  local file="$1"
  local enabled="$2"
  local max="$3"
  local excess=$(( enabled - max ))

  echo "  → Fixing $file (commenting out $excess excess tool(s))" >&2

  # Comment out enabled: true for tools beyond the limit, counting from the bottom up
  # We find all `- name:` entries in the tools section and comment out the last $excess ones
  python3 - "$file" "$max" <<'PYEOF'
import sys, re

filepath = sys.argv[1]
max_tools = int(sys.argv[2])

with open(filepath) as f:
    content = f.read()

lines = content.split('\n')

# Find the tools: section boundaries
tools_start = None
tools_end = len(lines)
for i, line in enumerate(lines):
    if re.match(r'^tools:', line):
        tools_start = i
    elif tools_start is not None and re.match(r'^[a-z]', line) and not re.match(r'^tools:', line):
        tools_end = i
        break

if tools_start is None:
    print('\n'.join(lines))
    sys.exit(0)

# Find enabled: true entries within the tools section
enabled_indices = []
for i in range(tools_start, tools_end):
    if re.match(r'\s+enabled: true', lines[i]):
        enabled_indices.append(i)

# Comment out the ones beyond max
to_comment = enabled_indices[max_tools:]
for idx in to_comment:
    lines[idx] = lines[idx].replace('enabled: true', 'enabled: false  # auto-disabled by mcp-audit.sh')

with open(filepath, 'w') as f:
    f.write('\n'.join(lines))

print(f"  Commented out {len(to_comment)} tools in {filepath}", file=sys.stderr)
PYEOF
}

# ─── Collect agent files ─────────────────────────────────────────────────────

# Build AGENT_FILES array (bash 3.2-compatible; no mapfile)
AGENT_FILES=()
while IFS= read -r -d '' f; do
  AGENT_FILES+=("$f")
done < <(find "$REPO_ROOT/agents" -name "agent.yaml" -print0 | sort -z)

if [[ ${#AGENT_FILES[@]} -eq 0 ]]; then
  echo "No agent.yaml files found under $REPO_ROOT/agents" >&2
  exit 1
fi

# ─── Audit ───────────────────────────────────────────────────────────────────

declare -a REPORT_ROWS=()

if [[ "$REPORT_MODE" == false ]]; then
  printf "\n%-40s %7s %5s  %s\n" "Agent" "Enabled" "Max" "Status"
  printf "%s\n" "$(printf '─%.0s' {1..65})"
fi

for file in "${AGENT_FILES[@]}"; do
  name=$(get_agent_name "$file")
  enabled=$(count_enabled_tools "$file")
  max=$(get_max_enabled "$file")
  rel_path="${file#$REPO_ROOT/}"

  if (( enabled > max )); then
    status="❌ VIOLATION (+$(( enabled - max )) over)"
    VIOLATIONS=$(( VIOLATIONS + 1 ))
    if [[ "$FIX_MODE" == true ]]; then
      fix_agent_file "$file" "$enabled" "$max"
      status="🔧 FIXED (was +$(( enabled - max )) over)"
    fi
  elif (( enabled == max )); then
    status="⚠️  AT LIMIT"
  else
    status="✅ OK"
  fi

  if [[ "$REPORT_MODE" == false ]]; then
    printf "%-40s %7d %5d  %s\n" "$rel_path" "$enabled" "$max" "$status"
  fi

  # Build JSON row
  REPORT_ROWS+=("{\"file\":\"$rel_path\",\"agent\":\"$name\",\"enabled\":$enabled,\"max\":$max,\"violation\":$(( enabled > max ? 1 : 0 )),\"status\":\"$status\"}")
done

# ─── Output ──────────────────────────────────────────────────────────────────

if [[ "$REPORT_MODE" == false ]]; then
  printf "%s\n" "$(printf '─%.0s' {1..65})"
  if (( VIOLATIONS > 0 )); then
    printf "\n❌ %d violation(s) found. Run with --fix to auto-remediate.\n\n" "$VIOLATIONS"
  else
    printf "\n✅ All agents within tool limits.\n\n"
  fi
else
  # JSON report
  IFS=","
  cat <<JSON
{
  "audit_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "max_tools_limit": $MAX_TOOLS,
  "total_agents": ${#AGENT_FILES[@]},
  "violations": $VIOLATIONS,
  "agents": [${REPORT_ROWS[*]}]
}
JSON
  unset IFS
fi

# Exit 1 if violations (and not in fix mode — fix mode resolves them)
if [[ "$FIX_MODE" == false && $VIOLATIONS -gt 0 ]]; then
  exit 1
fi

exit 0
