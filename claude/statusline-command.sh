#!/usr/bin/env bash
# Claude Code status line — mirrors powerlevel10k_lean.omp.json prompt segments

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Colors matching the omp theme
COLOR_PATH='\033[38;2;119;228;247m'   # #77E4F7
COLOR_GIT='\033[38;2;255;231;0m'      # #FFE700
COLOR_TIME='\033[38;2;0;197;199m'     # #00C5C7
COLOR_MODEL='\033[38;2;180;140;255m'  # purple
COLOR_BAR_FILL='\033[38;2;80;220;120m'   # green
COLOR_BAR_EMPTY='\033[38;2;80;80;80m'   # dark gray
COLOR_COST='\033[38;2;255;180;60m'    # orange
COLOR_LIMIT_OK='\033[38;2;80;220;120m'  # green
COLOR_LIMIT_WARN='\033[38;2;255;200;0m' # yellow
COLOR_LIMIT_CRIT='\033[38;2;255;80;80m' # red
COLOR_RESET='\033[0m'

# Path segment (clickable link to git remote if available)
path_segment="$cwd"

# Git segment — current branch or detached HEAD, plus staged/modified counts
git_branch=""
git_segment=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  remote_url=$(git -C "$cwd" remote get-url origin 2>/dev/null \
    | sed 's|git@\([^:]*\):\(.*\)\.git|https://\1/\2|' \
    | sed 's|\.git$||')
  if [ -n "$remote_url" ]; then
    path_segment="\033]8;;${remote_url}\a${cwd}\033]8;;\a"
  fi
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    staged=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    git_status=""
    [ "$staged" -gt 0 ]   && git_status="${git_status}$(printf '%b' "$COLOR_BAR_FILL")+${staged}$(printf '%b' "$COLOR_RESET")"
    [ "$staged" -gt 0 ] && [ "$modified" -gt 0 ] && git_status="${git_status} "
    [ "$modified" -gt 0 ] && git_status="${git_status}$(printf '%b' "$COLOR_COST")~${modified}$(printf '%b' "$COLOR_RESET")"
    [ "$untracked" -gt 0 ] && [ \( "$staged" -gt 0 \) -o \( "$modified" -gt 0 \) ] && git_status="${git_status} "
    [ "$untracked" -gt 0 ] && git_status="${git_status}$(printf '%b' "$COLOR_LIMIT_WARN")?${untracked}$(printf '%b' "$COLOR_RESET")"
    [ -n "$git_status" ] && git_status=" [${git_status}]"
    git_branch=" $branch"

    # PR hyperlinks — find open PRs for this branch
    pr_segment=""
    if command -v gh > /dev/null 2>&1; then
      pr_json=$(gh pr list --head "$branch" --json number,url 2>/dev/null)
      if [ -n "$pr_json" ] && [ "$(echo "$pr_json" | jq 'length')" -gt 0 ]; then
        pr_links=""
        while IFS= read -r line; do
          pr_num=$(echo "$line" | jq -r '.number')
          pr_url=$(echo "$line" | jq -r '.url')
          link="\033]8;;${pr_url}\a#${pr_num}\033]8;;\a"
          pr_links="${pr_links:+${pr_links}, }${link}"
        done < <(echo "$pr_json" | jq -c '.[]')
        pr_segment=" [${pr_links}]"
      fi
    fi

    git_segment="${pr_segment}${git_status}"
  fi
fi

# Model segment
model_segment=$(echo "$input" | jq -r '.model.display_name // empty')

