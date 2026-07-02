# AGENTS.md

## Documentation Privacy

- Do not include personal or machine-specific data in README files, documentation, install commands, examples, or generated project files unless the user explicitly requests it. This includes local usernames, absolute home-directory paths, private repository aliases, hostnames, email addresses, tokens, account IDs, and other identifying local details. Use placeholders or portable commands such as `$(pwd)` instead.

## Documentation Maintenance

- When making structural changes, significant feature additions, or breaking API changes, proactively update corresponding documentation (e.g., README.md, CHANGELOG.md, or docstrings) to ensure it reflects the current state of the code.

## Security & Code Quality

- Perform a light security review of all new code: check for potential injection vulnerabilities, hardsoded credentials in the logic itself, or insecure patterns. If the project includes a linter or security scanner (e.g., `eslint`, `bandit`), run it as part of the verification step.

## Error Handling & Failure Protocol

- When a command returns a non-zero exit code or an unexpected error occurs, do not immediately attempt a fix. First, capture and analyze the full error output; if the cause is unclear, propose a diagnostic step (like checking environment variables) before proceeding with a repair.

## Behavior Corrections and Rule Generalization

- Treat explicit user corrections to agent behavior as feedback about a reusable behavior pattern, not only as a one-off instruction for the current task.
- When corrected, identify the general rule behind the correction: the trigger condition, the preferred future behavior, and the anti-pattern to avoid.
- Apply the generalized rule immediately when it does not conflict with higher-priority instructions.
- If the correction is durable across future tasks or agents, propose an update to the maintained agent instructions so the rule can prevent the same error again.
- Keep generalized rules concise, portable, and privacy-preserving. Do not overfit them to incidental details from a single situation.

## Completion, Review, and Commit Workflow

- When a task is complete, verify the result with the relevant checks, tests, inspections, or review steps before calling the work done.
- If review feedback exists, address it first. Continue to the commit decision only after the review result is positive.
- After a positive review result, summarize all changes made in the task so the user can make an informed version-control decision.
- After the change summary, ask the user how to proceed with version control and offer exactly these options:
  1. `Commit only` - Create one or more commits, grouped by task category when appropriate, but do not push.
  2. `Commit and push` - Create one or more commits, grouped by task category when appropriate, then push to the configured remote.
- Treat the user's choice as applying only to the task just completed. Do not reuse or carry forward a previous commit decision for later tasks.
- When committing, split commits by task category if the work naturally spans multiple categories. Keep each commit focused and independently understandable.
- Do not mix unrelated changes in the same commit.
- Use clear commit messages that describe the intent of each task category.
- Never push unless the user explicitly chooses `Commit and push`.
- If no remote or upstream branch is configured, explain the situation and ask before changing git remote or branch configuration.

## Task Review

- Before the final change summary and commit decision for non-trivial work, perform a cross-reference review.
- Review tool priority: 1. Codex, 2. Claude Code.
- Review agent usage priority: 1. Use a different agent from the one performing the task when available. For example, if the task is being performed by Codex, use Claude Code as the first-priority cross-check agent. 2. If no other agent is available, use self-subagents with available review skills.
- Cross-reference the user's request, the implementation diff, verification results, and applicable project instructions such as `AGENTS.md`.
- Address any review findings before reporting a positive review result.
