# `node.js.yml`

## Purpose

Node.js CI pipeline with three parallel jobs - build, lint, and test - running against Node.js 20. Validates that the project compiles, passes linting rules, and all tests pass on every push and pull request to `dev` and `main`.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev, main]` |
| `pull_request` | branches: `[dev, main]` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Node version | `20` |
| Typical duration | ~2–5 min |
| Concurrency | none |
| Permissions | default |

---

## Environment Variables

| Variable | Value | Purpose |
|----------|-------|--------|
| `GH_TOKEN` | `secrets.GITHUB_TOKEN` | npm auth for private packages |
| `NPM_SCOPE` | `@frmscoe` | npm scope for registry routing |
| `NPM_REGISTRY` | `https://npm.pkg.github.com/` | GitHub Packages registry |
| `NODE_ENV` | `test` | sets test environment |
| `STARTUP_TYPE` | `nats` | messaging system type expected by some tests |

---

## Jobs

### `build` - run build

1. `actions/checkout@v4`
2. `actions/setup-node@v4` - Node 20, npm cache, registry and scope
3. `npm ci`
4. `npm run build`

### `lint` - check style

1. `actions/checkout@v4`
2. `actions/setup-node@v4`
3. `npm ci`
4. `npm run lint`

### `test` - check tests

1. `actions/checkout@v4`
2. `actions/setup-node@v4`
3. `npm ci`
4. `npm test`

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|-------|
| `GITHUB_TOKEN` | auto | npm authentication via `GH_TOKEN` |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| **All repos** | **Excluded from sync** - `node.js.yml` is explicitly removed before the sync bundle is assembled; every repo maintains its own copy |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v4` | - |
| `actions/setup-node` | tag ref `v4` | - |

---

## Known Limitations / Notes

- Excluded from sync to preserve per-repo customisations (some repos have additional jobs or environment-specific configurations). Any changes to the canonical file must be propagated manually to each repo (see `update-workflows.md` Track A6 / Track B4).
- `NPM_SCOPE` is set to `@frmscoe`; this is intentional as many private packages are still published under the `@frmscoe` scope.
- `dependabot[bot]` actors are excluded.

---

## Repository Overrides

Not applicable - this workflow is not synced; every repo maintains its own copy. Some repos previously had a `bench` job included in this file; that job is being removed via separate PRs.
