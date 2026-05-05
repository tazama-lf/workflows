# `node-ci.yml`

## Purpose

Reusable Node.js CI pipeline with three parallel jobs - build, lint, and test - running against Node.js 20. Contains all CI logic for Node.js consumer repos. Called by the [`node.js.yml`](nodejs.md) caller stub which is synced to all consumer repos.

This file is **not synced** to consumer repos - it stays in `tazama-lf/workflows` and is referenced by the stub at runtime via `uses: tazama-lf/workflows/.github/workflows/node-ci.yml@dev`.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `node.js.yml` stub in consumer repos |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Node version | `20` |
| Typical duration | ~2-5 min |
| Concurrency | none |
| Permissions | `contents: read` |

---

## Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `NPM_SCOPE` | `@tazama-lf` | npm scope for GitHub Packages registry routing |
| `NPM_REGISTRY` | `https://npm.pkg.github.com/` | GitHub Packages registry URL |
| `NODE_ENV` | `test` | sets test environment for all jobs |

---

## Jobs

### `build` - run build

**Condition:** `github.actor != 'dependabot[bot]' && github.actor != 'dependabot-preview[bot]'`

1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (v6.0.2)
2. `actions/setup-node@53b83947a5a98c8d113130e565377fae1a50d02f` (v6.3.0) - Node 20, npm cache, registry and scope
3. `npm ci` (authenticated via `NODE_AUTH_TOKEN: secrets.GITHUB_TOKEN`)
4. `npm run build`

### `lint` - check style

**Condition:** `github.actor != 'dependabot[bot]' && github.actor != 'dependabot-preview[bot]'`

1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (v6.0.2)
2. `actions/setup-node@53b83947a5a98c8d113130e565377fae1a50d02f` (v6.3.0)
3. `npm ci` (authenticated via `NODE_AUTH_TOKEN: secrets.GITHUB_TOKEN`)
4. `npm run lint`

### `test` - check tests

**Condition:** `github.actor != 'dependabot[bot]' && github.actor != 'dependabot-preview[bot]'`

1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (v6.0.2)
2. `actions/setup-node@53b83947a5a98c8d113130e565377fae1a50d02f` (v6.3.0)
3. `npm ci` (authenticated via `NODE_AUTH_TOKEN: secrets.GITHUB_TOKEN`)
4. `npm test`

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `GITHUB_TOKEN` | auto | npm authentication for GitHub Packages (`NODE_AUTH_TOKEN` per step) |

Secrets are forwarded from the caller stub via `secrets: inherit`.

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| **All repos** | **Not synced** - reusable workflow stays in `tazama-lf/workflows` only; consumer repos reference it by the `@dev` branch ref at runtime |

The caller stub (`node.js.yml`) is what gets synced. See [`nodejs.md`](nodejs.md).

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `de0fac2e4500dabe0009e67214ff5f5447ce83dd` | v6.0.2 |
| `actions/setup-node` | `53b83947a5a98c8d113130e565377fae1a50d02f` | v6.3.0 |

---

## Known Limitations / Notes

- All three jobs run in parallel; there is no dependency between them.
- `npm run lint` is expected to run both ESLint and Prettier checks (`lint:eslint && lint:prettier`). Repos that do not have a `lint` script will fail the lint job.
- `npm run build` and `npm test` must be defined in the consumer repo's `package.json`.
- `STARTUP_TYPE` and `GH_TOKEN` top-level env vars present in the legacy `node.js.yml` have been intentionally removed: `STARTUP_TYPE` was a leftover from integration test era (unit tests must be self-contained), and `GH_TOKEN` is replaced by the scoped `NODE_AUTH_TOKEN` pattern which is the correct approach for `actions/setup-node` registry authentication.
