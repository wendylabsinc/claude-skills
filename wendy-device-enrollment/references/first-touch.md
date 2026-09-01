# First Touch and Post-Expiry Recovery (§5.4, D14, D15)

## Online Flow (v0.12 model)

1. At OS-install time, the operator requests an enrollment token from cloud.
2. Cloud relays the operator's **signed request** to pki-core over the inter-service fabric — that signature is the authorization attestation.
3. pki-core mints a **device- and tenant-bound, single-use** token and tracks it.
4. The device redeems the token to enroll. pki-core enforces **local single-use + not-revoked** at redemption.
5. If authorization is withdrawn before redemption, cloud pushes a **fail-safe token-revoke** over the signal channel.

This revoke-push model (v0.12) replaced an earlier "live cloud authorization check at redemption." It matters because enrollment now **survives cloud being unreachable** — pki-core is the pure enforcement point, and cloud's role is authorize-at-mint plus a fail-safe removal, never a synchronous gate. The residual — a revoke racing a redemption — is bounded because the token is single-use, short-lived, and device+tenant-bound (D15).

Token realization follows tier: Tier A/B redeem an ACME EAB key (A with attestation required); Tier C redeems a lightweight EST bootstrap-token / CSR-REST token.

## Offline / Airgapped Flow

1. The device is connected to the operator's PC at first boot and emits a **CSR** — the key never leaves the device.
2. The operator submits the CSR as a **signed request** to cloud.
3. Cloud attaches a **grant**.
4. pki-core mints the cert on `key-possession + grant ≤ platform cap`.
5. The cert is installed on the device via the wendy CLI.

This is the same grant-bearing machinery as operator-approved post-expiry re-enrollment below (D14) — applied at first touch instead of after a lapse.

## Post-Expiry Recovery (D14)

What a lapsed device can still present depends on its **tier's attestation capability**:

- **Tier A** (or a Tier-C device with an attestable key) simply **re-attests and re-enrolls unattended** — attestation is a standing capability, not a one-time secret.
- **Tier B** (or a Tier-C device without an attestable key) has no standing proof left. It enters the **operator pending-approval queue**: the device presents its expired cert as an **identity claim only** — this grants nothing on its own. The operator approves or denies based on whether the device is still in operation and in their possession; approval is operator-signed (step-up) and relayed to pki-core as a grant.

**Duplicate requests on one identity are a theft signal** and are held/flagged rather than auto-approved. This preserves the no-roll-forward rule's intent — recovery is never possession-only — while still giving offline/intermittent fleets a path that's unattended from the device's side (it just retries and polls).
