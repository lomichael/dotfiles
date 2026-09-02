#!/usr/bin/env bash
# Claude Code status line
# Shows: cwd | git branch | model (+ thinking) | context usage | session cost

input=$(cat)

# --- Colors (dimmed, terminal-friendly) ---
DIM='\033[2m'
RESET='\033[0m'
CYAN='\033[2;36m'
GREEN='\033[2;32m'
YELLOW='\033[2;33m'
MAGENTA='\033[2;35m'
BLUE='\033[2;34m'

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

# --- Model name + thinking status ---
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
thinking_on=$(echo "$input" | jq -r '.thinking.enabled // false')
model_display="$model_name"
if [ "$thinking_on" = "true" ]; then
    model_display="$model_display (thinking)"
fi

# --- Context usage ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
    context_display=$(printf "ctx %.0f%%" "$used_pct")
else
    context_display="ctx --"
fi

# --- Session cost ---
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ]; then
    cost_display=$(printf '$%.2f' "$cost")
else
    cost_display=""
fi

# --- Assemble status line ---
line=$(printf "${CYAN}%s${RESET}" "$dir_display")

if [ -n "$git_branch" ]; then
    line="${line} ${DIM}|${RESET} $(printf "${GREEN}%s${RESET}" "$git_branch")"
fi

line="${line} ${DIM}|${RESET} $(printf "${MAGENTA}%s${RESET}" "$model_display")"
line="${line} ${DIM}|${RESET} $(printf "${YELLOW}%s${RESET}" "$context_display")"

if [ -n "$cost_display" ]; then
    line="${line} ${DIM}|${RESET} $(printf "${BLUE}%s${RESET}" "$cost_display")"
fi

printf "%b\n" "$line"
