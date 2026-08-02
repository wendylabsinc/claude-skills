# Audit Baseline

The third A — accounting. The contract's guarantees depend on being able to reconstruct and attribute what happened, so this is the shape every service's audit trail must converge on (§12, D13).

## Reference shape: pki-core's `internal/audit`

pki-core already has the target shape, and the other two services are adopting it rather than something new being invented:

- **Hash-chained** — each row binds the previous row's hash, tamper-evident by construction.
- **Atomic with the mutation** — the audit row is written in the same transaction as the cert/CA change it describes, not appended best-effort after the fact.
- **Per-tenant** — chains are scoped per tenant (a system/nil-UUID chain covers platform-level events).
- **Secret-free** — summary rows only; no signed artifact or key material is ever stored.

## Where cloud and wendy-auth stand

- **wendy-auth** has built hash-chaining + durable in-order append + per-realm-key-signed checkpoints + `correlation_id` threading (its W5 work, gated on `w3-inter-service-fabric`) but it is **pending review**, not landed — check current state before assuming it's still behind or already merged.
- **cloud** is still best-effort, mutable rows (`audit_logs`) as of this writing — it has not yet adopted the shape. Verify current state rather than assuming either way; this is exactly the kind of fact that drifts as work lands.

Don't take either status as fixed — confirm against the contract/codebase before stating it in a review.

## What "non-repudiation" means here

Summaries only, never artifacts or key material. Non-repudiation in this model means *"this event, as summarized, was recorded, and the record is tamper-evident"* — **not** after-the-fact re-verification of the original signature. The system deliberately does not store artifacts, so don't describe audit as if it lets you re-verify the original signed request.

## Threading and checkpoints

- Every stream threads `correlation_id` end-to-end — one id per flow, adopted or minted once, never regenerated mid-flow.
- Periodic checkpoints (`{stream, seq, head_hash, time}`), signed by the emitting service's own workload identity, are appended so deletion or truncation of the chain surfaces as a broken chain or a missing checkpoint.
- Reads are tenant-scoped: a tenant sees only its own records; platform-level events are Wendy-only.

## Residual, stated honestly

A compromised node can misreport or withhold the summaries of **its own** actions — it authors its own stream, and artifacts aren't stored to re-verify against. This is caught only via cross-service correlation (checking what other services logged for the same `correlation_id`) or detectable hash-chain/checkpoint gaps — it is not preventable by that node alone. State this residual honestly in any design doc; don't claim audit makes misreporting impossible.
