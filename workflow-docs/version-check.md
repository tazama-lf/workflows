# `version-check.yml`

## Purpose

Blocks a pull request from merging to `main` if `package.json` contains a prerelease version suffix (e.g. `1.2.3-rc.1`). Ensures only clean semver versions (`X.Y.Z`) reach `main` and are published as the `latest` dist-tag by `publish.yml`.

---

## Trigger

| Event | Conditions |
|-------|-----------|
| `pull_request` | branches: `[main]` |

---

## Execution Context

| Property | Value |
|----------|-------|
| Runner | `ubuntu-latest` |
| Typical duration | ~15 s |
| Concurrency | none |
| Permissions | `contents: read` |

---

## Jobs

### `check-version`

**Steps:**

1. `actions/checkout@v4` — checks out source
2. `Reject prerelease version on main PR` — reads `.version` from `package.json` via `jq`; exits `1` with an actionable message (showing both the current version and the corrected stable version) if a `-` suffix is detected

---

## Required Secrets

None.

---

## Sync Distribution

| Group | Behaviour |
|-------|-----------|
| `PUBLISH_REPOS` | Receives this file |
| All service repos (non-`PUBLISH_REPOS`) | **Excluded** — service repos do not publish npm packages and do not use the prerelease guard |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|--------------|
| `actions/checkout` | tag ref `v4` | — |

---

## Known Limitations / Notes

- Companion to `publish.yml` (guards the `main` push trigger) and `release-train.yml` (creates the release PR with the resolved stable version). Together these three form the library release pipeline.
- Only checks for a prerelease suffix; does not validate that the new version is higher than the previously published version.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all PUBLISH_REPOS use the canonical version)_ |
