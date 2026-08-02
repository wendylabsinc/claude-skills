# Postbox Verification (device side, §5.3)

The device is the last line of defense: cloud is only ever a queue, so every step below is something the device checks *itself* — never something it takes on cloud's word. Ordered checklist for each poll cycle:

1. **Poll + fetch checkpoint.** Poll cloud over the device's own mTLS certificate for "changes since `<ID>`," and separately fetch the latest signed **head checkpoint** for this `(tenant, target)`.
2. **Verify hash-chain links.** Each returned entry links to the prior one by hash; the device verifies the chain is intact end to end, not just that individual entries look well-formed.
3. **Enforce the stored high-water mark.** Reject any entry ID at or below the device's already-seen high-water mark — no rollback, ever. Gap-detect across monotonic IDs: a missing middle entry (e.g. 10, 11, 13 with no 12) is flagged, not silently skipped.
4. **Verify the checkpoint itself.** The checkpoint carries two independent bindings the device must both check: a JWS from the platform Checkpoint Signer (authorship) and an RFC 3161 TSA token over the same bytes (time) (D8). Check its TTL — a stale checkpoint means don't trust the tail: fail-safe and alert, never "assume 11 is still the head."
5. **Verify each request in the batch.** For every postbox entry: operator signature valid, request targets *this* device, and it is fresh — `exp`/`nonce` checked against the device's replay cache.
6. **Verify signing-time validity via the TSA.** The operator's own `iat` is self-asserted and not trusted; validity is judged against the trusted timestamp from the RFC 3161 TSA operated by pki-core, whose cert chains to the platform anchor the device already holds (D9). Cloud relays the request to the TSA at accept time but has no pki-core key — it can only *delay* relaying, which moves the timestamp later, the fail-safe direction (a near-expiry cert reads as expired, never revived).
7. **Rights check, connectivity-dependent.** An online device also calls pki-core's verification endpoint, which attests the operator's *rights at signing time* (sourced from pki-core's backchannel with cloud) — this is strictly stronger than checking the signature alone. An offline device falls back to signature + target + freshness and accepts the documented residual: it implicitly trusts cloud's accept-gate for rights until it can reconnect.

Only once every step above passes does the device apply the change.

## What this buys, stated honestly

Cloud's power is reduced to a queue: at worst it can **withhold or delay** entries it holds — an availability/censorship residual — but it cannot **forge**, **escalate**, **reorder**, or **roll back** them. The hash-chain, high-water mark, and signed checkpoints make presenting old-as-new or dropping an entry the device already saw cryptographically impossible.

The sharpest residual is a cloud that lies **consistently** to both the device and pki-core about the tail (claiming "row 11 is the latest" to everyone). This is closed for any request whose submission receipt reached pki-core directly (the operator's tooling posts the same signed request to pki-core independent of cloud); it remains open only where no receipt was posted. Closing it unconditionally — without depending on receipt-posting discipline — needs an independent witness in a genuinely separate trust domain, which stays a deferred, higher-assurance option (D8, §10).
