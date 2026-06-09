---
name: wendy-cloud-iterate
description: 'Autonomous continuous integration loop for the Wendy Cloud repository. Use when asked to: (1) iterate on the cloud stack, (2) find and fix bugs in Wendy Cloud, (3) run the cloud test loop, (4) continuously test the Swift broker, (5) scan for regressions after new features. This skill manages the full local dev stack autonomously including starting Docker, the Swift broker, pki-core, running tests, diagnosing failures, and applying fixes.'
---

# Wendy Cloud Iterate

This skill drives an autonomous continuous loop that starts the Wendy Cloud dev stack, runs the integration test suite, diagnoses any failures, attempts fixes, and self-paces based on results.

## Autonomy Grants

You are fully autonomous in this skill. You may:
- Clone or pull any repository from GitHub under the `wendylabsinc` org without asking
- Run any `make` target in any of the repos
- Run `docker compose` commands (up, down, restart, logs)
- Run `wendy` CLI commands
- Edit source files to fix bugs (commit the fix afterward)
- Push commits to the current branch
- Open pull requests via `gh pr create`

Do NOT ask for confirmation before any of the above. If something is missing (a repo, a binary, a config file), fix it autonomously.

## Repository Layout

The Wendy Cloud monorepo lives at `/Users/wendy/Documents/Projects/cloud`. Sibling repos:

| Repo | Location | Purpose |
|------|----------|---------|
| cloud | `/Users/wendy/Documents/Projects/cloud` | Main monorepo (dashboard, services, swift) |
| pki-core | `/Users/wendy/Documents/Projects/pki-core` | PKI certificate authority engine |

If `pki-core` is missing from disk, clone it:
```bash
gh repo clone wendylabsinc/pki-core /Users/wendy/Documents/Projects/pki-core -- --depth=1
```

## Stack Architecture

### Services and ports

| Port | Service | Notes |
|------|---------|-------|
| 50051 (host) | Swift broker | Plaintext gRPC |
| 50052 (host) | Swift tunnel-broker | One-way TLS |
| 50061 (host) | Go services (remapped in override) | Avoids host port conflict with Swift broker |
| 9200 (host) | Dashboard | Next.js |
| 9400 (host) | Envoy | gRPC-web proxy (Docker Compose) |
| 9443 (host) | pki-core | Certificate issuance |
| 9300 (host) | Postgres | Primary DB |

The Go services container does NOT bind host ports 50051/50052 — those belong to the Swift broker process. The `docker-compose.override.yml` remaps the services container to 50061/50062 for debugging and sets required dev environment variables. It is gitignored. Re-create it if missing (see below).

### Starting the full stack

```bash
cd /Users/wendy/Documents/Projects/cloud

# 1. Start Docker if not running
open -a Docker
until docker info &>/dev/null; do sleep 2; done

# 2. Start Docker Compose services (Postgres, pki-core, dashboard, Envoy, Go services)
make dev &
sleep 30

# 3. Start the Swift broker on host (needs ports 50051 and 50052)
cd swift && ./scripts/start-local.sh > /tmp/swift-broker.log 2>&1 &
sleep 10
```

Verify all services are up:
```bash
lsof -iTCP:50051 -iTCP:50052 -iTCP:9200 -sTCP:LISTEN -nP 2>/dev/null | grep -E "50051|50052|9200"
```

### Recreating docker-compose.override.yml

If `docker-compose.override.yml` does not exist at the repo root, create it:

