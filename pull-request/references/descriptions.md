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

## Length and tone

A reviewer should be able to read the whole body in under a minute. The default format above is the target size, not a floor to build on.

- **Say it once.** The issue holds the problem, the diff holds the code, CI holds the evidence. The body connects them.
- **Add a section only when it carries information the reader cannot get elsewhere.** An empty section, an `N/A`, or an unused checklist is noise.
- **State facts.** No hedging, no salesmanship, no praise for the change.
- **Write for a human and an agent arriving cold.** Enough context to know what changed and why, in plain language.
- **Keep AI attribution out.** Generated-with footers, tool badges, and agent signatures belong in commit trailers if a repository wants them at all.

Do not write:

- **Problem / Cause / Solution essays.** They restate the linked issue or the design document.
- **Pasted command output or narrated verification runs.** Name the command under **Tests**; the run itself lives in CI.
- **"What I checked" tours.** Reviewers assume the work was checked; findings matter, process does not.
- **Revision history.** Never append "this PR has been extended" or corrections to earlier paragraphs. Rewrite the body to describe the current branch; the commits and comments already hold the history.

If the body cannot be trimmed to this size without losing something material, the PR is probably too large—see the splitting guidance in the skill.

## Relationship links

Put issue and stack relationships before **In plain terms**, one per line:

- **Closes** — complete resolution.
- **Advances** — partial delivery.
- **Related** — context without claimed progress.
- **Issue** — neutral association.
- **Depends on** — a parent PR that must land first.
- **Followed by** — a known child PR.
- **Mode** — **Contract** or **Implementation** in the normal two-level stack; **Boundary**, **Structure**, or **Implementation** in a three-level stack.
- **Implements** — an agreed boundary, structure, or combined contract PR implemented by this child.

Do not summarize the linked issue or contract. Only use closing automation when the PR genuinely resolves the whole issue.

## In plain terms

Write one short paragraph for non-engineers such as product managers, support, and leadership. It must summarize this PR rather than the issue.

- **Change first.** State what this PR now makes possible, fixes, or changes for people. The linked issue already explains the original problem.
- **Use 2–4 sentences.** A longer explanation usually belongs in the summary or indicates an overly broad PR.
- **Avoid jargon, files, and function names.** Product names and familiar terms are fine; internal identifiers are not.
- **State material trade-offs.** If the safe fix is slower, changes compatibility, or disables an optimization, say so.
- **Be honest about non-behavioral work.** Say “No behavior change” or “Display-only” when true.
- **For follow-ups, describe only the additional behavior.** Link the parent rather than retelling it.

## Summary

Explain this PR's delta at the level reviewers need:

- lead with behavior and meaningful design choices;
- include important scope boundaries, compatibility, rollout, or failure behavior;
- avoid narrating every file changed;
- avoid vague bullets such as “update code” or “fix bugs”;
- use two or three bullets for a small PR;
- do not oversell the change.

Prefer outcome-focused wording:

- Good: “Start refreshes quickly, then back off to the configured interval.”
- Bad: “Add `increasingRefreshInterval` and call `delay()`.”

## Boundary changes

Add this section only when the PR changes a durable external or user-facing boundary: database schema, gRPC/protobuf, REST, public SDK, UI journey, or CLI contract.

Use one succinct bullet per changed boundary. Describe the externally observable before → after behavior, compatibility classification, and migration or rollout consequence when material. Focus on what clients, users, persisted data, or downstream repositories must now rely on—not the internal classes or functions used to implement it.

```markdown
## Boundary changes
- **gRPC:** `WatchDevices` adds the optional `disconnected_reason` field as field 8; older clients continue to ignore it.
- **SDK:** `Device.events` is now an `AsyncSequence` rather than a callback registration API. Existing callers must migrate before the deprecated callback is removed.
- **UI:** Organization selection now requires an explicit confirmation before changing the active device list.
```

Do not add an empty “No boundary changes” section unless the repository template requires one.

## Agreed structure

Use this only in contract-first work when a human deliberately wants internal structure included in the review contract. Keep it separate from externally durable boundaries.

```markdown
## Agreed structure
- `DeviceView` owns rendering and user intent; `DeviceViewModel` owns loading and state transitions.
- The view model receives a `DeviceEvents` protocol rather than constructing transport dependencies.
- UI state remains main-actor isolated.
```

Include only selected high-leverage seams such as modules, type responsibilities, ownership, data flow, protocols, concurrency isolation, or test seams. Do not enumerate private helpers or predesign implementation detail merely to make the section look complete.

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
- Migration, compatibility, deployment, or rollback notes not already captured with a boundary change.

## Follow-ups
- Known work intentionally outside this PR.

## Try it
- Preview, experimental build, artifact, or reproducible local journey.

## Contract drift
- **Boundary:** `None`, or a link to the boundary update and renewed agreement.
- **Structure:** `None`, or a link to the structure update and renewed agreement.
```

Use **Try it** and **Contract drift** for contract-first implementation PRs. Omit them from ordinary PRs when they add no value. In a two-level stack, omit the **Structure** line when no internal structure was promoted into the contract.

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

### Trimming a bloated body

Before—an essay that restates the spec, proves its own work, and logs its own revisions:

```markdown
> **This pull request has been extended.** The first round built the program and
> proved adoption with an empty preview. A second round has since moved the
> service into the program. See the update at the bottom, which also corrects
> three statements below.

## Problem
The design spec calls for infrastructure as code, matching the earlier
precedent. The proof of concept deliberately shipped a shell script instead,
logged as chosen debt in the decision log...

## Cause
Speed, chosen knowingly. Decision log entry 3 records...

## Solution
### Verification: the preview is empty
    $ pulumi preview
    Resources: 10 unchanged

Read these two lines precisely, because they are the only two things in the run
that are not "unchanged"...
```

After—the same PR, current state only:

```markdown
- **Closes:** [PROJECT-201 Replace the bootstrap script with infrastructure as code](https://linear.app/example/issue/PROJECT-201/replace-the-bootstrap-script-with-infrastructure-as-code)

> **In plain terms:** The dev data stack is now described in code instead of a
> shell script, so changes to it are reviewable and repeatable. Nothing about
> the running stack changes.

## Summary
- Adopt the nine live dev resources by import rather than recreating them; a clean preview reports no changes.
- Mark the bucket, disk, and instance as protected so a future change cannot replace the stored data.
- Move the service and its least-privilege roles into the program.

## Tests
- `pulumi preview --refresh` (no creates, replaces, or deletes)
- `go build ./...`

## Follow-ups
- The live VM does not run the startup script the old bootstrap generated; reconciling that is separate work.
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
