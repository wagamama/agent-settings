#!/bin/bash

# Claude Code Status Line Script
# Displays project info and token usage from ccusage

# Read JSON input from stdin
input=$(cat)

# Extract basic information
folder=$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")
model=$(echo "$input" | jq -r '.model.display_name')

# Detect project type and language info
lang_info=""

# Check for Python project (venv exists or Python files present)
if [ -n "$VIRTUAL_ENV" ]; then
    # Python project with virtual environment
    venv_raw=$(echo "${VIRTUAL_ENV##*/}" | sed 's/-[0-9].*//')
    if [ "$venv_raw" = ".venv" ] || [ "$venv_raw" = "venv" ]; then
        venv="($folder)"
    else
        venv="($venv_raw)"
    fi
    pyver=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')
    lang_info=" | 💼 $venv | 🐍 $pyver"
elif [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
    # Python project without venv
    pyver=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')
    lang_info=" | 🐍 $pyver"
elif [ -f "go.mod" ] || [ -f "go.sum" ] || ls *.go >/dev/null 2>&1; then
    # Go project
    gover=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/go//' || echo 'N/A')
    if [ "$gover" != "N/A" ]; then
        lang_info=" | 🦫 $gover"
    fi
fi

# Git branch
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')

# Base status line with existing information
base_status="📁 $folder${lang_info} | 🌿 $branch | 🤖 $model"

# Token ratio formatting helper (awk function shared by multiple fields)
fmt_ratio() {
    echo "$1 $2" | awk '{
        if ($1 >= 1000000) t = sprintf("%.1fM", $1/1000000)
        else if ($1 >= 1000) t = sprintf("%dK", $1/1000)
        else t = sprintf("%d", $1)
        if ($2 >= 1000000) l = sprintf("%.1fM", $2/1000000)
        else if ($2 >= 1000) l = sprintf("%dK", $2/1000)
        else l = sprintf("%d", $2)
        printf "%s/%s", t, l
    }'
}

# Try to get usage information
cost_info=""
if command -v bun >/dev/null 2>&1; then
    # Context window usage from transcript (same method as context-bar.sh)
    transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
    max_context=$(echo "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
    if [ -n "$transcript_path" ] && [ -f "$transcript_path" ] && [ -n "$max_context" ] && [ "$max_context" != "0" ]; then
        ctx_tokens=$(jq -s '
            map(select(.message.usage and .isSidechain != true and .isApiErrorMessage != true)) |
            last |
            if . then
                (.message.usage.input_tokens // 0) +
                (.message.usage.cache_read_input_tokens // 0) +
                (.message.usage.cache_creation_input_tokens // 0)
            else 0 end
        ' < "$transcript_path" 2>/dev/null)
        ctx_pct=$(echo "${ctx_tokens:-0} $max_context" | awk '{printf "%d", ($1/$2)*100}')
        ctx_ratio=$(fmt_ratio "${ctx_tokens:-0}" "$max_context")
    fi

    # Block quota % and time remaining from ccusage
    blocks_json=$(bun x ccusage blocks --active --json --token-limit max 2>/dev/null)
    if [ -n "$blocks_json" ]; then
        # Time remaining
        remaining_minutes=$(echo "$blocks_json" | jq -r '.blocks[0].projection.remainingMinutes // empty' 2>/dev/null)
        if [ -n "$remaining_minutes" ] && [ "$remaining_minutes" != "null" ] && [ "$remaining_minutes" != "0" ]; then
            hours=$((remaining_minutes / 60))
            mins=$((remaining_minutes % 60))
            time_left="${hours}h ${mins}m left"
        fi

        # Weekly token quota % (weekly tokens / 34 blocks × block limit)
        token_limit=$(echo "$blocks_json" | jq -r '.blocks[0].tokenLimitStatus.limit // empty' 2>/dev/null)
    fi

    # Use Max plan block limit as fallback when no active block
    token_limit=${token_limit:-1499903}
    weekly_json=$(bun x ccusage weekly --json 2>/dev/null)
    weekly_tokens=$(echo "$weekly_json" | jq -r '.weekly[-1].totalTokens // empty' 2>/dev/null)
    weekly_limit=$(echo "$token_limit" | awk '{printf "%d", $1 * 34}')
    if [ -n "$weekly_tokens" ] && [ "$weekly_tokens" != "null" ]; then
        weekly_pct=$(echo "$weekly_tokens $weekly_limit" | awk '{printf "%d", ($1/$2)*100}')
        weekly_ratio=$(fmt_ratio "$weekly_tokens" "$weekly_limit")
    fi

    # Build status info string
    cost_parts=()

    if [ -n "$ctx_pct" ]; then
        cost_parts+=("🧠 ${ctx_pct}% (${ctx_ratio})")
    fi

    if [ -n "$weekly_pct" ]; then
        cost_parts+=("📅 ${weekly_pct}% (${weekly_ratio})")
    fi

    if [ -n "$time_left" ]; then
        cost_parts+=("⏱️ $time_left")
    fi

    # Join parts with " | "
    if [ ${#cost_parts[@]} -gt 0 ]; then
        cost_info=" | "
        for i in "${!cost_parts[@]}"; do
            if [ $i -gt 0 ]; then
                cost_info="${cost_info} | "
            fi
            cost_info="${cost_info}${cost_parts[$i]}"
        done
    fi
fi

# Output the complete status line
echo "${base_status}${cost_info}"