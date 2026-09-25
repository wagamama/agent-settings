# AGENTS.md

## Writing Style

- Use ASD-STE100 Simplified Technical English and Zinsser's four principles: simplicity, brevity, clarity, and humanity.

## Permissions

- For the full requested task, prefer safe, authorized methods that need fewer permission requests. Use existing approval, sandboxed tools, and reversible steps when suitable. Never bypass a required approval or weaken safety or scope to avoid a request.

## Documentation

- Keep personal and machine-specific data out of README files, documentation, install commands, examples, and generated project files unless the user explicitly asks for it. This includes usernames, home paths, private repository aliases, hostnames, email addresses, tokens, and account IDs. Use placeholders or portable commands such as `$(pwd)`.
- Update related documentation after structural changes, significant features, or breaking API changes.

## Security and Code Quality

- Review new code for injection risks, hardcoded credentials, and insecure patterns. Run the project's linter or security scanner, if present, during verification.

## Errors

- After a failed command or unexpected error, capture and analyze the full output before a fix. If the cause is unclear, propose a diagnostic step before repair.

## Behavior Corrections

- Treat an explicit correction as a reusable rule. Identify its trigger, preferred behavior, and anti-pattern; apply it now unless a higher-priority rule conflicts.
- For a durable correction, propose a concise, portable update to the maintained agent instructions. Avoid details unique to one case.

## Subagents

- Prefer subagents for independent work that can run in parallel with little shared context. Use one per clear problem domain; avoid them for coupled work, shared state, broad architecture choices, or edits to the same files.
- Give each subagent a narrow, self-contained task with the goal, relevant files or errors, constraints, and expected summary. Use them to preserve context and time, not only to save tokens.
- Review returned summaries and diffs for conflicts or duplicate work, then run relevant checks before accepting the result.

## Completion, Review, and Version Control

- Verify completed work with relevant checks, tests, inspections, or review steps.
- Before the final summary and commit decision for non-trivial work, cross-reference the request, diff, verification results, and project instructions. Use a different review agent when available (Claude Code for Codex work); otherwise use self-subagents with review skills. For review tools, prefer Codex, then Claude Code. Address findings before calling the review positive.
- After a positive review, summarize all task changes so the user can make an informed version-control decision. Then offer exactly these choices:
  1. `Commit only` - Make focused commits by task category when appropriate; do not push.
  2. `Commit and push` - Make focused commits by task category when appropriate; then push to the configured remote.
- Apply the choice only to this task. Do not reuse a prior choice. Keep unrelated changes out of each commit and use clear messages that state each category's intent. Push only after the user chooses `Commit and push`.
- If no remote or upstream branch is configured, explain this and ask before changing that configuration.
