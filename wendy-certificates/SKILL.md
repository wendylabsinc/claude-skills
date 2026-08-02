---
name: wendy-certificates
description: 'Expert guidance on requesting, renewing, and revoking certificates in the Wendy ecosystem via pki-core. Use when developers mention: (1) requesting or issuing a certificate, (2) operator or service identity certs, (3) entitlement-bearing certs or field/USB access, (4) CSR, proof-of-possession, or cnf.jkt binding, (5) cert renewal or revocation, (6) service accounts, machine users, or CI credentials, (7) ML-DSA or post-quantum signing, (8) SPIFFE URIs or tenant_uuid.'
references:
  - references/operator-identity-cert.md
  - references/renewal-revocation.md
---

# Wendy Certificates

How principals in the Wendy ecosystem get, renew, and lose certificates. **pki-core is the sole issuer** — every cert it mints binds a client-held key, never a bare identity claim. Which cert type a flow needs depends on *where authorization will be enforced*: a cloud-facing cert stays identity-only because cloud authorizes live against its own mutable state, while a device-facing cert must carry entitlements because the device has no live authority to consult when offline (§4.2). Full flow-level detail — including how the two credential shapes interact with the rest of the AAA contract — lives in the `wendy-aaa-interop` skill; this skill is the certificate-request/renewal/revocation slice of it.

## Decision Table: Which Cert / Which Path

| Need | Path |
|---|---|
| Identity-only operator cert (steady-state login/session) | Direct pki-core endpoint — no cloud in this path |
| Entitlement-bearing cert (direct field/USB device access) | Operator-signed request + CSR → cloud attaches a grant → relayed to pki-core |
| Device cert (enrollment, first touch, recovery) | Enrollment flows — see the `wendy-device-enrollment` skill |
| Service account / machine user | Identical operator flow, through a different wendy-auth front door (§5.2, D17) |

(§5.2, D17)

## Key Rules (non-negotiable)

1. **Client-generated keys only.** Private keys are always generated on the client; pki-core's engine-side `GenerateKeyAndIssueCert` is **prohibited** for principal certs. The sole exception is the **server-keygen-over-USB fallback**, for a device that genuinely cannot generate its own key, with in-memory zeroization after use (§5.2).
2. **`extractable:false` is the floor.** WebCrypto keys are non-exportable by default; high-assurance operators use a FIDO2/passkey hardware authenticator instead, so signing happens inside the device and malware can only *use* the key while resident, never exfiltrate it (§7).
3. **No pure bearer PATs.** Only sender-constrained tokens exist in this system — a copy-pasteable secret is rejected outright, for humans and service accounts alike (D17).
4. **Request-signing is JWS/COSE with ML-DSA, not RFC 9421.** Proof-of-possession is a signature over a canonical request descriptor, algorithm ML-DSA per RFC 9964 (default leaf **ML-DSA-65**), enveloped as JWS (HTTP/cloud) or COSE_Sign1 (edge/gRPC) — not RFC 9421 HTTP Message Signatures, whose registry has no ML-DSA algorithm (§4.1).

## Service Accounts & CI

A service account is a normal user behind a **different wendy-auth front door**, flagged and privileged by cloud exactly like a human — same §5.2 cert flow (issuance + renewal + in-flight status check), no weaker path. It gets its own `service` SPIFFE kind (`spiffe://wendy.sh/tenant/<uuid>/service/<name>`) so audit and offline enforcement can tell human and machine principals apart.

CI never holds a long-lived secret: `wendy-cloud-action` federates the job's IdP OIDC token *into wendy-auth*, which mints a wendy-auth token bound to an ephemeral in-job key; the job then calls the same identity-cert endpoint for a short-lived cert. No PAT ever exists at any point in this flow (D17).

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

- `wendy-aaa-interop` — the full contract this skill distills a slice of
- `wendy-device-enrollment` — device certs: first touch, tiers, post-expiry recovery
- `wendy-security-baselines` — the invariants any interop change must respect
- `wendy-self-hosted` — the standing dual-path rule
