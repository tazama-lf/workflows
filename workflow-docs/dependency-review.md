# `dependency-review.yml`

## Purpose

Scans dependency manifest file changes in pull requests and blocks merging if newly added or updated dependencies contain known security vulnerabilities.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | all types |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~30 s |
| Concurrency | none |
| Permissions | `contents: read` |

---

## Jobs

### `dependency-review` - Dependency Review

**Steps:**

1. `actions/checkout@v4` - checks out source
2. `actions/dependency-review-action@v4` - reviews dependency manifests; fails PR if vulnerable versions are introduced

---

## Required Secrets

None.

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v4` | - |
| `actions/dependency-review-action` | tag ref `v4` | - |

---

## Known Limitations / Notes

- Requires GitHub Advanced Security (or a public repo) for results to be enforced as a blocking check.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
