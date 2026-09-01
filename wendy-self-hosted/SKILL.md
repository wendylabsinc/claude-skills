---
name: wendy-self-hosted
description: 'The Wendy dual-path rule: the wendy stack must always run without the SaaS stack. MANDATORY when: (1) any feature integrates wendyos/wendy-agent with pki-core, cloud, or wendy-auth, (2) self-hosted, on-prem, or airgapped deployments, (3) deployment profiles or workload identity backends, (4) code that talks to GCP metadata, PSC, or Google JWKS, (5) degraded-mode or offline behavior, (6) making pki-core (or wendy-auth) self-hostable.'
references:
  - references/identity-backends.md
  - references/review-checklist.md
---

# Wendy Self-Hosted Rule

**The wendy stack (wendyos / wendy-agent) must ALWAYS be able to run without the SaaS stack.**

Every agent working on interop must keep the self-hosted path intact — or create it where it doesn't exist yet. A SaaS-only feature is an incomplete feature.

This is not a preference or a stretch goal. Wendy serves critical-infrastructure partners who will not — and in some cases legally cannot — run their fleet control loop through a vendor's multi-tenant cloud. If a change only works when `pki-core`, Wendy Cloud, or `wendy-auth` are the managed GCP services, it is not done.

## Scope

- **wendy-agent / wendyos — always.** The device fleet's core loop (enrollment, renewal, postbox polling, image pull) must work with zero SaaS reachability from the device's perspective beyond whatever the operator's own private infrastructure provides.
- **pki-core — must itself be self-hostable.** It is the trust root for both profiles; it cannot itself hard-depend on GCP.
- **wendy-auth — potentially later, but write for it now.** No path in wendy-auth service code should hard-assume GCP or SaaS reachability, even before a self-hosted wendy-auth ships. Retrofitting this later is far more expensive than not regressing it now.

## The Two Deployment Profiles

The contract treats self-hosted as a first-class deployment profile, not an afterthought — cite this when someone claims SaaS-only is fine (§11.1):

| | **Managed (GCP)** | **Self-hosted** |
|---|---|---|
| Network isolation | Private Service Connect endpoints inside a VPC Service Controls perimeter — no public IPs, no open-internet egress for control-plane RPCs | The operator's own private network / service mesh; no PSC/VPC-SC |
| Transport auth (fabric) | **v1 target: uniform GCP-WI-OIDC** across all fabric legs (Google-signed, audience-bound OIDC token, verified via Google's JWKS + a caller-service-account allowlist) | **mTLS carries the weight** — retained as the self-hosted backend (post-v1) (§6, §11.1) |

Either way, the invariant holds: authority is never transport-derived — the transport just says *which service* is calling; a principal's authority always rides as an in-message signed artifact.

## Never Assume

No service or device code path may hard-assume reachability of:

- The **GCP metadata server**
- **PSC (Private Service Connect) endpoints**
- **VPC-SC** (VPC Service Controls)
- **Google's JWKS** endpoint
- **Artifact Registry**
- **A reachable cloud control plane** at all

The contract's degraded-mode behaviors exist precisely for this last one — e.g. online enrollment is designed to survive the cloud being unreachable at redemption time (v0.12, §5.4), and device runtime behavior fails safe (hold state, alert) rather than treating cloud reachability as a precondition for correctness. If a design only works with a live cloud connection, it needs a fail-safe degraded mode, not a shrug.

Provider/backend selection is by **config**, never by a hard-wired issuer: no code path may assume a specific identity provider or trust root (D11).

## How to Add the Seam

When a feature needs a SaaS service (GCP metadata, PSC, a Google-issued token, cloud reachability, etc.), don't wire the SaaS backend in directly. Instead:

1. **Define the interface** the feature actually needs (e.g. "give me a verifiable service identity," not "call the GCP metadata server").
2. **Make the managed (GCP) implementation one backend** behind that interface — not the only path.
3. **Provide the self-hosted backend** — or, if it isn't built yet, **stub it behind the seam with a tracked issue**. The seam existing and being selected by config is what matters; the self-hosted backend can land later, but the interface must not assume GCP going in.
4. **Select the backend by config**, handing peers the matching trust bundle. No environment-sniffing, no "it's probably GCP" defaults baked into call sites.

Use the **D11 pluggable-identity-provider pattern** as the reference shape for this: see `references/identity-backends.md` for how the mesh workload-identity lifecycle implements exactly this seam with three interchangeable backends.

## Source of Truth

This skill distills the **AAA Contract v0.12** (draft, pending engineering approval).
The living contract lives in Linear: [AAA Contract — Authentication, Authorization, Accounting](https://linear.app/wendylabsinc/document/aaa-contract-authentication-authorization-accounting-v012-dff5a8351650).
It is versioned and evolving: check it for flow-level detail, and if it disagrees with this skill, **the contract wins** — then update this skill.

## Related Skills

- **wendy-aaa-interop** — the responsibility split and two-key authority this rule protects.
- **wendy-certificates** — requesting and holding certificates; each backend here has to work.
- **wendy-device-enrollment** — device lifecycle; online/offline enrollment both keep degraded mode.
- **wendy-device-interop** — agent runtime behavior; the fail-safe catalogue this rule requires.
- **wendy-security-baselines** — invariants any interop PR must respect, alongside this one.

Each of those skills carries a mandatory pointer back to this one — if you're touching interop code from any of them, this rule applies.
