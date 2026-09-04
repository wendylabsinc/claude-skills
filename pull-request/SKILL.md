---
name: pull-request
description: "Create and maintain clear, reviewable pull requests. Use when writing or updating a PR description; linking issues or stacked PRs; splitting changes; documenting database, API, SDK, UI, or CLI boundaries; monitoring CI and review feedback; preserving commit history and authorship; or checking PR readiness and merge mechanics."
---

# Pull Requests

## Goal

Make every PR easy to understand, review, validate, and merge without losing issue traceability, current evidence, commit history, or contributor attribution.

This skill owns PR mechanics. Mode selection, human-agreement stages, implementation authorization, and experiential-development workflow belong to the `agentic-development` skill; see the appendix.

## Repository conventions and authorization

Read the repository's contributor guidance, PR template, required checks, and merge policy first. A repository-specific convention takes precedence over this default.

Treat local commits, pushing, opening or updating a draft, starting remote CI, marking ready, merging, and deploying as distinct mutations. Perform only the stages actually authorized. Do not disturb unrelated dirty state or add opportunistic cleanup.

For contract-first Stages 1–2, the `agentic-development` skill authorizes small isolated local commits while its local-first feedback loop controls publication cadence. Local commits do not authorize a push and do not trigger PR maintenance or remote CI. Instructions below about what to do after a push never authorize the push itself and must not interrupt rapid local human iteration.

## Human-facing references

Whenever mentioning an issue, pull request, workflow run, release, project, initiative, or comparable tracked artifact to a human, include its current title, scoped identifier, and direct link. Never report only `PROJECT-123`, `#42`, or a run number. Resolve titles from the source instead of guessing. In normal Markdown, link the combined identifier and title, for example `[PROJECT-123 — Problem title](https://...)` or `[repository #42 — Delivered outcome](https://...)`.

For Slack, give each artifact its own two-line block with the title bolded, followed by the scoped identifier, then the bare URL:

```text
*Problem title* PROJECT-123
https://tracker.example/PROJECT-123

*Delivered outcome* repository #42
https://github.com/example/repository/pull/42
```

After a full introduction, use “the issue” or “that PR” rather than repeating a bare identifier.

## Issue links and titles

When an issue exists, link it at the top instead of repeating its content:

```markdown
- **Closes:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)

> **In plain terms:** Describe only what this PR changes for people.
```

Choose the relationship that is true:

- **Closes** — this PR fully resolves the issue.
- **Advances** — this PR delivers only part of the issue.
- **Related** — the issue provides context without claimed progress.
- **Issue** — a neutral association.

Use one line per issue. Only use automatic closing behavior for full resolution. If there is no issue, omit the link and give enough context in **In plain terms** for the PR to stand alone.

The PR title describes the behavior delivered and need not copy the issue title. The issue remains the problem record; the PR is the implementation record.

## Description mechanics

Use this compact default unless the repository template differs:

```markdown
- **Closes:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)

> **In plain terms:** One short paragraph describing what this PR changes for
> people without repeating the linked issue.

## Summary
- Explain the implemented change and material trade-offs succinctly.

## Tests
- `command that was run`
- Or: Not run (reason)
```

Keep the body grounded in the cumulative diff and current validation. Avoid file-by-file narration, private helper names, vague bullets, stale intent, and claims not supported by the branch.

Keep it short enough to read in under a minute: relationship links, **In plain terms**, a few summary bullets, and **Tests**. Add another section only when it carries something the reviewer cannot get from the diff, the checks, or the linked issue. A body that needs scrolling usually means the PR is too large or the description is padded.

Write plainly and factually, with enough context that a human or an agent arriving cold understands what changed and why. Leave out:

- problem, cause, or solution essays that restate the linked issue or design document;
- pasted command output, transcribed verification runs, and "what I checked" tours—evidence belongs in CI, commits, and review replies;
- revision history such as "this PR has been extended" or corrections to earlier paragraphs; rewrite the body to describe the current branch instead;
- empty sections, `N/A` placeholders, unused checklists, and other template scaffolding;
- hedging, salesmanship, and praise for the change.

Keep AI attribution out of the PR body. Generated-with footers, tool badges, and agent signatures belong in commit trailers if a repository wants them at all; in a description they only add noise.

For complete writing guidance, optional sections, and examples, read [references/descriptions.md](references/descriptions.md).

