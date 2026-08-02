# Renewal & Revocation

## Renewal

**Operator certs** renew via X.509 renewal at pki-core during an active session, ahead of expiry. Renewal is not a rubber stamp: pki-core re-validates the identity's **status in-flight**, using SSF-fed revoke/deprovision state and/or a live check to wendy-auth, and refuses to re-issue if the user has been disabled. A live session stays smooth without a repeated human factor, yet a disabled user's cert stops renewing within one cert lifetime (§5.2).

**Device certs** renew unattended over ACME/EST. Two live checks ride the same renewal gate: an in-flight **disabled-check** (the device analogue of the operator check above — a disabled device stops renewing within one cert lifetime, no push required) and a **field-mode live-check** that reads the device's current field-mode state from cloud so it can be toggled on demand rather than fixed at enrollment. Field mode escalates nothing — it only affects the issued cert's validity window, bounded by tenant CA policy and the platform cap. This model is captured in the contract but **not yet implemented** — it depends on the cloud↔pki-core live-check fabric (D16).

**No roll-forward from an expired cert.** Renewal requires presenting a *currently valid* cert. Once a cert has expired, the possession-only auto-renew path is closed — a device offline past expiry cannot silently re-credential on the bare expired cert alone. Everything past this point is post-expiry recovery, which is device-enrollment territory, not renewal: see the `wendy-device-enrollment` skill for the tier-dependent recovery paths (§5.4).

## Revocation

Revocation is operator- or tenant-triggered and carried over the SSF signal channel — **fail-safe direction only** (revoke / downgrade / deprovision / session-kill), never a grant. Connected principals see it promptly. Offline devices are bounded by how fast their CRL/OCSP staple refreshes — an accepted, documented residual for disconnected operation, not something further hardenable without connectivity (§5.4).

**Dueling renewals are a theft signal.** A cloned key and the real device fighting over renewals produce detectable serial churn/lockout, which should raise a tenant alert rather than be silently resolved (§5.4).
