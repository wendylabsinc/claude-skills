# Postbox Verification (device side, §5.3)

The device is the last line of defense: cloud is only ever a queue, so every step below is something the device checks *itself* — never something it takes on cloud's word. Ordered checklist for each poll cycle:

1. **Poll + fetch checkpoint.** Poll cloud over the device's own mTLS certificate for "changes since `<ID>`," and separately fetch the latest signed **head checkpoint** for this `(tenant, target)`.
2. **Verify hash-chain links.** Each returned entry links to the prior one by hash; the device verifies the chain is intact end to end, not just that individual entries look well-formed.
3. **Enforce the stored high-water mark.** Reject any entry ID that precedes the device's already-seen high-water mark — no rollback, ever. Gap-detect across monotonic IDs: a missing middle entry (e.g. 10, 11, 13 with no 12) is flagged, not silently skipped.
4. **Verify the checkpoint itself.** The head checkpoint (`{tenant/target, max_id, hash_of_head, time, sig}`) is signed by pki-core and RFC 3161-timestamped, with a short TTL (D8). Reject any checkpoint below the device's high-water mark or past its TTL — stale ⇒ fail-safe: alert, never "assume 11 is still the head."
5. **Verify each request in the batch.** For every postbox entry: operator signature valid, request targets *this* device, and it is fresh — `exp`/`nonce` checked against the device's replay cache.
6. **Verify signing-time validity via the TSA.** The operator's own `iat` is self-asserted and not trusted; validity is judged against the trusted timestamp from the RFC 3161 TSA operated by pki-core, whose cert chains to the platform anchor the device already holds (D9). Cloud relays the request to the TSA at accept time but has no pki-core key — it can only *delay* relaying, which moves the timestamp later, the fail-safe direction (a near-expiry cert reads as expired, never revived).
7. **Rights check, connectivity-dependent.** An online device also calls pki-core's verification endpoint, which attests the operator's *rights at signing time* (sourced from pki-core's backchannel with cloud) — this is strictly stronger than checking the signature alone. An offline device falls back to signature + target + freshness and accepts the documented residual: it implicitly trusts cloud's accept-gate for rights until it can reconnect.

Only once every step above passes does the device apply the change.

## What this buys, stated honestly

Cloud's power is reduced to a queue: at worst it can **withhold or delay** entries it holds — an availability/censorship residual — but it cannot **forge**, **escalate**, **reorder**, or **roll back** them. The hash-chain, high-water mark, and signed checkpoints make presenting old-as-new or dropping an entry the device already saw cryptographically impossible.

The sharpest residual is a cloud that lies **consistently** to both the device and pki-core about the tail (claiming "row 11 is the latest" to everyone) — since pki-core learns the head only via cloud, this is **irreducible in the current baseline**: the device cannot distinguish "quiet" from "censored." Closing it needs a second ingestion path cloud doesn't control — for example, operator tooling posting signed submission receipts directly to pki-core, or a witness in a separate trust domain — noted only as a **deferred, higher-assurance add-on** (D8, §10 item 4), not something the baseline provides today.
