# Pulumi conventions

- **Language: Go preferred.** Other languages acceptable when there's a reason (existing codebase, team familiarity) — say the reason.
- **State backend: GCS.** `pulumi login gs://<state-bucket>` — uses Application Default Credentials. One bucket per project (or per team), deploy identity gets `roles/storage.objectAdmin` on that bucket only.
- **Secrets provider: gcpkms**, never passphrase:

```bash
pulumi stack init dev \
  --secrets-provider="gcpkms://projects/<project>/locations/<loc>/keyRings/<ring>/cryptoKeys/<key>"
```

Key purpose must be `ENCRYPT_DECRYPT`; deploy identity needs `roles/cloudkms.cryptoKeyEncrypterDecrypter` on that CryptoKey. Existing stacks migrate with `pulumi stack change-secrets-provider`.

- **Runtime app secrets** live in Secret Manager (created by Pulumi, read by the runtime SA) — Pulumi config secrets are for deploy-time values only.

## Stacks & naming

- Two stacks per app: `dev` and `prod`. Same GCP project (for now), split by naming: every resource name carries the stack, e.g. `wendy-status-dev`. Use `ctx.Stack()` in names rather than hardcoding.
- Config per stack (`Pulumi.dev.yaml` / `Pulumi.prod.yaml`): image tag, sizing, min-instances. Prod and dev must differ only by config, never by code paths.
- Image tags: dev deploys `sha-<short>`, prod deploys the semver tag — prod is always traceable to a release.

## Safety rules

- **Never clash with pre-existing resources.** Before `pulumi up` on a new stack in a shared project, list what already exists (especially DNS — see `dns.md`, and anything named similarly in `wendy-customer`). If a resource already exists outside the stack, surface it — adopt via `pulumi import` only when the user confirms the stack should own it.
- **Stateful resources get protection:** `pulumi.Protect(true)` and provider-level deletion protection (e.g. `DeletionProtection: true` on Cloud SQL) on databases, buckets with data, and anything holding state. A `pulumi destroy` of a dev stack must never be able to take customer data with it.
- `pulumi preview` runs on PRs; `pulumi up` only from the deploy workflow (default branch → dev, tag → prod). No `up` from laptops against prod except during initial bootstrap.

## CI integration

Use `pulumi/actions` (verify current version at authoring time — v7 as of 2026-07; there is also `pulumi/auth-actions` for Pulumi Cloud OIDC, not needed with the GCS backend). Env for GCS backend: `PULUMI_BACKEND_URL: gs://<bucket>` avoids a login step. The google-github-actions/auth step (see `github-oidc.md`) supplies ADC for state, KMS, and the GCP provider in one go.
