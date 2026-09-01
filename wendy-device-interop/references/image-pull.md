# Image Pull (device side, §5.7)

When an applied change references an OCI image, the device pulls it only through **wendy-proxy** — never a direct registry connection.

- **Same mTLS cert, no registry credential.** The device presents its own hardware-backed device certificate to wendy-proxy — the same cert used to poll the postbox. No token and no registry credential ever reach the device.
- **Tenant scope is cryptographic.** wendy-proxy derives the tenant from the cert's SPIFFE SAN (`spiffe://wendy.sh/tenant/<uuid>/device/<name>`) and scopes the pull to that tenant's registry. Cloud has no way to influence this — it is rooted in the certificate, not in anything the device asks for — so cross-tenant image access is impossible, even under a full cloud compromise (D6).
- **Assignment is cloud's decision, proxy only enforces it.** wendy-proxy checks a *live* per-device image assignment — may this device pull this image/tag — sourced from cloud's authorization state. The proxy holds no issuance power and makes no authorization decision of its own; it is a pure enforcement point.
- **Per-request, downscoped credentials only.** On a match, wendy-proxy mints a short-lived, tenant-scoped downscoped credential (STS token exchange / credential access boundary / Workload Identity Federation) derived from the verified device identity, and proxies the pull with it. It holds **no standing fleet-wide registry credential** (D10).
- **Blast radius of a device compromise.** A compromised device yields only that device's tenant-scoped, assignment-bounded pull rights — never registry keys, never another tenant's images.

## Agent implication

- Never embed a registry credential of any form on the device.
- Never bypass wendy-proxy for a "just this once" direct registry pull.
- Treat an in-tenant misassignment (cloud letting a device pull an image within its own tenant it shouldn't) as cloud's accepted residual, not a bug to route around on-device — it is bounded by, and strictly inside, the cryptographic tenant boundary the cert enforces (guarantee B, §2, §5.7).
