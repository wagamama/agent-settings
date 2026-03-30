#!/bin/bash

# Claude Code Status Line Script
# Displays project info and time remaining in current billing block

input=$(cat)

folder=$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")
model=$(echo "$input" | jq -r '.model.display_name')

# Detect project language
lang_info=""
if [ -n "$VIRTUAL_ENV" ]; then
    venv_raw=$(echo "${VIRTUAL_ENV##*/}" | sed 's/-[0-9].*//')
    if [ "$venv_raw" = ".venv" ] || [ "$venv_raw" = "venv" ]; then
        venv="($folder)"
    else
        venv="($venv_raw)"
    fi
    pyver=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')
    lang_info=" | 💼 $venv | 🐍 $pyver"
elif [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
    pyver=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')
    lang_info=" | 🐍 $pyver"
elif [ -f "go.mod" ] || [ -f "go.sum" ] || ls *.go >/dev/null 2>&1; then
    gover=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/go//' || echo 'N/A')
    [ "$gover" != "N/A" ] && lang_info=" | 🦫 $gover"
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')
base_status="📁 $folder${lang_info} | 🌿 $branch | 🤖 $model"

# Time remaining in current billing block
time_info=""
if command -v bun >/dev/null 2>&1; then
    blocks_json=$(bun x ccusage blocks --active --json --token-limit max 2>/dev/null)
    if [ -n "$blocks_json" ]; then
        remaining_minutes=$(echo "$blocks_json" | jq -r '.blocks[0].projection.remainingMinutes // empty' 2>/dev/null)
        if [ -n "$remaining_minutes" ] && [ "$remaining_minutes" != "null" ] && [ "$remaining_minutes" != "0" ]; then
            hours=$((remaining_minutes / 60))
            mins=$((remaining_minutes % 60))
            time_info=" | ⏱️ ${hours}h ${mins}m left"
        fi
    fi
fi

echo "${base_status}${time_info}"
