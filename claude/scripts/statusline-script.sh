#!/bin/bash

# Claude Code Status Line Script
# Displays project info, context window usage, and billing block time remaining

input=$(cat)

# --- Helpers ---

jq_input() { echo "$input" | jq -r "$1" 2>/dev/null; }

fmt_num() {
    echo "$1" | awk '{
        if ($1 >= 1000000) printf "%.1fM", $1/1000000
        else if ($1 >= 1000) printf "%dK", $1/1000
        else printf "%d", $1
    }'
}

# --- Base info ---

folder=$(basename "$(jq_input '.workspace.current_dir')")
model=$(jq_input '.model.display_name')
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')

# --- Language detection ---

lang_info=""
if [ -n "$VIRTUAL_ENV" ]; then
    venv_raw=$(echo "${VIRTUAL_ENV##*/}" | sed 's/-[0-9].*//')
    venv=$( [ "$venv_raw" = ".venv" ] || [ "$venv_raw" = "venv" ] && echo "($folder)" || echo "($venv_raw)" )
    pyver=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')
    lang_info=" | 💼 $venv | 🐍 $pyver"
elif [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
    pyver=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')
    lang_info=" | 🐍 $pyver"
elif [ -f "go.mod" ] || [ -f "go.sum" ] || ls *.go >/dev/null 2>&1; then
    gover=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/go//' || echo 'N/A')
    [ "$gover" != "N/A" ] && lang_info=" | 🦫 $gover"
fi

# --- Status line assembly ---

status="📁 $folder${lang_info} | 🌿 $branch | 🤖 $model"

# Context window usage from transcript
transcript_path=$(jq_input '.transcript_path // empty')
max_context=$(jq_input '.context_window.context_window_size // empty')
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
    status="${status} | 🧠 ${ctx_pct}% ($(fmt_num "${ctx_tokens:-0}")/$(fmt_num "$max_context"))"
fi

# Time remaining in current billing block
if command -v bun >/dev/null 2>&1; then
    blocks_json=$(bun x ccusage blocks --active --json 2>/dev/null)
    remaining_minutes=$(echo "$blocks_json" | jq -r '.blocks[0].projection.remainingMinutes // empty' 2>/dev/null)
    if [ -n "$remaining_minutes" ] && [ "$remaining_minutes" != "null" ] && [ "$remaining_minutes" != "0" ]; then
        status="${status} | ⏱️ $((remaining_minutes / 60))h $((remaining_minutes % 60))m left"
    fi
fi

echo "$status"