## Scope and splitting

Prefer one coherent user, product, or operational outcome per PR. Split work when parts have meaningfully different:

- outcomes or issue relationships;
- risk, rollback, deployment, or durable contract boundaries;
- reviewers or ownership domains;
- release timing;
- dependencies that can land independently.

Do not split mechanically by file count, language, directory, or implementation layer. Keep a supporting refactor with its only consumer. Do not create a foundation PR solely to make the visible feature PR look smaller.

Every split PR still needs a coherent purpose, accurate relationship, and validation at its actual boundary. Intermediate PRs use **Advances**; only the PR completing the issue uses **Closes**.

## Durable boundary changes

Inspect the diff specifically for interfaces that users, clients, persisted data, scripts, or other repositories will depend on and that become costly to reverse:

- **Database schemas:** tables, columns, types, constraints, semantically important indexes, persisted meanings, migrations, compatibility windows, and rollback behavior.
- **gRPC and protobuf:** services, RPCs, messages, field numbers and presence, enum values, wire meaning, errors, and reservation or compatibility requirements.
- **REST APIs:** methods, paths, authentication, request and response shapes, status and error contracts, pagination, defaults, and versions.
- **Public SDK APIs:** exported modules, types, functions, signatures, protocols, behavior guarantees, errors, concurrency semantics, platform support, deprecations, and source or binary compatibility.
- **User interfaces:** the journey people see—actions, navigation, state, terminology, feedback, accessibility, and screenshots where useful.
- **Command-line interfaces:** commands, flags, arguments, defaults, prompts, output formats, exit codes, configuration, environment variables, and scripting compatibility.

When one changes, add a concise section describing only the observable contract delta:

```markdown
## Boundary changes
- **REST:** `POST /devices` now returns `409 device_already_exists` for a duplicate identity instead of a generic `400`.
- **CLI:** `wendy deploy --wait` now exits nonzero when device confirmation times out; scripts that ignored the old timeout message may need adjustment.
```

Use before → after wording when helpful. State whether the change is additive, compatible, deprecated, or breaking, and mention affected consumers and material migration, rollout, or rollback constraints.

Do not list replaceable helpers, handlers, ORM models, view types, or internal refactors here unless they alter the external contract or risk. Do not add an empty boundary section.

In contract-first work, human-selected internal seams belong under **Agreed structure**, not **Boundary changes**.

## Stack mechanics

Keep stacks shallow. Base each child on its actual parent and declare relationships before **In plain terms**:

```markdown
- **Advances:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)
- **Depends on:** [#101 Add the shared transport](https://github.com/example/repository/pull/101)
- **Followed by:** [#103 Expose the user workflow](https://github.com/example/repository/pull/103)
```

For every stack:

- describe only the current PR's delta, not the cumulative stack;
- give each PR its own validation;
- update bases and links as parents merge;
- avoid overlapping edits that create cascading conflicts;
- do not present a child as independently mergeable while its parent is unresolved;
- preserve the stage commits even when review-only parents are not independently merged.

Contract-first work uses one of these shapes:

```text
Contract → Implementation
Boundary → Structure → Implementation   # rare
```

Every contract layer is real code at an exact commit: declarations, protocol or schema definitions, migrations, types, stubs, mocks, fixtures, views, view models, tests, examples, or previews. PR prose and standalone design documents may explain or index that code, but they are not the contract and cannot replace it.

The code must occupy its intended final modules and files under ordinary production names. Do not create review-only `Contract`, `Structure`, `Proposal`, `Spec`, or `Stub` source files, namespaces, or catch-all containers unless that name is genuinely part of the final product architecture. A structure layer is the real program skeleton with implementation bodies and replaceable private helpers omitted; its child fills those holes instead of replacing the skeleton.

Represent the layers mechanically:

```markdown
# Combined contract PR
- **Mode:** Contract
- **Followed by:** [#102 Implement the contract](...)

# Optional structure PR
- **Mode:** Structure
- **Depends on:** [#101 Agree the boundaries](...)
- **Followed by:** [#103 Implement the agreed structure](...)

# Implementation PR
- **Mode:** Implementation
- **Depends on:** [#102 Agree the structure](...)
- **Implements:** [#101 Agree the boundaries](...)
- **Implements:** [#102 Agree the structure](...)
```

