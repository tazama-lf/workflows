# `publish.yml`

## Purpose

Publishes a Node.js package to GitHub Packages (`@tazama-lf` scope). Prerelease versions (containing `-`) are published under the `rc` dist-tag so they do not become the default `latest` install target; stable versions are published under `latest`. Triggered automatically on merge to `main` or manually via `workflow_dispatch`.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[main]` |
| `workflow_dispatch` | manual |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Node version | `20` |
| Registry | `https://npm.pkg.github.com/` |
| Scope | `@tazama-lf` |
| Typical duration | ~1–2 min |
| Concurrency | none |
| Permissions | `packages: write`, `contents: read` |

---

## Jobs

### `build-and-publish`

**Steps:**

1. `actions/checkout@v4` - checks out source (token: `GH_TOKEN_LIB`)
2. `actions/setup-node@v4` - Node 20, GitHub Packages registry, `@tazama-lf` scope
3. `Set up npm authentication` - appends `_authToken` to `~/.npmrc`
4. `npm ci` - installs dependencies
5. `npm run build` - compiles package
6. `Publish package` - reads version from `package.json`; if version contains `-` publishes with `--tag rc`; otherwise publishes with implicit `latest`
7. `Send Slack notification` - posts to `SLACK_WEBHOOK_URL`

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `GH_TOKEN_LIB` | org | npm publish auth + checkout token |
| `SLACK_WEBHOOK_URL` | org | Slack notification |

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| `PUBLISH_REPOS` | Receives this file |
| All service repos (non-`PUBLISH_REPOS`) | **Excluded** - service repos publish Docker images, not npm packages |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | tag ref `v4` | - |
| `actions/setup-node` | tag ref `v4` | - |

---

## Known Limitations / Notes

- Works in conjunction with `version-check.yml` (blocks prerelease merging to `main`) and `release-train.yml` (creates the release PR with stable version). Together these three form the library release pipeline.
- Resolves tazama-lf/workflows#27.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all PUBLISH_REPOS use the canonical version)_ |
