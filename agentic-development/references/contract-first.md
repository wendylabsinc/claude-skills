# Contract-first development templates

Use these as concise starting points, not mandatory boilerplate. Remove sections that do not carry sourced decisions or useful evidence, and follow the repository's template when it differs.

## Orientation decision

```markdown
**Recommended mode:** Contract-first

**Why:** The public API and user journey affect multiple clients and can be agreed independently of the internal implementation.

**Durable boundaries:**
- Public SDK API
- gRPC contract
- User-visible device flow

**Experience path:** Per-PR experimental build on a test device.

**Next gate:** Authorize the draft contract PR. Implementation waits for explicit contract agreement and implementation authorization.
```

## Contract PR

```markdown
- **Advances:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)
- **Mode:** Contract
- **Followed by:** [#102 Implement the agreed contract](https://github.com/example/repository/pull/102)

> **In plain terms:** This defines the behavior and interfaces for human agreement. It does not implement them yet.

## Boundary changes
- **gRPC:** `WatchDevices` adds optional field 8, `disconnected_reason`; older clients ignore it.
- **SDK:** `Device.events` exposes an `AsyncSequence` while retaining the callback API as deprecated for one release.
- **UI:** Device details show the disconnect reason beside the current connection state.

## Experience contract
- Selecting a disconnected device shows its reason without leaving the details screen.
- Existing clients continue to receive the current connection state unchanged.

## Concrete specification
- Public declarations, protocol/schema diffs, help text, examples, screenshots, fixtures, or contract tests in this branch are authoritative.

## Deliberately omitted
- Runtime transport and storage implementation
- Private type and control-flow choices
- Performance optimizations that do not alter the contract

## Contract validation
- `command that verifies schemas, docs, examples, or compile-safe stubs`

## Open decisions
- Only genuinely unresolved boundary decisions requiring human input.
```

The issue link supplies the original problem; do not copy it into the contract PR. The actual boundary files, docs, examples, and tests—not only this body—form the specification.

## Implementation PR

```markdown
- **Closes:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)
- **Mode:** Implementation
- **Implements:** [#101 Define the agreed device-event contract](https://github.com/example/repository/pull/101)

> **In plain terms:** This makes the agreed device-event behavior available and provides an experimental build for trying it on a device.

## Summary
- Explain material implementation behavior or trade-offs without repeating the contract.

## Try it
- **Artifact/environment:** Exact build, URL, artifact, or command tied to this commit.
- **Journey:** The shortest steps a human follows to experience the result.
- **Expected:** Observable result.
- **Limitations:** Meaningful differences from production or incomplete preview capability.

## Boundary drift
- None.

## Tests
- `focused command`
- `full command or relevant CI workflow`
```

When drift exists, replace `None` with links to the contract diff and explicit renewed agreement. Do not explain a changed contract only in the implementation body.

## Integrated PR

```markdown
- **Closes:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)

> **In plain terms:** Describe the complete delivered outcome without repeating the issue.

## Summary
- Concise implementation and material trade-offs.

## Boundary changes
- Only durable externally observable changes, when present.

## Try it
- Include only when a preview or reproducible journey adds value.

## Tests
- Actual current validation.
```

Integrated mode does not need a **Mode** line unless the repository wants explicit classification.

## Contract agreement record

Record agreement in the contract PR with the exact commit:

```markdown
Contract agreed at `abc1234` by @reviewer on YYYY-MM-DD. Implementation may proceed under the previously granted authorization.
```

Do not claim authorization in this sentence unless it was actually granted. Otherwise record only the agreement and wait for implementation authorization.

## Boundary drift record

```markdown
Contract updated from `abc1234` to `def5678` because live validation showed that callers need to distinguish user cancellation from transport failure. The SDK error enum and CLI exit behavior changed accordingly. Renewed agreement: <decision link>.
```

Keep the record short; the linked diff remains authoritative.
