#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/codex/AGENTS.md"
SOURCE_SCRIPTS_DIR="$ROOT_DIR/codex/scripts"

targets=(
  "$ROOT_DIR/claude/CLAUDE.md"
  "$ROOT_DIR/gemini/GEMINI.md"
  "$ROOT_DIR/hermes/AGENTS.md"
)

for target in "${targets[@]}"; do
  mkdir -p "$(dirname "$target")"
  cp "$SOURCE_FILE" "$target"
  chmod 0644 "$target"
done

script_targets=(
  "$ROOT_DIR/claude/scripts"
  "$ROOT_DIR/gemini/scripts"
  "$ROOT_DIR/hermes/scripts"
)

for target_dir in "${script_targets[@]}"; do
  mkdir -p "$target_dir"
  cp -R "$SOURCE_SCRIPTS_DIR/." "$target_dir/"
done
