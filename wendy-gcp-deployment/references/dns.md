# DNS — wendy.sh / wendy.dev

The `*.wendy.sh` and `*.wendy.dev` managed zones live in the cloud project (`cloud-c7e56`) — always. Apps in other projects that need records reach across projects with a narrowly-scoped identity; the zones never move.

## Rules

1. **Never clash with pre-existing records.** Before creating anything:
   ```bash
   gcloud dns record-sets list --zone=<zone> --project=cloud-c7e56 --filter="name~<name>"
   ```
   If the name exists, stop and surface it to the user — never overwrite, never import someone else's record into your stack.
2. **Access is per-record, not per-zone.** Grant the deploy identity a custom role restricted with an IAM condition to exactly the records the app owns.
3. Pulumi manages records via a second explicit provider pointed at `cloud-c7e56`.

## Narrowest grant (verified against Cloud DNS docs, 2026-07)

Cloud DNS supports **zone-level IAM** (`gcloud dns managed-zones set-iam-policy`) and **per-RRset IAM conditions**. Resource name format for conditions:

```
projects/cloud-c7e56/managedZones/<zone>/rrsets/<domain>./<TYPE>   # note trailing dot
```

Custom role permissions for managing records:

- Mutations need BOTH: `dns.changes.create` AND `dns.resourceRecordSets.create` / `.update` / `.delete`
- Reads: `dns.resourceRecordSets.get`, `dns.resourceRecordSets.list`, `dns.changes.get`, `dns.managedZones.get`

**Caveat from the docs:** `dns.changes.create` cannot be usefully constrained by an RRset condition — grant it (and the reads) in an unconditional binding on the managed zone, and put the RRset condition on the binding that carries create/update/delete. Under very restrictive conditions `list`/`get` can fail; transactional edits may need `--skip-soa-update`.

Example condition (CEL) for an app owning `status.wendy.sh`:

```
resource.name.endsWith('/rrsets/status.wendy.sh./A') ||
resource.name.endsWith('/rrsets/status.wendy.sh./TXT')
```

(Use `resource.name.extract('/rrsets/{name}/').endsWith('.status.wendy.sh.')` style for a subtree.)

**Note:** zone-level IAM policies may reject federated (`principalSet://`) members — test during bootstrap; if rejected, this is a legitimate case for a deploy SA + impersonation (see `github-oidc.md`).

## Pulumi cross-project record (Go)

```go
dnsProvider, err := gcp.NewProvider(ctx, "dns", &gcp.ProviderArgs{
    Project: pulumi.String("cloud-c7e56"),
})
// ...
_, err = dns.NewRecordSet(ctx, "status-a", &dns.RecordSetArgs{
    ManagedZone: pulumi.String("<zone-name>"), // verify actual zone name first
    Name:        pulumi.String("status.wendy.sh."),
    Type:        pulumi.String("A"),
    Ttl:         pulumi.Int(300),
    Rrdatas:     pulumi.StringArray{ip.Address},
}, pulumi.Provider(dnsProvider))
```

Verify the actual managed-zone names in `cloud-c7e56` (`gcloud dns managed-zones list --project=cloud-c7e56`) — don't assume `wendy-sh`/`wendy-dev`.
