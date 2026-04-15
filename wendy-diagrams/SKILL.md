---
name: wendy-diagrams
description: 'D2 diagramming standards for Wendy repositories. Use when: (1) creating or editing a docs/*.d2 file, (2) asked to diagram architecture or system design, (3) setting up CI for diagram rendering, (4) asked about diagram colours, layout, or naming conventions.'
---

# D2 Diagramming — Wendy Standards

All Wendy repositories store diagrams as D2 source files under `docs/` and render them via CI. The canonical render is committed to the branch by the pipeline; local renders are gitignored.

## Agent Behavior Contract (Follow These Rules)

- Always use the ELK layout engine. Never use TALA (requires a paid licence).
- Always include the boilerplate `vars` and `classes` block at the top of every `.d2` file.
- Never apply D2 built-in themes. They flatten all nodes to a single colour, removing semantic distinction.
- Never set `width`, `height`, or `style.padding` on nodes. ELK sizes nodes from label content; overrides break the layout.
- Assign `class:` to individual nodes. Use inline `style.*` declarations on container nodes (they need a lighter tint, not the class fill).
- Use `style.stroke-dash: 5` for ambient infrastructure dependencies. Use solid lines for direct runtime calls.
- Do not embed a legend inside the diagram. Put the solid/dashed explanation in the repository README as prose.
- When a node sits directly adjacent to a container and its edge would target a child inside that container, connect to the container instead and name the internal destination in the edge label. This prevents ELK from routing the edge along the container wall.
- Keep node identifiers short PascalCase tokens. Put descriptive text in the quoted label using `·` as a separator and `\n` for a second line.
- `docs/*.png` is gitignored. CI commits the PNG with `git add --force`. The first PNG in a new repo must be bootstrapped manually with `git add --force docs/architecture.png`.

## Boilerplate (Top of Every .d2 File)

```d2
vars: {
  d2-config: {
    layout-engine: elk
  }
}

classes: {
  ext:   {style.fill: "#f8fafc"; style.stroke: "#94a3b8"; style.font-color: "#334155"}
  dash:  {style.fill: "#dbeafe"; style.stroke: "#3b82f6"; style.font-color: "#1e40af"}
  gw:    {style.fill: "#ede9fe"; style.stroke: "#7c3aed"; style.font-color: "#4c1d95"}
  auth:  {style.fill: "#fef3c7"; style.stroke: "#d97706"; style.font-color: "#78350f"}
  svc:   {style.fill: "#dcfce7"; style.stroke: "#16a34a"; style.font-color: "#14532d"}
  db:    {style.fill: "#fee2e2"; style.stroke: "#dc2626"; style.font-color: "#7f1d1d"}
  infra: {style.fill: "#f1f5f9"; style.stroke: "#64748b"; style.font-color: "#1e293b"}
}
```

## Colour Classes

| Class | Role |
|-------|------|
| `ext` | External actors — browsers, devices, third-party callers |
| `dash` | Frontend / dashboard layer |
| `gw` | API gateways and proxies |
| `auth` | Authentication and authorisation |
| `svc` | Backend services and business logic |
| `db` | Databases and persistent stores |
| `infra` | Platform services — certificate authorities, registries, log aggregators |

## Shapes

| Shape | Use for |
|-------|---------|
| `shape: oval` | External actors |
| `shape: cylinder` | Databases |
| (default rectangle) | Everything else |

## Naming

```d2
# Identifier: short PascalCase
# Label: descriptive, middle-dot separator, \n for second line
Envoy: "Envoy Proxy\ngRPC-Web to gRPC · :9400" { class: gw }

# Container: short uppercase label, inline style for lighter tint
Backend: "BACKEND" {
  style.fill: "#f0fdf4"
  style.stroke: "#16a34a"
  style.font-color: "#14532d"

  Auth: "Auth & Access Control\nJWT · PAT · mTLS · Casbin RBAC" { class: auth }
}
```

## ELK Layout — Edge Direction Controls Vertical Placement

ELK places source nodes above target nodes. Draw edges in the direction that produces the intended vertical stack.

For infrastructure nodes that should sit at the top of the diagram, flip the edge direction so they are the source:

```d2
# Infrastructure placed above Backend because it is the source
Infrastructure.Firebase -> Backend.Auth: "Provides JWKS" { style.stroke-dash: 5 }

# NOT: Backend.Auth -> Infrastructure.Firebase
```

For service-to-database connections, draw forward (service to database) so the database layer sinks to the bottom:

```d2
Backend.Identity -> Database.Users: "SQL · sqlc"
```

## Edge Conventions

```d2
# Direct runtime call — solid line (default)
Dashboard.App -> Envoy: "gRPC-Web · HTTP/1.1"

# Ambient dependency (keys, certs, credentials, log ingestion) — dashed
Infrastructure.Firebase -> Backend.Auth: "Provides JWKS" { style.stroke-dash: 5 }
```

## Adjacent Node — Container Connection Pattern

When a node is positioned beside a container and its edge would target an inner node, connect to the container and name the destination in the label:

```d2
# Correct — avoids wall-hugging edge routing
WendyOS -> Backend: "mTLS · :50052\nto Device Management"

# Incorrect — ELK routes this along the container wall
WendyOS -> Backend.DevMgmt: "mTLS · :50052"
```

## CI Job

Add this job to `.github/workflows/ci.yml`. It renders only changed `.d2` files on pull requests and commits the PNG back with `--force` to bypass the gitignore.

```yaml
jobs:
  diagrams:
    name: Render D2 diagrams
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}
          fetch-depth: 0

      - name: Detect changed diagrams
        id: check
        run: |
          CHANGED=$(git diff --name-only origin/${{ github.base_ref }}...HEAD \
                    | grep '^docs/.*\.d2$' || true)
          echo "changed=$([[ -n "$CHANGED" ]] && echo true || echo false)" >> $GITHUB_OUTPUT

      - name: Install D2
        if: steps.check.outputs.changed == 'true'
        run: curl -fsSL https://d2lang.com/install.sh | sh -s --

      - name: Render diagrams
        if: steps.check.outputs.changed == 'true'
        run: |
          for f in $(git diff --name-only origin/${{ github.base_ref }}...HEAD \
                     | grep '^docs/.*\.d2$'); do
            d2 --layout elk "$f" "${f%.d2}.png"
          done

      - name: Commit rendered diagrams
        if: steps.check.outputs.changed == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add --force docs/*.png
          git diff --cached --quiet \
            || git commit -m "ci: render updated diagrams [skip ci]"
          git push
```

### Bootstrap a New Repository

After adding the `.d2` file and CI job for the first time, commit the initial PNG manually:

```bash
d2 --layout elk docs/architecture.d2 docs/architecture.png
git add --force docs/architecture.png
git commit -m "docs: add initial architecture diagram"
```

## Local Development

```bash
# Install D2
curl -fsSL https://d2lang.com/install.sh | sh -s --

# Watch and re-render on save (output is gitignored)
d2 --layout elk --watch docs/architecture.d2 docs/architecture.png
```
