#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/codex/AGENTS.md"

"$ROOT_DIR/scripts/sync-agent-docs.sh"

for target in \
  "$ROOT_DIR/claude/CLAUDE.md" \
  "$ROOT_DIR/gemini/GEMINI.md" \
  "$ROOT_DIR/hermes/AGENTS.md"
do
  cmp -s "$SOURCE_FILE" "$target"
  test "$(stat -f "%Lp" "$target")" = "644"
done

for target_dir in \
  "$ROOT_DIR/claude/scripts" \
  "$ROOT_DIR/gemini/scripts" \
  "$ROOT_DIR/hermes/scripts"
do
  for source_script in "$ROOT_DIR"/codex/scripts/*; do
    target_script="$target_dir/$(basename "$source_script")"
    cmp -s "$source_script" "$target_script"
    test -x "$target_script"
  done
done
