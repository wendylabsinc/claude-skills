---
name: wendy-security-baselines
description: 'Security invariants every Wendy interop change must respect, distilled from the AAA contract. Use when: (1) reviewing or writing any code touching pki-core, wendy-auth, cloud, wendy-proxy, or wendy-agent interop, (2) designing auth, tokens, or credentials, (3) questions about the platform cap or policy ceilings, (4) SSF/CAEP events or revocation, (5) PATs, API keys, or service credentials, (6) audit logging or tamper evidence, (7) post-quantum or ML-DSA decisions, (8) TTLs, step-up, or key custody.'
references:
  - references/anti-patterns.md
  - references/audit.md
---

# Wendy Security Baselines

Invariants any interop PR must respect, regardless of which side of the AAA contract it touches. This is a review checklist, not a design guide — for the responsibility split and two-key authority model, see `wendy-aaa-interop`; for cert issuance mechanics, `wendy-certificates`; for enrollment, `wendy-device-enrollment`; for device runtime behavior, `wendy-device-interop`.

## The platform cap is cloud-immune

**No cloud-plane path may ever touch the platform cap.** It lives in pki-core configuration, owned by Wendy platform administration alone.

- Every mint enforces `issued ≤ min(requested, tenant ceiling, platform cap)` — operator, device, and signing certs alike (§8, D4).
- It is the sole bound on a compromised cloud's ability to escalate a legitimately-authenticating principal — the reason "cloud cannot authorize on its own" holds *in the form that matters* (§8).
- If a design routes a platform-cap change through any cloud-facing API or config surface, that is a contract violation, not an optimization.

## Push signals are fail-safe only

**The SSF/CAEP stream carries revoke / downgrade / deprovision / session-kill — never grants.**

- A compromised node on this stream can *over-revoke* — a detectable, recoverable DoS — but cannot escalate by pushing a fake grant. Any authority increase stays on the in-band, two-key crypto path (§6, D2).
- Distinguish the *push* stream from pki-core's on-request rights **query** to cloud during device-side verification: that query is cloud exercising its existing authorization authority on request, still bounded by the platform cap and gated by the principal's own signature — not a second grant path (§6).
- Safe directions are all removals: auth → cloud/pki-core (deprovision, MFA revoke, group removal), cloud → pki-core (cert revoke on role change/compromise), cloud → auth (force sign-out) (§6).

## No bearer secrets

**No pure-bearer PATs, no copy-pasteable secrets, ever — sender-constrained tokens only.**

- Proof-of-possession rides as per-request signing: JWS or COSE_Sign1, algorithm ML-DSA per RFC 9964, default leaf **ML-DSA-65** — never bearer-on-wire (§4.1, D17).
- Explicitly **not** RFC 9421 HTTP Message Signatures — its registry has no ML-DSA algorithm, which would force a private, non-interoperable `alg` (§4.1).
- Service accounts and CI get the identical operator cert flow through a different front door, never a weaker bearer-token shortcut (D17).

## Keys: client-generated, non-exportable, hardware where possible

**A privileged cert is minted only behind a fresh human factor, on a key the client generated.**

- Human-factor-gated minting: the key alone never authenticates to wendy-auth, so a stolen key can only ride the *current* short-lived cert, never roll forward (§7).
- Short TTLs bound the exposure window; step-up (FIDO2/passkey) is required for high-impact/destructive actions even on an otherwise-valid session (§7).
- Unattended renewal is the *device* exception — not a general pattern — and is compensated by hardware-backed custody (TPM/OP-TEE/eFuse-DS) plus fast revocation, not by loosening the human-factor rule elsewhere (§7).

## Audit is tamper-evident, secret-free, correlation-threaded

**Every authority-bearing event must be recorded, attributable, tenant-scoped, and stitched by `correlation_id`.** See `references/audit.md` for the full baseline and current per-service status (§12, D13).

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

- **wendy-aaa-interop** — the responsibility split and two-key authority model these baselines enforce.
- **wendy-certificates** — where client-generated keys and ML-DSA request-signing get applied in practice.
- **wendy-device-enrollment** — where the hardware-custody and TTL rules land at first touch.
- **wendy-device-interop** — where fail-safe push signals get consumed on the device side.
- **wendy-self-hosted** — the mandatory dual-path (SaaS + self-hosted) rule.
