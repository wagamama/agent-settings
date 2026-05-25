# AGENTS.md

## Agent Instructions Sync

- Treat `codex/AGENTS.md` as the only maintained source for shared coding-agent instructions.
- After every change to `codex/AGENTS.md`, run `scripts/sync-agent-docs.sh`.
- After syncing, run `bash scripts/test-sync-agent-docs.sh` to verify generated agent instruction files match `codex/AGENTS.md`.
- Do not edit generated agent instruction files directly unless the user explicitly requests a one-off change.
