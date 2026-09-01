---
name: pull-request
description: "Create and manage pull requests from scope selection through review and merge readiness. Use when asked to create, split, stack, describe, publish, update, monitor, review, ready, or merge a PR; when deciding PR boundaries; or when responding to CI, automated review, security findings, or reviewer feedback. Preserves issue traceability, accurate descriptions, commit history, and author attribution."
---

# Pull Requests

## Goal

Produce coherent, reviewable changes with accurate issue relationships, current descriptions, complete feedback handling, and preserved authorship.

A pull request is the implementation record. Its linked issue remains the problem record. Its commits remain the historical record of who changed what and why.

## Authorization and repository conventions

Read the repository's contributor guidance, PR template, merge policy, and required checks first. Follow a repository-specific convention when it conflicts with this default.

Treat branch creation, implementation, pushing, opening a draft, marking ready, merging, and deploying as distinct actions. Do not infer authorization for a later action from authorization for an earlier one. Never merge or deploy unless explicitly authorized.

Do not disturb unrelated dirty state or broaden the change with opportunistic cleanup.

## Issue handoff

When an issue exists, link it at the top of the PR instead of repeating its content:

```markdown
- **Closes:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)

> **In plain terms:** Describe only what this PR changes for people.
```

Choose the relationship that is actually true:

- **Closes** — this PR fully resolves the issue.
- **Advances** — this PR delivers only part of the issue.
- **Related** — the issue provides context without claimed progress.
- **Issue** — a neutral association when no lifecycle claim is appropriate.

Use one line per issue when several are relevant. Only use automatic closing behavior for full resolution. If no issue exists, omit the link and give enough context in **In plain terms** for the PR to stand alone.

The PR title describes the behavior delivered and need not copy the issue title. Do not rewrite the issue into a retrospective implementation specification.

For complete description guidance and examples, read [references/descriptions.md](references/descriptions.md).

## Scope and splitting

Prefer one coherent user, product, or operational outcome per PR. A PR should have one primary reason to exist and be understandable without unrelated changes.

Split work when parts have meaningfully different:

- outcomes or issue relationships;
- risk, rollback, deployment, or durable contract boundaries;
- reviewers or ownership domains;
- release timing;
- dependencies that can land independently.

Do not split mechanically by file count, language, directory, or implementation layer. Keep supporting refactors with their consumer when they have no independent value. Do not create a foundation PR merely to make the visible feature PR look smaller.

A split PR must still be coherent. State what it delivers, test it at its actual boundary, and use **Advances** until the issue is genuinely complete. Only the PR that completes the remaining issue may use **Closes**.

## Durable boundary changes

Give disproportionate attention to interfaces that users, clients, persisted data, or other repositories will depend on and that are costly to reverse after release. Inspect the diff specifically for:

- **Database schemas:** tables, columns, types, constraints, indexes with semantic impact, persisted meanings, data migrations, compatibility windows, and rollback behavior.
- **gRPC and protobuf contracts:** services, RPCs, messages, field numbers, field presence, enum values, wire meaning, error behavior, and compatibility or reservation requirements.
- **REST APIs:** methods, paths, authentication, request and response shapes, status codes, error contracts, pagination, defaults, and version compatibility.
- **Public SDK APIs:** exported modules, types, functions, signatures, protocol conformances, behavior guarantees, errors, concurrency semantics, platform support, deprecations, and source or binary compatibility.
- **User interfaces:** changes to the journey people see—available actions, navigation, state, terminology, feedback, accessibility, and screenshots where useful.
- **Command-line interfaces:** commands, flags, arguments, defaults, prompts, output formats, exit codes, configuration, environment variables, and scripting compatibility.

When one of these boundaries changes, add a concise **Boundary changes** section or equivalent repository-template content. Describe only the externally observable contract delta:

```markdown
## Boundary changes
- **REST:** `POST /devices` now returns `409 device_already_exists` for a duplicate identity instead of a generic `400`.
- **CLI:** `wendy deploy --wait` now exits nonzero when device confirmation times out; scripts that ignored the prior timeout message may need adjustment.
```

Use before → after wording when it removes ambiguity. State whether the change is additive, compatible, deprecated, or breaking, and mention required migration, rollout ordering, or rollback constraints. If several repositories consume the boundary, identify the affected consumers or linked PRs.

Keep this section succinct. Do not list private helpers, handlers, ORM models, view types, internal refactors, or other replaceable implementation mechanics unless they materially alter the contract, compatibility, risk, or review strategy. If no durable boundary changed, do not add an empty section merely to satisfy a template.

## Stacking

Use a stack only when an unavoidable dependency prevents clean independent PRs. Prefer independent PRs or one reasonably sized PR when either is easier to review and merge.

For a stack:

