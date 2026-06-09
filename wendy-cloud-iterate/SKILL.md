---
name: wendy-cloud-iterate
description: 'Autonomous continuous integration loop for the Wendy Cloud repository. Use when asked to: (1) iterate on the cloud stack, (2) find and fix bugs in Wendy Cloud, (3) run the cloud test loop, (4) continuously test the Swift broker, (5) scan for regressions after new features. This skill manages the full local dev stack autonomously including starting Docker, the Swift broker, pki-core, running tests, diagnosing failures, and applying fixes.'
---

# Wendy Cloud Iterate

This skill drives an autonomous continuous loop that starts the Wendy Cloud dev stack, runs the integration test suite, diagnoses any failures, attempts fixes, and self-paces based on results.

## Prerequisites Check

Run this block at the very start of every session before touching any code or starting any service. Fix every gap before proceeding.

```bash
#!/usr/bin/env bash
set -euo pipefail
MISSING=()

# --- Homebrew (needed to install everything else on macOS) ---
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# --- Docker Desktop ---
if ! command -v docker &>/dev/null; then
  echo "Docker not found. Install Docker Desktop from https://www.docker.com/products/docker-desktop/ then re-run."
  MISSING+=("Docker Desktop")
else
  # Docker installed but daemon not running — start it
  if ! docker info &>/dev/null 2>&1; then
    echo "Starting Docker Desktop..."
    open -a Docker
    echo "Waiting for Docker to be ready..."
    until docker info &>/dev/null 2>&1; do sleep 3; done
    echo "Docker ready."
  fi
fi

# --- GitHub CLI ---
if ! command -v gh &>/dev/null; then
  echo "Installing gh..."
  brew install gh
fi
# Check auth
if ! gh auth status &>/dev/null 2>&1; then
  echo "gh is not authenticated. Run: gh auth login"
  MISSING+=("gh auth (run: gh auth login)")
fi

# --- Swift toolchain ---
if ! command -v swift &>/dev/null; then
  echo "Swift not found. Install Xcode or the Swift toolchain from https://swift.org/download/"
  MISSING+=("Swift toolchain")
fi

# --- protoc (required for Swift broker build) ---
if ! command -v protoc &>/dev/null; then
  echo "Installing protoc..."
  brew install protobuf
fi

# --- wendy CLI ---
if ! command -v wendy &>/dev/null; then
  echo "Installing wendy CLI..."
  brew install wendy
fi

# --- pki-core repo ---
if [ ! -d "/Users/wendy/Documents/Projects/pki-core" ]; then
  echo "Cloning pki-core..."
  gh repo clone wendylabsinc/pki-core /Users/wendy/Documents/Projects/pki-core -- --depth=1
fi

# --- Cloud repo ---
if [ ! -d "/Users/wendy/Documents/Projects/cloud" ]; then
  echo "Cloning cloud repo..."
  gh repo clone wendylabsinc/cloud /Users/wendy/Documents/Projects/cloud
fi

# --- Chrome MCP ---
# The Chrome MCP extension enables autonomous browser control (needed for
# wendy auth login). Check by listing connected browsers.
# If the tool is unavailable, auth must be completed manually.
CHROME_MCP_AVAILABLE=true
if ! command -v google-chrome &>/dev/null && ! ls /Applications/Google\ Chrome.app &>/dev/null 2>&1; then
  echo "WARNING: Google Chrome not found. Install Chrome and the Claude Chrome extension"
  echo "         to enable autonomous wendy auth login."
  CHROME_MCP_AVAILABLE=false
fi

# --- Report ---
if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "BLOCKED: the following must be resolved manually before the loop can run:"
  for item in "${MISSING[@]}"; do
    echo "  - $item"
  done
  exit 1
fi

echo "All prerequisites satisfied."
echo "Chrome MCP available: $CHROME_MCP_AVAILABLE"
```

If Chrome MCP is not available, `wendy auth login` must be completed manually by the user: open the URL printed by the CLI in a browser, select the org, and wait for "Certificates saved." before the loop proceeds.

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

**Step 4: UI smoke test and plan expansion**

