# Pull request descriptions

Use this guidance when drafting or updating a PR body. The repository's own PR template takes precedence, but preserve the issue-link and plain-language intent.

## Default format

```markdown
- **Closes:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)

> **In plain terms:** One short paragraph describing what this PR changes for
> people without repeating the linked issue.

## Summary
- Explain the implemented change in human terms.
- Mention notable scope, behavior, or trade-offs when useful.

## Tests
- `command that was run`
- Or: Not run (reason)
```

When there is no issue, omit the relationship line and include enough problem context in **In plain terms** for the PR to stand alone.

## Relationship links

Put issue and stack relationships before **In plain terms**, one per line:

- **Closes** — complete resolution.
- **Advances** — partial delivery.
- **Related** — context without claimed progress.
- **Issue** — neutral association.
- **Depends on** — a parent PR that must land first.
- **Followed by** — a known child PR.

Do not summarize the linked issue. Only use closing automation when the PR genuinely resolves the whole issue.

## In plain terms

Write one short paragraph for non-engineers such as product managers, support, and leadership. It must summarize this PR rather than the issue.

- **Change first.** State what this PR now makes possible, fixes, or changes for people. The linked issue already explains the original problem.
- **Use 2–4 sentences.** A longer explanation usually belongs in the summary or indicates an overly broad PR.
- **Avoid jargon, files, and function names.** Product names and familiar terms are fine; internal identifiers are not.
- **State material trade-offs.** If the safe fix is slower, changes compatibility, or disables an optimization, say so.
- **Be honest about non-behavioral work.** Say “No behavior change” or “Display-only” when true.
- **For follow-ups, describe only the additional behavior.** Link the parent rather than retelling it.

## Summary

Explain the implementation at the level reviewers need:

- lead with behavior and meaningful design choices;
- include important scope boundaries, compatibility, rollout, or failure behavior;
- avoid narrating every file changed;
- avoid vague bullets such as “update code” or “fix bugs”;
- use two or three bullets for a small PR;
- do not oversell the change.

Prefer outcome-focused wording:

- Good: “Start refreshes quickly, then back off to the configured interval.”
- Bad: “Add `increasingRefreshInterval` and call `delay()`.”

## Tests

Record what was actually run and the result implied by the PR's current commit. Include focused commands, manual validation, or a concise explanation when tests were not run. Do not list intended, stale, or unrelated validation.

Update this section whenever new commits change the relevant test evidence.

## Optional sections

Add only when useful:

```markdown
## Notes
- Information reviewers need before reading the diff.

## Screenshots
- Evidence for UI changes.

## Rollout
- Migration, compatibility, deployment, or rollback notes.

## Follow-ups
- Known work intentionally outside this PR.
```

## Examples

### Complete bug fix

```markdown
- **Closes:** [PROJECT-123 Replaced apps can leave processes running](https://linear.app/example/issue/PROJECT-123/replaced-apps-can-leave-processes-running)

> **In plain terms:** Replacing an app now reliably shuts down everything the
> old version started, and reports a failed shutdown instead of hiding it.

## Summary
- Stop every process the old container task spawned before starting its replacement.
- Return shutdown failures to the caller rather than logging and continuing.

## Tests
- `go test ./internal/agent/...`
```

### Partial stacked delivery with a trade-off

```markdown
- **Advances:** [PROJECT-124 Make redeployments verify device images](https://linear.app/example/issue/PROJECT-124/make-redeployments-verify-device-images)
- **Depends on:** [#101 Expose device image digests](https://github.com/example/repository/pull/101)
- **Followed by:** [#103 Enable multi-service verification](https://github.com/example/repository/pull/103)

> **In plain terms:** Single-service redeployments now confirm that the device
> holds the new image before reporting success. Multi-service apps remain on the
> safe re-upload path until the next PR adds equivalent verification.

## Summary
- Verify the device-side digest before honoring the upload-skip optimization.
- Fall back to a full upload when verification fails or is unavailable.

## Tests
- `go test ./internal/cli/... ./internal/agent/...`
```

### No behavior change

```markdown
- **Related:** [PROJECT-125 Prepare generated bindings for upcoming work](https://linear.app/example/issue/PROJECT-125/prepare-generated-bindings-for-upcoming-work)

> **In plain terms:** No behavior change—this refreshes generated code so the
> upcoming feature PR shows only its real changes.

## Summary
- Regenerate the Swift protocol bindings with the pinned toolchain.

## Tests
- `swift build` in `swift/`.
```