# Context progress bar
BAR_WIDTH=10
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_used=$(echo "$input" | jq -r '
  .context_window.current_usage |
  if . != null then
    (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)
  else empty end
')
colored_bar=""
pct_int=""
ctx_detail=""
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  filled=$(echo "$used_pct $BAR_WIDTH" | awk '{printf "%d", int($1 * $2 / 100 + 0.5)}')
  empty=$((BAR_WIDTH - filled))
  pct_int=$(printf "%.0f" "$used_pct")
  if   [ "$pct_int" -ge 70 ]; then bar_fill="$COLOR_LIMIT_CRIT"
  elif [ "$pct_int" -ge 50 ]; then bar_fill="$COLOR_LIMIT_WARN"
  else                              bar_fill="$COLOR_BAR_FILL"
  fi
  fill_str=""; for i in $(seq 1 "$filled"); do fill_str="${fill_str}█"; done
  empty_str=""; for i in $(seq 1 "$empty");  do empty_str="${empty_str}░"; done
  colored_bar="${bar_fill}${fill_str}${COLOR_RESET}${COLOR_BAR_EMPTY}${empty_str}${COLOR_RESET}"
  if [ -n "$ctx_used" ] && [ -n "$ctx_size" ]; then
    ctx_detail=$(echo "$ctx_used $ctx_size" | awk '{
      used=$1; total=$2
      split("K M", units)
      if (used >= 1000000)      u_str = sprintf("%.1fM", used/1000000)
      else if (used >= 1000)    u_str = sprintf("%.0fK", used/1000)
      else                      u_str = used
      if (total >= 1000000)     t_str = sprintf("%.1fM", total/1000000)
      else if (total >= 1000)   t_str = sprintf("%.0fK", total/1000)
      else                      t_str = total
      printf "(%s/%s)", u_str, t_str
    }')
  fi
fi

# Cost segment — use the pre-calculated cost.total_cost_usd field
cost_segment=""
cost_str=$(echo "$input" | jq -r '
  .cost.total_cost_usd |
  if . != null then
    if . < 0.01 then "<$0.01"
    elif . < 1   then ("$" + (. * 100 | round | . / 100 | tostring))
    else              ("$" + (. * 10  | round | . / 10  | tostring))
    end
  else empty end
' 2>/dev/null)
if [ -n "$cost_str" ]; then
  cost_segment="$cost_str"
fi

# Rate limit indicators — rate_limits.five_hour / rate_limits.seven_day
# Present only for Claude.ai subscribers after the first API response.
limit_5h_pct=$(echo "$input"  | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
limit_7d_pct=$(echo "$input"  | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
limit_5h_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
limit_7d_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)

_limit_color() {
  local pct="$1"
  if [ -z "$pct" ] || [ "$pct" = "null" ]; then echo ""; return; fi
  local int
  int=$(printf "%.0f" "$pct" 2>/dev/null)
  if   [ "$int" -ge 90 ]; then printf '%b' "$COLOR_LIMIT_CRIT"
  elif [ "$int" -ge 70 ]; then printf '%b' "$COLOR_LIMIT_WARN"
  else                         printf '%b' "$COLOR_LIMIT_OK"
  fi
}

_time_until() {
  local resets_at="$1"
  local now remaining
  now=$(date +%s)
  remaining=$((resets_at - now))
  if [ "$remaining" -le 0 ]; then
    echo "0m"
  else
    local h m
    h=$((remaining / 3600))
    m=$(((remaining % 3600) / 60))
    if [ "$h" -gt 0 ]; then
      echo "${h}h${m}m"
    else
      echo "${m}m"
    fi
  fi
}

reset_col=$(printf '%b' "$COLOR_RESET")
if [ -n "$limit_5h_pct" ] && [ "$limit_5h_pct" != "null" ]; then
  col=$(_limit_color "$limit_5h_pct")
  pct_5h=$(printf "%.0f" "$limit_5h_pct")
  countdown_5h=""
  if [ -n "$limit_5h_resets" ] && [ "$limit_5h_resets" != "null" ]; then
    countdown_5h=" ($(_time_until "$limit_5h_resets"))"
  fi
  part_5h="5h: ${col}${pct_5h}%${reset_col}${countdown_5h}"
else
  part_5h="5h: --"
fi
if [ -n "$limit_7d_pct" ] && [ "$limit_7d_pct" != "null" ]; then
  col=$(_limit_color "$limit_7d_pct")
  pct_7d=$(printf "%.0f" "$limit_7d_pct")
  countdown_7d=""
  if [ -n "$limit_7d_resets" ] && [ "$limit_7d_resets" != "null" ]; then
    countdown_7d=" ($(_time_until "$limit_7d_resets"))"
  fi
  part_7d="7d: ${col}${pct_7d}%${reset_col}${countdown_7d}"
else
  part_7d="7d: --"
fi
limit_row="${part_5h} | ${part_7d}"

# Build output
# Line 1: path + git branch + git status
printf '%b' "${COLOR_PATH}${path_segment}${COLOR_RESET}${COLOR_GIT}${git_branch}${COLOR_RESET}${git_segment}"

# Line 2: model + context bar + cost
printf "\n"
printf "${COLOR_MODEL}%s${COLOR_RESET} |" "${model_segment:---}"
if [ -n "$colored_bar" ]; then
  printf "  ${colored_bar} %s%%" "$pct_int"
  [ -n "$ctx_detail" ] && printf " %s" "$ctx_detail"
else
  printf " ---------- (--/--)"
fi
printf " | ${COLOR_COST}%s${COLOR_RESET}" "${cost_segment:---}"

# Line 3: rate limits
printf "\n%s" "$limit_row"