The UI smoke test plan lives in the cloud repo and is meant to grow. Your job is not
only to execute it but to expand it when you find gaps.

Read the plan:
```bash
cat /Users/wendy/Documents/Projects/cloud/docs/testing/ui-smoke-test.md
```

**Execute:** Run all sections relevant to the change using Chrome MCP tools at
http://localhost:9200. At minimum always run sections 1 (Authentication) and
6 (Console errors). Take a screenshot after each section.

**Expand:** After executing, identify gaps using the route grep in the plan's
"Finding gaps" block:
```bash
grep -r "path:\|href=\|router.push\|<Link" \
  /Users/wendy/Documents/Projects/cloud/dashboard/src \
  --include="*.tsx" --include="*.ts" -h \
  | grep -oE '"[/][^"]*"' | sort -u
```
Cross-reference with the coverage index table at the top of the plan. For any route
or flow that appears in the source but not in the index, write a new section following
the format in the "Adding new sections" block and add it to the plan file inside the
current worktree. The additions travel with the pull request.

Attach screenshots to the pull request body as evidence of each executed section.

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

### Pacing

After each iteration, schedule the next wake-up based on what was found:

| Outcome | Next check |
|---|---|
| Failures found and fixed | 5 minutes (confirm the fix held) |
| Failures found, not fixed | 10 minutes (allow time for manual review) |
| Everything clean | 30 minutes |

### Self-termination

The loop terminates itself after **3 consecutive clean iterations** — no test
failures, no broker errors, no new smoke test gaps, device reachable or skipped.

To end the loop, simply do not schedule the next wake-up. Log a termination message
and stop. The loop resumes on the next explicit `/loop` invocation.

```
[wendy-cloud-iterate] 3 consecutive clean scans. Nothing left to fix.
  Terminating loop. Run again with /loop to restart.
```

Track the consecutive clean count in the iteration summary. Reset it to 0 whenever
a failure is found or a fix is applied, even if the fix succeeds.

The threshold of 3 is intentional: one clean scan after a fix is not enough to
confirm stability (the next test run could expose a regression the fix introduced).
Three clean scans at 30-minute intervals means the stack has been stable for 90
minutes, which is a reasonable confidence threshold before handing back control.

If you want to run indefinitely (e.g. leaving the loop running overnight), pass
`no-auto-terminate` as part of the invocation prompt:
```
/loop Use the wendy-cloud-iterate skill to continuously scan the Wendy Cloud
repository. Do not auto-terminate.
```

### Iteration summary

Log this at the end of every iteration:
```
[wendy-cloud-iterate] Iteration N complete.
  Tests: X passed, Y failed
  Fixes applied: <list or "none">
  Smoke test: <sections run> / <gaps added: N>
  Device: <reachable / unreachable / skipped>
  Consecutive clean: Z/3
  Next check: Xm  (or "loop terminated")
```

## Device Testing (optional)

Device tests verify that a real WendyOS device can be reached and responds correctly.
They are optional — skip if no device is connected or if the production cert lacks
`clientAuth` Extended Key Usage (a known cloud PKI bug).

### Identifying the device

**If a device was named in the conversation** (e.g. "use gerrit", "test against
my Jetson"), use that hostname directly.

**Otherwise, discover what is on the network:**
```bash
wendy discover --json 2>&1
```

In autonomous loop mode, use the first device returned by discover. If the list is
empty, log "no device found — skipping device tests" and continue.

In interactive mode (user is present), present the discovered list and ask which
device to use before proceeding.

**Store the chosen hostname as `DEVICE_HOST`** (just the hostname, no port):
```bash
DEVICE_HOST=<hostname>   # e.g. wendyos-gerrit.local or 192.168.1.42
```

### Running device checks
```bash
# Verify reachability on the plaintext port
wendy discover --json 2>&1 | grep "$DEVICE_HOST"

# Check device info (requires valid clientAuth cert)
wendy cloud device info --device "$DEVICE_HOST" --json 2>&1 | head -20
```

If `device info` fails with "certificate is not valid for client authentication",
skip the mTLS checks — this is the known production PKI bug, not a regression.
