#!/usr/bin/env bash
# hooks/post-merge/notify.sh
# Sends merge notification (placeholder for Slack/iMessage integration)
set -euo pipefail

echo "🔔 [notify] Sending merge notification..."

# Gather merge context
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
AUTHOR=$(git log -1 --format="%an" 2>/dev/null || echo "unknown")
MESSAGE=$(git log -1 --format="%s" 2>/dev/null || echo "unknown")
REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/\.git$//' || echo "unknown")
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")

NOTIFICATION="✅ Merge complete
  Repo:    $REPO
  Branch:  $BRANCH
  Commit:  $COMMIT
  Author:  $AUTHOR
  Message: $MESSAGE
  Time:    $TIMESTAMP"

echo ""
echo "$NOTIFICATION"
echo ""

# --- Slack integration (placeholder) ---
# Uncomment and set SLACK_WEBHOOK_URL to enable
# SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
# if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
#   curl -s -X POST "$SLACK_WEBHOOK_URL" \
#     -H "Content-Type: application/json" \
#     -d "{\"text\": \"$NOTIFICATION\"}"
#   echo "  ✅ Slack notification sent."
# fi

# --- iMessage integration (placeholder) ---
# Uncomment and configure for Boris/OpenClaw iMessage dispatch
# IMESSAGE_TARGET="${IMESSAGE_TARGET:-}"
# if [[ -n "$IMESSAGE_TARGET" ]]; then
#   osascript -e "tell application \"Messages\" to send \"$NOTIFICATION\" to buddy \"$IMESSAGE_TARGET\""
#   echo "  ✅ iMessage notification sent."
# fi

# --- OpenClaw Boris dispatch (placeholder) ---
# If running in OpenClaw environment, Boris can be pinged via:
# openclaw message --to boris --text "$NOTIFICATION"

echo "  ℹ️  Notification channels not configured. Set SLACK_WEBHOOK_URL or IMESSAGE_TARGET to enable."
echo "  ✅ Notification hook completed."
exit 0
