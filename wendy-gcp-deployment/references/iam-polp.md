# IAM — Principle of Least Privilege

Every app gets its own deploy identity with the smallest permission set that makes its `pulumi up` succeed. Broad predefined roles (`roles/run.admin`, `roles/cloudsql.admin`, `roles/secretmanager.admin`, `roles/dns.admin`, any `*.admin`) are not the floor — the exact permission list is.

## The recipe

1. **List what the stack actually manages.** From the Pulumi program: which resource types are created/updated/read?
2. **Derive the exact permissions.** Check the GCP docs for the permissions each operation needs (don't guess from memory — permission strings change). E.g. deploying a Cloud Run revision needs `run.services.get/update`, not all of `run.*`.
3. **Create a custom role per app** (or per app+concern when one app spans projects):

```bash
gcloud iam roles create wendyStatusDeploy \
  --project=wendy-customer \
  --title="wendy-status deploy" \
  --permissions=run.services.get,run.services.update,run.revisions.get,... \
  --stage=GA
```

4. **Bind it as narrowly as the resource supports**: resource-level IAM (a zone, a secret, a bucket, a KMS key, a service account) beats project-level. Add IAM conditions where the service supports them (DNS record sets do — see `dns.md`).
5. **Iterate by failure, not by inflation.** When `pulumi up` fails with a missing permission, add that one permission to the custom role. Never "fix" a permission error by swapping in a predefined admin role.

## Standard identities per app

- **Deploy identity** — used by CI via WIF (see `github-oidc.md`). Prefer **Direct WIF** (the `principalSet://` from the workload identity pool gets the IAM bindings directly — no service account at all). Where an API rejects federated principals, fall back to a dedicated deploy SA + impersonation.
- **Runtime SA** — one per app (`<app>-run@...`), attached to the Cloud Run service/VM. Gets only what the app needs at runtime (e.g. `roles/cloudsql.client`, `secretmanager.secretAccessor` **on the specific secret**). Never the default compute SA.
- `roles/iam.serviceAccountUser` for the deployer is granted **on the runtime SA resource**, never project-wide.

Per-app isolation in `wendy-customer` is deliberate: one app's deploy identity must not be able to touch another app's resources.

## Known-good narrow grants

| Need | Grant |
|---|---|
| Push images | `roles/artifactregistry.writer` on the specific repository |
| Read one secret at runtime | `roles/secretmanager.secretAccessor` on that secret |
| Pulumi state | `roles/storage.objectAdmin` on the state bucket only |
| Pulumi secrets (gcpkms) | `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the specific CryptoKey (lowest grantable level) |
| Deploy acting as runtime SA | `roles/iam.serviceAccountUser` on that SA |
| DNS records | custom role + per-RRset condition — see `dns.md` |

## Bootstrap flow (privileged setup)

Creating custom roles, SAs, WIF pools/bindings requires privileges the deploy identity must never hold. Flow:

1. Do it via **the human's own gcloud credentials**, locally, with the user approving each privileged command. Enable required APIs here too (`gcloud services enable ...`) — the pipeline never gets `serviceusage` permissions.
2. **If the human lacks permissions**, don't escalate creatively. Produce an admin handoff:

```markdown
## IAM bootstrap request: <app>
**Use case:** <one paragraph: what the app is, where it deploys, what CI needs to manage>
**Requested by:** <human> for repo <org/repo>
**Commands** (run by someone with iam.roles.create / iam.serviceAccounts.create / WIF admin):
<the exact gcloud commands, ready to paste>
**Resulting blast radius:** <what this identity can and cannot touch>
```

## Self-check before finishing any IAM design

- Does any binding contain `*.admin`? Justify it or replace it.
- Is every grant on the narrowest resource the service supports?
- Could this app's deploy identity affect a sibling app? If yes in `wendy-customer`, redesign.
