---
name: wendy-cloud-testing
description: 'Wendy Cloud testing skill — supplies test commands, stack setup, and failure-mode knowledge for the cloud monorepo. Use when: (1) running Swift broker integration tests, (2) checking whether the local dev stack is healthy, (3) diagnosing enrollment or certificate errors, (4) verifying device reachability. Pair with /wendy-iterating to drive a continuous fix loop.'
---

# Wendy Cloud Testing

This skill supplies the Wendy Cloud-specific testing knowledge. Pair it with
`/wendy-iterating` to drive a continuous iterate-fix-ship loop:

> "Iterate on this feature using /wendy-iterating. Use /wendy-cloud-testing to determine how to test for bugs and completion."

## Prerequisites Check

Run at the very start of every session. Fix every gap before running any tests.

```bash
#!/usr/bin/env bash
set -euo pipefail
MISSING=()

if ! command -v brew &>/dev/null; then MISSING+=("Homebrew"); fi

if ! command -v docker &>/dev/null; then
  MISSING+=("Docker Desktop")
else
  if ! docker info &>/dev/null 2>&1; then
    open -a Docker
    until docker info &>/dev/null 2>&1; do sleep 3; done
  fi
fi

if ! command -v gh &>/dev/null; then MISSING+=("gh"); fi
if ! gh auth status &>/dev/null 2>&1; then MISSING+=("gh auth (run: gh auth login)"); fi
if ! command -v swift &>/dev/null; then MISSING+=("Swift toolchain"); fi
if ! command -v protoc &>/dev/null; then brew install protobuf; fi
if ! command -v wendy &>/dev/null; then MISSING+=("wendy CLI"); fi
[ -d "/Users/wendy/Documents/Projects/pki-core" ] || \
  gh repo clone wendylabsinc/pki-core /Users/wendy/Documents/Projects/pki-core -- --depth=1

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "BLOCKED:"; for item in "${MISSING[@]}"; do echo "  - $item"; done; exit 1
fi
echo "All prerequisites satisfied."
```

## Repository Layout

| Repo | Location | Purpose |
|------|----------|---------|
| cloud | `/Users/wendy/Documents/Projects/cloud` | Main monorepo (console, swift broker, infra). `main` = current codebase; `legacy` = old Firebase prod, frozen |
| pki-core | `/Users/wendy/Documents/Projects/pki-core` | PKI certificate authority engine |

## Stack Architecture

### Ports

| Port | Service | Notes |
|------|---------|-------|
| 50051 | Swift broker | Plaintext gRPC |
| 50052 | Swift tunnel-broker | One-way TLS |
| 8080 | Swift broker HTTP | Video REST/WebSocket |
| 9400 | Envoy | gRPC-web proxy |
| 9443 | pki-core | Certificate issuance |
| 9300 | Postgres | Primary database |

### Starting the full stack

```bash
cd /Users/wendy/Documents/Projects/cloud
make dev-local    # broker built on the host (fast rebuilds)
# or: make dev-docker   # broker in Docker, no Swift toolchain needed
```

Both are zero-parameter: Postgres, Swift broker + tunnel-broker, gRPC-web Envoy,
dev user/org seed. There is no separate Go `services` container any more.

Verify:
```bash
lsof -iTCP:50051 -iTCP:50052 -iTCP:9400 -sTCP:LISTEN -nP 2>/dev/null | grep -E "50051|50052|9400"
```

The launcher copies `docker-compose.override.yml.example` to
`docker-compose.override.yml` on first run; edit that copy rather than writing one by hand.

## Authenticating the CLI Against the Local Stack

> **Known broken end to end (WDY-2330)** per cloud `docs/local-dev.md`: the broker only
> trusts wendy-auth realm JWKS, so the HS256 Dev Login token is rejected (`UNAUTHENTICATED`).
> Treat this flow as its shape, not a working path, until `console/` replaces it.

Run once per session:

```bash
cd /Users/wendy/Documents/Projects/cloud
wendy auth login --cloud http://localhost:9200 --cloud-grpc localhost:50051 --json \
  > /tmp/wendy-auth-out.txt 2>&1 &
sleep 3
cat /tmp/wendy-auth-out.txt
```

Then use Chrome MCP tools to complete the browser flow:
1. Navigate to the `cli-auth` URL printed in the output.
2. If redirected to `/login`: click "Dev Login (local only)", wait 3s, re-navigate.
3. Click "Select" next to "wendylabsinc".
4. Wait 8 seconds for certificate issuance.
5. Verify: output ends with `Certificates saved.`

## Running the Test Suite

### Swift integration tests (primary signal)

```bash
cd /Users/wendy/Documents/Projects/cloud
make test-swift 2>&1 | tail -40
```

Filter to a specific test (the Makefile target has no `FILTER` knob):
```bash
cd swift && swift test --filter <TestName>
```

Tests use BrokerFixture (in-process gRPC, MockPKIServer, real Postgres). No real
Swift broker or pki-core needed. Approximately 60 tests across 8 suites.

## What to Check Each Iteration

1. Run `make test-swift` — any failures are the primary signal.
2. With `make dev-local`, broker logs go only to the launcher terminal (`swift/scripts/start-local.sh` runs the broker in the background on stdout; no log file). Read them there.
3. With `make dev-docker`, check container logs: `docker compose logs --since 10m swift-broker 2>/dev/null | grep -iE "error|fatal|panic" | tail -20`
4. Check device reachability: `wendy discover --json 2>&1 | head -10`

## Clean Definition

An iteration is clean when ALL of the following hold:

- `make test-swift` reports 0 failures
- No `error|fatal|panic` lines in broker logs from the last check interval
- `wendy discover` returns at least one device (or device testing is explicitly skipped)

## Common Failure Modes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Bool? nil creates OID 0 params` | PostgresNIO cannot infer type for nil Bool | Use `\(value)::bool` explicit cast |
| `connection pool exhausted` | Postgres default max_connections (100) hit | Set pool size to 1 in TestDB.swift |
| Handler not registered in BrokerFixture | Handler created but never added to test server | Register handler in BrokerFixture.swift |
| `Address already in use` on :50051 or :50052 | Previous broker process still running | `pkill -f start-local.sh; pkill -f /.build/.*broker; sleep 2` |
| `unknown profile "operator-tier-a"` | pki-core profile name mismatch | Use profile `"operator"` in CertificateServiceHandler.swift |
| `certificate is not valid for client authentication` | Production CLI cert missing clientAuth Extended Key Usage | Known cloud PKI bug; use local stack for testing |

## Device Testing (Optional)

Skip if no device is on the network or if the production cert lacks `clientAuth`
Extended Key Usage (a known cloud PKI bug).

```bash
# Discover devices
wendy discover --json 2>&1

# Check device info (requires valid clientAuth cert)
wendy cloud device info --device "$DEVICE_HOST" --json 2>&1 | head -20
```

If `device info` fails with "certificate is not valid for client authentication",
skip the mTLS checks — this is the known production PKI bug, not a regression.
