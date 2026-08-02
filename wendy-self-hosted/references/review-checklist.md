# Self-Hosted Review Checklist

Run through this on any interop PR that touches wendy-agent/wendyos, `pki-core`, `wendy-auth`, or the inter-service fabric.

- [ ] **Does the feature work on the self-hosted profile?** Or, if the self-hosted backend isn't built yet, is it stubbed behind a clean seam with a tracked issue — rather than the seam not existing at all?
- [ ] **Is backend/provider selection config-driven?** No hard-wired issuer, no environment-sniffing, no "it's probably GCP" default baked into a call site.
- [ ] **Does anything import or assume GCP metadata, PSC, or Google JWKS outside the managed backend?** If the managed-GCP code path is reachable when the self-hosted backend is selected, that's a bug, not a fallback.
- [ ] **When the SaaS stack is unreachable, does the device keep operating on held state and alert (degraded mode) — rather than brick?** And, at the same time, does it still refuse to accept unverifiable material for availability's sake? Both halves matter: availability failures must fail safe, never fail open.
- [ ] **Are trust bundles configurable**, while the pinned platform root is still honored? (The platform Root baked into the OS image is never replaced by a self-hosted trust bundle — it's the anchor the self-hosted chain must still validate up to where applicable.)
- [ ] **Does mTLS work as the fabric transport where GCP-WI-OIDC is unavailable?** (§11.1 — mTLS is the retained self-hosted backend, not a hypothetical.)
- [ ] **Do docs and config samples cover both profiles** — not just the managed-GCP happy path?

If any box can't be checked, the PR is not done — it's a SaaS-only feature, and the standing rule says that's incomplete.
