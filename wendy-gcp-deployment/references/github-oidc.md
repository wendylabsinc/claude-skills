# GitHub Actions → GCP via OIDC (Workload Identity Federation)

Mandatory for all CI deploys. There is no service-account-key path — `credentials_json`, `gcloud iam service-accounts keys create`, and JSON keys in repo secrets are forbidden, including "temporarily".

## Two modes (per google-github-actions/auth README)

- **Direct WIF (preferred, Google's current recommendation):** the workload identity pool principal gets IAM bindings directly on resources; no intermediate service account exists at all. Configure `auth` with `project_id` + `workload_identity_provider` only.
- **SA impersonation:** add `service_account:`. Use only where an API rejects federated principals (some do — Cloud DNS zone-level policies are a suspect; test during bootstrap).

## Bootstrap (once per repo, via the human's gcloud — see iam-polp.md)

```bash
gcloud iam workload-identity-pools create github \
  --project=<project> --location=global

gcloud iam workload-identity-pools providers create-oidc github-actions \
  --project=<project> --location=global --workload-identity-pool=github \
  --issuer-uri="https://token.actions.githubusercontent.com/" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository == '<org>/<repo>'"
```

**The attribute condition is required, not optional** — GitHub is a shared issuer across all of github.com; without the condition, any repo on GitHub whose claims you map could try to enter the pool. Scope it to the exact repo (tighten further with `assertion.ref` for prod-only pools if wanted).

Bindings then go to:

```
principalSet://iam.googleapis.com/projects/<num>/locations/global/workloadIdentityPools/github/attribute.repository/<org>/<repo>
```

## Workflow side

```yaml
permissions:
  contents: read
  id-token: write   # required for OIDC

steps:
  - uses: google-github-actions/auth@v3   # v3 verified latest 2026-07 — re-verify when authoring
    with:
      project_id: <project>
      workload_identity_provider: projects/<num>/locations/global/workloadIdentityPools/github/providers/github-actions
```

For Pulumi state on GCS and gcpkms secrets, this same auth provides Application Default Credentials — nothing extra needed.

Version note: verify current action versions at authoring time (see the `github-actions` skill) — the tags above were verified 2026-07 and will age.

## dev/prod in the workflow

- Push to default branch → deploy `dev` stack.
- Semver tag `v*` → deploy `prod` stack.
- One WIF binding per repo is fine for both; if prod needs stronger control, a second pool/provider with `assertion.ref == 'refs/tags/...'`-style conditions is the mechanism.
