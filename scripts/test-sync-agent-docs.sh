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
