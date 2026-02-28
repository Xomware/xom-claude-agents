#!/usr/bin/env bash
# .claude/hooks/pre-tool-check.sh
# Validates tool calls aren't running dangerous patterns before execution.
# Receives tool info via environment variables set by Claude Code.
#
# Claude Code sets:
#   CLAUDE_TOOL_NAME     — name of the tool being called (e.g., "Bash", "Write")
#   CLAUDE_TOOL_INPUT    — JSON of the tool input
#
# Exit 0 to allow, exit 1 to block.
set -euo pipefail

TOOL="${CLAUDE_TOOL_NAME:-unknown}"
INPUT="${CLAUDE_TOOL_INPUT:-}"
TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S%z")
LOG_DIR=".claude/logs"
mkdir -p "$LOG_DIR"

# ── Dangerous Bash patterns ──────────────────────────────────────────────────
BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "mkfs\."
  "dd if=/dev/zero"
  ":(){ :|:& };:"          # fork bomb
  "curl.*\| *bash"
  "wget.*\| *bash"
  "curl.*\| *sh"
  "wget.*\| *sh"
  "> /etc/passwd"
  "> /etc/shadow"
  "chmod 777 /"
  "chown.*:.*/"
)

if [[ "$TOOL" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "$INPUT")

  for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qP "$pattern" 2>/dev/null; then
      echo "🚫 [pre-tool-check] BLOCKED: Dangerous pattern detected in Bash command"
      echo "   Pattern: $pattern"
      echo "   Command: $COMMAND"
      # Log the block
      echo "$TIMESTAMP BLOCKED tool=$TOOL pattern='$pattern' cmd='$COMMAND'" >> "$LOG_DIR/blocked.log"
      exit 1
    fi
  done
fi

# ── Protect critical files from Write/Edit ───────────────────────────────────
PROTECTED_FILES=(
  ".git/config"
  ".claude/settings.json"
)

if [[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]]; then
  FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('file_path', d.get('path','')))" 2>/dev/null || echo "")

  for protected in "${PROTECTED_FILES[@]}"; do
    if [[ "$FILE_PATH" == *"$protected"* ]]; then
      echo "⚠️  [pre-tool-check] WARNING: Writing to protected file: $FILE_PATH"
      echo "$TIMESTAMP WARNING tool=$TOOL protected_file='$FILE_PATH'" >> "$LOG_DIR/warnings.log"
      # Warn but allow (exit 0) — just log it
    fi
  done
fi

# Allow the tool call
exit 0
