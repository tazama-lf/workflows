# `gpg-verify.yml`

## Purpose

Verifies that every commit in a pull request has a valid GPG signature using the GitHub REST API, ensuring that only verified commits can be merged.

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
| Typical duration | ~20–30 s |
| Concurrency | none |
| Permissions | default |

---

## Jobs

### `gpg-verify` — GPG Verify

**Steps:**

1. `actions/checkout@v4` — full history fetch (`fetch-depth: 0`)
2. `Set up environment variables` — captures `PR_HEAD_REF`, `PR_BASE_REF`, `GITHUB_TOKEN`, `GITHUB_REPOSITORY`
3. `Check GPG verification status` — iterates commits via `git log`; queries `/repos/:repo/commits/:sha/check-runs` for each; fails if any GPG check run conclusion is not `success`

---

## Required Secrets

None (uses auto-provided `GITHUB_TOKEN`).

---

## Sync Distribution

| Group | Behaviour |
|-------|----------|
| All `REPOS` | Receives this file |

---

## Dependencies (pinned actions)

| Action | Pinned SHA | Semver alias |
|--------|-----------|----------|
| `actions/checkout` | tag ref `v4` | — |

---

## Known Limitations / Notes

- `dependabot[bot]` actors are excluded.
- The check queries the `check-runs` API endpoint for each commit individually, which may hit API rate limits on large PRs.
- The lookup relies on a check run named `"GPG verify"` already existing. On first-run PRs there may be a race condition where the check run is not yet present, causing spurious failures.

---

## Repository Overrides

| Repository | Reason |
|-----------|--------|
| _(none)_ | _(all synced repos use the canonical version)_ |