- keep it shallow and order it from prerequisite to user-facing outcome;
- give each PR a coherent purpose and its own validation;
- base each child on its actual parent branch;
- declare dependencies and successors before **In plain terms**;
- describe only the current PR's delta, not the cumulative stack;
- use **Advances** on intermediate PRs and **Closes** only when the issue is fully resolved;
- update bases, links, and descriptions as parent PRs merge;
- avoid parallel edits to the same lines that create cascading conflicts.

```markdown
- **Advances:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)
- **Depends on:** [#101 Add the shared transport](https://github.com/example/repository/pull/101)
- **Followed by:** [#103 Expose the user workflow](https://github.com/example/repository/pull/103)

> **In plain terms:** This PR adds the device-side behavior required by the next PR.
```

Do not mark a child ready as though it were independently mergeable when its parent is unresolved. After a parent merges, retarget or rebase only as repository policy requires, without casually rewriting published history.

## Commits, history, and authorship

Preserve the original commit history and author metadata whenever practical:

- do not recreate another person's changes under the agent's identity;
- do not squash, collapse, reorder, or rewrite published commits merely for cosmetic history;
- avoid force-pushing published branches unless the repository workflow requires it and the affected collaborators agree;
- keep new commits attributable to the person or agent that made them;
- retain valid co-author trailers and sign-offs;
- prefer follow-up commits during review over rewriting commits other people may already be reviewing.

Prefer a merge commit when merging is authorized because it preserves the branch's commits, ordering, and authors. Do not squash-merge by default, especially when multiple authors contributed. Use squash or rebase merge only when explicitly requested or required by repository policy; make the loss or rewrite of commit history clear and preserve all required attribution.

## Opening and maintaining the PR

Open a draft at the first coherent publication boundary when authorized. A draft may be incomplete, but its scope, relationship links, current behavior, and validation must be honest.

Derive the title and body from the actual diff and tests, not from an intended plan. After every push:

1. Re-read the cumulative diff against the current base.
2. Update the title if the delivered scope changed.
3. Update issue, dependency, and successor links.
4. Update **In plain terms**, summary, durable boundary changes, trade-offs, tests, rollout notes, and follow-ups.
5. Remove claims invalidated by new commits.

Never let the PR description describe work that is no longer in the branch or omit material behavior added later.

## CI and feedback loop

After every push, watch CI and automated review until the relevant checks reach a terminal state. Do not report success merely because workflows started. Inspect failures, cancellations, skipped required checks, and stale checks rather than looking only at the aggregate badge.

Review all feedback channels:

- human reviews and inline threads;
- issue comments on the PR;
- test, lint, documentation, contract-generation, migration, and compatibility checks;
- security, dependency, static-analysis, and AI review findings.

Address every finding within the authorized scope:

- fix valid findings and add or update focused tests where appropriate;
- reply with the relevant commit or evidence when a concern is addressed;
- if a finding is incorrect or inapplicable, resolve or silence it through the tool's narrow, documented suppression mechanism and record the rationale;
- never ignore feedback, hide an unresolved result, broadly disable a check, lower a security baseline, or mark a false positive without evidence merely to make CI green;
- ask for direction when feedback conflicts with product intent, repository policy, or authorized scope.

Treat credible security, privacy, credential, data-loss, and supply-chain findings as blocking. Do not paste secrets or sensitive scanner output into public comments.

Push coherent fixes rather than one commit per bot message, then repeat the description, CI, and feedback review. Avoid wasteful reruns when no relevant input changed. If a failure is external or infrastructural, document the evidence and keep the PR honestly blocked or draft until policy permits otherwise.

## Ready and merge gates

Mark a PR ready only when:

- its scope and issue relationships are accurate;
- its description matches the current diff;
- required tests and checks are green;
- all actionable human and automated feedback is addressed;
- invalid findings are narrowly resolved or suppressed with rationale;
- durable schema, API, SDK, UI, and CLI boundary changes are concise, explicit, and compatibility-reviewed where applicable;
- dependencies, migrations, rollout, and follow-ups are explicit where material;
- the branch is mergeable and has no unresolved conflicts;
- the PR is not knowingly incomplete or blocked.

Do not approve or present a red, dirty, conflicting, stale, or misleading PR as ready. Do not merge merely because GitHub enables the button. When merging is authorized, recheck status, reviews, base branch, and merge strategy immediately beforehand.

## Useful GitHub commands

```bash
# Inspect the PR and its current claims
gh pr view <number> --json number,title,body,headRefName,baseRefName,isDraft,mergeable,reviewDecision,statusCheckRollup,closingIssuesReferences

# Inspect the actual change
git diff --stat <base>...HEAD
git diff <base>...HEAD

# Watch checks after a push
gh pr checks <number> --watch

# Open or update through a body file
gh pr create --draft --title "..." --body-file <file>
gh pr edit <number> --body-file <file>
```

GitHub's summary does not always expose every inline thread or third-party finding. Use the provider UI or API when necessary, and do not claim all feedback is addressed until those channels have been checked.
