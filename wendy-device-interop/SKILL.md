---
name: wendy-device-interop
description: 'Expert guidance on wendy-agent runtime interop with the SaaS stack: polling for changes, verifying operator-signed requests, and pulling images. Use when developers mention: (1) the postbox or device polling, (2) operator-signed change requests or desired state, (3) hash chains, checkpoints, or high-water marks, (4) applying deployments on devices, (5) image pull, wendy-proxy, or registries, (6) TSA or RFC 3161 timestamps, (7) fail-safe behavior on devices, (8) device mTLS to cloud.'
references:
  - references/postbox-verification.md
  - references/image-pull.md
---

# Wendy Device Interop

wendy-agent's prime directive against the SaaS stack: **apply a change only when it carries a valid operator signature the device can verify itself.** Cloud is a queue, never an authority — it can accept, append, relay, and enforce, but it holds no key that lets it originate an authoritative change (§5.3, D3). Everything below flows from that one rule.

## Hard Rules

- **Poll-only.** The device polls cloud's postbox for changes; it never accepts a pushed change. There is no code path where cloud calls the device to mutate its state (§5.3).
- **Device presents its own mTLS cert.** To cloud (postbox poll) and to wendy-proxy (image pull) alike, the device authenticates with its own hardware-backed certificate. Cloud never holds a certificate of its own to act as a principal (§5.3, §5.7).
- **No registry credential or token ever on-device.** Images come only through wendy-proxy; the device never talks to a registry directly and never stores a pull credential (§5.7).
- **Independent verifiability.** Nothing is applied on the strength of "cloud said so." Every change must be independently checkable by the device: valid operator signature, current freshness, and binding to *this* device — see `references/postbox-verification.md` for the full checklist.

## Fail-Safe Catalogue

| Condition | Response |
|---|---|
| Stale head checkpoint (past TTL, or below the device's high-water mark) | Don't trust the tail; alert (D8) |
| Unknown or too-stale trusted time | Hold current state; apply no time-gated change; alert (§4.4) |
| Unverifiable artifact or signature (chain link, checkpoint, request, or TSA token fails to verify) | Reject; alert |
| SaaS unreachable | Keep operating on held state (degraded mode) — never brick, never accept unverifiable material to stay "available" |

**Availability degrades. Security never does.**

## Audit

Every apply and verify outcome is emitted as a tamper-evident audit record, threaded by `correlation_id` so a single change can be traced across cloud, pki-core, and the device that applied it (§9 agent delta, §12).

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

- **wendy-aaa-interop** — the full contract this skill distills a slice of.
- **wendy-device-enrollment** — how the device got the mTLS cert it polls and pulls with.
- **wendy-security-baselines** — the invariants any interop change must respect.
- **wendy-self-hosted** — the standing dual-path rule.
