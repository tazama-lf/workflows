# `dockerhub-image-build-dual-rc.yml`

## Purpose

Builds two Docker images - one for the `backend` subdirectory and one for the `frontend` subdirectory - and pushes each to Docker Hub with a floating `:rc` tag whenever code is merged to `dev`. Provides testable release-candidate images for both components without overwriting the stable production tags. A **reusable workflow** (`workflow_call`): dual-container repos receive a sync-stamped caller stub of the same filename that fires on `push: dev` and `workflow_dispatch`, calling this definition `@dev`.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by the stamped stub in each dual-container repo |

Stub triggers: `push` branches `[dev]`, `workflow_dispatch`.

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~5–8 min per job (jobs run in parallel) |
| Concurrency | none |
| Permissions | `packages: write`, `contents: read`, `attestations: write`, `id-token: write` |

---

## Jobs

### `push_backend_rc` - Push backend RC Docker image to Docker Hub

**Steps:**

1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (`ref: dev`) - checks out the `dev` (rc) line
2. `docker/login-action@4907a6ddec9925e35a0a9e82d7399ccc52663121` - authenticates to Docker Hub
3. `Set ENV variables` - derives `REPO_NAME` from `GITHUB_REPOSITORY`
4. `docker/metadata-action@030e881283bb7a6894de51c315a6bfe6a94e05cf` - generates tag: `type=raw,value=rc`; image name: `tazamaorg/<REPO_NAME>-backend`
5. `docker/build-push-action@d08e5c354a6adb9ed34480a06d141179aa583294` - builds from `./backend` context and `./backend/Dockerfile`; pushes image; passes `GH_TOKEN_LIB` as `GH_TOKEN` build secret
6. `actions/attest-build-provenance@a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` - generates local build attestation (`push-to-registry: false` - RC builds are not published to the Sigstore transparency log)
7. `Resolve source PR` - best-effort lookup of the PR behind the pushed commit for the notification
8. `Send Slack Notification` (`if: always()`) - posts to `SLACK_WEBHOOK_URL`

### `push_frontend_rc` - Push frontend RC Docker image to Docker Hub

**Steps:**

1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (`ref: dev`) - checks out the `dev` (rc) line
2. `docker/login-action@4907a6ddec9925e35a0a9e82d7399ccc52663121` - authenticates to Docker Hub
3. `Set ENV variables` - derives `REPO_NAME` from `GITHUB_REPOSITORY`
4. `docker/metadata-action@030e881283bb7a6894de51c315a6bfe6a94e05cf` - generates tag: `type=raw,value=rc`; image name: `tazamaorg/<REPO_NAME>-frontend`
5. `docker/build-push-action@d08e5c354a6adb9ed34480a06d141179aa583294` - builds from `./frontend` context and `./frontend/Dockerfile`; pushes image; passes `GH_TOKEN_LIB` as `GH_TOKEN` build secret
6. `actions/attest-build-provenance@a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` - generates local build attestation (`push-to-registry: false` - RC builds are not published to the Sigstore transparency log)
7. `Resolve source PR` - best-effort lookup of the PR behind the pushed commit for the notification
8. `Send Slack Notification` (`if: always()`) - posts to `SLACK_WEBHOOK_URL`

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `DOCKER_USERNAME` | org | Docker Hub login |
| `DOCKER_PASSWORD` | org | Docker Hub password |
| `GH_TOKEN_LIB` | org | `npm ci` build secret (passed to the Docker build as `GH_TOKEN`) for private package access |
| `SLACK_WEBHOOK_URL` | org | Slack notification |

Secrets reach the reusable workflow via `secrets: inherit` in the caller stub.

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| `DUAL_REPOS` (`connection-studio`, `rule-studio`) | Receive a **caller stub** of the same filename stamped by sync; the stub calls this reusable workflow `@dev` with `secrets: inherit` and an explicit `permissions` block |
| All other repos | Excluded - the reusable definition is removed from the sync bundle (`rm -f`), like the `*-ci.yml` reusables |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `de0fac2e4500dabe0009e67214ff5f5447ce83dd` | v4 |
| `docker/login-action` | `4907a6ddec9925e35a0a9e82d7399ccc52663121` | v3 |
| `docker/metadata-action` | `030e881283bb7a6894de51c315a6bfe6a94e05cf` | v5 |
| `docker/build-push-action` | `d08e5c354a6adb9ed34480a06d141179aa583294` | v6 |
| `actions/attest-build-provenance` | `a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` | v2 |

---

## Known Limitations / Notes

- The two jobs (`push_backend_rc` and `push_frontend_rc`) run in parallel and are independent. A failure in one does not cancel the other.
- The `:rc` tag is a floating pointer overwritten on every push to `dev`. Use a version-pinned prerelease tag for reproducible deployments.
- Both checkout steps are pinned to `ref: dev` so a manual `workflow_dispatch` always builds the `dev` line. `actions/checkout` otherwise defaults to the triggering ref, which after the default-branch pivot to `main` would build stable code and mislabel it with the `:rc` tag. Do not remove the `ref: dev` pin.
- `dependabot[bot]` actors are excluded from both jobs.

---

## Repository Overrides

None - both dual-container repos run the identical stamped stub calling this canonical definition.

| Repository | Distribution |
|-----------|--------|
| `connection-studio` | Sync-stamped caller stub (`@dev`) |
| `rule-studio` | Sync-stamped caller stub (`@dev`) |
