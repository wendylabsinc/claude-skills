---
name: github-actions
description: 'Expert guidance on writing GitHub Actions workflows. Use when: (1) writing or editing any file under .github/workflows/, (2) choosing between an existing action and a shell script in CI, (3) picking action versions, (4) configuring workflow permissions or cloud authentication from CI, (5) reviewing a workflow in a PR.'
---

# GitHub Actions

Applies to every workflow — deploys, tests, releases, anything under `.github/workflows/`.

## Rule 1: Prefer established actions over hand-rolled scripts

If a mature, maintained action covers the use case, use it. Hand-roll only when no action covers the case — and say so in the PR. Checking out code, docker login/build/push, cloud auth, uploading artifacts, releases: all covered by first-party or vendor actions (`actions/*`, `docker/*`, `google-github-actions/*`, `pulumi/*`).

Maturity check for third-party actions: maintained (recent releases), widely used, ideally from the vendor of the tool. Obscure single-maintainer actions holding credentials are worse than a script.

## Rule 2: Verify versions at authoring time — never from memory

Your memory of "the current major" is stale. Proof, from a real baseline test (2026-07): a model confidently pinned `actions/checkout@v4` and `google-github-actions/auth@v2` as "current majors" — the actual latest were **v7** and **v3**. Every version you remember is a version to verify.

The check takes seconds per action:

```bash
gh api repos/actions/checkout/releases/latest --jq .tag_name
```

(or the releases page / marketplace). Do this for **every** action in the workflow you're writing, at the moment you're writing it. Writing a version without having run the check this session is the violation — "it was current last month" doesn't count.

Pin by major tag (`@v7`) normally; pin by commit SHA when supply-chain hygiene demands it (workflows with credentials touching prod).

## Rule 3: Least privilege

- Explicit `permissions:` block on every job: start from `contents: read`, add only what's needed (e.g. `id-token: write` for OIDC).
- Cloud auth via OIDC federation only — no long-lived cloud secrets in GitHub. For GCP specifically, the wendy-gcp-deployment skill (`references/github-oidc.md`) is the authority; `credentials_json` / SA keys are forbidden, including as a fallback or stopgap.
- Secrets that must exist in GitHub (e.g. a token for a SaaS with no OIDC) get environment-level scoping, not repo-wide, when environments are in play.

## Quick checklist for any new workflow

- [ ] Every step that could be an established action is one
- [ ] Every action version verified this session (`gh api .../releases/latest`)
- [ ] `permissions:` block present and minimal
- [ ] Cloud auth is OIDC; no `credentials_json`, no key JSON in secrets
- [ ] `concurrency:` group on deploy workflows (one deploy per ref at a time)
- [ ] Deploy trigger split: default branch → dev, semver tags (`v*`) → prod

## Rationalizations that don't fly

| Excuse | Reality |
|---|---|
| "v4 is what I've always used" | That's the definition of answering from memory. Run the check. |
| "The major version barely matters" | Old majors lose runner compatibility and security fixes; some are deprecated outright. |
| "I'll leave a TODO to bump versions" | The TODO ships. Verify now — it's one command per action. |
| "A curl in a run: block is simpler than learning the action" | The action handles auth, retries, and edge cases the curl doesn't. Simpler today, pager duty later. |
| "credentials_json just until WIF is set up" | Keys outlive intentions. WIF bootstrap takes minutes; do it first. |
