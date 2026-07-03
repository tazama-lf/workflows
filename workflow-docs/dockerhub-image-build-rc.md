# `dockerhub-image-build-rc.yml`

## Purpose

Builds a Docker image and pushes it to Docker Hub with a floating `:rc` tag whenever code is merged to `dev`. Provides a testable release-candidate image without overwriting the stable production tag.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `push` | branches: `[dev]` |
| `workflow_dispatch` | manual |

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

### `push_to_registry` - Push Docker image to Docker Hub

**Steps:**

1. `actions/checkout@v4` (`ref: dev`) - checks out the `dev` (rc) line
2. `docker/login-action@4907a6ddec9925e35a0a9e82d7399ccc52663121` - authenticates to Docker Hub
3. `Set ENV variables` - derives `REPO_NAME` from `GITHUB_REPOSITORY`
4. `docker/metadata-action@030e881283bb7a6894de51c315a6bfe6a94e05cf` - generates tag: `type=raw,value=rc`
5. `docker/build-push-action@d08e5c354a6adb9ed34480a06d141179aa583294` - builds and pushes image; passes `GH_TOKEN` as build arg for private package access
6. `actions/attest-build-provenance@a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` - generates local build attestation (`push-to-registry: false` - RC builds are not published to the Sigstore transparency log)
7. `Send Slack Notification` - posts to `SLACK_WEBHOOK_URL`

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `DOCKER_USERNAME` | org | Docker Hub login |
| `DOCKER_PASSWORD` | org | Docker Hub password |
| `GH_TOKEN` | org | `npm ci` build arg for private package access |
| `SLACK_WEBHOOK_URL` | org | Slack notification |

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| `REPOS` (service repos) | Receives this file |
| `SPECIFIC_REPOS` | **Excluded** - library/non-Docker repos do not build Docker images |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | tag ref `v4` | - |
| `docker/login-action` | `4907a6ddec9925e35a0a9e82d7399ccc52663121` | v3 |
| `docker/metadata-action` | `030e881283bb7a6894de51c315a6bfe6a94e05cf` | v5 |
| `docker/build-push-action` | `d08e5c354a6adb9ed34480a06d141179aa583294` | v6 |
| `actions/attest-build-provenance` | `a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` | v2 |

---

## Known Limitations / Notes

- The `:rc` tag is a floating pointer overwritten on every push to `dev`. Use a version-pinned prerelease tag (e.g. `1.2.3-rc.4`) for reproducible deployments.
- The checkout step is pinned to `ref: dev` so a manual `workflow_dispatch` always builds the `dev` line. `actions/checkout` otherwise defaults to the triggering ref, which after the default-branch pivot to `main` would build stable code and mislabel it with the `:rc` tag. Do not remove the `ref: dev` pin.
- `dependabot[bot]` actors are excluded.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| `relay-service` | Builds multiple Docker images in a matrix (one per integration plugin); the canonical single-image workflow cannot model this. Tracked in tazama-lf/workflows A5. |
