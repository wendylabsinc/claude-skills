# Device Tiers (§5.4)

Tier is a **capability/trust + (re)enrollment** axis, set by the device's **hardware envelope** — not by where it lives or how often it's online.

- **Tier A — hardware attestation** (TPM/fTPM/SE). Proves key-in-hardware at enrollment and **re-attests unattended after expiry** — self-recovering, no operator in the loop.
- **Tier B — network-enrollable, no/weak attestation.** Renews by possession in-window; **post-expiry requires operator approval** (see `first-touch.md`) — it has no standing hardware proof to re-attest with.
- **Tier C — constrained envelope** (lightweight crypto/protocols/power). Post-expiry recovery is **A-like if its envelope includes an attestable key, else B-like** — the tier fixes the envelope, not the recovery path.

**Tier A is defined by possessing an accepted attestation method, not raw custody.** A hardware-custody device whose keystore has no attestation pki-core accepts behaves as Tier B for recovery purposes (D14).

## Two Orthogonal Axes

Tier is independent of:

- **Deployment** — `field_mode` / `offline_bundle`. A Tier-A box on a forest pole is still Tier A, just field-mode.
- **Provisioning method** — client-generated key (default) vs. the server-keygen-over-USB fallback for a device that genuinely cannot keygen (§5.2).

These extensions are recorded separately on purpose: `device_trust_tier` for the tier, `field_mode`/`offline_bundle` for deployment.

## Protocol and Custody Binding

- **Tier A/B enroll over ACME** — the injected enrollment token *is* the ACME EAB key (single-use, device+tenant bound). Tier A additionally requires attestation (`attestation_required`); Tier B does not.
- **Tier C** cannot do ACME — it enrolls over a lightweight **EST bootstrap-token / CSR-REST** path.
- **Key custody** is hardware-backed where the SoC allows: **TPM** (x86), **OP-TEE** (Jetson), **eFuse-DS** (ESP32-C6). Software custody only where the hardware offers nothing (Tier B may be software-backed, but hardware is preferred wherever possible).

Attestation methods chain to the SoC/TPM-vendor attestation root. Today attestation is TPM only; OP-TEE, eFuse-DS, and a lightweight constrained form are being added.