```yaml
# Local dev override. Not committed — gitignored.
#
# Uses the real pki-core from the sibling repo at ../pki-core.
# pki-core is required for the Swift broker to issue device and user certificates.
#
# Enables dev auth: the dashboard shows a "Dev Login" button that sets a fixed
# fake JWT as the firebase-token cookie. The services backend accepts that token
# without verifying its signature when FIREBASE_AUTH_DISABLED=true.
# Run `make seed-dev` once after `make dev` to populate the dev user and org.
services:
  pki-core:
    build:
      context: ../pki-core
      dockerfile: Dockerfile
      args: {}
    healthcheck:
      disable: true

  dashboard:
    environment:
      - GRPC_SERVER_ENDPOINT=http://envoy:8080
      - NEXT_PUBLIC_DEV_AUTH_ENABLED=true
      - DEV_AUTH_ENABLED=true
      - NEXT_PUBLIC_APP_URL=http://localhost:9200

  services:
    ports:
      # Remap host ports so the Go services container can coexist with the
      # Swift broker (which binds host :50051 and :50052 directly).
      # Internal Docker routing (Envoy -> services:50051) is unaffected.
      - "50061:50051"
      - "50062:50052"
    environment:
      PKICORE_ENABLED: "false"
      FIREBASE_AUTH_DISABLED: "true"
      # Must match JWT_SECRET in swift/scripts/start-local.sh so the Swift
      # broker can verify enrollment tokens issued by the Go services.
      PROVISIONING_JWT_SECRET: "local-dev-jwt-secret-change-in-prod"
```

Key notes on the override:
- `PROVISIONING_JWT_SECRET` in the services container must match `JWT_SECRET` in `swift/scripts/start-local.sh` (both default to `"local-dev-jwt-secret-change-in-prod"`). A mismatch causes `wendy auth login` to fail with "invalid or expired enrollment token".
- `PKICORE_ENABLED: "false"` in the services container is intentional — the Go services do not call pki-core directly; only the Swift broker does.
- The base `docker-compose.yml` does NOT bind host ports 50051/50052 for the services container. This is a committed change. Docker Compose merges port lists, so adding ports only in the override avoids a conflict with the Swift broker.

## Authenticating the CLI Against the Local Stack

The `wendy` CLI needs a local auth session to call the Swift broker. Run this once per session (the session persists in `~/.wendy/config.json`):

```bash
cd /Users/wendy/Documents/Projects/cloud
wendy auth login --cloud http://localhost:9200 --cloud-grpc localhost:50051 --json > /tmp/wendy-auth-out.txt 2>&1 &
sleep 3
cat /tmp/wendy-auth-out.txt  # shows the cli-auth URL with callback port
```

Then use the Chrome MCP tools to complete the flow:
1. Read the callback port from the output: `http://localhost:9200/cli-auth?redirect_uri=http%3A%2F%2F127.0.0.1%3A<PORT>%2Fcli-callback`
2. Navigate to that URL: `mcp__Claude_in_Chrome__navigate` with `url: "http://localhost:9200/cli-auth?redirect_uri=http://127.0.0.1:<PORT>/cli-callback"`
3. If redirected to `/login`: click "Dev Login (local only)" at approximately coordinate (756, 508), wait 3s, re-navigate to the cli-auth URL
4. Once the org list loads, click "Select" next to "wendylabsinc" (row 2, button at approximately coordinate (1113, 391))
5. Wait 8 seconds for certificate issuance to complete
6. Verify: `cat /tmp/wendy-auth-out.txt` should end with `Certificates saved.`

Expected successful output:
```
Received enrollment token.
Authentication successful. Certificates saved.
```

## Running the Test Suite

### Swift integration tests (primary signal)

```bash
cd /Users/wendy/Documents/Projects/cloud
make test-swift 2>&1 | tail -40
```

Filter to a specific test:
```bash
make test-swift FILTER=TestCreateAsset
```

Tests use BrokerFixture (in-process gRPC, MockPKIServer, real Postgres). No real Swift broker or pki-core needed for tests. Approximately 60 tests across 6 suites.

### Go services tests

```bash
make test-services 2>&1 | tail -40
```

## Bug Finding and Fixing

### What to check each iteration

1. Run `make test-swift` — any failures are the primary signal.
2. Check broker logs for runtime errors: `cat /tmp/swift-broker.log | grep -iE "error|fatal|panic" | tail -30`
3. Check Go services logs: `docker compose logs --since 10m services 2>/dev/null | grep -iE "error|fatal|panic" | tail -20`
4. Run `wendy discover --json 2>&1 | head -10` — verify Gerrit (wendyos-gerrit.local) is reachable if hardware testing is the goal.

### Fix workflow — worktree per fix, pull request required

Every code change follows this sequence. Do NOT commit directly to the current branch.

**Step 1: Identify the current branch**
```bash
git -C /Users/wendy/Documents/Projects/cloud branch --show-current
# Note this as BASE_BRANCH
```

