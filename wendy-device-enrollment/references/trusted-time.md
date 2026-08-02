# Trusted Time on Devices (§4.4, D12)

Every freshness/TTL/timestamp check in the whole contract — `iat`/`exp`/`nonce` on operator-signed requests, checkpoint TTLs, certificate validity windows — presupposes the verifying device has **trustworthy wall-clock time**. A headless/offline device doesn't get that for free: bare NTP is unauthenticated and spoofable, and a clock-rollback attacker could otherwise revive expired material or defeat staleness detection.

## The Model

- **Authenticated time source, never bare NTP.** NTS (RFC 8915) or Roughtime preferred (independent, signed), with a **pki-core-signed time attestation** as bootstrap/fallback — so clock trust never depends on pki-core alone.
- **Persisted monotonic anti-rollback floor.** A "latest trusted time" high-water mark, advanced only by an authenticated source or the newest verified artifact, **never moved backward**, hardware-backed where available (TPM/SE). A rolled-back RTC cannot pull the floor down.
- **Seeded at enrollment.** The device receives its initial trusted time via a **pki-core-signed timestamp in the enrollment response** — so a fresh unit starts above epoch, not at zero, and the seed is authenticated rather than assumed.
- **Fail-safe on unknown/too-stale time.** If the device cannot establish trusted time within a bound, it **holds current state, applies no time-gated change, and alerts** — it never guesses.
- **Bounded skew tolerance** so honest small drift doesn't false-reject, kept tight enough to bound replay.

## Why This Matters Here

Trusted time isn't a side concern for enrollment — it's the foundation every other enrollment and renewal rule stands on. The no-roll-forward rule, the enrollment token's short-lived binding, and every certificate validity check all assume the device's clock can be trusted. Get this wrong and every other guarantee in `tiers.md` and `first-touch.md` becomes unenforceable.
