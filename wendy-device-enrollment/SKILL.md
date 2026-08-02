---
name: wendy-device-enrollment
description: 'Expert guidance on enrolling WendyOS devices with pki-core and managing their certificate lifecycle. Use when developers mention: (1) device enrollment or provisioning, (2) enrollment tokens, ACME, EAB, or EST, (3) device tiers or attestation (TPM, OP-TEE, eFuse), (4) first-touch, flashing, or airgapped setup, (5) post-expiry recovery or re-enrollment, (6) trusted time, NTS, or anti-rollback, (7) platform root or trust anchors, (8) field mode or offline bundles.'
references:
  - references/tiers.md
  - references/first-touch.md
  - references/trusted-time.md
---

# Wendy Device Enrollment

Wendy does not manufacture hardware. There is no factory birth-key — the root of trust at first touch is an **authenticated operator** flashing the Wendy-built OS image onto off-the-shelf hardware and enrolling it. The device generates its own keypair (hardware-backed where the SoC allows), and the private key **never leaves the device** (D15).

## The Three Rules Every Enrollment Change Must Keep

1. **The platform Root is baked into the OS image — never trust-on-first-use.** The enrollment-delivered chain must validate up to the Root the operator already flashed, not to whatever chain the first enrollment happens to hand the device (§5.4).
2. **No roll-forward from an expired cert.** Renewal always requires a currently-valid cert to present. Once a cert has expired, the only way back is a **standing proof** — an unattended re-attestation, or an operator-approved grant (D14). A bare expired cert is never enough on its own.
3. **Trusted time is seeded at enrollment and must fail safe.** Every freshness/TTL check downstream depends on it; if trusted time can't be established, the device holds state and alerts — it never guesses (§4.4).

## Choosing the Flow

- **Online (has internet).** The operator requests an enrollment token at OS-install; cloud relays the signed request to pki-core, which mints a device- and tenant-bound, single-use token for the device to redeem. Fast, unattended once the operator has acted.
- **Offline / airgapped (no internet).** The device is connected to the operator's PC at first boot, emits a CSR (key never leaves it), and the operator carries a signed request to cloud for a grant. Slower, requires physical operator presence at both ends.

See `references/first-touch.md` for the full mechanics of both, plus post-expiry recovery.

## Renewal

Renewal is **unattended and automatic** over ACME/EST — a human factor cannot gate a turbine. Every renewal gets an in-flight disabled-check: pki-core refuses to re-issue a disabled/deregistered/revoked device.

Device **field mode** is set in Wendy Cloud, not by the device, and is live-checked by pki-core at each renewal (D16). It escalates nothing — no added entitlement or authority — its only effect is a longer validity window for a "not always online" device, bounded by tenant policy and the platform cap.

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

- **wendy-aaa-interop** — the hub skill for the wider AAA contract (authentication, authorization, accounting, the two-key model).
- **wendy-certificates** — cert issuance, renewal, and revocation mechanics shared across operators and devices.
- **wendy-device-interop** — the agent-side runtime behavior once a device is enrolled: postbox polling, verifying operator-signed changes, image pull.
- **wendy-self-hosted** — keeping every enrollment path viable without the SaaS stack.