**Step 2: Create a worktree for the fix**
```bash
BASE=/Users/wendy/Documents/Projects/cloud
BRANCH=fix/<short-description>   # e.g. fix/nil-bool-cast
git -C "$BASE" worktree add "$BASE/.worktrees/$BRANCH" -b "$BRANCH"
```

**Step 3: Dispatch a subagent to implement and test the fix in the worktree**

Give the subagent:
- The exact file(s) and line(s) to change
- The root cause and the fix
- Instructions to run `make test-swift FILTER=<TestName>` inside the worktree to verify
- Instructions to commit once tests pass

The subagent works entirely inside `$BASE/.worktrees/$BRANCH` and never touches the main checkout.

**Step 4: UI smoke test**

Before opening the pull request, verify the fix in the running dashboard:
1. Ensure the full stack is up (`make dev` + `start-local.sh`)
2. Use Chrome MCP to exercise the relevant flow in the browser (http://localhost:9200)
3. Confirm no visible regressions

**Step 5: Open a pull request and wait for CI**
```bash
cd "$BASE/.worktrees/$BRANCH"
gh pr create --base BASE_BRANCH --title "fix: <description>" --body "..."
gh pr checks --watch   # wait for all checks to pass
```

Do NOT proceed until `gh pr checks` reports all green. If CI fails, diagnose and push additional commits to the same branch.

**Step 6: Merge and clean up**
```bash
gh pr merge --squash --delete-branch
git -C "$BASE" worktree remove "$BASE/.worktrees/$BRANCH"
```

Only after the pull request is merged does the fix land on the current branch.

**When to open a Linear issue instead of fixing inline:**
- The fix touches more than 30 lines or spans multiple subsystems
- Root cause is unclear after 15 minutes of investigation
- Fix requires architectural changes

### Common failure modes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Bool? nil creates OID 0 params` | PostgresNIO can't infer type for nil Bool | Use `\(value)::bool` explicit cast |
| `connection pool exhausted` | Postgres default max_connections (100) hit | Set pool size to 1 in TestDB.swift |
| Handler not registered in BrokerFixture | Handler created but never added to test server | Register handler in BrokerFixture.swift |
| `Address already in use` on :50051 or :50052 | Previous broker process still running | `pkill -f start-local.sh; pkill -f /.build/.*broker; sleep 2` |
| `invalid or expired enrollment token` | `PROVISIONING_JWT_SECRET` in services container does not match `JWT_SECRET` in swift/scripts/start-local.sh | Set `PROVISIONING_JWT_SECRET: "local-dev-jwt-secret-change-in-prod"` in docker-compose.override.yml services environment |
| `unknown profile "operator-tier-a"` | pki-core profile name mismatch; operator certs must use profile `"operator"` | Fixed in CertificateServiceHandler.swift (both IssueCertificate and RefreshCertificate) |
| `certificate is not valid for client authentication` | Production CLI cert missing clientAuth Extended Key Usage | Known cloud PKI bug; use local stack for testing |
| `pki-core unavailable at startup` | pki-core repo not cloned | Clone to `/Users/wendy/Documents/Projects/pki-core` and ensure override builds from `../pki-core` |

## Loop Behavior

After each iteration:
- If test failures were found and fixed: schedule next check in 5 minutes (short cycle to confirm fix held)
- If test failures were found but not fixed: schedule next check in 10 minutes (give time for manual review)
- If everything is clean: schedule next check in 30 minutes

Log a summary each iteration:
```
[wendy-cloud-iterate] Iteration complete.
  Tests: N passed, M failed
  Fixes applied: <list or "none">
  Device: <reachable / unreachable / skipped>
  Next check: Xm
```

## Device Testing (optional)

Gerrit is a Jetson Orin Nano enrolled in the production cloud:
- LAN hostname: `wendyos-gerrit.local`
- Production cloud org: 2, asset ID: 95
- mTLS port post-enrollment: 50052

Check reachability: `wendy discover --json 2>&1 | head -10`

Device tests require the production cloud session (in `~/.wendy/config.json`) and a cert with `clientAuth` Extended Key Usage — currently blocked by a cloud PKI bug. Skip device tests if the production cert lacks clientAuth Extended Key Usage.