The contract or boundary PR records **Boundary changes** and points reviewers to the concrete contract code. Selected internal seams use **Agreed structure** in the combined contract or optional structure PR, but the actual type and module stubs remain authoritative. The implementation PR links rather than repeats them and includes:

```markdown
## Try it
- Preview, experimental build, artifact, or reproducible local journey.

## Contract drift
- **Boundary:** None.
- **Structure:** None.
```

Omit inapplicable structure lines in a two-level stack. When drift exists, link the owning parent update and renewed agreement. A contract PR is a review surface and does not need to be independently deployable; the `agentic-development` skill defines safe final integration, mode selection, and agreement workflow.

## Commits, history, and authorship

Preserve original history and author metadata whenever practical:

- do not recreate another person's changes under the agent's identity;
- do not squash, collapse, reorder, or rewrite published commits for cosmetic history;
- avoid force-pushing published branches unless repository workflow requires it and affected collaborators agree;
- keep new commits attributable to their actual author;
- retain valid co-author trailers and sign-offs;
- prefer follow-up review commits over rewriting commits others may already be reviewing.

When merging is authorized, prefer a merge commit because it preserves commits, ordering, and authors. Do not squash-merge by default, especially with multiple authors. Use squash or rebase merge only when explicitly requested or required by repository policy; preserve required attribution and make the history loss or rewrite clear.

## Keep the PR current after every authorized publication push

After every explicitly authorized publication push:

1. Re-read the cumulative diff against the current base.
2. Update the title if delivered scope changed.
3. Update issue, dependency, and successor links.
4. Update **In plain terms**, summary, boundary changes, agreed structure, trade-offs, tests, rollout, **Try it**, drift, and follow-ups as applicable.
5. Remove claims invalidated by new commits.

Never let the description claim work absent from the branch or omit material behavior added later.

## CI and feedback

After every explicitly authorized publication push, ensure relevant CI and automated review eventually reach terminal states. During active contract-first Stages 1–2, do not block the human's local experience loop waiting for remote checks and do not publish another revision merely to satisfy intermediate automated feedback. Reconcile the published candidate's checks and feedback before requesting exact-commit agreement or presenting the PR as ready.

Inspect failures, cancellations, skipped required checks, stale checks, and all feedback channels:

- human reviews, inline threads, and PR comments;
- tests, lint, documentation, contract generation, migrations, and compatibility;
- security, dependency, static-analysis, and AI review findings.

Address every finding within authorized scope:

- fix valid findings and add focused tests where appropriate;
- reply with the relevant commit or evidence;
- narrowly resolve or suppress incorrect findings through the tool's documented mechanism and record the rationale;
- never ignore feedback, hide unresolved results, broadly disable a check, or lower a security baseline merely to turn CI green;
- ask for direction when feedback conflicts with product intent, repository policy, or scope.

Treat credible security, privacy, credential, data-loss, and supply-chain findings as blocking. Do not expose sensitive scanner output publicly. Avoid wasteful reruns when no relevant input changed.

## Ready and merge mechanics

Present a PR as ready only when its description matches the diff, required checks are green, actionable feedback is addressed, invalid findings have evidence-backed resolution, dependencies and material rollout concerns are explicit, and the branch is conflict-free.

Do not approve or present a red, dirty, conflicting, stale, blocked, or misleading PR as ready. Before an authorized merge, recheck status, reviews, base branch, dependency order, and merge strategy.

## Useful GitHub commands

```bash
gh pr view <number> --json number,title,body,headRefName,baseRefName,isDraft,mergeable,reviewDecision,statusCheckRollup,closingIssuesReferences
git diff --stat <base>...HEAD
git diff <base>...HEAD
gh pr checks <number> --watch
gh pr create --draft --title "..." --body-file <file>
gh pr edit <number> --body-file <file>
```

GitHub's summary may omit inline threads or third-party findings. Use the provider UI or API as needed before claiming all feedback is addressed.

## Appendix: agentic development lifecycle

Load the `agentic-development` skill when deciding between integrated and contract-first work or handling boundary drafts, human-promoted structure, agreement commits, implementation authorization, previews, live experience, or contract drift.

That skill owns the lifecycle and human/agent collaboration model. This skill only defines how the resulting PRs are represented, maintained, validated, and merged.
