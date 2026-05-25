#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/codex/AGENTS.md"

targets=(
  "$ROOT_DIR/claude/CLAUDE.md"
  "$ROOT_DIR/gemini/GEMINI.md"
)

for target in "${targets[@]}"; do
  mkdir -p "$(dirname "$target")"
  cp "$SOURCE_FILE" "$target"
  chmod 0644 "$target"
done
