#!/bin/bash

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

# Send the notification
terminal-notifier \
  -title "Claude Code Complete" \
  -message "$MESSAGE" \
  -sound "Submarine"
