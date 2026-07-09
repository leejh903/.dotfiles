#!/usr/bin/env bash
# Claude Code status line — mirrors Powerlevel10k lean style
# Left: user  cwd  git branch
# Right: model  ctx:used/total (remaining% left)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
total_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')

# Subscription rate limit fields (Claude.ai plan — only present after first API response)
rl_5h_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ANSI color codes — 3 colors total
RESET='\033[0m'
BOLD='\033[1m'
COLOR_DIM='\033[38;5;240m'    # dim gray — labels, separators, neutral text
COLOR_OK='\033[38;5;71m'      # green — normal/good state
COLOR_WARN='\033[38;5;203m'   # coral red — warning (>75% usage)

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Username only (no hostname)
user="$(whoami)"

# Build left section
left=$(printf "${BOLD}%s${RESET}  ${COLOR_OK}%s${RESET}" "$user" "$short_cwd")

# Append git branch/worktree if available
if [ -n "$git_worktree" ]; then
  left=$(printf "%s  ${COLOR_DIM}%s${RESET}" "$left" "$git_worktree")
else
  if [ -n "$cwd" ] && branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
    left=$(printf "%s  ${COLOR_DIM}%s${RESET}" "$left" "$branch")
  fi
fi

# Build right section (main line: model + context tokens)
right=""
if [ -n "$model" ]; then
  right=$(printf "${COLOR_DIM}%s${RESET}" "$model")
fi
if [ -n "$used_pct" ]; then
  formatted_pct=$(printf "%.0f" "$used_pct")
  # Use coral red when context is getting full (>75%), green otherwise
  if [ "$formatted_pct" -gt 75 ] 2>/dev/null; then
    ctx_color="$COLOR_WARN"
  else
    ctx_color="$COLOR_OK"
  fi
  # Build token detail string: used_tokens / total_tokens (remaining%)
  if [ -n "$used_tokens" ] && [ -n "$total_tokens" ] && [ "$total_tokens" -gt 0 ] 2>/dev/null; then
    used_k=$(awk "BEGIN {printf \"%.0f\", $used_tokens/1000}")
    total_k=$(awk "BEGIN {printf \"%.0f\", $total_tokens/1000}")
    if [ -n "$remaining_pct" ]; then
      remaining_fmt=$(printf "%.0f" "$remaining_pct")
      ctx_str=$(printf "${ctx_color}ctx:${used_k}k/${total_k}k (${remaining_fmt}%% left)${RESET}")
    else
      ctx_str=$(printf "${ctx_color}ctx:${used_k}k/${total_k}k (${formatted_pct}%% used)${RESET}")
    fi
  else
    ctx_str=$(printf "${ctx_color}ctx:${formatted_pct}%% used${RESET}")
  fi
  if [ -n "$right" ]; then
    right=$(printf "%s  %s" "$right" "$ctx_str")
  else
    right="$ctx_str"
  fi
fi

# Build subscription rate limit section (second line)
# Claude.ai plan: shows 5-hour and/or 7-day used % when data is present.
# Minutes-until-reset is shown when usage is above 50% (actionable info).
_rl_segment() {
  local label="$1" used_pct="$2" resets_at="$3"
  if [ -z "$used_pct" ]; then return; fi
  local used_fmt
  used_fmt=$(printf "%.0f" "$used_pct")
  local remaining_fmt=$(( 100 - used_fmt ))
  local color
  if [ "$used_fmt" -gt 75 ] 2>/dev/null; then
    color="$COLOR_WARN"
  else
    color="$COLOR_OK"
  fi
  local reset_str=""
  if [ -n "$resets_at" ] && [ "$used_fmt" -gt 50 ] 2>/dev/null; then
    local now
    now=$(date +%s)
    local mins_left=$(( (resets_at - now) / 60 ))
    if [ "$mins_left" -gt 0 ]; then
      reset_str=$(printf " (~%dm)" "$mins_left")
    fi
  fi
  printf "${color}${label}:${remaining_fmt}%% left${reset_str}${RESET}"
}

rl_5h_seg=$(_rl_segment "5h" "$rl_5h_used" "$rl_5h_resets")
rl_7d_seg=$(_rl_segment "7d" "$rl_7d_used" "$rl_7d_resets")

rl_str=""
if [ -n "$rl_5h_seg" ] && [ -n "$rl_7d_seg" ]; then
  rl_str=$(printf "%b  %b" "$rl_5h_seg" "$rl_7d_seg")
elif [ -n "$rl_5h_seg" ]; then
  rl_str="$rl_5h_seg"
elif [ -n "$rl_7d_seg" ]; then
  rl_str="$rl_7d_seg"
fi

# Output: main line, then rate limit line (if any) on a second line
if [ -n "$right" ]; then
  printf "%b ${COLOR_DIM}|${RESET} %b" "$left" "$right"
else
  printf "%b" "$left"
fi
if [ -n "$rl_str" ]; then
  printf "\n%b" "$rl_str"
fi
