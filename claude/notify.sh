#!/bin/bash

# Parse --mode argument (default: stop)
MODE="stop"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ "$MODE" = "permission" ]; then
  TITLE_BASE="Permissions Required"
  MESSAGE="permissions requested"
  SOUND="Bottle"
else
  TITLE_BASE="Completed"
  SOUND="Submarine"

  # Read the hook payload from stdin
  HOOK_PAYLOAD=$(cat)

  # Extract the transcript path from the hook payload
  TRANSCRIPT_PATH=$(echo "$HOOK_PAYLOAD" | jq -r '.transcript_path')

  # Read the JSONL transcript and find the last user message
  # where .message.content is a plain string (not an array or object)
  MESSAGE=$(
    jq -s '
      [
        .[]
        | select(.type == "user")
        | select(.message.content | type == "string")
      ]
      | last
      | .message.content
    ' "$TRANSCRIPT_PATH"
  )

  # Remove the surrounding quotes that jq leaves on
  MESSAGE=$(echo "$MESSAGE" | jq -r '.')

  # Truncate to 100 characters so the notification isn't too long
  MESSAGE=$(echo "$MESSAGE" | cut -c1-100)

  # Fall back to a default message if something went wrong
  if [ -z "$MESSAGE" ] || [ "$MESSAGE" = "null" ]; then
    MESSAGE="Task complete"
  fi
fi

# Build the notification title, appending tmux session/window if inside tmux
TITLE="$TITLE_BASE"
if [ -n "$TMUX" ]; then
  TMUX_SESSION=$(tmux display-message -p '#S')
  TMUX_WINDOW=$(tmux display-message -p '#W')
  TITLE="\[$TMUX_SESSION:$TMUX_WINDOW] - $TITLE_BASE"
fi

# Send the notification
terminal-notifier \
  -title "$TITLE" \
  -message "$MESSAGE" \
  -sound "$SOUND"
