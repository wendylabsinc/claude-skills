---
name: pr-description
description: "Craft or update pull request descriptions. Use when asked to write, improve, summarize, or update a PR body, especially for GitHub PRs. Produces humane, succinct descriptions that link the owning issue, explain what the PR changes, and record how it was tested."
---

# PR Description

## Goal

Write PR descriptions that help reviewers quickly understand the change.

Prefer plain language over implementation narration. Be specific, but concise.
Link to the issue for problem context instead of repeating it. Explain the behavior
or user-visible effect of this PR first; mention implementation details only when
they help review the change.

## Default format

Use this structure unless the repository has a different existing convention:

```markdown
- **Closes:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)

> **In plain terms:** One short paragraph a non-engineer can read.
> Describe what this PR changes for people without repeating the linked issue.

## Summary
- Explain the implemented change in human terms.
- Mention notable scope, behavior, or trade-offs if useful.

## Tests
- `command that was run`
- Or: Not run (reason)
```

## Issue relationship

When a PR has an owning or related issue, link it before the plain-terms block. Do
not summarize or repeat the issue; the link supplies the problem context.

Choose the relationship that is actually true:

- **Closes** — the PR fully resolves the issue.
- **Advances** — the PR delivers only part of the issue.
- **Related** — the issue provides context but this PR does not claim progress on it.
- **Issue** — a neutral link when no lifecycle claim is appropriate.

Use one line per issue when several are relevant. Only use closing automation when
the PR genuinely resolves the whole issue. If there is no issue, omit the link and
include enough problem context in the plain-terms paragraph for it to stand alone.
The PR title should describe the behavior delivered and need not copy the issue
title.

## The "In plain terms" blockquote

After any issue links, every PR body opens its explanation with this blockquote,
written for non-engineers (product managers, support, leadership). It is the one
part of the description they will actually read, so it must stand alone as a
summary of the PR—not of the issue.

- **Change first.** State what this PR now makes possible, fixes, or changes for
  people. The linked issue already explains the original problem. When no issue is
  linked, briefly include the problem before the outcome. Never open with file or
  function names.
- **One paragraph, 2–4 sentences.** If it needs more, the PR probably needs a
  narrower scope, not a longer blockquote.
- **No jargon, no file or function names.** Product and household names are
  fine (Wendy, Docker, CUDA, Ctrl-C); identifiers like `classifyFlashError`
  are not.
- **Name the stakes when they clarify the change.** Do not restate the issue's
  background, but explain a material consequence or trade-off of this PR when a
  reviewer needs it.
- **State trade-offs honestly.** If the safe fix is slower or disables an
  optimization, say so and point at the follow-up.
- **Chores and display-only changes say so explicitly:** "No behavior change —
  this refreshes auto-generated code…", "Display-only — no behavior change."
- **Follow-ups link to their parent.** Use **Related** for the parent and describe
  only the additional behavior delivered here.
- Italics are welcome for the one surprising word: "kept running the *old*
  version", "the error shown could be about the *retry*".

## Style

- Keep it succinct.
- Make it sound like a person wrote it.
- Avoid restating every file changed.
- Avoid vague bullets like "update code" or "fix bugs".
- Prefer outcome-focused wording:
  - Good: "Start refreshes quickly, then back off to the configured interval."
  - Bad: "Add increasingRefreshInterval helper and call delay()."
- Include concrete examples when they clarify behavior.
- Do not oversell the change.
- If the PR is small, two or three summary bullets are enough.

## Workflow

1. Inspect the current PR, branch, and linked issue when one exists:
   - `gh pr view --json number,title,body,headRefName,baseRefName,closingIssuesReferences`
   - `git diff --stat <base>...HEAD`
   - `git diff <base>...HEAD` when needed
2. Classify each issue link as **Closes**, **Advances**, **Related**, or **Issue**.
3. Identify from the actual diff and validation:
   - What this PR changes
   - User-visible behavior
   - Important constraints, trade-offs, or edge cases
   - Tests run
4. Draft the PR body with issue links first, followed by the "In plain terms"
   blockquote. Do not copy the issue description into either the blockquote or
   summary.
5. If updating an existing PR, preserve useful existing sections and remove stale
   or overly mechanical wording. Add the relationship link and blockquote if they
   are missing.
6. Apply with:
   - `gh pr edit <number> --body-file <file>`

## Optional sections

Add only when useful:

```markdown
## Notes
- Anything reviewers should know before reading the diff.

## Screenshots
- For UI changes.

## Rollout
- Migration, compatibility, or deployment notes.

## Follow-ups
- Known work intentionally left out of this PR.
```

## Examples

### Bug fix with real stakes

```markdown
- **Closes:** [PROJECT-123 Replaced apps can leave processes running](https://linear.app/example/issue/PROJECT-123/replaced-apps-can-leave-processes-running)

> **In plain terms:** Replacing an app now reliably shuts down everything the
> old version started, and reports a failed shutdown instead of hiding it.

## Summary
- Kill every process the old container's task spawned before starting the
  replacement, instead of only signalling the init process.
- Report shutdown failures to the caller rather than logging and continuing.

## Tests
- `go test ./internal/agent/...`
```

### Fix with an honest trade-off

```markdown
- **Closes:** [PROJECT-124 Redeployments can keep using an old image](https://linear.app/example/issue/PROJECT-124/redeployments-can-keep-using-an-old-image)

> **In plain terms:** Redeploying now confirms the device actually holds the new
> image before claiming success, and re-uploads when it cannot confirm. Trade-off:
> multi-service apps now always re-upload—safe but slower—until a follow-up
> optimization lands.

## Summary
- Verify the device-side image digest before honoring the push-skip
  optimization; fall back to a full upload when verification fails.
- Multi-service push-skip is disabled until a registry-digest RPC exists.

## Tests
- `go test ./internal/cli/... ./internal/agent/...`
```

### Chore / no behavior change

```markdown
- **Related:** [PROJECT-125 Prepare generated bindings for upcoming work](https://linear.app/example/issue/PROJECT-125/prepare-generated-bindings-for-upcoming-work)

> **In plain terms:** No behavior change—this refreshes auto-generated code so
> upcoming feature PRs show only their real changes.

## Summary
- Regenerate the Swift proto bindings against the pinned generator toolchain.

## Tests
- `swift build` in `swift/`.
```

### Follow-up to a merged PR

```markdown
- **Related:** [#1367 Report actionable flash failures](https://github.com/example/repository/pull/1367)

> **In plain terms:** This follow-up makes Ctrl-C abort flashing cleanly without
> starting another multi-gigabyte retry, and records cancellations correctly in
> error analytics.

## Summary
- Abort on context cancellation before entering the fallback write path.
- Classify cancellation as its own failure kind instead of "unknown".

## Tests
- `go test ./internal/cli/commands`
```
