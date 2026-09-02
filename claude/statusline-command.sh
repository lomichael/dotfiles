#!/usr/bin/env bash
# Claude Code status line
# Shows: cwd | git branch | model (+ effort/thinking) | context+tokens | cost (+lines) | 5h rate limit

input=$(cat)

# --- Colors (dimmed, terminal-friendly) ---
DIM='\033[2m'
RESET='\033[0m'
CYAN='\033[2;36m'
GREEN='\033[2;32m'
YELLOW='\033[2;33m'
MAGENTA='\033[2;35m'
BLUE='\033[2;34m'
RED='\033[2;31m'

sep=" ${DIM}|${RESET} "

# --- Number formatting: 16700 -> "16.7k", 200000 -> "200k" ---
human_num() {
    awk -v n="$1" 'function fmt(v, s) { return (v == int(v)) ? sprintf("%d%s", v, s) : sprintf("%.1f%s", v, s) }
    BEGIN {
        if (n >= 1000000) printf "%s", fmt(n / 1000000, "m");
        else if (n >= 1000) printf "%s", fmt(n / 1000, "k");
        else printf "%d", n;
    }'
}

# --- Current directory (abbreviate $HOME as ~) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
dir_display="${cwd/#$HOME/~}"

# --- Git branch (skip optional locks so we never write/lock the repo) ---
git_branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    fi
    [ -n "$branch" ] && git_branch="$branch"
fi

# --- Model name + reasoning effort + thinking status ---
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')
thinking_on=$(echo "$input" | jq -r '.thinking.enabled // false')

model_tag=""
if [ -n "$effort_level" ]; then
    model_tag="$effort_level"
elif [ "$thinking_on" = "true" ]; then
    model_tag="thinking"
fi
[ -n "$model_tag" ] && [ "$thinking_on" = "true" ] && [ -n "$effort_level" ] && model_tag="$model_tag, thinking"

model_display="$model_name"
[ -n "$model_tag" ] && model_display="$model_display ($model_tag)"

# --- Context window: percentage + raw token usage ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
used_tok=$((in_tok + out_tok))

if [ -n "$used_pct" ]; then
    if [ -n "$ctx_size" ] && [ "$ctx_size" != "0" ]; then
        context_display="ctx ${used_pct}% ($(human_num "$used_tok")/$(human_num "$ctx_size"))"
    else
        context_display=$(printf "ctx %s%%" "$used_pct")
    fi
else
    context_display="ctx --"
fi

# --- Session cost + lines changed ---
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
[ -n "$cost" ] && cost_display=$(printf '$%.2f' "$cost")

lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
lines_display=""
if [ "$lines_added" != "0" ] || [ "$lines_removed" != "0" ]; then
    lines_display="$(printf "${GREEN}+%s${RESET}" "$lines_added")/$(printf "${RED}-%s${RESET}" "$lines_removed")"
fi

# --- 5-hour rate limit (Pro/Max plans only) ---
rate_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
[ -n "$rate_pct" ] && rate_display=$(printf "5h %s%%" "$rate_pct")

# --- Assemble status line ---
line=$(printf "${CYAN}%s${RESET}" "$dir_display")

[ -n "$git_branch" ] && line="${line}${sep}$(printf "${GREEN}%s${RESET}" "$git_branch")"

line="${line}${sep}$(printf "${MAGENTA}%s${RESET}" "$model_display")"
line="${line}${sep}$(printf "${YELLOW}%s${RESET}" "$context_display")"

[ -n "$cost_display" ] && line="${line}${sep}$(printf "${BLUE}%s${RESET}" "$cost_display")"
[ -n "$lines_display" ] && line="${line}${sep}${lines_display}"
[ -n "$rate_display" ] && line="${line}${sep}$(printf "${DIM}%s${RESET}" "$rate_display")"

printf "%b\n" "$line"
