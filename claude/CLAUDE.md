# AGENTS.md

## Documentation Privacy

- Do not include personal or machine-specific data in README files, documentation, install commands, examples, or generated project files unless the user explicitly requests it. This includes local usernames, absolute home-directory paths, private repository aliases, hostnames, email addresses, tokens, account IDs, and other identifying local details. Use placeholders or portable commands such as `$(pwd)` instead.

## Completion, Review, and Commit Workflow

- When a task is complete, verify the result with the relevant checks, tests, inspections, or review steps before calling the work done.
- If review feedback exists, address it first. Continue to the commit decision only after the review result is positive.
- After a positive review result, summarize all changes made in the task so the user can make an informed version-control decision.
- After the change summary, ask the user how to proceed with version control and offer exactly these options:
  1. `Do not commit` - Leave all changes uncommitted.
  2. `Commit only` - Create one or more commits, grouped by task category when appropriate, but do not push.
  3. `Commit and push` - Create one or more commits, grouped by task category when appropriate, then push to the configured remote.
- Treat the user's choice as applying only to the task just completed. Do not reuse or carry forward a previous commit decision for later tasks.
- When committing, split commits by task category if the work naturally spans multiple categories. Keep each commit focused and independently understandable.
- Do not mix unrelated changes in the same commit.
- Use clear commit messages that describe the intent of each task category.
- Never push unless the user explicitly chooses `Commit and push`.
- If no remote or upstream branch is configured, explain the situation and ask before changing git remote or branch configuration.
