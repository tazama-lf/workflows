# `dockerhub-image-build-dual.yml`

## Purpose

Builds two Docker images - one for the `backend` subdirectory and one for the `frontend` subdirectory - and pushes each to Docker Hub tagged with the version from the ROOT `package.json` (the single platform version stamped by the release train) plus `latest`. A **reusable workflow** (`workflow_call`): dual-container repos receive a sync-stamped caller stub of the same filename that fires on `push: main`, `release: published`, and `workflow_dispatch`, calling this definition `@v1`.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by the stamped stub in each dual-container repo |

Stub triggers: `push` branches `[main]`, `release` types `[published]`, `workflow_dispatch`.

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

### `push_backend` - Push backend Docker image to Docker Hub

**Steps:**

1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` - checks out source
2. `docker/login-action@4907a6ddec9925e35a0a9e82d7399ccc52663121` - authenticates to Docker Hub
3. `Set ENV variables` - derives `REPO_NAME` from `GITHUB_REPOSITORY`
4. `Get package version` - reads `VERSION` from the ROOT `package.json` via `node -p`; sets step output `VERSION`
5. `docker/metadata-action@030e881283bb7a6894de51c315a6bfe6a94e05cf` - generates tags: `type=raw,value=${{ steps.pkg_version.outputs.VERSION }}` and `type=raw,value=latest`; image name: `tazamaorg/<REPO_NAME>-backend`
6. `docker/build-push-action@d08e5c354a6adb9ed34480a06d141179aa583294` - builds from `./backend` context and `./backend/Dockerfile`; pushes image; passes `GH_TOKEN_LIB` as `GH_TOKEN` build secret
7. `actions/attest-build-provenance@a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` - generates and pushes build attestation to Sigstore transparency log
8. `Resolve source PR` - best-effort lookup of the PR behind the pushed commit for the notification
9. `Send Slack Notification` (`if: always()`) - posts to `SLACK_WEBHOOK_URL`

### `push_frontend` - Push frontend Docker image to Docker Hub

**Steps:**

1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` - checks out source
2. `docker/login-action@4907a6ddec9925e35a0a9e82d7399ccc52663121` - authenticates to Docker Hub
3. `Set ENV variables` - derives `REPO_NAME` from `GITHUB_REPOSITORY`
4. `Get package version` - reads `VERSION` from the ROOT `package.json` via `node -p`; sets step output `VERSION`
5. `docker/metadata-action@030e881283bb7a6894de51c315a6bfe6a94e05cf` - generates tags: `type=raw,value=${{ steps.pkg_version.outputs.VERSION }}` and `type=raw,value=latest`; image name: `tazamaorg/<REPO_NAME>-frontend`
6. `docker/build-push-action@d08e5c354a6adb9ed34480a06d141179aa583294` - builds from `./frontend` context and `./frontend/Dockerfile`; pushes image; passes `GH_TOKEN_LIB` as `GH_TOKEN` build secret
7. `actions/attest-build-provenance@a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32` - generates and pushes build attestation to Sigstore transparency log
8. `Resolve source PR` - best-effort lookup of the PR behind the pushed commit for the notification
9. `Send Slack Notification` (`if: always()`) - posts to `SLACK_WEBHOOK_URL`

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
| `DUAL_REPOS` (`connection-studio`, `rule-studio`) | Receive a **caller stub** of the same filename stamped by sync; the stub calls this reusable workflow `@v1` with `secrets: inherit` and an explicit `permissions` block |
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

- The two jobs (`push_backend` and `push_frontend`) run in parallel and are independent. A failure in one does not cancel the other.
- Both images are tagged with the same ROOT `package.json` version; the `backend/` and `frontend/` `package.json` versions are not consulted.
- The caller stub pins `@v1` - a floating tag advanced manually. The stub only picks up changes to this definition after `v1` is moved past them.
- `dependabot[bot]` actors are excluded from both jobs.

---

## Repository Overrides

None - both dual-container repos run the identical stamped stub calling this canonical definition.

| Repository | Distribution |
|-----------|--------|
| `connection-studio` | Sync-stamped caller stub (`@v1`) |
| `rule-studio` | Sync-stamped caller stub (`@v1`) |
