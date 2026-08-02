---
name: wendy-aaa-interop
description: 'Expert guidance on the AAA contract between the wendy stack and the SaaS stack (wendy-auth, Wendy Cloud, pki-core, wendy-proxy). Use when developers mention: (1) AAA contract or two-key authority, (2) interop between wendy-agent/wendyos and pki-core, cloud, or wendy-auth, (3) who owns authentication vs authorization vs issuance, (4) SPIFFE identities or credential shapes, (5) signed grants, SETs, or operator-signed requests, (6) the inter-service fabric or SSF signal channel, (7) correlation_id propagation, (8) platform cap or tenant ceiling.'
references:
  - references/flows.md
  - references/glossary.md
---

# Wendy AAA Interop

The AAA contract defines *who is trusted for what* across the control-plane services (`wendy-auth`, Wendy Cloud, `pki-core`, `wendy-proxy`) and the cryptographic invariants that hold even when one of them is compromised. It exists because Wendy serves critical-infrastructure partners: a breach of the SaaS control plane must never translate into the ability to act on a customer's fleet (§1).

## Responsibility Split

| Service | Owns | Does NOT own |
|---|---|---|
| **wendy-auth** | Authentication; the identity graph (tenant + user + group(s)); IdP federation; issuance of identity assertions (tokens/SETs) | Authorization decisions; certificates; entitlements |
| **Wendy Cloud** | Authorization (group→role→entitlement mapping) + org-native lifecycle + orchestration | Authentication of humans; minting any private key or certificate |
| **pki-core** | Certificate issuance/revocation; enforcement of the platform + per-tenant policy ceiling; the cryptographic root of tenant isolation | Deciding *who* a principal is (defers to wendy-auth) or *what* they may do (defers to cloud), except as bounded by policy caps |
| **wendy-proxy** | Pure enforcement: fronting the image registries, deriving tenant scope from the device cert, enforcing a live per-device image assignment | Any issuance; any authorization decision of its own |

(§1)

## Two-Key Authority

```
authority(action) = identity(wendy-auth) ∩ authorization(cloud) ∩ policy-cap(pki-core)
```

No single party manufactures authority (§3):

| Party alone has… | …and is missing | Result |
|---|---|---|
| Cloud: the authorization decision | the principal's key / signature | cannot get a credential issued that acts as the principal |
| Principal: identity + key | authority beyond what cloud grants | cannot self-escalate past cloud's grant |
| pki-core: issuance power | both proofs (it refuses without them) | mints only under identity ∩ authorization, capped by policy |

## The Two Guarantees

- **(A) Non-impersonation — strong, cryptographic.** No single service can act *as* a user, operator, or device.
- **(B) Non-escalation of a present principal — bounded, not absolute.** Cloud is the authorization authority, so a compromised cloud can inflate a legitimately-authenticating principal's authority, but only up to the platform hard cap.

State guarantee (B) honestly; never claim more (§2).

## Authority Is Never Transport-Derived

Transport (mTLS peer, or GCP-WI-OIDC on the inter-service fabric) names the *service* making the call — never a principal's authority. Principal authority always rides as an in-message signed artifact: a wendy-auth token, an operator signature + CSR, a cloud grant, a TSA token, or a SET. A relay (e.g. cloud carrying an operator request to pki-core) can withhold that artifact, but never forge it (§4.3, §11.1).

## Two Credential Shapes

- **Cloud-facing = identity-only.** Carries the SPIFFE identity, no entitlements. Cloud authorizes *live* against its own mutable state — more containable than a baked-in snapshot; embedding entitlements here would only make a stolen key harder to contain.
- **Device-facing = entitlement-bearing X.509.** The device is an offline enforcement point with no live authz to consult, so entitlements travel with the credential: grammar `entitlement:{category}:{permission}:{effect}`, deny-wins, vocabulary = the wendy-agent gRPC method set ∪ cloud-defined entitlements.

(§4.2)

## correlation_id

One id per end-to-end flow, not per service and not per mutation: each service **adopts** the inbound id if the request already carries one, **mints** a fresh id only when it is the true origin, and **propagates** it unchanged on every downstream call — persisting it into every audit record and every emitted signal for that flow. Never regenerate mid-flow (§11.2).

## Self-Hosted Rule (mandatory)

The wendy stack (wendyos / wendy-agent) must ALWAYS be able to run **without** the SaaS stack.
Before shipping any interop change, consult the **wendy-self-hosted** skill: keep the
self-hosted path intact, or create it where it doesn't exist yet. A SaaS-only feature is
an incomplete feature.

## Source of Truth

This skill distills the **AAA Contract v0.12** (draft, pending engineering approval).
The living contract lives in Linear: [AAA Contract — Authentication, Authorization, Accounting](https://linear.app/wendylabsinc/document/aaa-contract-authentication-authorization-accounting-v012-dff5a8351650).
It is versioned and evolving: check it for flow-level detail, and if it disagrees with this skill, **the contract wins** — then update this skill.

## Related Skills

- **wendy-certificates** — requesting and holding certificates.
- **wendy-device-enrollment** — device lifecycle (first touch through recovery).
- **wendy-device-interop** — agent runtime behavior against the postbox and image pull.
- **wendy-security-baselines** — invariants any interop PR must respect.
- **wendy-self-hosted** — the mandatory dual-path (SaaS + self-hosted) rule.
