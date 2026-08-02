# Workload-Identity Lifecycle — Bootstrap & Renewal (§11.4, D11)

The inter-service fabric requires every service to have a verifiable identity before it can talk to another service (§11.1). §11.4 solves the chicken-and-egg problem — a freshly-deployed instance can't call `pki-core` for a cert using a cert it doesn't yet have — with a **pluggable identity provider** rather than one hard-wired mechanism, so the same contract serves both the managed SaaS and self-hosted deployments.

## The Invariant (holds across every backend)

- The provider yields a **short-lived, auto-renewed, SPIFFE-style identity** that names the service.
- Peers validate that identity against a configured **trust bundle**.
- **Transport identity never conveys principal authority** — that always rides as an in-message signed artifact (wendy-auth token, operator signature, cloud grant, TSA token, SET).

Because of that last point, **the transport trust root does not have to be `pki-core`.** It only has to reliably say *which service* is calling. This is what makes backend 3 (bring-your-own PKI) safe for self-hosted operators who don't want Wendy in their trust chain at all.

## Backend 1 — GCP Workload Identity (managed default)

Every GCP workload already holds a **Google-signed, zero-secret, platform-attested** identity from the metadata server, verifiable via Google's JWKS. Used directly as an audience-bound OIDC token (the Cloud Run idiom) or exchanged for mesh-CA mTLS certs.

- GCP handles both **bootstrap and rotation** — nothing to pre-plant, always fresh, so there is no roll-forward problem.
- Transport trust root = GCP IAM (which already decides what service account each workload runs as).
- This is the **managed-profile default**. It does not exist, and must not be assumed reachable, on self-hosted deployments.

## Backend 2 — pki-core-issued (self-hosted, or a unified SPIFFE domain)

An attestation → cert exchange, the D5 pattern (the operator token + proof-of-possession exchange) one layer down: the service generates a key, presents `{attestation + CSR + PoP}`, `pki-core` verifies the attestation, checks an identity allowlist, and mints a short-lived SPIFFE workload cert bound to the key.

- The **attestor itself is pluggable**: a GCP WI token, a Kubernetes projected ServiceAccount token, a one-time bootstrap token, or an external OIDC IdP. This is what lets a self-hosted cluster bootstrap without a GCP metadata server at all.
- `pki-core` **self-bootstraps** from its own KMS-held CA key — no cycle.
- Cost: services depend on `pki-core` being reachable to (re)issue.

## Backend 3 — External chain (bring-your-own PKI, self-hosted)

The operator supplies workload certs from their own issuer — SPIRE, cert-manager, Vault, a corporate CA — and services are simply configured to trust that root bundle.

- Wendy issues nothing for the mesh in this backend.
- The **operator owns rotation** end to end.

## Profile Defaults

| Profile | Default backend |
|---|---|
| Managed (GCP) | Backend 1 |
| Self-hosted | Backend 2 (non-GCP attestor) **or** Backend 3 — operator's choice |

A service selects its provider **by config**; peers are handed the matching trust bundle. No code path assumes a specific issuer.

## Renewal (all backends)

Identities are short-lived and renewed by **re-running the backend's issuance path** (re-attest / re-fetch) — never by rolling a stale credential forward. This mirrors the device renewal rule (§5.4): possession of an expiring credential is not itself sufficient; the issuance path runs again.
