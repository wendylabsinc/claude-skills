# Contract-first development templates

Use these as concise starting points, not mandatory boilerplate. Remove sections that do not carry sourced decisions or useful evidence, and follow the repository's template when it differs.

The contract is the code diff at an exact commit. PR prose only indexes and explains declarations, stubs, mocks, fixtures, previews, and tests that reviewers can inspect. A document or description without concrete contract code is not a contract-first PR.

Use the final intended production file layout and ordinary type names from the start. The review layer should look like the finished program with method bodies and replaceable private helpers omitted. Do not create `*Contract`, `*Structure`, `*Proposal`, `*Spec`, or `*Stub` source files or a monolithic review-only container that the implementation will later delete or split. Normal mocks, fixtures, previews, and tests may live in their standard support locations.

## Local iteration before publication

Stages 1–2 are a rapid local loop by default:

```text
edit contract code → focused validation → small local commit → refresh experience → human feedback → repeat
```

Commit each coherent iteration locally so changes stay isolated and recoverable. Do not push, create or edit the remote PR, start remote CI, or wait for checks between tweaks. Feedback on the local experience is not publication authorization. When the human explicitly asks to checkpoint or publish, push the accumulated local commits without squashing or rewriting them by default, update the draft PR, and reconcile CI before requesting agreement on that exact commit. If iteration resumes, return to the local loop until the next explicit publication request.

## Orientation decision

```markdown
**Recommended mode:** Contract-first

**Why:** The public API and user journey affect multiple clients and can be agreed independently of the internal implementation.

**Durable boundaries:**
- Public SDK API
- gRPC contract
- User-visible device flow

**Potential structure review:** View/view-model responsibilities may be worth adding during human iteration; start with the boundary draft before deciding whether they need a separate PR.

**Experience path:** Per-PR experimental build on a test device.

**Next gate:** Authorize local boundary exploration. Publishing the draft contract checkpoint, agreeing its exact commit, and implementation remain separate gates.
```

## Contract PR

Use this only after the human authorizes publishing a checkpoint.

```markdown
- **Advances:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)
- **Mode:** Contract
- **Followed by:** [#102 Implement the agreed contract](https://github.com/example/repository/pull/102)

> **In plain terms:** This proposes the behavior and interfaces for human agreement. Humans may add selected structural constraints before implementation begins.

## Boundary changes
- **gRPC:** `WatchDevices` adds optional field 8, `disconnected_reason`; older clients ignore it.
- **SDK:** `Device.events` exposes an `AsyncSequence` while retaining the callback API as deprecated for one release.
- **UI:** Device details show the disconnect reason beside the current connection state.

## Contract code
- `api/device_events.proto` defines the wire contract.
- `DeviceEvents.swift` defines the SDK declarations and mock.
- `DeviceDetailView.swift` and `DeviceViewModel.swift` define the view, state, and intentional implementation holes.
- Contract tests and previews make the expected journey executable or inspectable.

## Agreed structure
- Summarize only internal structure deliberately promoted during human iteration; the corresponding module, type, protocol, view/view-model, mock, or test stubs in the diff are authoritative.

## Deliberately unimplemented
- Runtime transport and storage method bodies
- Private details not deliberately included in **Agreed structure**
- Performance optimizations that do not alter the contract

## Contract validation
- `command that type-checks declarations, builds stubs, verifies schemas, and exercises mocks/previews/contract tests`

## Open decisions
- Only genuinely unresolved boundary decisions requiring human input.
```

The issue link supplies the original problem; do not copy it into the contract PR. The actual declarations, stubs, mocks, fixtures, previews, and tests form the contract. Documentation accompanies them but never substitutes for them. Omit **Agreed structure** from the initial agent draft when no structure has been selected; add it as humans promote concrete code into the agreement.

## Optional structure PR

Use this only when structural exploration is substantial enough to deserve a separate agreement gate:

```markdown
- **Advances:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)
- **Mode:** Structure
- **Depends on:** [#101 Agree the device-event boundaries](https://github.com/example/repository/pull/101)
- **Followed by:** [#103 Implement the agreed design](https://github.com/example/repository/pull/103)

> **In plain terms:** This proposes the internal shape humans will maintain without filling in the runtime implementation.

## Structure code
- `DeviceView.swift` stubs rendering and user intents.
- `DeviceViewModel.swift` defines state ownership and main-actor isolation with empty behavior bodies.
- `DeviceEvents.swift` defines the protocol plus a mock used by previews and tests.

## Agreed structure
- `DeviceView` renders state and emits user intent.
- `DeviceViewModel` owns loading and state transitions on the main actor.
- A `DeviceEvents` protocol provides the test and transport seam.

## Deliberately unimplemented
- Concrete transport adapter
- Retry and buffering mechanics
- Private helpers and optimizations

## Structure validation
- `command that type-checks the real declarations, dependency direction, mocks, previews, and stubs`

## Open decisions
- Only unresolved structural decisions requiring human input.
```

The **Agreed structure** prose indexes the concrete structure code; it does not replace it. Each listed source file and declaration should be the actual production skeleton that the implementation child will retain and fill in. The structure PR must not redesign agreed boundaries. If it needs to, update and re-agree the boundary code first.

## Implementation PR

```markdown
- **Closes:** [PROJECT-123 Problem title](https://linear.app/example/issue/PROJECT-123/problem-title)
- **Mode:** Implementation
- **Depends on:** [#102 Agree the view and view-model structure](https://github.com/example/repository/pull/102)
- **Implements:** [#101 Agree the device-event boundaries](https://github.com/example/repository/pull/101)
- **Implements:** [#102 Agree the view and view-model structure](https://github.com/example/repository/pull/102)

> **In plain terms:** This makes the agreed device-event behavior available and provides an experimental build for trying it on a device.

## Summary
- Explain material implementation behavior or trade-offs without repeating the contract.

## Try it
- **Artifact/environment:** Exact build, URL, artifact, or command tied to this commit.
- **Journey:** The shortest steps a human follows to experience the result.
- **Expected:** Observable result.
- **Limitations:** Meaningful differences from production or incomplete preview capability.

## Contract drift
- **Boundary:** None.
- **Structure:** None.

## Tests
- `focused command`
- `full command or relevant CI workflow`
```

Point **Depends on** to the implementation branch's immediate parent. In a two-level stack, point it to the combined contract PR and omit the second **Implements** link and **Structure** drift line when no separate or promoted structure exists. When drift exists, replace `None` with links to the owning contract diff and explicit renewed agreement. Do not explain a changed contract only in the implementation body.

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

Record agreement for each applicable layer at its exact commit:

```markdown
Boundary agreed at `abc1234` by @reviewer on YYYY-MM-DD.
Structure agreed at `def5678` by @reviewer on YYYY-MM-DD.
Implementation may proceed under the previously granted authorization.
```

Omit the structure line when it does not apply. Do not claim authorization in this record unless it was actually granted. Otherwise record only the agreements and wait for implementation authorization.

## Contract drift record

```markdown
Boundary updated from `abc1234` to `abc5678` because live validation showed that callers need to distinguish user cancellation from transport failure. The SDK error enum and CLI exit behavior changed accordingly. Renewed agreement: <decision link>.

Structure updated from `def5678` to `def9012` because the agreed view model otherwise owned a transport lifecycle that must outlive the screen. Renewed agreement: <decision link>.
```

Keep the record short; the linked diff remains authoritative.
