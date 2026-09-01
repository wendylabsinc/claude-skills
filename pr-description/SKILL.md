---
name: pr-description
description: "Craft or update pull request descriptions. Use when asked to write, improve, summarize, or update a PR body, especially for GitHub PRs. Produces humane, succinct descriptions that explain what is changing, why it matters, and how it was tested — opening with a plain-terms paragraph for product managers."
---

# PR Description

## Goal

Write PR descriptions that help reviewers quickly understand the change.

Prefer plain language over implementation narration. Be specific, but concise.
Explain the behavior or user-visible effect first; mention implementation details
only when they help review the PR.

## Default format

Use this structure unless the repository has a different existing convention:

```markdown
> **In plain terms:** One short paragraph a non-engineer can read.
> Lead with the problem as a user experienced it, then what changes for them.

## Summary
- Explain the main change in human terms.
- Include why it matters or what problem it solves.
- Mention notable scope, behavior, or rollout details if useful.

## Tests
- `command that was run`
- Or: Not run (reason)
```

## The "In plain terms" blockquote

Every PR body opens with this blockquote, written for non-engineers (product
managers, support, leadership). It is the one part of the description they
will actually read, so it must stand alone.

- **Problem first, fix second.** Start with what a user saw or suffered, in
  concrete terms ("the org selection screen offers no way to actually pick an
  org and continue"). Then the outcome ("This fixes the picker so selecting
  works"). Never open with "This PR adds…".
- **One paragraph, 2–4 sentences.** If it needs more, the PR probably needs a
  narrower scope, not a longer blockquote.
- **No jargon, no file or function names.** Product and household names are
  fine (Wendy, Docker, CUDA, Ctrl-C); identifiers like `classifyFlashError`
  are not.
- **Name the stakes when they're real.** "a fix looks shipped but isn't",
  "hogging the camera so nothing else could use it" — the cost of the bug is
  what makes a PM care.
- **State trade-offs honestly.** If the safe fix is slower or disables an
  optimization, say so and point at the follow-up.
- **Chores and display-only changes say so explicitly:** "No behavior change —
  this refreshes auto-generated code…", "Display-only — no behavior change."
- **Follow-ups anchor to their parent:** "Two small polish fixes on the
  flash-error reporting that just shipped in #1367: …"
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

1. Inspect the current PR and branch:
   - `gh pr view --json number,title,body,headRefName,baseRefName`
   - `git diff --stat <base>...HEAD`
   - `git diff <base>...HEAD` when needed
2. Identify:
   - What changed
   - Why it changed
   - User-visible behavior
   - Important constraints or edge cases
   - Tests run
3. Draft the PR body, starting with the "In plain terms" blockquote.
4. If updating an existing PR, preserve useful existing sections and remove stale
   or overly mechanical wording. Add the blockquote if it is missing.
5. Apply with:
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
> **In plain terms:** When you replaced or redeployed an app, the
> old copy could keep running invisibly for hours — in one case hogging the
> camera so nothing else could use it. Now replacing an app reliably shuts
> down everything the old version started, and a failed shutdown is reported
> instead of hidden.

## Summary
- Kill every process the old container's task spawned before starting the
  replacement, instead of only signalling the init process.
- Report shutdown failures to the caller rather than logging and continuing.

## Tests
- `go test ./internal/agent/...`
```

### Fix with an honest trade-off

```markdown
> **In plain terms:** When you redeploy an app, Wendy could report
> success while the device quietly kept running the *old* version — so a fix
> looks shipped but isn't. This makes Wendy confirm the device actually holds
> the new image before claiming success; if it can't confirm, it re-uploads
> instead. Trade-off: multi-service apps now always re-upload (safe but
> slower) until a follow-up optimization lands.

## Summary
- Verify the device-side image digest before honoring the push-skip
  optimization; fall back to a full upload when verification fails.
- Multi-service push-skip is disabled until a registry-digest RPC exists.

## Tests
- `go test ./internal/cli/... ./internal/agent/...`
```

### Chore / no behavior change

```markdown
> **In plain terms:** No behavior change — this refreshes
> auto-generated code that had fallen out of date, so upcoming feature PRs
> show only their real changes.

## Summary
- Regenerate the Swift proto bindings against the pinned generator toolchain.

## Tests
- `swift build` in `swift/`.
```

### Follow-up to a merged PR

```markdown
> **In plain terms:** Two small polish fixes on the flash-error
> reporting that just shipped in #1367: cancelling a flash with Ctrl-C now
> aborts cleanly instead of kicking off a fresh multi-gigabyte retry, and
> cancellations are counted correctly in our error analytics.

## Summary
- Abort on context cancellation before entering the fallback write path.
- Classify cancellation as its own failure kind instead of "unknown".

## Tests
- `go test ./internal/cli/commands`
```
