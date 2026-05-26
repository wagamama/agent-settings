#!/bin/bash
set -u

# Stop hook: remind the assistant to run the user's completion/review/commit
# workflow whenever the current repo still has uncommitted changes.

if ! command -v git >/dev/null 2>&1; then
  exit 0
fi

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

status=$(git status --porcelain=v1 2>/dev/null)
[ -z "$status" ] && exit 0

cat >&2 <<'EOF'

COMPLETION WORKFLOW GUARD

This task left uncommitted git changes. Before a final answer, follow the user's
"Completion, Review, and Commit Workflow":

1. Verify/review the completed work with relevant checks.
2. Summarize all changes made in this task.
3. Ask exactly:
   1. `Do not commit` - Leave all changes uncommitted.
   2. `Commit only` - Create one or more commits, grouped by task category when appropriate, but do not push.
   3. `Commit and push` - Create one or more commits, grouped by task category when appropriate, then push to the configured remote.

Do not reuse an earlier commit decision for this task.

Current git status:
EOF

printf '%s\n' "$status" >&2
exit 0
