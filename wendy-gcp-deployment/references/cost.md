# Cost-efficiency rules

Cost-consciousness is a MUST. The bill is reviewed; over-provisioning is treated as a defect.

## Cloud Run posture (default for low/moderate traffic)

- `min-instances = 0` (scale-to-zero is Cloud Run's default — keep it unless cold starts violate a stated requirement).
- Request-based billing (default): CPU allocated only while serving; idle costs nothing.
- Modest limits by default: 1 vCPU / 512 MiB unless the app demonstrably needs more.
- `max-instances` low (e.g. 2–5) for internal tools, so a bug can't fan out into a big bill.

## Database decision ladder (walk it top-down, stop at the first fit)

1. **No database.** Can state live in the client, a file, or be recomputed? Many dashboards/tools need no DB.
2. **SQLite on a volume / GCS.** Single-writer, small data, internal tool → a mounted volume or GCS object is fine.
3. **Firestore.** Serverless, scales to zero cost on no traffic, generous free tier. Good for key-value/document state.
4. **Cloud SQL Postgres, smallest tier, zonal.** `db-f1-micro` (~$8–10/mo) or `db-g1-small`. `availabilityType: ZONAL` (no HA), 10 GB disk, backups on, PITR off. Shared-core tiers have no SLA — that is acceptable for dev and internal tools, and for many small prod apps.
5. **Bigger Cloud SQL / HA.** Only with a stated requirement (SLA, load, compliance). HA roughly doubles cost.

**Never** default to: HA/regional Cloud SQL, dedicated-core tiers, read replicas, or AlloyDB (no permanent free tier; entry cost far above shared-core Cloud SQL) — unless requirements demand them.

> Real incident this section exists for: apps that needed a small history table were given full Cloud SQL clusters. The requirement was step 2–4 on the ladder; the bill said otherwise.

## Other recurring-cost traps

- **Global external ALB:** the forwarding rule alone has a fixed monthly cost (order of ~$20/mo) before traffic. For a small internal service, consider Cloud Run domain mapping (free, but requires one-time domain verification and is region-constrained) or IAP on Cloud Run directly. Present the tradeoff; let the user pick.
- **Static IPs** reserved but unattached bill hourly.
- **VPC connectors, NAT gateways:** standing hourly cost. Avoid needing them (public-IP Cloud SQL via the connector/auth-proxy path needs no VPC connector).
- **Artifact Registry:** storage billed per GiB — set a cleanup policy (keep last N versions) on repos with frequent pushes.
- **Idle dev environments:** dev stacks should scale to zero. A dev environment with `min-instances: 1` or a dedicated-core dev database is a bug.

## Rule of thumb

Estimate the monthly cost of what you're about to provision and say it out loud in the design ("~$X/mo"). If you can't estimate it, look up current pricing — never guess from memory. Anything over ~$25/mo for an internal/low-traffic app needs an explicit justification tied to a requirement the user stated.
