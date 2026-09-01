---
name: agentic-development
description: "Guide AI-led software delivery through integrated or contract-first development. Use when choosing how humans and agents should collaborate on implementation; creating a specification or stub PR; separating durable contracts from replaceable implementation; waiting for human contract approval; implementing autonomously behind an agreed boundary; producing preview builds or live experiences; or handling boundary drift between a contract PR and its implementation PR."
---

# Agentic Development

## Goal

Spend human attention where it has the greatest leverage: durable product and technical boundaries, user experience, material trade-offs, and irreversible risk. Let agents and automation carry more of the replaceable implementation work while preserving evidence, security, and the ability for humans to inspect anything.

Load the `pull-request` skill for PR mechanics, descriptions, stacking, CI, feedback, history, and merge readiness. This skill governs how development is staged and where human agreement is required.

## Core principles

- The issue owns the problem.
- The contract owns the durable behavior and boundaries.
- The implementation owns the replaceable mechanics behind that contract.
- A runnable experience tests whether the contract is actually useful.
- Automation reviews implementation deeply; “compiled” or opaque never means unchecked.
- Any implementation discovery that changes the contract returns to human review.

## Choose a mode during orientation

Use one of two modes explicitly.

### Integrated mode

One PR contains contract and implementation. This is the default when:

- the change is small or straightforward;
- contract and implementation must be discovered together;
- splitting would add more review or merge risk than it removes;
- the work is urgent;
- security, destructive migration, or irreversible operational behavior dominates the change;
- no meaningful stub or preview can represent the intended experience.

Humans and agents review the same PR normally, with extra attention to durable boundaries.

### Contract-first mode

Use a two-PR stack when:

- durable boundaries can be meaningfully agreed before implementation;
- several clients, repositories, or teams depend on the contract;
- user-facing UI or CLI behavior benefits from early human iteration;
- implementation is substantial but mostly replaceable behind the boundary;
- a preview, experimental build, artifact, or reproducible journey can validate the result;
- separating contract review will make the eventual implementation easier to evaluate.

Do not use contract-first mode merely because the implementation is large. A bad split creates ceremony without moving important decisions earlier.

During orientation, state the recommended mode, why it fits, the durable boundaries involved, how humans will experience the result, and the next authorization gate.

## Authorization gates

Treat these as separate gates:

1. Authorize contract exploration and the draft contract PR.
2. Agree to the contract.
3. Authorize implementation, unless that authority was explicitly bundled with contract agreement.
4. Authorize marking ready, merging, and deployment according to project policy.

Silence, inactivity, passing CI, or ordinary review comments do not constitute contract agreement. Record explicit human agreement in the contract PR or linked decision record.

If implementation authorization was granted in advance, the agent may begin after explicit contract agreement without asking a redundant question, but the prior authorization must be cited clearly.

## Integrated workflow

1. Reconcile the issue, repository conventions, current behavior, and durable boundaries.
2. Present a KISS-first approach, trade-offs, validation, and authorization needs.
3. Implement within the approved scope.
4. Open and maintain one PR using the `pull-request` skill.
5. Provide a runnable experience when useful and available.
6. Address CI and all feedback, then wait for the normal ready and merge gates.

## Contract-first workflow

### Stage 1: Draft the contract

Create a draft contract PR containing the smallest faithful, reviewable expression of the intended behavior:

- database schema and migration shape;
- gRPC/protobuf, REST, or other external protocol definitions;
- public SDK signatures, documentation, examples, errors, and compatibility intent;
- CLI commands, flags, help, output, exit behavior, and examples;
- user-visible UI journeys, wording, state, accessibility, screenshots, or prototypes;
- cross-repository consumer relationships;
- fixtures, snapshots, usage examples, or executable contract tests where they clarify behavior;
- the minimum compile-safe stubs required to make the contract concrete.

Keep stubs inert, unreachable, mocked, or feature-gated. Do not accidentally expose unfinished behavior. A contract PR may remain draft while incomplete, but it must not be presented as ready with broken builds, failing placeholders, or production-visible nonfunctional APIs.

Exclude private architecture, helper types, storage mechanics, control flow, and optimization choices unless they constrain the durable contract or create material risk.

Use the contract PR template in [references/contract-first.md](references/contract-first.md).

### Stage 2: Iterate with humans

Focus discussion on:

