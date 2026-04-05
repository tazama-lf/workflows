# `dockerhub-image-build.yml`

## Purpose

Builds a Docker image and pushes it to Docker Hub with a version tag derived from `package.json` (e.g. `3.1.0`) whenever a release is published or code is merged to `main`.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[main]` |
| `release` | types: `[published]` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~5–8 min |
| Concurrency | none |
| Permissions | `packages: write`, `contents: read`, `attestations: write`, `id-token: write` |

---

## Jobs

### `push_to_registry` — Push Docker image to Docker Hub

**Steps:**

1. `actions/checkout@v4` — checks out source
2. `docker/login-action@4907a6ddec9925e35a0a9e82d7399ccc52663121` — authenticates to Docker Hub
3. `Set ENV variables` — derives `REPO_NAME` from `GITHUB_REPOSITORY`
4. `Get package version` — reads `VERSION` from `package.json` via `node -p`; sets step output `VERSION`
5. `docker/metadata-action@030e881283bb7a6894de51c315a6bfe6a94e05cf` — generates tag: `type=raw,value=${{ steps.pkg_version.outputs.VERSION }}`
6. `docker/build-push-action@d08e5c354a6adb9ed34480a06d141179aa583294` — builds and pushes image; passes `GH_TOKEN` as build arg
7. `actions/attest-build-provenance@a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` — generates and pushes build attestation to Sigstore transparency log
8. `Send Slack Notification` — posts to `SLACK_WEBHOOK_URL`

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|-------|
| `DOCKER_USERNAME` | org | Docker Hub login |
| `DOCKER_PASSWORD` | org | Docker Hub password |
| `GH_TOKEN` | org | `npm ci` build arg for private package access |
| `SLACK_WEBHOOK_URL` | org | Slack notification |

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| `REPOS` (service repos) | Receives this file |
| `SPECIFIC_REPOS` | **Excluded** — library/non-Docker repos do not build Docker images |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v4` | — |
| `docker/login-action` | `4907a6ddec9925e35a0a9e82d7399ccc52663121` | v3 |
| `docker/metadata-action` | `030e881283bb7a6894de51c315a6bfe6a94e05cf` | v5 |
| `docker/build-push-action` | `d08e5c354a6adb9ed34480a06d141179aa583294` | v6 |
| `actions/attest-build-provenance` | `a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` | v2 |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- Version tag is read from `package.json` at build time; if `package.json` version is stale the wrong tag will be pushed. `version-check.yml` guards against prerelease versions reaching `main` in library repos, but service repos have no equivalent guard.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| `relay-service` | Builds multiple Docker images in a matrix (one per integration plugin); the canonical single-image workflow cannot model this. Tracked in tazama-lf/workflows A5. |
