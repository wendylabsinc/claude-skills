# Anti-Patterns — Reject on Sight

Each of these contradicts a specific AAA contract guarantee. If you see one in a diff, stop and flag it — don't wave it through as a stopgap or "just for this one case."

- **Authorization backdoors** (e.g. a `users.is_super_admin`-style global bypass). A single row/flag granting total authority flatly contradicts the non-impersonation/non-escalation guarantees (§2); this is precisely what's being deleted from cloud's Casbin model (§9).
- **Token decoding without signature verification.** Any path that reads claims out of a JWT/token without verifying its signature first — the Firebase test-mode path being removed for exactly this reason (§9).
- **Unsigned desired-state rows a device obeys.** A device must never apply a change that isn't an operator-signed artifact it can verify; this was the pre-contract push/desired-state model's blast radius, replaced by the signed, poll-based postbox (§5.3).
- **Cloud pushing changes to devices, or cloud holding a tenant certificate.** Cloud is authorization-gate-and-queue only — it never pushes and never acts as a credentialed principal toward a device (D3).
- **Trust-on-first-use anchors.** The platform Root must be baked into the OS image (or delivered over the operator-PC channel), never accepted as whatever chain a first enrollment happens to hand the device (§5.4).
- **Entitlements riding a cloud-facing cert.** Entitlements belong only on the device-facing, offline-enforcement credential; a cloud-facing identity-only cert carrying entitlements defeats the reason it's identity-only (cloud authorizes live against mutable state) (§4.2).
- **Authority derived from transport identity.** mTLS peer or GCP-WI-OIDC token tells you *which service* is calling, never a principal's authority — authority always rides as an independently-verifiable signed artifact inside the message, never inferred from the transport (§11.1).
- **Bearer PATs or long-lived CI secrets.** No copy-pasteable, pure-bearer credential is ever acceptable — for humans or service accounts — and CI must federate its IdP OIDC token into wendy-auth for a short-lived cert instead of holding a standing secret (D17).
- **Grants riding the SSF/CAEP push stream.** That stream is fail-safe/revoke-only; any authority increase must go over the in-band, two-key path — a "grant" arriving as a push event is itself the compromise signal (§6).
- **Resolving tenants by realm slug instead of `tenant_uuid`.** A realm slug is renameable; tenant identity must resolve on the immutable `tenant_uuid` claim, cross-checked against the issuing realm (§5.2/v0.11).
- **Weaker service-account-only auth paths.** Service accounts get the identical operator cert flow through a different wendy-auth front door — never a separate, lower-assurance path "because it's just a machine" (D17).
- **Silently skipping the self-hosted path.** Shipping an interop change that only works against the SaaS stack, with no self-hosted equivalent and no note explaining why — see the `wendy-self-hosted` skill before merging.
