---
name: linear
description: 'Linear issue tracking and project management through the CLI or GraphQL API. Use when developers mention: (1) Linear issues or tickets, (2) issue tracking or task management, (3) WDY team issues, (4) closing, updating, or triaging tickets, (5) linking PRs to issues, (6) issue states (triage, backlog, started, completed).'
---

# Linear

## Overview

Use the Linear CLI (`linear`) when it is available. Do not assume it is installed. When the CLI is unavailable or does not support the required operation, use Linear's GraphQL API with the API key already supplied by the environment.

## Access selection

1. Check for the CLI without failing:

   ```bash
   command -v linear
   ```

2. If it exists, use the CLI guidance below.
3. Otherwise verify that the GraphQL credential is available without printing it:

   ```bash
   test -n "${LINEAR_API_KEY:-}"
   ```

   Projects using direnv commonly declare `LINEAR_API_KEY` in an ignored environment file and load it from `.envrc`. If it is missing, let direnv load the project environment (for example, by entering/allowing the project or using `direnv exec`) rather than reading, logging, or copying the secret.

4. Send GraphQL operations to `https://api.linear.app/graphql` with `Authorization: $LINEAR_API_KEY` and JSON content type. Use GraphQL variables rather than interpolating issue text into the query:

   ```bash
   query='query Viewer { viewer { id name email } }'
   payload=$(jq -cn --arg query "$query" '{query: $query, variables: {}}')
   response=$(curl -sS https://api.linear.app/graphql \
     -H "Authorization: $LINEAR_API_KEY" \
     -H 'Content-Type: application/json' \
     --data "$payload")
   jq -e '.errors == null' <<<"$response" >/dev/null || {
     jq '.errors' <<<"$response" >&2
     exit 1
   }
   jq '.data' <<<"$response"
   ```

For mutations, query IDs and current state first rather than guessing or relying on stale hardcoded IDs. Treat a GraphQL HTTP 200 response containing an `errors` array as a failure. Never print the API key, include it in command output, commit it, or place it directly in a query or variables object.

## Issue authoring

A request to create, draft, rewrite, or expand an issue authorizes faithful problem capture—not product planning or solution design. The issue should explain the problem to solve and leave implementation discovery to the human or agent who owns the work.

### Default format

Every issue body opens with one short plain-language paragraph:

```markdown
> **In plain terms:** Describe what is wrong or missing, who or what it affects, and why it matters. Do not prescribe the implementation.
```

This block must stand alone for a non-specialist reader. If the request contains only one sentence, the issue may contain only this one-sentence block. Add further sections only when sourced material justifies them.

### Tentpoles

- **Problem before solution.** Describe current behavior, the desired user or operational outcome when known, the affected people or systems, impact, and useful evidence. Titles should name the problem or outcome rather than an implementation task.
- **Only sourced facts.** Include only details stated by the human, present in a cited source, or directly verified. Preserve uncertainty instead of filling gaps with plausible requirements.
- **No ticket boilerplate.** Do not add headings merely to make an issue look complete. There is no minimum length and no required template beyond the opening plain-terms block.
- **No invented requirements.** Do not infer acceptance criteria, user stories, personas, scope, non-goals, edge cases, testing, rollout, migration, telemetry, security, or operational requirements.
- **No invented planning metadata.** Do not infer priority, estimate, deadline, labels, parent, dependencies, assignee, subtasks, or checklists.
- **Do not lock in a solution.** Do not invent architecture, APIs, data models, UI, or implementation steps. If the human suggests a solution, retain it as attributed context or a constraint without expanding it into settled design.
- **Clarify only when necessary.** Ask a concise question only when creating the issue without it would materially misstate the problem. Otherwise create the smallest faithful issue and leave genuine unknowns open.
- **Prefer an existing issue.** Check for likely duplicates when practical; reuse and minimally correct an existing issue rather than creating a parallel ticket.

Add acceptance criteria, planning metadata, or solution detail only when a human explicitly supplied or agreed to it, or when faithfully copying cited material. Make the source or decision clear and do not elaborate beyond it.

Expected behavior stated in a bug report belongs in the problem description; do not duplicate it as generated acceptance criteria. Starting work on an issue also does not authorize rewriting it into a solution specification—put implementation proposals in the eventual owner's plan or discussion instead.

Before creating or updating an issue, remove every sentence that cannot be traced to the request, cited evidence, direct observation, or an explicit human decision.

## CLI configuration

CLI commands require `LINEAR_ISSUE_SORT` to be set:

```bash
export LINEAR_ISSUE_SORT=priority
```

Without this, most commands will fail.

## Team

Use `linear team list` to discover available teams.

## Issue States

| State | Description |
|-------|-------------|
| `triage` | New issues needing triage |
| `backlog` | Prioritized but not started |
| `unstarted` | Ready to start (Todo) |
| `started` | In Progress |
| `completed` | Done |
| `canceled` | Canceled/Won't do |

## Common Commands

### List Issues

```bash
# Active issues (excludes completed/canceled)
LINEAR_ISSUE_SORT=priority linear issue list --team WDY --no-pager

# Filter by state
LINEAR_ISSUE_SORT=priority linear issue list --team WDY --no-pager -s started -s unstarted

# All issues including completed/canceled
LINEAR_ISSUE_SORT=priority linear issue list --team WDY --no-pager --all-states
```

### View Issue

```bash
LINEAR_ISSUE_SORT=priority linear issue view WDY-123 --no-pager
```

### Update Issue Status

```bash
linear issue update WDY-123 --state "Done"
linear issue update WDY-123 --state "In Progress"
```

### Create PR Linked to Issue

```bash
linear issue pr WDY-123
```

### List Teams

```bash
linear team list
```

## Workflows

### Check Issues to Close

```bash
# List active issues
LINEAR_ISSUE_SORT=priority linear issue list --team WDY --no-pager -s started -s unstarted -s backlog

# Cross-reference with recent commits
git log --oneline -30 --all
```

### Triage New Issues

```bash
# View issues in triage
LINEAR_ISSUE_SORT=priority linear issue list --team WDY --no-pager -s triage
```
