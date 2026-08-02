# Operator Identity Cert: The Token + Proof-of-Possession Exchange

When pki-core's operator-facing identity-cert endpoint receives `{ wendy-auth token, CSR, proof-of-possession }`, it runs this checklist before minting (§5.2):

1. **Verify the token itself.** Check the signature against the realm JWKS, `iss`/`exp`/`iat`, and consult the `jti` replay cache to reject a token already spent.
2. **Verify `aud` membership.** The token's `aud` must include the RFC 8707 resource `https://pki.wendy.sh/identity` — accepted as a bare string or an array (RFC 7519 §4.1.3). This resource string is a configured value **pinned identically** on the wendy-auth side (which sets it) and the pki-core side (which checks it); a token minted for a different resource is not spendable here.
3. **The crux — bind the cert to the caller's key.** Require `thumbprint(CSR public key) == cnf.jkt` (the token's bound key) `==` the key that signed the proof-of-possession. All three must be the same key. This is what makes a stolen bearer token alone worthless: without the non-exportable private key behind it, the token yields no certificate.
4. **Resolve tenant by `tenant_uuid`, never `org_id`.** Read the immutable `tenant_uuid` claim (set once at provision, never renamed) — **not** the human-facing `org_id` realm slug, which can be renamed. Reject any otherwise-valid token that lacks `tenant_uuid` (the unmapped-realm case). Cross-check that the issuing realm is the one bound to that `tenant_uuid`, so one realm cannot mint an identity for another tenant.
5. **Mint.** `spiffe://wendy.sh/tenant/<uuid>/operator/<name>`, identity-only (no entitlements), short TTL, bound to the CSR key.

## Where cloud sits (D7)

The identity-only cert above is issued by a **direct operator-facing pki-core endpoint** — cloud is not in this path at all, because an identity-only cert carries no entitlements and there is nothing for cloud to authorize. Only **grant-bearing** requests (entitlement-bearing certs, policy-ceiling changes) relay through cloud, which acts purely as an authorization barrier: it can **withhold** a grant (an availability residual) but it can never **forge** a cert, since it holds no pki-core key.