- what users and clients can observe;
- before → after behavior;
- compatibility and deprecation;
- data migration, rollout, and rollback;
- terminology, examples, and error semantics;
- the user journey and how it will be experienced;
- decisions that become costly after release.

Keep unresolved decisions explicit. Update the actual stubs, docs, examples, and tests as agreement changes; do not let the PR description become a substitute for the contract diff.

Before implementation, record explicit agreement and identify the exact contract commit that was agreed.

### Stage 3: Implement behind the contract

Create the implementation branch from the agreed contract branch. Link it as an implementation PR and describe only its delta, evidence, material trade-offs, and experience path.

Within the agreed boundary, agents may choose simple internal designs, iterate, refactor, and fix implementation defects without requesting human review of every replaceable choice. They must still:

- follow repository and architecture constraints;
- keep commits and authorship honest;
- run focused and full validation as appropriate;
- watch CI and address all human and automated feedback;
- use automated security, correctness, compatibility, and code review deeply;
- update the PR description after every push;
- preserve the agreed contract unless boundary drift is handled explicitly.

Do not optimize for making implementation code look opaque. Optimize for making it trustworthy through tests, review, observability, and an experience humans can validate.

### Stage 4: Make it experiential

Give humans the shortest safe path to experience the implemented behavior:

- a per-PR mobile or desktop build;
- an isolated web or service preview;
- a downloadable CLI or SDK artifact;
- a local container or reproducible command;
- a device deployment;
- screenshots, video, or recorded output when interaction is not yet possible.

The implementation PR includes a concise **Try it** section with the artifact or environment, steps, expected behavior, and material limitations. Never expose credentials or production data. State honestly when no live preview capability exists and provide the best available substitute.

Live experience complements rather than replaces automated tests, security review, compatibility checks, and migration validation.

### Stage 5: Handle boundary drift

If implementation or live experience reveals a contract flaw:

1. Stop treating the implementation PR as ready.
2. Update the contract PR's stubs, docs, examples, tests, and **Boundary changes**.
3. Explain why the boundary changed and which consumers are affected.
4. Obtain renewed human agreement on the new contract commit.
5. Reconcile the implementation branch and update **Boundary drift** with the decision link.

Do not hide contract changes in implementation commits or describe drift as an internal refactor.

### Stage 6: Ready and merge

Before either PR is ready:

- the contract reflects the agreed user and client behavior;
- the implementation conforms to that exact contract or records approved drift;
- previews and validation reflect current commits;
- CI and feedback satisfy the `pull-request` ready gates;
- the contract PR is safe to land before the implementation, usually through inert stubs or feature gating.

Merge the contract first and the implementation second. Prefer merge commits so the contract and implementation histories, authors, and review boundaries remain visible. Do not leave the default branch broken or expose unfinished behavior between merges.

## Evidence-led implementation review

Humans may inspect any implementation code. Human implementation review remains expected when internal choices carry durable or irreversible risk, including:

- authentication, authorization, cryptography, and credentials;
- destructive data operations or irreversible migrations;
- privacy, billing, compliance, and tenancy isolation;
- concurrency, memory safety, and resource exhaustion;
- supply-chain, deployment, IAM, and production security;
- behavior whose failure cannot be repaired safely after release.

For lower-risk replaceable mechanics, human review can focus on contract conformance and live behavior while agents, CI, tests, scanners, and automated reviewers inspect the implementation in depth. Invalid automated findings still require narrow, evidence-backed resolution rather than being ignored.

## Project preview capability

Projects should progressively make implementation PRs easy to experience. A good preview mechanism provides:

- an artifact or isolated environment tied to the exact commit;
- safe configuration, authentication, and test data;
- a link or command surfaced in the PR;
- logs and diagnostics sufficient to investigate feedback;
- lifecycle cleanup or expiration;
- clear limitations compared with production.

Preview infrastructure is an enabling capability, not a prerequisite for every contract-first stack. Never claim a live experience that the project cannot currently provide.

## Failure modes

Avoid:

- using contract-first mode for changes too small to benefit;
- putting implementation architecture into the contract PR;
- merging stubs that expose nonfunctional production behavior;
- treating lack of feedback as contract approval;
- beginning implementation without the required authorization;
- silently changing boundaries in the implementation PR;
- treating “opaque” implementation as exempt from review or security;
- offering a stale preview built from a different commit;
- merging the contract into a broken interval before its child;
- squashing away the distinction or contributor history between stages.
