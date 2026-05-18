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
  SOUND="Bottle"

  HOOK_PAYLOAD=$(cat)
  TOOL_NAME=$(echo "$HOOK_PAYLOAD" | jq -r '.tool_name // "unknown tool"')

  # Build a human-readable description from whichever tool_input fields are present
  TOOL_DESC=$(echo "$HOOK_PAYLOAD" | jq -r '
    .tool_input
    | if .command then .command
      elif .file_path then .file_path
      elif .url then .url
      else (to_entries | map("\(.key): \(.value | tostring)") | join(", "))
      end
  ')

  MESSAGE="${TOOL_NAME}: ${TOOL_DESC}"
  MESSAGE=$(echo "$MESSAGE" | cut -c1-200)
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

  # Extract the assistant response to the current (last) user prompt.
  # Anchoring to after the last user message avoids returning a stale
  # response from a previous turn when the transcript hasn't been flushed yet.
  RESPONSE=$(
    jq -rs '
      to_entries as $entries
      | ($entries
         | map(select(.value.type == "user") | select(.value.message.content | type == "string"))
         | last | .key) as $last_user_idx
      | if $last_user_idx != null then
          [$entries[$last_user_idx + 1:][]
            | select(.value.type == "assistant")
            | select(.value.message.content | type == "array")
            | .value]
          | last
          | if . != null then
              [.message.content[] | select(.type == "text") | .text] | join("")
            else ""
            end
        else ""
        end
    ' "$TRANSCRIPT_PATH"
  )

  if [ -z "$RESPONSE" ] || [ "$RESPONSE" = "null" ]; then
    RESPONSE=""
  fi

  # Truncate to 1000 characters for Discord embed field limit
  RESPONSE=$(echo "$RESPONSE" | cut -c1-1000)
fi

# Build the notification title, appending tmux session/window if inside tmux
TITLE="$TITLE_BASE"
if [ -n "$TMUX" ]; then
  TMUX_SESSION=$(tmux display-message -p '#S')
  TMUX_WINDOW=$(tmux display-message -p '#W')
  TITLE="\[$TMUX_SESSION:$TMUX_WINDOW] - $TITLE_BASE"
fi

# Send the notification
if [ -n "$CLAUDE_CODE_NOTIFY_URL" ]; then
  PAYLOAD=$(jq -n --arg title "$TITLE" --arg message "$MESSAGE" --arg response "${RESPONSE:-}" \
    '{
      "embeds": [{
        "title": $title,
        "description": $message,
        "fields": (if $response != "" then [{"name": "Response", "value": $response}] else [] end)
      }]
    }')
  curl -s -X POST "$CLAUDE_CODE_NOTIFY_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null
else
  terminal-notifier \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -sound "$SOUND"
fi
