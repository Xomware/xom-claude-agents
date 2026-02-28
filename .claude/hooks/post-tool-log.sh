#!/usr/bin/env bash
# .claude/hooks/post-tool-log.sh
# Logs tool call completions for audit trail.
# Receives tool info via environment variables set by Claude Code.
#
# Claude Code sets:
#   CLAUDE_TOOL_NAME      — name of the tool called
#   CLAUDE_TOOL_INPUT     — JSON of the tool input
#   CLAUDE_TOOL_OUTPUT    — JSON of the tool output
#   CLAUDE_TOOL_EXIT_CODE — exit code of the tool (0 = success)
set -euo pipefail

TOOL="${CLAUDE_TOOL_NAME:-unknown}"
INPUT="${CLAUDE_TOOL_INPUT:-}"
OUTPUT="${CLAUDE_TOOL_OUTPUT:-}"
EXIT_CODE="${CLAUDE_TOOL_EXIT_CODE:-0}"
TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S%z")

LOG_DIR=".claude/logs"
AUDIT_LOG="$LOG_DIR/audit.log"
ERROR_LOG="$LOG_DIR/errors.log"

mkdir -p "$LOG_DIR"

# Summarize the input (truncate for readability)
INPUT_SUMMARY=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Extract most relevant field
    for key in ['command', 'file_path', 'path', 'query']:
        if key in d:
            val = str(d[key])
            print(f'{key}={val[:120]}')
            break
    else:
        s = json.dumps(d)
        print(s[:120])
except Exception:
    s = sys.stdin.read()
    print(s[:120])
" 2>/dev/null <<< "$INPUT" || echo "${INPUT:0:80}")

# Determine status
if [[ "$EXIT_CODE" == "0" ]]; then
  STATUS="OK"
else
  STATUS="FAIL"
fi

# Write to audit log
echo "$TIMESTAMP [$STATUS] tool=$TOOL exit=$EXIT_CODE input=$INPUT_SUMMARY" >> "$AUDIT_LOG"

# Write to error log if failed
if [[ "$STATUS" == "FAIL" ]]; then
  echo "$TIMESTAMP [FAIL] tool=$TOOL exit=$EXIT_CODE input=$INPUT_SUMMARY" >> "$ERROR_LOG"
  OUTPUT_SNIPPET="${OUTPUT:0:300}"
  echo "  output=$OUTPUT_SNIPPET" >> "$ERROR_LOG"
fi

# Rotate logs if they get too large (> 1MB)
if [[ -f "$AUDIT_LOG" ]]; then
  SIZE=$(stat -f%z "$AUDIT_LOG" 2>/dev/null || stat -c%s "$AUDIT_LOG" 2>/dev/null || echo 0)
  if [[ "$SIZE" -gt 1048576 ]]; then
    mv "$AUDIT_LOG" "${AUDIT_LOG}.$(date +%Y%m%d%H%M%S).bak"
    echo "$TIMESTAMP [LOG_ROTATED] Previous log archived" >> "$AUDIT_LOG"
  fi
fi

exit 0
