---
name: wendy-iterating
description: 'General-purpose iterate-fix-and-ship loop for any codebase. Use when: (1) running a continuous bug-fixing loop, (2) iterating on a feature until all tests pass, (3) driving worktree-per-fix PR workflows autonomously. Pair with a project-specific testing skill (e.g. /wendy-cloud-testing) that supplies test commands and failure-mode knowledge.'
---

# Wendy Iterating

This skill drives a continuous find-fix-ship loop. It owns the workflow mechanics:
worktree isolation, subagent dispatch, pull request lifecycle, loop pacing, and
auto-termination. It does **not** know how to test your specific project — pair it
with a testing skill.

## Testing Companion

Before starting the loop, identify which testing skill supplies:

1. **Test command** — what to run to determine pass/fail
2. **Log check** — where to look for runtime errors after tests pass
3. **Clean definition** — what "no issues found" looks like for this project
4. **Common failure modes** — known root causes and their fixes

Example invocation:
> "Iterate on this feature using /wendy-iterating. Use /wendy-cloud-testing to determine how to test for bugs and completion."

At the start of each iteration: invoke the testing skill, run its checks, then apply this skill's fix workflow and pacing.

## Fix Workflow — Worktree Per Fix, Pull Request Required

Every code change follows this sequence. Do NOT commit directly to the current branch.

**Step 1: Identify the current branch**
```bash
git -C <repo-root> branch --show-current
# Note this as BASE_BRANCH
```

**Step 2: Create a worktree for the fix**
```bash
BASE=<repo-root>
BRANCH=fix/<short-description>
git -C "$BASE" worktree add "$BASE/.worktrees/$BRANCH" -b "$BRANCH"
```

**Step 3: Dispatch a subagent to implement and test the fix in the worktree**

Give the subagent:
- The exact file(s) and line(s) to change
- The root cause and the fix
- Instructions to run the targeted test command inside the worktree to verify
- Instructions to commit once tests pass

The subagent works entirely inside `$BASE/.worktrees/$BRANCH` and never touches
the main checkout.

**Step 4: Open a pull request and wait for CI**
```bash
cd "$BASE/.worktrees/$BRANCH"
gh pr create --base "$BASE_BRANCH" --title "fix: <description>" --body "..."
gh pr checks --watch
```

Do NOT proceed until `gh pr checks` reports all green. If CI fails, diagnose and
push additional commits to the same branch.

**Step 5: Merge and clean up**
```bash
gh pr merge --squash --delete-branch
git -C "$BASE" worktree remove "$BASE/.worktrees/$BRANCH"
```

Only after the pull request is merged does the fix land on the current branch.

**When to open a Linear issue instead of fixing inline:**
- The fix touches more than 30 lines or spans multiple subsystems
- Root cause is unclear after 15 minutes of investigation
- Fix requires architectural changes

## Loop Behavior

### Pacing

Schedule the next wake-up based on what was found this iteration:

| Outcome | Next check |
|---|---|
| Failures found and fixed | 5 minutes (confirm the fix held) |
| Failures found, not fixed | 10 minutes (allow time for manual review) |
| Everything clean | 30 minutes |

### Self-termination

The loop terminates after **3 consecutive clean iterations** — no test failures, no
runtime errors, no new gaps found.

To end the loop, omit the next `ScheduleWakeup` call. Log a termination message
before stopping so the outcome is clear.

```
[wendy-iterating] 3 consecutive clean scans. Nothing left to fix.
  Terminating loop. Run again to restart.
```

Track the consecutive clean count in the iteration summary. Reset it to 0 whenever
a failure is found or a fix is applied, even if the fix succeeds immediately.

To run indefinitely, include `no-auto-terminate` in the invocation prompt.

### Iteration summary

Log this at the end of every iteration:
```
[wendy-iterating] Iteration N complete.
  Tests: X passed, Y failed
  Fixes applied: <list or "none">
  Consecutive clean: Z/3
  Next check: Xm  (or "loop terminated")
```
