# AAA Flows — Summary

Deliberately summaries, not mirrors of the contract. Read the Linear contract (see SKILL.md's Source of Truth) for the exact wire-level detail before implementing against any of these.

## 5.1 Operator login

- Operator authenticates to wendy-auth (identifier-first, org-SSO, MFA/passkey) → access token + refresh token.
- The Swift-WASM frontend generates an `extractable:false` keypair and calls pki-core's operator-facing identity-cert endpoint **directly** — cloud is not in this path.
- pki-core verifies the wendy-auth token + key binding and returns a short-lived, **identity-only** operator certificate (no entitlements).
- All subsequent requests to cloud are request-signed with that certificate; cloud authorizes live against the session's groups.
- High-impact device-mutating actions require a fresh human factor (step-up) producing an operator-signed change request (§5.1, §5.3).

## 5.2 Operator certificate — issuance & renewal

- Issuance is one-key (identity-only): wendy-auth token + CSR + proof-of-possession → pki-core mints, bound to the caller's non-exportable key. No cloud grant participates.
- Renewal is X.509, with pki-core re-validating the identity's status in-flight (SSF-fed and/or a live check) — a disabled user's cert stops renewing within one cert lifetime.
- **Entitlement-bearing** certs (direct operator→device access, field/USB) are the exception: issuance still goes through cloud, which attaches a grant before pki-core mints.

## 5.3 Postbox — device-mutating operator-signed requests

- Operator **pre-signs** a change request (deploy/stop/config/…) with their operator cert.
- Cloud accepts/rejects on live authorization + the operator cert's validity **at signing time**, then relays to pki-core's RFC 3161 TSA for a trusted timestamp and **appends** `{request, operator sig, TSA token, monotonic ID, hash of prior entry}` to an immutable, hash-chained postbox. Cloud never acts on the device.
- The device **polls** cloud over its own mTLS cert, verifies the hash-chain and its stored high-water mark, and fetches a signed head checkpoint.
- The device verifies each request (signature, target, freshness) offline against the operator cert, or online via a pki-core verification endpoint that also attests the operator's rights at signing time.
- Cloud's residual power is reduced to withhold/delay — it cannot forge, escalate, reorder, or roll back a change.

## 5.4 Enrollment & renewal

- Device tiers A/B/C are a capability/trust + (re)enrollment axis set by the hardware envelope — orthogonal to deployment (`field_mode`/`offline_bundle`) and to provisioning method.
- **Online** first touch: operator requests an enrollment token via cloud → pki-core mints a device- and tenant-bound, single-use token; the device redeems it (Tiers A/B via ACME EAB key, Tier C via lightweight EST/CSR).
- **Offline/airgapped** first touch: device emits a CSR on the operator's PC → operator-signed request → cloud grant → pki-core mint — the same grant-bearing mint machinery as post-expiry re-enrollment.
- **No roll-forward**: renewal requires presenting a currently valid cert; an expired cert cannot silently re-credential.
- Post-expiry recovery is by standing proof, by tier: Tier A re-attests unattended; Tier B (no standing hardware proof) goes through the **D14 operator-approved pending-approval queue**.

## 5.5 Tenant creation

- Cloud orchestrates end-to-end; no single service can create a tenant unilaterally: cloud creates the org record → pki-core `CreateCustomerCA` mints a tenant UUID + CA hierarchy → wendy-auth provisions the realm bound to that UUID.
- `pki_tenant_uuid` is set once at provision and is **immutable** — the anchor for cryptographic tenant isolation, resolved by UUID and never by the renameable realm slug (`org_id`).

## 5.6 Policy ceilings

- Three tiers, each bounding the next: **platform hard cap** (pki-core config, Wendy platform admin only, unreachable from cloud) bounds the **per-tenant ceiling** (cloud's authorization decision) bounds the **per-request** TTL/scope (`min(requested, tenant ceiling, platform cap)`).
- Raising a tenant ceiling requires the tenant-admin's step-up signature **and** cloud's grant, relayed to pki-core, which enforces the platform cap regardless.
- Downgrades (revoking `policy:write`, force-lowering a ceiling) may be pushed fail-safe over the SSF signal channel.

## 5.7 Device image pull (`wendy-proxy`)

- The device presents its own mTLS device cert to wendy-proxy — no token, no registry credential ever on-device.
- wendy-proxy reads the tenant UUID from the cert's SPIFFE SAN and scopes the request to that tenant's registry — cryptographic tenant isolation, not anything the device asks for.
- wendy-proxy enforces a **live** per-device image assignment from cloud (may THIS device pull THIS image/tag?).
- On a match, wendy-proxy mints a short-lived, tenant-scoped **downscoped credential** per request; it holds no standing fleet-wide registry credential.

---

## §11.3 Who calls whom (baseline)

| Caller → callee | Purpose | Authority artifact carried |
|---|---|---|
| cloud → pki-core | relay **authorization-gated** operator requests — entitlement certs (§5.2) + policy-ceiling changes (§5.6) (D7); request TSA timestamps (§5.3); revocation | operator sig + CSR + cloud grant |
| operator → pki-core *(direct frontend, not fabric)* | identity-only bootstrap cert (§5.2) | wendy-auth token + CSR + PoP |
| device → pki-core *(direct frontend, not fabric)* | enrollment (ACME/EST §5.4); change-request verification (§5.3) | device mTLS cert / bootstrap token |
| cloud → wendy-auth | verify tokens; consume `groups`; force sign-out (SSF) | — (transport mTLS) |
| wendy-auth → cloud, pki-core | SSF/CAEP SETs — revoke/downgrade/deprovision (§6) | signed SET (RFC 8417) |
| wendy-proxy → cloud | live per-device image-assignment check (§5.7) | device cert identity (from the pull's mTLS) |
| wendy-proxy → GCP STS/IAM | mint per-request tenant-scoped downscoped credential (§5.7) | verified device identity |

New methods (per-device assignment query, checkpoint publication, TSA) are added under §11.2's envelope + capability handshake, not as bespoke one-off endpoints.

## §6 SSF fan-out summary

- **Transmitter:** wendy-auth. **Receivers:** cloud (all removals: session-revoked, account-disabled, account-purged, token-claims-change, credential-change) and pki-core (only the cert-relevant subset: account-disabled, account-purged, driving its in-flight disabled-check).
- **Fail-safe only, never grants.** The SSF push stream carries revoke/downgrade/deprovision/session-kill only — a compromised node can over-revoke (detectable DoS) but never escalate. Any authority increase stays on the in-band, two-key path (§3, §5.6).
- v1 delivery is best-effort (`PushSecurityEventAck{jti, accepted}`, idempotent on replay) — acceptable because revoke-only means a dropped SET fails safe.
