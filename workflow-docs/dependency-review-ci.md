# `dependency-review-ci.yml`

## Purpose

Centralised reusable workflow that runs GitHub's Dependency Review action on every pull request, blocking merges that introduce dependencies with known vulnerabilities or incompatible licences. Called by the [`dependency-review.yml`](dependency-review.md) caller stub in every consumer repo. **Not synced to consumer repos.**

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `workflow_call` | Called by `dependency-review.yml` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~1 min |
| Concurrency | none |
| Permissions | `contents: read` (default) |

---

## Jobs

### `dependency-review`

**Steps:**

1. `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4) - checks out the repository
2. `actions/dependency-review-action@2031cfc080254a8a887f58cffee85186f0e49e48` (v4.9.0) - scans the diff for dependency changes; fails if any introduced dependency has a known CVE or an incompatible licence

---

## Required Secrets

None. Uses the default `GITHUB_TOKEN` (implicit).

---

## Permissions

| Scope | Level |
|-------|-------|
| `contents` | `read` |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | v4 |
| `actions/dependency-review-action` | `2031cfc080254a8a887f58cffee85186f0e49e48` | v4.9.0 |
