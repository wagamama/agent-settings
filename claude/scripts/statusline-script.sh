#!/bin/bash

# Claude Code Status Line Script
# Line 1: Sonnet 4.6  project → branch ! ↑2
# Line 2: ctx ████░░░░░░ 35%  · $84.31 · 8h 31m  │  personal  5h: 77% left ↺2h 43m · 7d: 95% left ↺1d 1h

# Read JSON input from stdin, parse all fields in one jq call
eval "$(cat | jq -r '
  @sh "model_name=\(.model.display_name // "")",
  @sh "current_dir=\(.workspace.current_dir // "")",
  @sh "total_cost=\(.cost.total_cost_usd // 0)",
  @sh "ctx_pct=\(.context_window.used_percentage // 0)",
  @sh "duration_ms=\(.cost.total_duration_ms // 0)",
  @sh "five_hour_pct=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "five_hour_resets_at=\(.rate_limits.five_hour.resets_at // "")",
  @sh "seven_day_pct=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "seven_day_resets_at=\(.rate_limits.seven_day.resets_at // "")"
' | tr ',' '\n')"

# Fallbacks for empty values
total_cost=${total_cost:-0}
ctx_pct=${ctx_pct:-0}
duration_ms=${duration_ms:-0}

# Account name from claude-switch links
account_name=""
if [ -n "$current_dir" ] && [ -f "$HOME/.claude-switch/links" ]; then
    account_name=$(grep "^${current_dir}=" "$HOME/.claude-switch/links" | cut -d= -f2)
fi

# ANSI colors — tuned to match Claude Code's purple/blue palette
RESET="\033[0m"
PURPLE="\033[38;5;255m"   # model name — bright white
BLUE="\033[38;5;111m"     # project name — calm blue
DIM="\033[38;5;245m"      # secondary info (cost, duration, git branch)
OK="\033[38;5;114m"       # green — safe (<50%)
WARN="\033[38;5;221m"     # amber — caution (50-79%)
CRIT="\033[38;5;204m"     # rose-red — danger (≥80/90%)

# Shorten model name: "Claude Opus 4.6" → "Opus 4.6"
short_model="${model_name#Claude }"

# Get project name
if [ -n "$current_dir" ]; then
    project_name=$(basename "$current_dir")
else
    project_name=$(basename "$(pwd)")
fi

# Get git info: branch, dirty, ahead/behind — one subprocess via status -sb
git_branch=""
git_plain=""
if [ -n "$current_dir" ]; then
    git_status=$(timeout 1 git -C "$current_dir" status -sb 2>/dev/null)
    if [ -n "$git_status" ]; then
        first_line=$(printf '%s' "$git_status" | head -1)
        git_branch=$(printf '%s' "$first_line" | sed 's/^## //;s/\.\.\..*//;s/^No commits yet on //')
        ahead=$(printf '%s' "$first_line" | sed -n 's/.*ahead \([0-9]*\).*/\1/p')
        behind=$(printf '%s' "$first_line" | sed -n 's/.*behind \([0-9]*\).*/\1/p')
        dirty_lines=$(printf '%s' "$git_status" | tail -n +2)
        [ -n "$dirty_lines" ] && git_plain+=" !"
        [ -n "$ahead" ]       && git_plain+=" ↑${ahead}"
        [ -n "$behind" ]      && git_plain+=" ↓${behind}"
    fi
fi

# Context window progress bar (10 blocks)
ctx_int=${ctx_pct%%.*}
ctx_int=${ctx_int:-0}
if [ "$ctx_int" -ge 90 ] 2>/dev/null; then
    CTX_COLOR="$CRIT"
elif [ "$ctx_int" -ge 70 ] 2>/dev/null; then
    CTX_COLOR="$WARN"
else
    CTX_COLOR="$OK"
fi
if [ "$ctx_int" -eq 0 ] 2>/dev/null; then
    # Session start: no API call yet, all counts are zero — show placeholder
    ctx_display="${DIM}ctx ░░░░░░░░░░ --${RESET}"
else
    filled=$((ctx_int / 10))
    empty=$((10 - filled))
    bar=$(printf "%${filled}s" | tr ' ' '█')$(printf "%${empty}s" | tr ' ' '░')
    ctx_pct_fmt=$(printf "%.1f" "$ctx_pct")
    ctx_display="${CTX_COLOR}ctx ${bar} ${ctx_pct_fmt}%${RESET}"
fi

# Cost
cost_display=""
if [ "$total_cost" != "0" ] && [ "$total_cost" != "null" ]; then
    cost_int=${total_cost%%.*}
    if [ "${cost_int:-0}" -ge 10 ] 2>/dev/null; then
        cost_display=$(printf " · ${WARN}\$%.2f${RESET}" "$total_cost")
    else
        cost_display=$(printf " · ${DIM}\$%.2f${RESET}" "$total_cost")
    fi
fi

# Duration — human readable: <60m → Xm, <24h → Xh Ym, ≥24h → Xd Yh
duration_display=""
if [ "$duration_ms" != "0" ] && [ "$duration_ms" != "null" ]; then
    total_mins=$((duration_ms / 60000))
    if [ "$total_mins" -lt 60 ]; then
        dur_text="${total_mins}m"
    elif [ "$total_mins" -lt 1440 ]; then
        dur_text="$((total_mins / 60))h $((total_mins % 60))m"
    else
        days=$((total_mins / 1440))
        hours=$(( (total_mins % 1440) / 60 ))
        dur_text="${days}d ${hours}h"
    fi
    duration_display=" · ${DIM}${dur_text}${RESET}"
fi

# Human-readable time until window reset
format_reset() {
    local resets_at="$1"
    [ -z "$resets_at" ] && echo "" && return
    local now remaining mins
    now=$(date +%s)
    remaining=$(( resets_at - now ))
    [ "$remaining" -le 0 ] && echo "now" && return
    mins=$(( remaining / 60 ))
    if   [ "$mins" -lt 60 ];   then echo "${mins}m"
    elif [ "$mins" -lt 1440 ]; then echo "$((mins/60))h $((mins%60))m"
    else echo "$((mins/1440))d $(( (mins%1440)/60 ))h"
    fi
}

# One rate-limit segment: "5h: 20% left in 3h 23m"
build_rate_segment() {
    local sep="$1" label="$2" usage_pct="$3" resets_at="$4"
    [ -z "$usage_pct" ] || [ "$usage_pct" = "null" ] && return
    local usage_int remaining color reset_str
    usage_int="${usage_pct%%.*}"
    remaining=$(( 100 - ${usage_int:-0} ))
    if [ "$remaining" -le 10 ] 2>/dev/null; then color="$CRIT"
    elif [ "$remaining" -le 30 ] 2>/dev/null; then color="$WARN"
    else color="$OK"
    fi
    reset_str=$(format_reset "$resets_at")
    local reset_display=""
    [ -n "$reset_str" ] && reset_display=" ${DIM}in ${reset_str}${RESET}"
    printf '%s%s: %b%d%% left%b' "$sep" "$label" "$color" "$remaining" "$RESET$reset_display"
}

rate_display=""
rate_display+=$(build_rate_segment "  " "5h" "$five_hour_pct" "$five_hour_resets_at")
rate_display+=$(build_rate_segment " · " "7d" "$seven_day_pct" "$seven_day_resets_at")

# Line 1: model · project → branch
git_info=""
[ -n "$git_branch" ] && git_info="  ${DIM}→ ${git_branch}${git_plain}${RESET}"

printf "%b\n" "${PURPLE}${short_model}${RESET}  ${BLUE}${project_name}${RESET}${git_info}"

# Line 2: ctx · cost · duration  │  account  5h … · 7d …
account_badge=""
if [ -n "$account_name" ]; then
    PL_L=$(printf '\xee\x82\xb6')
    PL_R=$(printf '\xee\x82\xb4')
    account_badge="  \033[38;5;141m${PL_L}\033[48;5;141m\033[38;5;232m ${account_name} \033[0m\033[38;5;141m${PL_R}\033[0m"
fi
rate_section=""
[ -n "${account_badge}${rate_display}" ] && rate_section="  │ ${account_badge}${rate_display}"
printf "%b\n" "${ctx_display}${cost_display}${duration_display}${rate_section}"