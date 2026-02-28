#!/usr/bin/env bash
# hooks/post-merge/sync-board.sh
# Calls the board sync script to update XomBoard after a merge
set -euo pipefail

echo "📋 [sync-board] Syncing XomBoard after merge..."

BOARD_SYNC_SCRIPT="/Users/dom/.openclaw/workspace/scripts/sync-board.sh"

if [[ -f "$BOARD_SYNC_SCRIPT" ]]; then
  echo "  Running: $BOARD_SYNC_SCRIPT"
  if bash "$BOARD_SYNC_SCRIPT"; then
    echo "  ✅ XomBoard synced successfully."
  else
    echo "  ⚠️  Board sync returned non-zero. Check sync-board.sh logs."
    exit 1
  fi
else
  echo "  ⚠️  Board sync script not found at: $BOARD_SYNC_SCRIPT"
  echo "  ℹ️  Skipping board sync (non-fatal in CI environments)."
  # Non-fatal — board sync script is local-only
  exit 0
fi
