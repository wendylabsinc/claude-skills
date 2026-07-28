---
name: wendy-gcp-deployment
description: 'Expert guidance on deploying Wendy applications and infrastructure to Google Cloud. Use when: (1) deploying anything to GCP, (2) writing or changing Pulumi programs, (3) creating GCP service accounts, IAM roles, or custom roles, (4) touching wendy.sh / wendy.dev DNS records, (5) choosing GCP compute or databases, (6) setting up CI/CD deployment to GCP, (7) provisioning Cloud Run, Cloud SQL, or Artifact Registry.'
references:
  - references/cost.md
  - references/iam-polp.md
  - references/dns.md
  - references/github-oidc.md
  - references/pulumi.md
---

# Wendy GCP Deployment

How Wendy deploys to Google Cloud. **Status: intermediate.** These conventions hold until v1 of the stack runs and the compute workload is consolidated (possibly k8s/GitOps later). The methodology (Pulumi, OIDC, PoLP) is expected to survive that transition; specific names may not.

## Hard rules (non-negotiable)

1. **Requirements before infrastructure.** Never design infra without asking the user about the app's requirements first (see interview below). Never invent project names, regions, or scale assumptions.
2. **Cost-consciousness is a MUST**, not a preference. Read `references/cost.md` before choosing compute or a database.
3. **PoLP via custom IAM roles.** Prefer a custom role with the exact permissions needed over any predefined broad role. Needing to alter one DNS record never justifies `roles/dns.admin`. See `references/iam-polp.md`.
4. **No service account keys. Ever.** CI authenticates via GitHub OIDC / Workload Identity Federation (`references/github-oidc.md`); workloads use attached service accounts. If you are about to write `credentials_json`, export a key, or suggest one "as a stopgap" — stop; that path does not exist here.
5. **No GCP credentials client-side.** Frontends, device apps, anything running outside Wendy's server perimeter never holds GCP credentials of any form. Devices get mediated access via server-side proxies minting short-lived downscoped credentials (wendy-proxy pattern). Authority: the AAA contract, `/home/sem/wendy/aaa-contract-*.md` (read the latest version when touching auth between services).
6. **dev/prod split by default.** Default branch deploys to dev; semver tags (`v*`) deploy to prod. Skip the split only with a stated good reason. Both live in the same GCP project for now, split by resource naming (`-dev` / `-prod` suffixes).
7. **Never clash with pre-existing resources.** Check before creating — especially DNS records (`references/dns.md`) and anything in shared projects.

## Requirements interview (always first)

Before proposing any design, ask the user (don't assume):

- Traffic shape and volume; public or internal?
- State: does it truly need a database? What kind/size?
- Latency and availability requirements (is scale-to-zero cold start acceptable?)
- Which project does it belong in (see map below)? Dev/prod needed?
- Anything that must survive redeploys (volumes, IPs, data)?

Shape the design to the answers. When requirements are modest, the infrastructure must be too.

## Project map (current truth — verify with `gcloud projects list` if in doubt)

| Project | Purpose |
|---|---|
| `wendy-customer` | All customer-facing apps (apps not part of the cloud stack). Per-app isolation inside this project matters: own SA, own custom role, own resources per app. |
| `wendy-auth` | wendy-auth |
| `wendy-pki-secure` | pki-core engine |
| `wendy-pki-services` | pki-core frontends |
| `cloud-c7e56` | SaaS cloud stack; hosts the `*.wendy.sh` and `*.wendy.dev` DNS zones |

Default region: **`us-central1`** (current home; movable given a real use case — ask, don't switch unilaterally).

## Compute selection

- **Cloud Run first.** Scale-to-zero, request-based billing, no OS to maintain. Default for services and jobs.
- **VMs are leaned against**, for one specific reason: once spun up, nobody maintains the OS. A VM is acceptable **only** if the OS is completely maintenance-free (e.g. Container-Optimized OS with automated updates, MIGs with automated image rotation). If the plan involves a human ever SSHing in to patch it, it's not an option.
- **Databases:** the cheapest thing that meets requirements. Read `references/cost.md` — it exists because of a real incident (expensive Cloud SQL clusters provisioned for apps that didn't need them).

## Deployment workflow

1. Requirements interview (above).
2. Design: compute, data, IAM (custom roles per `references/iam-polp.md`), DNS (`references/dns.md`), dev/prod stacks.
3. Bootstrap privileged resources (deploy SA, custom role, WIF binding) via the human's own gcloud, with their approval per command. If the human lacks permission: produce the exact commands + a use-case writeup to hand to an admin (template in `references/iam-polp.md`).
4. Pulumi program — Go preferred, GCS state backend, KMS secrets provider, conventions in `references/pulumi.md`.
5. GitHub Actions workflow — OIDC only, per `references/github-oidc.md`. Also invoke the `github-actions` skill when writing the workflow.

## Rationalizations that don't fly

| Excuse | Reality |
|---|---|
| "roles/dns.admin scoped to the zone is minimal enough" | Cloud DNS supports per-RRset IAM conditions. Zone-wide admin is not the floor; the exact records are. |
| "A predefined role is simpler than a custom role" | Simpler to type, larger to breach. Custom roles are a one-time cost; see the recipe. |
| "credentials_json just to get it working" | A leaked key is a standing credential. WIF setup takes minutes; there is no keys-temporarily path. |
| "It'll need Cloud SQL HA when it grows" | Provision for today's requirements. Growth is a config change, not a sunk cost. |
| "Skipping dev, it's a small app" | Small apps get semver-tagged prod deploys too. Skipping the split is a decision the user makes, with a reason. |
| "The zone probably has no record with this name" | `gcloud dns record-sets list` takes two seconds. Check. |

## Red flags — stop and reconsider

- You wrote `roles/*.admin` for a deploy SA
- You wrote `credentials_json` or `gcloud iam service-accounts keys create`
- A GCP credential (of any form) ends up in frontend code, a device image, or an app config shipped outside Wendy's servers
- You picked a region, tier, or project name the user never confirmed
- Your design has no `-dev` stack and the user never said why
- You're about to create a DNS record without listing existing ones first
