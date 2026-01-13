#!/bin/bash
# Minimal Claude Code Statusline
# A clean, vibrant single-line statusline showing all essential info

input=$(cat)

# ═══════════════════════════════════════════════════════════════════════════════
# JQ Detection
# ═══════════════════════════════════════════════════════════════════════════════
HAS_JQ=0
command -v jq >/dev/null 2>&1 && HAS_JQ=1

# ═══════════════════════════════════════════════════════════════════════════════
# Color Configuration - Vibrant Theme
# ═══════════════════════════════════════════════════════════════════════════════
use_color=1
[ -n "$NO_COLOR" ] && use_color=0

c() { [ "$use_color" -eq 1 ] && printf '\033[38;5;%sm' "$1"; }
bold() { [ "$use_color" -eq 1 ] && printf '\033[1m'; }
dim() { [ "$use_color" -eq 1 ] && printf '\033[2m'; }
rst() { [ "$use_color" -eq 1 ] && printf '\033[0m'; }

# Vibrant color palette
COL_MODEL="141"      # Bright purple
COL_DIR="75"         # Sky blue
COL_GIT="114"        # Bright green
COL_CONTEXT_HI="46"  # Bright green (>40%)
COL_CONTEXT_MID="220" # Yellow (21-40%)
COL_CONTEXT_LO="196" # Red (<=20%)
COL_COST="214"       # Orange gold
COL_TOKENS="147"     # Light purple
COL_SEP="240"        # Dim gray for separators
COL_RATE="220"       # Yellow for burn rate

# ═══════════════════════════════════════════════════════════════════════════════
# JSON Extraction Functions
# ═══════════════════════════════════════════════════════════════════════════════
get_val() {
  local key="$1" default="$2"
  if [ "$HAS_JQ" -eq 1 ]; then
    val=$(echo "$input" | jq -r "$key // empty" 2>/dev/null)
    [ -n "$val" ] && [ "$val" != "null" ] && echo "$val" || echo "$default"
  else
    echo "$default"
  fi
}

get_num() {
  local key="$1" default="${2:-0}"
  if [ "$HAS_JQ" -eq 1 ]; then
    val=$(echo "$input" | jq -r "$key // $default" 2>/dev/null)
    [[ "$val" =~ ^[0-9.]+$ ]] && echo "$val" || echo "$default"
  else
    echo "$default"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Extract Data
# ═══════════════════════════════════════════════════════════════════════════════

# Model info
model_name=$(get_val '.model.display_name' 'Claude')
model_name=${model_name/Claude /}  # Remove "Claude " prefix for brevity

# Directory (abbreviated)
current_dir=$(get_val '.workspace.current_dir' '')
[ -z "$current_dir" ] && current_dir=$(get_val '.cwd' '~')
current_dir="${current_dir/#$HOME/\~}"
# Shorten path: show only last 2 components if longer
if [[ "$current_dir" == *"/"*"/"* ]]; then
  current_dir="…/${current_dir##*/}"
fi

# Git branch
git_branch=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
fi

# Context window calculation
context_pct=""
context_col="$COL_CONTEXT_HI"
if [ "$HAS_JQ" -eq 1 ]; then
  ctx_size=$(get_num '.context_window.context_window_size' '200000')
  input_tok=$(get_num '.context_window.current_usage.input_tokens' '0')
  cache_create=$(get_num '.context_window.current_usage.cache_creation_input_tokens' '0')
  cache_read=$(get_num '.context_window.current_usage.cache_read_input_tokens' '0')

  current_tokens=$((input_tok + cache_create + cache_read))
  if [ "$current_tokens" -gt 0 ] && [ "$ctx_size" -gt 0 ]; then
    used_pct=$((current_tokens * 100 / ctx_size))
    remaining=$((100 - used_pct))
    [ "$remaining" -lt 0 ] && remaining=0
    [ "$remaining" -gt 100 ] && remaining=100
    context_pct="${remaining}%"

    if [ "$remaining" -le 20 ]; then
      context_col="$COL_CONTEXT_LO"
    elif [ "$remaining" -le 40 ]; then
      context_col="$COL_CONTEXT_MID"
    fi
  fi
fi

# Cost info
cost_usd=$(get_num '.cost.total_cost_usd' '')
duration_ms=$(get_num '.cost.total_duration_ms' '0')
cost_per_hour=""
if [ -n "$cost_usd" ] && [ "$duration_ms" -gt 0 ]; then
  cost_per_hour=$(awk "BEGIN {printf \"%.2f\", $cost_usd * 3600000 / $duration_ms}")
fi

# Token counts
in_tok=$(get_num '.context_window.total_input_tokens' '0')
out_tok=$(get_num '.context_window.total_output_tokens' '0')
total_tokens=$((in_tok + out_tok))

# Format token count (K for thousands)
format_tokens() {
  local t="$1"
  if [ "$t" -ge 1000000 ]; then
    awk "BEGIN {printf \"%.1fM\", $t/1000000}"
  elif [ "$t" -ge 1000 ]; then
    awk "BEGIN {printf \"%.1fK\", $t/1000}"
  else
    echo "$t"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Progress Bar
# ═══════════════════════════════════════════════════════════════════════════════
progress_bar() {
  local pct="${1:-0}" width="${2:-8}"
  local filled=$((pct * width / 100))
  local empty=$((width - filled))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="▰"; done
  for ((i=0; i<empty; i++)); do bar+="▱"; done
  echo "$bar"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Render Statusline
# ═══════════════════════════════════════════════════════════════════════════════
sep() { printf '%s │%s ' "$(c $COL_SEP)" "$(rst)"; }

# Model
printf '%s%s%s%s' "$(bold)" "$(c $COL_MODEL)" "$model_name" "$(rst)"

# Directory
printf '%s%s%s%s' "$(sep)" "$(c $COL_DIR)" "$current_dir" "$(rst)"

# Git branch
if [ -n "$git_branch" ]; then
  printf '%s%s%s%s' "$(sep)" "$(c $COL_GIT)" "$git_branch" "$(rst)"
fi

# Context remaining with mini progress bar
if [ -n "$context_pct" ]; then
  remaining_num="${context_pct//%/}"
  bar=$(progress_bar "$remaining_num" 6)
  printf '%s%s%s %s%s' "$(sep)" "$(c $context_col)" "$context_pct" "$bar" "$(rst)"
fi

# Cost with burn rate
if [ -n "$cost_usd" ]; then
  cost_fmt=$(printf '$%.2f' "$cost_usd")
  printf '%s%s%s%s' "$(sep)" "$(c $COL_COST)" "$cost_fmt" "$(rst)"
  if [ -n "$cost_per_hour" ] && [ "$cost_per_hour" != "0.00" ]; then
    printf ' %s(%s$%s/h%s)%s' "$(dim)" "$(c $COL_RATE)" "$cost_per_hour" "$(rst)" "$(rst)"
  fi
fi

# Token count
if [ "$total_tokens" -gt 0 ]; then
  tok_fmt=$(format_tokens "$total_tokens")
  printf '%s%s%s tok%s' "$(sep)" "$(c $COL_TOKENS)" "$tok_fmt" "$(rst)"
fi

printf '\n'
